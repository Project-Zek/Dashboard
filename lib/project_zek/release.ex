defmodule ProjectZek.Release do
  @moduledoc """
  Release helpers for running Ecto tasks in a Mix release.

  Usage (on the server):
    bin/project_zek eval "ProjectZek.Release.migrate"
    bin/project_zek eval "ProjectZek.Release.rollback(ProjectZek.Repo, 20240329142045)"
  """

  @app :project_zek

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} =
        Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end

    :ok
  end

  def rollback(repo, version) do
    load_app()

    {:ok, _, _} =
      Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))

    :ok
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end

