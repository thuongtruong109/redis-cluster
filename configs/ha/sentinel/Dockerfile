FROM redis:7.2
COPY ./configs/ha/sentinel/sentinel.conf /etc/redis/sentinel.conf
CMD ["redis-sentinel", "/etc/redis/sentinel.conf"]
