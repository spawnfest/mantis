defmodule Mantis.Storage do
  @moduledoc false
  # This module provides a genserver for maintaining registers. It monitors
  # node connects in order to propagate existing registers.
  # TODO: This genserver is a bottleneck on the system. We should really try
  # to resolve this and move more work into the calling process in the future.

  use GenServer

  require Logger

  alias Mantis.Register

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  # Lookup the value for the key in ets. Return nil otherwise
  def get(key) do
    case :ets.lookup(__MODULE__, key) do
      [] ->
        nil

      [{^key, value}] ->
        value
    end
  end

  # The main api for setting a keys value
  def set(key, value) do
    GenServer.call(__MODULE__, {:set, key, value})
  end

  # Deletes all keys in the currently connected cluster. This is only
  # intended to be used in development and test
  def delete_all() do
    GenServer.multi_call(__MODULE__, :delete_all)
  end

  @impl true
  def init(args) do
    Process.flag(:trap_exit, true)

    :net_kernel.monitor_nodes(true)
    tab = __MODULE__ = :ets.new(__MODULE__, [:named_table, :set, :protected])
    registers = %{}
    schedule_sync_timeout()
    schedule_flush()

    {:ok, %{table: tab, registers: registers, repo: args[:repo]}, {:continue, :hydrate}}
  end

  @impl true
  def handle_continue(:hydrate, data) do
    import Ecto.Query

    Logger.info("[mantis][#{node()}] Hydrating from database..")

    registers =
      Mantis.Store
      |> order_by([s], [desc: s.clock])
      |> limit(1)
      |> select([s], s.registers)
      |> data.repo.one()
      |> Kernel.||(%{})

    GenServer.cast(__MODULE__, {:update_registers, registers})
    {:noreply, data}
  end

  @impl true
  def handle_call({:set, key, value}, _from, data) do
    registers = Map.update(data.registers, key, Register.new(key, value), fn reg ->
      Register.update(reg, value)
    end)
    :ets.insert(data.table, {key, registers[key].value})
    GenServer.abcast(__MODULE__, {:update_register, registers[key]})

    {:reply, :ok, %{data | registers: registers}}
  end

  def handle_call(:delete_all, _from, data) do
    registers = %{}
    :ets.delete_all_objects(data.table)

    {:reply, :ok, %{data | registers: registers}}
  end

  @impl true
  def handle_cast({:update_register, reg}, data) do
    registers = Map.update(data.registers, reg.key, reg, fn existing_reg ->
      Register.latest(reg, existing_reg)
    end)
    :ets.insert(data.table, {reg.key, registers[reg.key].value})
    {:noreply, %{data | registers: registers}}
  end

  def handle_cast({:update_registers, registers}, data) do
    new_registers = merge(data.registers, registers)

    for {key, reg} <- new_registers do
      :ets.insert(data.table, {key, reg.value})
    end

    {:noreply, %{data | registers: new_registers}}
  end

  @impl true
  def handle_info(msg, data) do
    case msg do
      {:nodeup, node} ->
        GenServer.cast({__MODULE__, node}, {:update_registers, data.registers})
        {:noreply, data}

      :sync_timeout ->
        GenServer.abcast(__MODULE__, {:update_registers, data.registers})
        schedule_sync_timeout()
        {:noreply, data}

      :flush ->
        schedule_flush()

        data.registers
        |> do_flush(data.repo)
        {:noreply, data}

      _msg ->
        {:noreply, data}
    end
  end

  @impl true
  def terminate(_reason, data) do
    data.registers
    |> do_flush(data.repo)
  end

  defp do_flush(term, repo) do
    {:ok, hlc} = HLClock.now(Mantis.Clock)

    data = %Mantis.Store{
      node: to_string(node()),
      registers: term,
      clock: hlc
    }

    Logger.info("[mantis][#{node()}] Flushing content to database..")
    case repo.insert(data) do
      {:ok, _} ->
        Logger.info("[mantis][#{node()}] Flushed data to database")
      reason ->
        Logger.error("[mantis][#{node()}] Error while flushing to database: #{inspect(reason)}")
    end
  end

  defp schedule_sync_timeout do
    # Wait between 10 and 20 seconds before doing another sync
    next_timeout = (:rand.uniform(10) * 1000) + 10_000
    Process.send_after(self(), :sync_timeout, next_timeout)
  end

  defp schedule_flush do
    one_minute = 60 * 1000
    Process.send_after(self(), :flush, one_minute)
  end

  defp merge(r1, r2) do
    keys =
      [Map.keys(r1), Map.keys(r2)]
      |> List.flatten()
      |> Enum.uniq

    keys
    |> Enum.map(fn key -> {key, Register.latest(r1[key], r2[key])} end)
    |> Enum.into(%{})
  end
end
