defmodule ProjectZek.PvpStats do
  @moduledoc """
  The PvpStats context.
  
  Handles operations related to PvP statistics, including retrieving PvP stats along with the associated character's name.
  """

  import Ecto.Query, warn: false
  alias ProjectZek.Repo

  alias ProjectZek.Characters.PvpStat
  alias ProjectZek.Characters.CharacterData

  @doc """
  Returns the list of PvP stats.

  ## Examples

      iex> list_pvp_stats()
      [%PvpStat{}, ...]

  """
  def list_pvp_stats do
    Repo.all(PvpStat)
    |> Repo.preload(:character_data)
  end

  @doc """
  Gets a single PvP stat by ID, including the character's name.

  Raises `Ecto.NoResultsError` if the PvP stat does not exist.

  ## Examples

      iex> get_pvp_stat!(123)
      %PvpStat{}

      iex> get_pvp_stat!(456)
      ** (Ecto.NoResultsError)

  """
  def get_pvp_stat!(id) do
    PvpStat
    |> Repo.get!(id)
    |> Repo.preload(:character_data)
  end

  @doc """
  Creates a PvP stat.

  ## Examples

      iex> create_pvp_stat(%{field: value})
      {:ok, %PvpStat{}}

      iex> create_pvp_stat(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_pvp_stat(attrs \\ %{}) do
    %PvpStat{}
    |> PvpStat.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a PvP stat.

  ## Examples

      iex> update_pvp_stat(pvp_stat, %{field: new_value})
      {:ok, %PvpStat{}}

      iex> update_pvp_stat(pvp_stat, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_pvp_stat(%PvpStat{} = pvp_stat, attrs) do
    pvp_stat
    |> PvpStat.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a PvP stat.

  ## Examples

      iex> delete_pvp_stat(pvp_stat)
      {:ok, %PvpStat{}}

      iex> delete_pvp_stat(pvp_stat)
      {:error, %Ecto.Changeset{}}

  """
  def delete_pvp_stat(%PvpStat{} = pvp_stat) do
    Repo.delete(pvp_stat)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking PvP stat changes.

  ## Examples

      iex> change_pvp_stat(pvp_stat)
      %Ecto.Changeset{data: %PvpStat{}}

  """
  def change_pvp_stat(%PvpStat{} = pvp_stat, attrs \\ %{}) do
    PvpStat.changeset(pvp_stat, attrs)
  end

  @doc """
  Fetches a PvP stat along with the character's name using the `character_data_id`.

  ## Examples

      iex> fetch_pvp_stat_with_character_name(123)
      {:ok, %{pvp_stat: %PvpStat{}, character_name: "CharacterName"}}

      iex> fetch_pvp_stat_with_character_name(456)
      {:error, :not_found}

  """
  def fetch_pvp_stat_with_character_name(id) do
    query =
      from p in PvpStat,
        where: p.id == ^id,
        join: c in CharacterData,
        on: p.character_data_id == c.id,
        select: %{pvp_stat: p, character_name: c.name}

    case Repo.one(query) do
      nil -> {:error, :not_found}
      result -> {:ok, result}
    end
  end
end