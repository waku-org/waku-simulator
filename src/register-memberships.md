# Register memberships


The [go-waku-light](https://github.com/alrevuelta/go-waku-light) tool can be used as well to register multiple RLN memberships. This can be useful to stress test the nodes, forcing a large amount of memberships. Set `amount` to the amount of memberships that you want to register. Note that it takes some time, since memberships are registered one after the other. You can spin up multiple services like this, but in that case you must provide different `priv-key` to each. Note that these memberships are kind of thrown away and not used to send messages.

```jsx
docker run --network waku-simulator_simulation alrevuelta/go-waku-light:07b8f32 \
--eth-endpoint=http://foundry:8545 \
--contract-address=0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9 \
register \
--priv-key=ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
--user-message-limit=1 \
--amount=100

```

🎯**Goals**:

- Tests how the network reacts to a massive amount of memberships.
- Tests that nodes pick-up new memberships in real time and match.

👀**Observability**:

- Check the RLN memberships being registered in the block explorer `localhost:3000`.
- Check in grafana `localhost:3001` the metric “RLN Registered Memberships” and verify the nodes are picking up the new registrations.

