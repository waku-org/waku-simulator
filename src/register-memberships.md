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

The foundry service in the waku-simulator generates deterministic accounts that can be used to register memberships. It is recommended to use different accounts for registering multiple memberships at the same time. The last 20 accounts generated are provided for ad-hoc testing purposes.

<details>
  <summary>Account and Private-key Pairs</summary>
  
  #### Account Addresses
  99. 0x98d08079928fccb30598c6c6382abfd7dbfaa1cd
  100. 0x8c3229ec621644789d7f61faa82c6d0e5f97d43d
  101. 0x9586a4833970847aef259ad5bfb7aa8901ddf746
  102. 0x0e9971c0005d91336c1441b8f03c1c4fe5fb4584
  103. 0xc4c81d5c1851702d27d602aa8ff830a7689f17cc
  104. 0x9c79357189d6af261691ecf48de9a6bbf30438fc
  105. 0xd96eb0f2e106ea7c0a939e9c460a17ace65fecff
  106. 0x4548774216f19914493d051481feb56246bc13f0
  107. 0xfdaa62ea18331afa45cc78b44dba58d809eab80e
  108. 0x7d19cea5598accbbf0005a8eb8ed6a02c6f8ab84
  109. 0xeabd5094570298ffd24e93e7af378162884611cb
  110. 0x51953940f874efa94f92eb2d6aed023617a07222
  111. 0x6813ae1fc15e995230c05d4480d50219bb635f15
  112. 0x11c9cfec77102a7c903a2d2319c79e7b0bbc9235
  113. 0xbe9086f1a38740f297f6347b531732541289b220
  114. 0xd4db664b707353422b1ffc94038cdd0a7d074d51
  115. 0x11ba29fe987addfa480ffecf3d98b26630917a78
  116. 0xffd57510605b4f47a58576ccc059ab8882c7ea00
  117. 0x83781cf2371117aac856621805fb83c9ca439bad
  118. 0x2bac2e5a4f39c32ed16205591ba26e307414ca9e
  119. 0x8d86ef40df93b1b3822bf996b972ba53e79c07c9
  
  #### Private-keys
  99. 0xa3f5fbad1692c5b72802300aefb5b760364018018ddb5fe7589a2203d0d10e60
  100. 0xdae4671006c60a3619556ace98eca6f6e092948d05b13070a27ac492a4fba419
  101. 0x13986e078393fca89aedc2ecd014df01dfbff153434c04b2e38cfedcbef710f7
  102. 0x7382cc0c1dd9fc4ff87ed969fafac4c040ebd4890d0b8fa35781524df5b15476
  103. 0x360e8f096c6aaec3c922df1a82a7b954b69b42bdc20a6b71b2f50438c13d2ec5
  104. 0x956840865a0d252ee192c683c48befc5d8432aa7b334be6cb79133cfacfcda1a
  105. 0x9dece36dc7cb98e2e521e85efa7417d68744f00ab93caf70ec39dc3d6b16d916
  106. 0xc69422615b990ce3dbed91d6ed41e378ff92f0ebf23b8d18bf3db912c6797fa1
  107. 0xbb78950939f8a5d5c0d3225d4d38cbfd7eace2c2b8347fa8ca97726cd10e486a
  108. 0x42e75fe4e54a2126d34a7e302d8dff04d888dbd434a6c690cfc2e1e3d9499c10
  109. 0xb479c6ebcce0347b5a9335f52519198307f01a7c4917e6b1e93e123a77e74aff
  110. 0x9e4e3ca5a15203ef569824c74164789921d372c12b83f1aeba7d4e096a8338fd
  111. 0x3659cf616cb9eff3ecdd1ce36221a3744df6deb907007dc2ad4330dc66aa2d13
  112. 0x23fe537a715500e8edf9a949d1a5894fd5296a257b412e6f7e598b22bc62b060
  113. 0xf1a9dd9e1f43e6832b9950520b8fe73203d14f171cb5b07dceb0d3090878045f
  114. 0x2130940937fb474f9a6ac3ea114536c5d693ae1f918bec1e33e98de810db312e
  115. 0x755e7b431c9224a9d798e1c03d0f8d7084486aeee98ab8ea87d4538a502a73c8
  116. 0x914a73ad0b138eedf80704f9ccd81be56f33bbd5f8b371c82de3b6b6a5a23ff7
  117. 0xf40eb48d6b4964072dad455aadf0f84e94d00a19695865bbe226f9b560c9ed76
  118. 0x69fcf89b49fb124ae6f6004a7028184cc8620f1d6e9daa9f97098ef693a03f80
  119. 0xcb926b6ec105a6c4a04a64dd1edab6b2a52c4ad5ec91ea1155ed80e43d4b5753 
</details>


🎯**Goals**:

- Tests how the network reacts to a massive amount of memberships.
- Tests that nodes pick-up new memberships in real time and match.

👀**Observability**:

- Check the RLN memberships being registered in the block explorer `localhost:3000`.
- Check in grafana `localhost:3001` the metric “RLN Registered Memberships” and verify the nodes are picking up the new registrations.

