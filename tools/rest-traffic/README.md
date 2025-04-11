# rest-traffic

Test utility for [nwaku](https://github.com/waku-org/nwaku).
Given the REST API endpoint, it injects traffic with a given message size at a given rate.

See usage:
```
./python traffic.py ---help
```

Use with docker:
```
    build:
      context: ./tools/rest-traffic
      dockerfile: Dockerfile
```