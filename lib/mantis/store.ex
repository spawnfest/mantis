defmodule Mantis.Store do
  @moduledoc false
  use Ecto.Schema

  schema "mantis_stores" do
    field :clock, Mantis.Ecto.Type.HLClock
    field :node, :string
    field :registers, Mantis.Ecto.Type.Registers
  end
end
