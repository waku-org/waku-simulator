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
export GOWAKU_IMAGE=wakuorg/go-waku:latest
export NWAKU_IMAGE=wakuorg/nwaku:v0.21.2-rc.0
export NUM_NWAKU_NODES=5
export NUM_GOWAKU_NODES=5
export TRAFFIC_DELAY_SECONDS=15
export MSG_SIZE_KBYTES=10
docker-compose up -d
```


This will:
* spin up grafana/prometheus for monitoring, see `http://localhost:3000`.
* spin up a bootstrap nwaku node.
* spin up a given amount of nwaku/gowaku nodes with specific versions.
* spin up a `rest-traffic` instance that will inject traffic into the network (see flags for rate and msg size)

## notes

The default login/password for grafana is `admin`/`admin`.

## warning

in case arp tables are overflowing:

```
sysctl net.ipv4.neigh.default.gc_thresh3=32000
```

Compose V2 users should spin up the containers with the following command:

```
docker-compose --compatibility up -d
```

# Infrastructure

An instance of this service is deployed at https://simulator.waku.org/.

It is configured using [`wakusim.env`](./wakusim.env) file, and new changes to this repository are picked up using a [GitHub webhook handler](https://github.com/status-im/infra-role-github-webhook).
The docker images used are updated using [Watchtower](https://github.com/containrrr/watchtower) as well.

For details on how it works please read the [Ansible role readme file](https://github.com/status-im/infra-misc/blob/master/ansible/roles/waku-simulator/). The original deployment issue can be found [here](https://github.com/status-im/infra-nim-waku/issues/79).
