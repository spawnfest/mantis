defmodule Mantis.Ecto.Type.Registers do
  use Ecto.Type

  def type, do: :binary

  def cast(r) when is_map(r), do: {:ok, r}

  def cast(_), do: :error

  def load(data) do
    {:ok, :erlang.binary_to_term(data)}
  end

  def dump(r) when is_map(r), do: {:ok, :erlang.term_to_binary(r)}
  def dump(_), do: :error
end
