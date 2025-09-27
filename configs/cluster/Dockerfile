FROM redis:7.2
RUN apt-get update && apt-get install -y gettext-base
COPY ./configs/cluster/node.conf /etc/redis/node.conf
CMD ["sh", "-c", "envsubst < /etc/redis/node.conf > /etc/redis/redis.conf && redis-server /etc/redis/redis.conf"]
