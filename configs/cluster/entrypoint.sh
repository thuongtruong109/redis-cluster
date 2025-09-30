#!/usr/bin/env bash
set -e

# If REDIS_HOST is not set, use the current container's IP address
if [ -z "${REDIS_HOST:-}" ]; then
    REDIS_HOST=$(hostname -i)
fi

export REDIS_HOST

envsubst < /etc/redis/node.conf > /etc/redis/redis.conf

exec redis-server /etc/redis/redis.conf
