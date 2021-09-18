# Mantis

I am Mantis.

## Usage

Mantis provides a distributed KV store for ephemeral data. It utilizes LWW-register
CRDTs and Hybrid-Logical clocks to ensure availability and a level
of consistency. For technical information on Mantis's implementation, please
refer to the [docs](https://hexdocs.pm/mantis).

## Installation

```elixir
def deps do
  [
    {:mantis, "~> 0.1"}
  ]
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
