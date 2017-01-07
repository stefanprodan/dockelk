# ELK v2.4
Docker logging stack: 
 - ElasticSearch Cluster (3x data nodes)
 - ElasticSearch Ingester node (used by Logstash indexer)
 - ElasticSearch Coordinator node (used by Kibana)
 - Logstash Indexer
 - Redis Broker
 - Logstash Shipper
 - Kibana
 - Docker GELF driver

Flow:

container -> docker gelf -> logstash shipper -> redis broker -> logstash indexer -> elasticsearch ingester -> elasticsearch data cluster -> elasticsearch coordinator -> kibana
