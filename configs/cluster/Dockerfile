
FROM redis:7.2
RUN apt-get update && apt-get install -y gettext-base
COPY ./configs/cluster/node.conf /etc/redis/node.conf
CMD ["sh", "-c", "envsubst < /etc/redis/node.conf > /etc/redis/redis.conf && redis-server /etc/redis/redis.conf"]

# FROM redis:7.2

# RUN apt-get update && apt-get install -y gettext-base

# COPY configs/cluster/node.conf /etc/redis/node.conf
# COPY configs/cluster/detect-host.sh /usr/local/bin/detect-host.sh

# RUN chmod +x /usr/local/bin/detect-host.sh

# CMD ["sh", "-c", "REDIS_HOST=$(detect-host.sh) envsubst < /etc/redis/node.conf > /etc/redis/redis.conf && redis-server /etc/redis/redis.conf"]

# detect-host.sh

#!/bin/sh
# Auto detect REDIS_HOST depending on environment

# if getent hosts host.docker.internal > /dev/null 2>&1; then
#   echo "host.docker.internal"
#   exit 0
# fi

# if [ "$GITHUB_ACTIONS" = "true" ]; then
#   echo "node-1"
#   exit 0
# fi

# echo "127.0.0.1"