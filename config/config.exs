import Config

config :ex_ipfs,
  api_url: "http://127.0.0.1:5001/api/v0"

config :ex_ipfs_pubsub,
  api_url: "ws://127.0.0.1:5002/topic"

import_config "#{config_env()}.exs"
