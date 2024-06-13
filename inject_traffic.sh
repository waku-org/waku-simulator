docker run -it --network waku-simulator_simulation alrevuelta/rest-traffic:d936446 \
--delay-seconds=${TRAFFIC_DELAY_SECONDS:-10} \
--msg-size-kbytes=${MSG_SIZE_KBYTES:-5} \
--pubsub-topic=/waku/2/rs/66/0 \
--multiple-nodes="http://waku-simulator_nwaku_[1..${NUM_NWAKU_NODES:-5}]:8645"
