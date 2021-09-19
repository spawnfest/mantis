# Mantis

Mantis is a distributed, eventually consistent KV store built on top of [Groot](https://github.com/keathley/groot). It inherits the characteristics of Groot (LWW CRDT and Hybrid-Logical Clock), but while Groot is meant for ephemeral data, Mantis adds a persistence layer.

Mantis periodically flushes the KV content to a database, it also flushes when it is being shut down.

Mantis is a Spawnfest project and is not ready for use. [Note for judges](https://github.com/spawnfest/mantis/JUDGES.md)

## Installation

```elixir
def deps do
  [
    {:mantis, "git://github.com/spawnfest/mantis.git"}
  ]
end
```

Next, start Mantis in your supervision tree in `application.ex` and provide it a repo.

```elixir
children = [
  YourApp.Repo,
  {Mantis, [repo: YourApp.Repo]}
]
```

You also need to create a table for Mantis to store the data.

`mix ecto.gen.migration add_mantis_stores_table`

```
defmodule MyApp.Repo.Migrations.AddMantisStoresTable do
  use Ecto.Migration

  def change do
    create table(:mantis_stores) do
      add :clock, :string, null: false
      add :node, :string, null: false
      add :registers, :binary, null: false
    end
  end
end
```

## Usage

```elixir
# Changes are propogated to other nodes.
:ok = Mantis.set(:key, "value")

# Read existing values. "Gets" are always done from a local ETS table.
"value" = Mantis.get(:key)
```

`set` operations will be replicated to all connected nodes. If new nodes join, or if a node rejoins the cluster after a network partition, then the other nodes in the cluster will replicate all of their registers to the new node.

## Caveats

Mantis relies on distributed erlang. All of the data stored in Mantis is
ephemeral and is _not_ maintained between node restarts.

Because we're using CRDTs to propagate changes, a change made on one node may take time to spread to the other nodes. It's safe to run the same operation on multiple nodes. Mantis always chooses the register with the latest HLC.

Mantis replicates all registers to all nodes. If you attempt to store thousands of keys in Mantis, you'll probably have a bad time.

## Should I use this?

If you need to store and replicate a relatively small amount of transient
values, then Mantis may be a good solution for you. If you need anything beyond those features, Mantis is probably a bad fit.

Here are some examples of good use cases:

- Feature Flags - [rollout](https://github.com/keathley/rollout) is an example of this.
- Runtime configuration changes
- User session state
- Generic caching
