return {
  name = "google-cloud-functions",
  fields = {
    { config = {
        type = "record",
        fields = {
          -- connection basics
          { timeout       = { type = "number",  default  = 600000}, },
          { keepalive     = { type = "number",  default  = 60000 }, },
          { https         = { type = "boolean", default  = true  }, },
          { https_verify  = { type = "boolean", default  = false }, },
          -- authorization
          {
            google_key = {
              type = "record",
              required = false,
              fields = {
                { private_key = { type = "string", required = true },},
                { client_email = { type = "string", required = true },},
                { token_uri = { type = "string", required = true },},
              }
            },
          },
          {
            google_key_file = { type = "string", required = false},
          },
          -- target/location
          { hostdomain    = { type = "string",  required = true, default = "cloudfunctions.net" }, },
          { functionname  = { type = "string",  required = true  }, },
          { region = { type = "string", required = true },},
          { project_id = { type = "string", required = true },},
        },
    }, },
  },
}
