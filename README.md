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

### Elasticseach Data Cluster

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
