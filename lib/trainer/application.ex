defmodule Trainer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TrainerWeb.Telemetry,
      Trainer.Repo,
      {DNSCluster, query: Application.get_env(:trainer, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Trainer.PubSub},
      # Start a worker by calling: Trainer.Worker.start_link(arg)
      # {Trainer.Worker, arg},
      # Start to serve requests, typically the last entry
      TrainerWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Trainer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TrainerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
