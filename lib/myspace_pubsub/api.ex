defmodule MyspacePubsub.Api do
  @moduledoc false
  use Tesla

  @api_url Application.compile_env(:myspace_pubsub, :api_url, "http://127.0.0.1:5002/api/v0")

  plug(Tesla.Middleware.BaseUrl, @api_url)
  plug(Tesla.Middleware.JSON)
end
