defmodule Mantis do
  @moduledoc """
  Mantis provides an eventually consistent, ephemeral KV store. It relies on
  distributed erlang and uses LWW-registers and Hybrid-logical clocks
  to ensure maximum availability. Mantis utilizes ETS for efficient reading.

  ## Usage

  ```elixir
  # Changes are propogated to other nodes.
  :ok = Mantis.set(:key, "value")

  # Read existing values
  "value" = Mantis.get(:key)
  ```

  Updates will replicate to all connected nodes. If a new node joins, or if a node
  rejoins the cluster after a network partition then the other nodes in the
  cluster will replicate all of their registers to the new node.

  ## Consistency

  Mantis uses LWW register CRDTs for storing values. Each register includes a
  hybrid logical clock (HLC). Ordering of events is determined by comparing HLCs.
  If a network partition occurs nodes on either side of the partition will
  continue to accept `set` and `get` operations. Once the partition heals, all
  registers will be replicated to all nodes. If there are any conflicts, the
  register with the largest HLC will be chosen.

  Mantis may lose writes under specific failures scenarios. For instance, if
  there is a network partition between 2 nodes, neither node will be able to
  replicate to the other. If either node crashes after accepting a write, that
  write will be lost.

  ## Data limitations

  Mantis replicates all keys to all connected nodes. Thus there may be performance
  issues if you attempt to store hundreds or thousands of keys. This issue may
  be fixed in a future release.
  """

  alias Mantis.Storage

  @doc """
  Gets a register's value. If the register is not found it returns `nil`.
  """
  @spec get(term()) :: term() | nil
  def get(key) do
    Storage.get(key)
  end

  @doc """
  Sets the value for a register.
  """
  @spec set(term(), term()) :: :ok
  def set(key, value) do
    Storage.set(key, value)
  end
end
