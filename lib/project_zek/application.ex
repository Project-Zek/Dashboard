defmodule ProjectZek.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ProjectZekWeb.Telemetry,
      ProjectZek.Repo,
      {DNSCluster, query: Application.get_env(:project_zek, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ProjectZek.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: ProjectZek.Finch},
      # Start a worker by calling: ProjectZek.Worker.start_link(arg)
      # {ProjectZek.Worker, arg},
      # Start to serve requests, typically the last entry
      ProjectZekWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ProjectZek.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ProjectZekWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
