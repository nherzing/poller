defmodule Poller.Repo do
  use Ecto.Repo,
    otp_app: :poller,
    adapter: Ecto.Adapters.Postgres
end
