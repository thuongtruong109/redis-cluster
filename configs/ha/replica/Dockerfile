FROM redis:7.2
COPY ./configs/ha/replica/slave.conf /etc/redis/redis.conf
CMD ["redis-server", "/etc/redis/redis.conf"]
