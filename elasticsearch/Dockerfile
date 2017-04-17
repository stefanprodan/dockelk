FROM elasticsearch:2.4.3

RUN /usr/share/elasticsearch/bin/plugin install --batch royrusso/elasticsearch-HQ/v2.0.3
RUN /usr/share/elasticsearch/bin/plugin install --batch lmenezes/elasticsearch-kopf

COPY docker-healthcheck /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-healthcheck

HEALTHCHECK CMD ["docker-healthcheck"]

COPY config /usr/share/elasticsearch/config