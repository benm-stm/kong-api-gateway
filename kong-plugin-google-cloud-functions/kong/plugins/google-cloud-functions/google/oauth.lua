local http = require "ssl.https"
local json = require "cjson"
local mime = require "mime"
local url = require "socket.url"
local inspect = require "inspect"
local jwt_parser = require "kong.plugins.jwt.jwt_parser"

local pkey = require "resty.openssl.pkey"
local digest = require "resty.openssl.digest"

local _M = {}

function _M:GetAccessToken()
  return self.generate_access_token(self)
end

function _M:SignString(string_to_sign)
  return self.sign_string(self, string_to_sign)
end

function _M:GetClientEmail()
  return self._client_email
end

function _M:GetProjectID()
  return self._project_id
end

function read_key_return_json(path)
  local file, err = io.open(path, "r")
  if not file then error("OAuth2: Can't read key file: " .. err) end
  if file then
    local contents = file:read("*a")
    local key_table = json.decode(contents);
    io.close(file)
    if type(key_table) == "table" then
      return key_table
    end
  end
  return nil
end

function params_builder(tbl)
  local tuples do
    local keyval = {}
    local index = 1
    for k, v in pairs(tbl) do
      keyval[index] = tostring(url.escape(k)) .. "=" .. tostring(url.escape(v))
      index = index + 1
    end
    tuples = keyval
  end
  return table.concat(tuples, "&")
end

-- @param scope (string) can be multiple scopes seperated by space, e.g. "scope1 scope2 scope2"
function construct(self, key_path, key, scope, function_full_url)
  local self
  local key_table = key_path and read_key_return_json(key_path) or key
  if key_table == nil then
    error("Either key_path or key must be specified")
    return self
  end

  self = setmetatable({
    _client_email = key_table.client_email,
    _private_key = key_table.private_key,
    _project_id = key_table.project_id,
    _function_full_url = function_full_url,
    _access_token = nil,
    _access_token_expire_time = nil,
    _scope = scope,
    _auth_token_url = key_table.token_uri,
    generate_access_token = function(self)
      if not self._access_token or os.time() > self._access_token_expire_time - 60 then
        self.refresh_access_token(self)
      end
      return self._access_token
    end,
    refresh_access_token = function(self)
      local time = os.time()
      local jwt = self.make_jwt(self)
      local req_params = params_builder({
       grant_type = "urn:ietf:params:oauth:grant-type:jwt-bearer",
       assertion = jwt
      })

      local res = assert(http.request(self._auth_token_url, req_params))
      res = json.decode(res)

      local unsafe, err = jwt_parser:new(res.id_token)

      if err then
        error("Bad token: " .. tostring(err))
      end
      
      print(inspect(unsafe.claims.exp))
      self._access_token_expire_time = time + unsafe.claims.exp
      self._access_token = res.id_token
    end,
    make_jwt = function(self)
      local claims = json.encode({
       iss = self._client_email,
       aud = self._auth_token_url,
       target_audience = self._function_full_url,
       iat = os.time(),
       exp = os.time() + (60 * 60)
      })
      local sign_input = mime.b64('{"alg":"RS256","typ":"JWT"}') .. "." .. mime.b64(claims)
      local signature = self.sign_string(self, sign_input)
      return sign_input .. "." .. signature
    end,
    sign_string = function(self, string_to_sign)
      local key = assert(pkey.new(self._private_key:gsub("\\n", "\n"), { format = "PEM", type = "pr" }))
      local d = assert(digest.new("sha256WithRSAEncryption"))
      d:update(string_to_sign)
      local sig = assert(key:sign(d))
      return (mime.b64(sig))
    end
  }, {__index = _M})
  return self
end

setmetatable(_M, {__call = construct, __type = "google.core.OAuth"})
return _M