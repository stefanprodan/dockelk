FROM elasticsearch:2.4.1

ENV ES_JAVA_OPTS="-Des.path.conf=/etc/elasticsearch"

COPY docker-healthcheck /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-healthcheck

HEALTHCHECK CMD ["docker-healthcheck"]