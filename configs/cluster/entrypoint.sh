#!/usr/bin/env bash
set -e

if [ -z "${REDIS_HOST:-}" ]; then
    REDIS_HOST=$(hostname -i)
fi

export REDIS_HOST

envsubst < /etc/redis/node.conf > /etc/redis/redis.conf

exec redis-server /etc/redis/redis.conf
