defmodule Curriculum.Repo do
  use Ecto.Repo,
    otp_app: :curriculum,
    adapter: Ecto.Adapters.Postgres
end
