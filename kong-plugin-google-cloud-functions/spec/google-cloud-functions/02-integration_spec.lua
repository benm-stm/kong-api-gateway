local helpers = require "spec.helpers"
local meta = require "kong.meta"
local inspect = require "inspect"
local os = require "os"



local PLUGIN_NAME = "google-cloud-functions"

local server_tokens = meta._SERVER_TOKENS
local function_secret = os.getenv("KONG_GCP_FUNCTION_SECRET")


for _, strategy in helpers.each_strategy() do
  describe(PLUGIN_NAME .. ": (access) [#" .. strategy .. "]", function()
    local proxy_client

    lazy_setup(function()

      local bp = helpers.get_db_utils(strategy, nil, { PLUGIN_NAME })

      -- Inject a test route. No need to create a service, there is a default
      -- service which will echo the request.
      local route1 = bp.routes:insert({
        hosts = { "cloudfunctions.net" },
      })
      -- add the plugin to test to the route we created
      bp.plugins:insert {
        name = PLUGIN_NAME,
        route = { id = route1.id },
        config = {
          https = true,
          functionname = "function-2",
          region = "us-central1",
          project_id = "personal-website-a60f9",
          google_key = {
             private_key = function_secret,
             client_email = "function-caller@personal-website-a60f9.iam.gserviceaccount.com",
             token_uri = "https://oauth2.googleapis.com/token",
          }
        },
      }

      -- start kong
      assert(helpers.start_kong({
        -- set the strategy
        database   = strategy,
        -- make sure our plugin gets loaded
        plugins = "bundled," .. PLUGIN_NAME,
      }))
    end)

    lazy_teardown(function()
      helpers.stop_kong(nil, true)
    end)

    before_each(function()
      proxy_client = helpers.proxy_client()
    end)

    after_each(function()
      if proxy_client then proxy_client:close() end
    end)

    it("basic access to cloud function", function()
      local res = assert(proxy_client:send {
        method  = "POST",
        path    = "/",
        headers = {
          ["Host"] = "cloudfunctions.net"
        }
      })

      assert.response(res).has.status(200)
    end)

  end)
end
