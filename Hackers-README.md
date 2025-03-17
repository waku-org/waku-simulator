# waku-simulator

Check 📖 [The Waku Simulator Book](https://waku-org.github.io/waku-simulator/)📖

## Quickstart

```
git clone https://github.com/waku-org/waku-simulator.git
cd waku-simulator
git checkout hackers-playground
```

Configure the simulation parameters. You can place the env variable in an `.env` file.

```
export NWAKU_IMAGE=quay.io/wakuorg/nwaku-pr:2759-rln-v2
export NUM_NWAKU_NODES=5
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
export ETH_FROM=0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266
export RLN_RELAY_EPOCH_SEC=10
export RLN_RELAY_MSG_LIMIT=2
export MAX_MESSAGE_LIMIT=100  # Contract's message limit. Needs to be higher or equal than RLN_RELAY_MSG_LIMIT, otherwise nodes won't start correctly.
```

Run the following command
```
docker compose up -d
```
(tested with Docker Compose version v2.28.1. Notice that we don't support docker compose v1)

## Warning

In case arp tables are overflowing:

  ```
  sysctl net.ipv4.neigh.default.gc_thresh3=32000
  ```
# Hackers playground

This branch is for hacking on the simulator. It is not meant to be deployed to production, but good for testing out different scenarios and setups.

## Modifications from the original waku-simulator setup

This setup is intended to provide an out of the box local test network for waku and applications on test with it. So it extends the supported node included right into the simulator - there is no need to attach them from outside.
RLN support remained as it was originally supported by the simulator.

# Network cluster and shard

- Cluster-id: 66
- Shard: 0
- Pubsub-topic: /waku/2/rs66/0

# Bootstrap node

It has now fixed IP and ENR.

#### Accessing the bootstrap node

> Bootnode IP: 10.2.0.100
>
>Bootnode Multiaddr: "/ip4/10.2.0.100/tcp/60000/p2p/16Uiu2HAmGNtM2rQ8abySFNhqPDFY4cmfAEpfo9Z9fD3NekoFR2ip"
>
>Bootnode ENR: "enr:-LG4QK3uc1orOi79J5eAprzwyfj4QcYaR_oamz1YY0U3PmaRY807UrJTkQJiSDT8PNmIPwxIw9POrel-sf1OOTlcK9UCgmlkgnY0gmlwhAoCAGSKbXVsdGlhZGRyc4oACAQKAgBkBupggnJzhQBCAQAAiXNlY3AyNTZrMaEDN06qX-XhZ-Cc7ZuIAdGNCVUicscmbFvEEfkFOQ2W_j2DdGNwgupgg3VkcIIjKIV3YWt1MgA" 

#### Rest api enabled

> http://127.0.0.1:8646

# Nwaku Service Node

A full featrued relay service node is added to the network - similar to nwaku-compose setup.
It has filter, lightpush and store mounted on it.

#### Accessing the service node

> Service node IP: 10.2.0.101
>
>Service node Multiaddr: "/ip4/10.2.0.101/tcp/60001/p2p/16Uiu2HAkyte8uj451tGkbww4Mjcg6DRnmAHxNeWyF4zp23RbpG3n"
> 
>Service node Websocket Multiaddr: "/ip4/10.2.0.101/tcp/8000/ws/p2p/16Uiu2HAkyte8uj451tGkbww4Mjcg6DRnmAHxNeWyF4zp23RbpG3n"
>
>Service node ENR: "enr:-LO4QDhRxZ-YJBeiriq07BkSiA-qSJCcy3Kz7bAWXeop48dIPpsQK2QNuDX7umonw3Wu0zFXXoMxGrIFmpQiJ1mBd_sBgmlkgnY0gmlwhAoCAGWKbXVsdGlhZGRyc4wACgQKAgBlBh9A3QOCcnOFAEIBAACJc2VjcDI1NmsxoQJCV1iKpD3kj-6EDB8QIiRtUZE3-g0OK1QbmXL2OoziNYN0Y3CC6mCDdWRwgiMohXdha3UyDw"  

#### Rest api enabled

> http://127.0.0.1:8645

# NWaku Edge node

A light/edge node is added with only lightpush-client, filter-client and store-client mounted on it.
Relay is disabled. Discover is switched of but directly linked to the service node.

#### Accessing the edge node
> Edge node IP: 10.2.0.102
>
>Edge node Multiaddr: "/ip4/10.2.0.102/tcp/60002/p2p/16Uiu2HAm5tojCrfxXrum5VxAVtCQk6h1jkA2Ecy447rQkKwwgf51"
>
>Edge node ENR: "enr:-KC4QAsSQM0tP9Zs8UxbHl3pe7HKE_0xLNA2P5LLVCbzCArsATKeH6EK43hhQJznAKjaMcpzqbMcd3UEjYJSkahMyg4BgmlkgnY0gmlwhAoCAGaKbXVsdGlhZGRyc4CCcnOFAEIBAACJc2VjcDI1NmsxoQKbiE_1i7pL24P02qgEFs0jHaso1XPo8HmcXAfqJPjGeIN0Y3CC6mKFd2FrdTIA"  

#### Rest api enabled

> http://127.0.0.1:8644
