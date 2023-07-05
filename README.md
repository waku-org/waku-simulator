# nwaku-simulator

## Requires
* docker
* docker-compose

## How to run
Without changing anything:

```
git clone https://github.com/waku-org/waku-simulator.git
cd waku-simulator
```

```
export NWAKU_IMAGE=statusteam/nim-waku:v0.18.0-rc.0
export NUM_NWAKU_NODES=5
docker-compose up -d
```


This will:
* spin up grafana/prometheus for monitoring
* spin up a bootstrap nwaku node
* spin up NUM_NWAKU_NODES nwaku nodes
* spin up a `waku-publisher` instance that will inject traffic into the network (see flags for rate and msg size)

Nodes can be monitored here:
http://localhost:3000/d/yns_4vFVk/nwaku-monitoring?orgId=1


## warning

in case arp tables are overflowing:

```
sysctl net.ipv4.neigh.default.gc_thresh3=32000
```
