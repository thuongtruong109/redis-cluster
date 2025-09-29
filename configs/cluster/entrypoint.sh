#!/usr/bin/env bash
set -e

# if [ -z "${REDIS_HOST:-}" ]; then
#     REDIS_HOST="127.0.0.1" # REDIS_HOST not set, defaulting to 127.0.0.1
# fi

export REDIS_HOST

envsubst < /etc/redis/node.conf > /etc/redis/redis.conf

exec redis-server /etc/redis/redis.conf
