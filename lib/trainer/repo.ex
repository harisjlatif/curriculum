defmodule Trainer.Repo do
  use Ecto.Repo,
    otp_app: :trainer,
    adapter: Ecto.Adapters.Postgres
end
