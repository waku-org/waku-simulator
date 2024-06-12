# Introduction to Waku Simulator

The [waku-simulator](https://github.com/waku-org/waku-simulator) tool allows simulating a waku network with a set of interconnected [nwaku](https://github.com/waku-org/nwaku) nodes with the following features:

- Configurable amount of nodes. Limits depends on the machine and upper bounded at around 200.
- Runs in a single machine, using `docker-compose` to orchestrate the containers.
- It uses discv5 for peer discovery, using a common bootstrap node.
- It runs a custom ad hoc network, isolated from the existing waku networks.
- It uses a freshly deployed private blockchain, with full control over it and minimum state to track.
- It deploys an RLN contract in the said private blockchain and configures it to be used by all nodes.
- It registers an RLN membership for each node in the network, configuring it in the node to publish valid messages.
- It exposes each node’s API, so that it can be used to inject traffic into the network.
- Simple to run. Everything is automated. Requires two commands to run.

The main goals of `waku-simulator` includes but is not limited to:
* Test new features in an end to end setup with multiple nodes.
* Use as a long-lived running network on latest master, to anticipate to breaking changes.
* Explore waku's limits by using different loads and configurations.
* Offer a tool to debug problems in a controled and easy to replicate environment.
