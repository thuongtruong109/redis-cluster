#!/usr/bin/env bash
set -e

# Nếu REDIS_HOST chưa set, tự detect IP container
if [ -z "${REDIS_HOST:-}" ]; then
    REDIS_HOST=$(hostname -i)
fi

export REDIS_HOST

# Tạo config thực tế từ template
envsubst < /etc/redis/node.conf > /etc/redis/redis.conf

# Start Redis
exec redis-server /etc/redis/redis.conf
