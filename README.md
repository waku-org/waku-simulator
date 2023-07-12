# nwaku-simulator

## Requires
* docker
* docker-compose

## How to run

```
git clone https://github.com/waku-org/waku-simulator.git
cd waku-simulator
```

Configure the simulation parameters. You can place the env variable in an `.env` file.

```
export GOWAKU_IMAGE=statusteam/go-waku:latest
export NWAKU_IMAGE=statusteam/nim-waku:v0.18.0-rc.0
export NUM_NWAKU_NODES=5
export NUM_GOWAKU_NODES=5
export MSG_PER_SECOND=10
export MSG_SIZE_KBYTES=10
docker-compose up -d
```


This will:
* spin up grafana/prometheus for monitoring, see `http://localhost:3000`.
* spin up a bootstrap nwaku node.
* spin up a given amount of nwaku/gowaku nodes with specific versions.
* spin up a `waku-publisher` instance that will inject traffic into the network (see flags for rate and msg size)


## warning

in case arp tables are overflowing:

```
sysctl net.ipv4.neigh.default.gc_thresh3=32000
```
