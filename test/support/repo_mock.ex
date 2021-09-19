defmodule Mantis.RepoMock.Behaviour do
  @callback insert(Ecto.Query.t()) :: {:ok, term()}
  @callback one(Ecto.Query.t()) :: map() | nil
end
