FROM redis:7.2

RUN apt-get update && apt-get install -y gettext-base

COPY configs/cluster/node.conf /etc/redis/node.conf
COPY configs/cluster/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]