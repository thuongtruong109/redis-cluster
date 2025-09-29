#!/usr/bin/env bash
set -e

if [ -z "${REDIS_HOST:-}" ]; then
    REDIS_HOST=$(hostname -i)
else
    echo "Using REDIS_HOST from environment: $REDIS_HOST"
fi

export REDIS_HOST

envsubst < /etc/redis/node.conf > /etc/redis/redis.conf

exec redis-server /etc/redis/redis.conf
