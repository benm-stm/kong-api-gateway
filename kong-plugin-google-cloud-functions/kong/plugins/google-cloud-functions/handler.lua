local constants     = require "kong.constants"
local meta          = require "kong.meta"
local http          = require "resty.http"
local OAuth = require "kong.plugins.google-cloud-functions.google.oauth"
local cjson = require "cjson"
local inspect = require('inspect')

local kong          = kong
local var           = ngx.var
local pairs         = pairs
local server_header = meta._SERVER_TOKENS
local conf_cache    = setmetatable({}, { __mode = "k" })

local function send(status, content, headers)
  if kong.configuration.enabled_headers[constants.HEADERS.VIA] then
    headers = kong.table.merge(headers)
    headers[constants.HEADERS.VIA] = server_header
  end

  return kong.response.exit(status, content, headers)
end


local gcp = {
  VERSION  = "1.0.0",
}

function gcp:get_key(conf)
  if conf.google_key then
    return conf.google_key
  end

  if conf.google_key_file then
    if self.key_file_cache ~= nil then
      return self.key_file_cache
    end

    local file_content = assert(assert(io.open(conf.google_key_file)):read("*a"))
    self.key_file_cache = cjson.decode(file_content)
    return self.key_file_cache
  end

  return nil
end


function gcp:access(config)
  local conf = conf_cache[config]
  if not conf then
    conf = {}
    for k,v in pairs(config) do
      conf[k] = v
    end
    conf.host = config.region .. "-" .. config.project_id .. "." .. config.hostdomain
    conf.port = config.https and 443 or 80
    local path = (config.functionname or ""):match("^/*(.-)/*$")

    conf.path = "/" .. path

    conf_cache[config] = conf
  end
  config = conf

  local client = http.new()
  local request_method = kong.request.get_method()
  local request_body = kong.request.get_raw_body()
  local request_headers = kong.request.get_headers()
  local request_args = kong.request.get_query()

  local key = self:get_key(config)
  local scope = "https://www.googleapis.com/auth/platform"
  local function_full_url = "https://" .. config.host .. config.path
  local oauth = OAuth(nil, key, scope, function_full_url)
  if oauth == nil then
    kong.log.err("Failed to create OAuth")
    return nil
  end

  client:set_timeout(config.timeout)

  local ok, err = client:connect(config.host, config.port)
  if not ok then
    kong.log.err("could not connect to Google service: ", err)
    return kong.response.exit(500, { message = "An unexpected error ocurred" })
  end

  if config.https then
    local ok2, err2 = client:ssl_handshake(false, config.host, config.https_verify)
    if not ok2 then
      kong.log.err("could not perform SSL handshake : ", err2)
      return kong.response.exit(500, { message = "An unexpected error ocurred" })
    end
  end

  local upstream_uri = var.upstream_uri
  local path = conf.path
  local end1 = path:sub(-1, -1)
  local start2 = upstream_uri:sub(1, 1)
  if end1 == "/" then
    if start2 == "/" then
      path = path .. upstream_uri:sub(2,-1)
    else
      path = path .. upstream_uri
    end
  else
    if start2 == "/" then
      path = path .. upstream_uri
    else
      if upstream_uri ~= "" then
        path = path .. "/" .. upstream_uri
      end
    end
  end
  print(inspect(request_headers))
  request_headers["host"] = nil
  request_headers["Authorization"] = "Bearer " .. tostring(oauth:GetAccessToken())

  local res
  res, err = client:request {
    method  = request_method,
    path    = path,
    body    = request_body,
    query   = request_args,
    headers = request_headers,
  }

  if not res then
    kong.log.err(err)
    return kong.response.exit(500, { message = "An unexpected error occurred" })
  end

  local response_headers = res.headers
  local response_status = res.status
  local response_content = res:read_body()

  if var.http2 then
    response_headers["Connection"] = nil
    response_headers["Keep-Alive"] = nil
    response_headers["Proxy-Connection"] = nil
    response_headers["Upgrade"] = nil
    response_headers["Transfer-Encoding"] = nil
  end

  ok, err = client:set_keepalive(config.keepalive)
  if not ok then
    kong.log.err("could not keepalive connection: ", err)
  end

  return send(response_status, response_content, response_headers)
end


return gcp