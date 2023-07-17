import Config

config :ex_ipfs,
  api_url: "http://127.0.0.1:5001/api/v0"

config :myspace_pubsub,
  api_url: "http://127.0.0.1:5002/api/v0",
  # URI module doesn't support ws://
  ws_url: "ws://127.0.0.1:5002/api/v0"

import_config "#{config_env()}.exs"
