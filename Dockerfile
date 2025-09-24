FROM redis:7.2
RUN apt-get update && apt-get install -y gettext-base
COPY ./configs/cluster.conf /etc/redis/cluster.conf
CMD ["sh", "-c", "envsubst < /etc/redis/cluster.conf > /etc/redis/redis.conf && redis-server /etc/redis/redis.conf"]
