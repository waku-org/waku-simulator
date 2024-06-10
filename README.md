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
export NWAKU_IMAGE=quay.io/wakuorg/nwaku-pr:2759-rln-v2
export NUM_NWAKU_NODES=5
export TRAFFIC_DELAY_SECONDS=15
export MSG_SIZE_KBYTES=10
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
export ETH_FROM=0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266
export RLN_RELAY_EPOCH_SEC=10
export RLN_RELAY_MSG_LIMIT=2

docker-compose --compatibility up -d
```


This will:
* create a private blockchain and attach a block explorer.
* deploy RLN contract to it.
* spin up a bootstrap nwaku node.
* spin up a given amount of nwaku nodes with specific versions.
* register an RLN membership for each nwaku node.
* spin up a `rest-traffic` instance that will inject traffic into the network via the REST API.
* see block-explorer `http://localhost:3000`.
* see grafana with node metrics `http://localhost:3001`.

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

The deployed branch is [deploy-wakusim](https://github.com/waku-org/waku-simulator/tree/deploy-wakusim).
