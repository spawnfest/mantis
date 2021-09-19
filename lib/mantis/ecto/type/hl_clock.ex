defmodule Mantis.Ecto.Type.HLClock do
  use Ecto.Type

  alias HLClock.Timestamp

  def type, do: :string

  def cast(%Timestamp{} = ts), do: {:ok, ts}
  def cast(_), do: :error

  def load(data) do
    # Because ISO8601 time has `-`, splitting on that breaks that up, so we need to manually construct it back.
    [year, month, time, counter, node_id] = String.split(data, "-")
    t = Enum.join([year, month, time], "-")
    {:ok, dt, _} = DateTime.from_iso8601(t)

    t = DateTime.to_unix(dt)
    counter = Base.decode16!(counter) |> :binary.decode_unsigned()
    node_id = Base.decode16!(node_id) |> :binary.decode_unsigned()

    {:ok, Timestamp.new(t, counter, node_id)}
  end

  def dump(%Timestamp{} = ts), do: {:ok, to_string(ts)}
  def dump(_), do: :error
end
