# Log transport and aggregation at scale for Docker containers

The logging stack: 
 - ElasticSearch Cluster (x3 data nodes)
 - ElasticSearch Ingester (used by Logstash indexer)
 - ElasticSearch Coordinator (used by Kibana)
 - Logstash Indexer
 - Redis Broker
 - Logstash Shipper
 - Kibana
 - Docker GELF driver

Flow:

container -> docker gelf -> logstash shipper -> redis broker -> logstash indexer -> elasticsearch ingester -> elasticsearch data cluster -> elasticsearch coordinator -> kibana

![Flow](https://raw.githubusercontent.com/stefanprodan/dockelk/master/diagram/infrastructure.png)

### Network setup

```
 docker network create --subnet=192.16.0.0/24 elk
```

In production you should use an internal DNS server and use domain names instead of fix IP addresses. Each service should reside on a dedicated host. The containers can be started with `--net=host` to bind directly to the host network to avoiding Docker bridge overhead.

### Elasticseach Nodes

All Elasticseach nodes use the same Docker image that containes the HQ and KOPF mangement plugins along with a health check command.

```
FROM elasticsearch:2.4.3

RUN /usr/share/elasticsearch/bin/plugin install --batch royrusso/elasticsearch-HQ
RUN /usr/share/elasticsearch/bin/plugin install --batch lmenezes/elasticsearch-kopf

COPY docker-healthcheck /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-healthcheck

HEALTHCHECK CMD ["docker-healthcheck"]

COPY config /usr/share/elasticsearch/config
```

***Elasticseach data nodes***

The Elasticseach data cluser is made out of 3 nodes, in production you should use a dedicated machine with at least 8GB RAM and 4 CPUs for each node.

```yml
  elasticsearch-node1:
    build: elasticsearch/
    container_name: elasticsearch-node1
    environment:
      ES_JAVA_OPTS: "-Xmx2g"
      ES_HEAP_SIZE: "1g"
    command: >
        elasticsearch 
        --node.name="node1" 
        --cluster.name="elk" 
        --network.host=0.0.0.0 
        --discovery.zen.ping.multicast.enabled=false 
        --discovery.zen.ping.unicast.hosts="192.16.0.11,192.16.0.12,192.16.0.13" 
        --node.data=true 
        --bootstrap.mlockall=true 
    ports:
      - "9201:9200"
      - "9301:9300"
    networks:
      default:
        ipv4_address: 192.16.0.11
    restart: unless-stopped

  elasticsearch-node2:
    build: elasticsearch/
    container_name: elasticsearch-node2
    environment:
      ES_JAVA_OPTS: "-Xmx2g"
      ES_HEAP_SIZE: "1g"
    command: >
        elasticsearch 
        --node.name="node2" 
        --cluster.name="elk" 
        --network.host=0.0.0.0 
        --discovery.zen.ping.multicast.enabled=false 
        --discovery.zen.ping.unicast.hosts="192.16.0.11,192.16.0.12,192.16.0.13" 
        --node.data=true 
        --bootstrap.mlockall=true 
    ports:
      - "9202:9200"
      - "9302:9300"
    networks:
      default:
        ipv4_address: 192.16.0.12
    restart: unless-stopped

  elasticsearch-node3:
    build: elasticsearch/
    container_name: elasticsearch-node3
    environment:
      ES_JAVA_OPTS: "-Xmx2g"
      ES_HEAP_SIZE: "1g"
    command: >
        elasticsearch 
        --node.name="node3" 
        --cluster.name="elk" 
        --network.host=0.0.0.0 
        --discovery.zen.ping.multicast.enabled=false 
        --discovery.zen.ping.unicast.hosts="192.16.0.11,192.16.0.12,192.16.0.13" 
        --node.data=true 
        --bootstrap.mlockall=true 
    ports:
      - "9203:9200"
      - "9303:9300"
    networks:
      default:
        ipv4_address: 192.16.0.13
    restart: unless-stopped
```

***Elasticseach ingest node***

The ingest node acts as a reverse proxy between Logstash Indexer and the Elasticsearch data cluster, 
when you scale out the data cluster by adding more nodes you don't have to change the Logstash config.

```yml
  elasticsearch-ingester:
    build: elasticsearch/
    container_name: elasticsearch-ingester
    command: >
        elasticsearch 
        --node.name="ingester" 
        --cluster.name="elk" 
        --network.host=0.0.0.0 
        --discovery.zen.ping.multicast.enabled=false 
        --discovery.zen.ping.unicast.hosts="192.16.0.11,192.16.0.12,192.16.0.13" 
        --node.master=false 
        --node.data=false 
        --node.ingest=true 
        --bootstrap.mlockall=true 
    ports:
      - "9221:9200"
      - "9321:9300"
    networks:
      default:
        ipv4_address: 192.16.0.21
    restart: unless-stopped
```

***Elasticseach coordinator node***

The coordinator node role acts as a router between Kibana and the Elasticsearch data cluster, his main role is to handle the search reduce phase.

```yml
  elasticsearch-coordinator:
    build: elasticsearch/
    container_name: elasticsearch-coordinator 
    command: >
        elasticsearch 
        --node.name="coordinator"
        --cluster.name="elk" 
        --network.host=0.0.0.0 
        --discovery.zen.ping.multicast.enabled=false 
        --discovery.zen.ping.unicast.hosts="192.16.0.11,192.16.0.12,192.16.0.13" 
        --node.master=false 
        --node.data=false 
        --node.ingest=false 
        --bootstrap.mlockall=true 
    ports:
      - "9222:9200"
      - "9322:9300"
    networks:
      default:
        ipv4_address: 192.16.0.22
```

### Kibana

The Kibana Docker image contains the yml config file where the Elasticseach coordinator node URL is specified and a startup script that waits for the Elasticseach cluster to be available.

***kibana.yml***

```
elasticsearch.url: "http://192.16.0.22:9200"
```

***entrypoint.sh***

```bash
echo "Stalling for Elasticsearch"
while true; do
    nc -q 1 192.16.0.22 9200 2>/dev/null && break
done

echo "Starting Kibana"
exec kibana
```

***Dockcerfile***

```
FROM kibana:4.6.2

RUN apt-get update && apt-get install -y netcat bzip2

COPY config /opt/kibana/config

COPY entrypoint.sh /tmp/entrypoint.sh
RUN chmod +x /tmp/entrypoint.sh

CMD ["/tmp/entrypoint.sh"]
```

***Service definition***

```yml
  kibana:
    build: kibana/
    container_name: kibana
    ports:
      - "5601:5601"
    restart: unless-stopped
```

