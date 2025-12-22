defmodule ProjectZek.EctoTypes.ZeroNaiveDatetime do
  @behaviour Ecto.Type

  def type, do: :naive_datetime

  def cast(%NaiveDateTime{} = dt), do: {:ok, dt}
  def cast(nil), do: {:ok, nil}
  def cast("0000-00-00 00:00:00"), do: {:ok, nil}
  def cast(_), do: :error

  # MariaDB/MySQL adapter may send :zero_datetime for invalid zeros
  def load(:zero_datetime), do: {:ok, nil}
  def load(%NaiveDateTime{} = dt), do: {:ok, dt}
  def load(nil), do: {:ok, nil}
  def load(_), do: :error

  def dump(%NaiveDateTime{} = dt), do: {:ok, dt}
  def dump(nil), do: {:ok, nil}
  def dump(_), do: :error
end

