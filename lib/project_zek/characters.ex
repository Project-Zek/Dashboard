defmodule ProjectZek.Characters do
  @moduledoc """
  The Characters context.
  """

  import Ecto.Query, warn: false
  alias ProjectZek.Repo

  alias ProjectZek.Characters.PvpEntry

  @doc """
  Returns the list of character_pvp_entries.

  ## Examples

      iex> list_character_pvp_entries()
      [%PvpEntry{}, ...]

  """
  def list_character_pvp_entries do
    Repo.all(PvpEntry)
  end

  @doc """
  Gets a single pvp_entry.

  Raises `Ecto.NoResultsError` if the Pvp entry does not exist.

  ## Examples

      iex> get_pvp_entry!(123)
      %PvpEntry{}

      iex> get_pvp_entry!(456)
      ** (Ecto.NoResultsError)

  """
  def get_pvp_entry!(id), do: Repo.get!(PvpEntry, id)

  @doc """
  Creates a pvp_entry.

  ## Examples

      iex> create_pvp_entry(%{field: value})
      {:ok, %PvpEntry{}}

      iex> create_pvp_entry(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_pvp_entry(attrs \\ %{}) do
    %PvpEntry{}
    |> PvpEntry.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a pvp_entry.

  ## Examples

      iex> update_pvp_entry(pvp_entry, %{field: new_value})
      {:ok, %PvpEntry{}}

      iex> update_pvp_entry(pvp_entry, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_pvp_entry(%PvpEntry{} = pvp_entry, attrs) do
    pvp_entry
    |> PvpEntry.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a pvp_entry.

  ## Examples

      iex> delete_pvp_entry(pvp_entry)
      {:ok, %PvpEntry{}}

      iex> delete_pvp_entry(pvp_entry)
      {:error, %Ecto.Changeset{}}

  """
  def delete_pvp_entry(%PvpEntry{} = pvp_entry) do
    Repo.delete(pvp_entry)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking pvp_entry changes.

  ## Examples

      iex> change_pvp_entry(pvp_entry)
      %Ecto.Changeset{data: %PvpEntry{}}

  """
  def change_pvp_entry(%PvpEntry{} = pvp_entry, attrs \\ %{}) do
    PvpEntry.changeset(pvp_entry, attrs)
  end
end
