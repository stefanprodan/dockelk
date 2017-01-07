FROM kibana:4.6.2

RUN apt-get update && apt-get install -y netcat bzip2

COPY config /opt/kibana/config

COPY entrypoint.sh /tmp/entrypoint.sh
RUN chmod +x /tmp/entrypoint.sh

CMD ["/tmp/entrypoint.sh"]
