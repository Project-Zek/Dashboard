defmodule ProjectZek.LoginServer.HashUtils do
  def sha1(input) do
    :crypto.hash(:sha, input)
    |> Base.encode16(case: :lower)
  end
end
