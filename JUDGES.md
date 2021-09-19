Thanks for taking the time to review my project!

Mantis is a proof of concept to add a persistence layer to Groot.

I chose this project because while I really like Groot's idea of an eventual consistent KV store, I thought Groot being ephemeral would reduce a number of potential use cases (especially since most deployments are stateless), so I thought I'd have a go at adding persistence layer.

You can also think of Mantis as another version DETS/Mnesia.

- Mnesia writes are expensive because it needs a transaction across the cluster, and it is also not tolerant of net splits.
- DETS is another choice, but it requires disk access whereas with my usual deployment with Render/Fly.io, I don't get access to disk space, so I thought it'd be great to just utilize a database.

# Mantis

I chose to go with a snapshot-style of backup (similar to how Redis does RDB snapshots). I didn't think a WAL/AOF style of backup make sense.

The project itself is far from complete (mainly, I am not able to figure out how to test it). A few hiccups:

- I wasn't able to get LocalCluster to start the Ecto repo needed for the test
- I couldn't figure out how to get LocalCluster to start a supervisor (`:rpc.call(node, Mantis, :start_link, [])` doesn't work.)
- I had a lot of trouble testing it so I finally decided to just mock Ecto with Mox (bad idea)

I also broke up the supervision tree to a really weird state - the implicit `Mantis.Application` now starts up two Clock module, but the Storage itself sits in the user's Supervision tree. This however means that I lose the ability to restart one if another fails (which could be problematic as `Mantis.Storage` is dependent on them.). One reason for this is because I thought I could allow user to start up multiple instances of `Mantis` by configuring the name, but because 1 node is only supposed to have one single HL Clock, the only way is to break up the tree like this.

Apart from the testing issue, this was manually tested and it worked fine.

# Future idea

- Make the persistence layer adapter-based
- Better test coverage that simulates the hydration etc (potentially get rid of Mox)
- Vacuum (The only thing that hydration cares about is the latest value - we can periodically delete the old historial entries to keep table small)

Twitter: [@edisonywh](https://twitter.com/edisonywh)
