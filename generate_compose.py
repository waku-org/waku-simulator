base = '''
version: "3.7"

services:

  #TODO: disable relay and make it just bootstrap? discv5
  bootstrap:
    image: ${NWAKU_IMAGE}
    restart: on-failure
    #TODO: expose some ports to inject traffic
    ports:
      - 127.0.0.1:60000:60000
      - 127.0.0.1:8008:8008
      - 127.0.0.1:9000:9000
      - 127.0.0.1:8545:8545
    entrypoint: sh
    command:
    - '/opt/run_bootstrap.sh'
    volumes:
      - ./run_bootstrap.sh:/opt/run_bootstrap.sh:Z

  gowaku:
    image: ${GOWAKU_IMAGE}
    restart: on-failure
    deploy:
      replicas: ${NUM_GOWAKU_NODES}
    entrypoint: sh
    command:
      - '/opt/run_gowaku.sh'
    volumes:
      - ./run_gowaku.sh:/opt/run_gowaku.sh:Z
    depends_on:
      - bootstrap

  #waku-publisher:
  #  image: alrevuelta/waku-publisher:9fb206c
  #  entrypoint: sh
  #    - 'opt/run_wakupublisher.sh'
  #  volumes:
  #    - ./run_wakupublisher.sh:/opt/run_wakupublisher.sh:Z
  #  environment:
  #    MSG_PER_SECOND: 10
  #    MSG_SIZE_KBYTES: 10

  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./monitoring/prometheus-config.yml:/etc/prometheus/prometheus.yml:z
    command:
      - --config.file=/etc/prometheus/prometheus.yml
      - --storage.tsdb.retention.time=7d
    ports:
      - 127.0.0.1:9090:9090
    restart: on-failure

  grafana:
    image: grafana/grafana:latest
    env_file:
      - ./monitoring/configuration/grafana-plugins.env
    volumes:
      - ./monitoring/configuration/grafana.ini:/etc/grafana/grafana.ini:z
      - ./monitoring/configuration/dashboards.yaml:/etc/grafana/provisioning/dashboards/dashboards.yaml:z
      - ./monitoring/configuration/datasources.yaml:/etc/grafana/provisioning/datasources/datasources.yaml:z
      - ./monitoring/configuration/dashboards:/var/lib/grafana/dashboards/:z
      - ./monitoring/configuration/customizations/custom-logo.svg:/usr/share/grafana/public/img/grafana_icon.svg:z
      - ./monitoring/configuration/customizations/custom-logo.svg:/usr/share/grafana/public/img/grafana_typelogo.svg:z
      - ./monitoring/configuration/customizations/custom-logo.png:/usr/share/grafana/public/img/fav32.png:z
    ports:
      #- 127.0.0.1:3000:3000
      # open port to access the dashboard
      - 3000:3000
    restart: on-failure
    depends_on:
      - prometheus

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor
    #ports:
    #  - 8080:8080
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:rw
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
    depends_on:
      - redis

  redis:
    image: redis:latest
    container_name: redis
    #ports:
    #  - 6379:6379

'''

nwaku = '''
  nwaku_INDEX:
    container_name: waku-simulator_nwaku_INDEX
    environment:
      REPLICA: INDEX
    image: ${NWAKU_IMAGE}
    restart: on-failure
    entrypoint: sh
    command:
      - '/opt/run_nwaku.sh'
    volumes:
      - ./run_nwaku.sh:/opt/run_nwaku.sh:Z
      - ./data/nwaku_INDEX:/data:Z
#      - ./rlnKeystore.json:/rlnKeystore.json:Z
#      - ./rln_tree.db:/rln_tree.db:Z # this should not be done as its being written by all the replicas
    depends_on:
      - bootstrap
'''

fname = "docker-compose.yml"
f = open(fname, "w")
f.write(base)
NUM_NWAKUS = 200
for i in range(1, NUM_NWAKUS+1):
    my_copy= nwaku.replace("INDEX", str(i))
    f.write(my_copy)
f.close()
print("done writting to:", fname)