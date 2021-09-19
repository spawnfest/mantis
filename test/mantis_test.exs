defmodule MantisTest do
  use ExUnit.Case
  import Mox

  doctest Mantis

  setup :set_mox_global
  setup :verify_on_exit!

  setup_all do
    Application.ensure_all_started(:mantis)
    nodes = LocalCluster.start_nodes("mantis", 2)

    {:ok, nodes: nodes}
  end

  setup do
    Mantis.Storage.delete_all()

    :ok
  end

  test "local node" do
    await_expect(%{})

    Mantis.set(:key, "value")

    assert Mantis.get(:key) == "value"
  end

  test "local node with hydration" do
    {:ok, hlc} = HLClock.now(Mantis.Clock)

    await_expect(%{key: %{key: :key, value: "value", hlc: hlc}})

    eventually(fn ->
      assert Mantis.get(:key) == "value"
    end)
  end

  # test "registers are replicated to connected nodes", %{nodes: nodes} do
    # [n1, n2] = nodes

    # await_expect(%{})

    # Have trouble getting distributed nodes to start Mantis..
    # :rpc.call(n1, Mantis, :start_link, [])
    # :rpc.call(n2, Mantis, :start_link, [])

    # Mantis.set(:key, "value")

    # eventually(fn ->
      # assert :rpc.call(n1, Mantis, :get, [:key]) == "value"
      # assert :rpc.call(n2, Mantis, :get, [:key]) == "value"
    # end)
  # end

  # test "disconnected nodes are caught up when they reconnect", %{nodes: nodes} do
  #   [n1, n2] = nodes

  #   Schism.partition([n1])

  #   :rpc.call(n2, Mantis, :set, [:key, "value"])

  #   eventually(fn ->
  #     assert Mantis.get(:key) == "value"
  #     assert :rpc.call(n1, Mantis, :get, [:key]) == nil
  #     assert :rpc.call(n2, Mantis, :get, [:key]) == "value"
  #   end)

  #   Schism.heal([n1, n2])

  #   eventually(fn ->
  #     assert Mantis.get(:key) == "value"
  #     assert :rpc.call(n1, Mantis, :get, [:key]) == "value"
  #     assert :rpc.call(n2, Mantis, :get, [:key]) == "value"
  #   end)
  # end

  # test "sending a register from the past is discarded", %{nodes: nodes} do
  #   [n1, n2] = nodes

  #   Schism.partition([n1])

  #   :rpc.call(n2, Mantis, :set, [:key, "first"])

  #   eventually(fn ->
  #     assert Mantis.get(:key) == "first"
  #     assert :rpc.call(n1, Mantis, :get, [:key]) == nil
  #     assert :rpc.call(n2, Mantis, :get, [:key]) == "first"
  #   end)

  #   :rpc.call(n1, Mantis, :set, [:key, "second"])

  #   eventually(fn ->
  #     assert Mantis.get(:key) == "second"
  #     assert :rpc.call(n1, Mantis, :get, [:key]) == "second"
  #     assert :rpc.call(n2, Mantis, :get, [:key]) == "first"
  #   end)

  #   Schism.heal([n1, n2])

  #   eventually(fn ->
  #     assert Mantis.get(:key) == "second"
  #     assert :rpc.call(n1, Mantis, :get, [:key]) == "second"
  #     assert :rpc.call(n2, Mantis, :get, [:key]) == "second"
  #   end)
  # end

  # @tag :skip
  # test "crashing processes does not result in lost data" do
  #   flunk "Not Implemented"

  #   # start_supervised!({Mantis, [repo: Mantis.TestRepo]})

  #   Mantis.set(:key, "value")

  #   assert Mantis.get(:key) == "value"

  #   Process.whereis(Mantis.Storage) |> Process.exit(:kill)

  #   assert Mantis.get(:key) == nil

  #   eventually(fn ->
  #     assert Mantis.get(:key) == "value"
  #   end)


  # end

  def eventually(f, retries \\ 0) do
    f.()
  rescue
    err ->
      if retries >= 10 do
        reraise err, __STACKTRACE__
      else
        :timer.sleep(500)
        eventually(f, retries + 1)
      end
  catch
    _exit, _term ->
      :timer.sleep(500)
      eventually(f, retries + 1)
  end

  # Helper function to start `Mantis` and hide away the async nature of the start-up sequence.
  defp await_expect(expected) do
    parent = self()
    ref = make_ref()

    Mantis.RepoMock
    |> expect(:one, fn _ ->
        send(parent, {ref, :done})
        expected
    end)

    Mantis.RepoMock
    |> stub(:insert, fn _ -> {:ok, :ok} end)

    Mantis.start_link([repo: Mantis.RepoMock])

    assert_receive {^ref, :done}
  end
end
