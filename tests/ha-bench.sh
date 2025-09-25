#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="docker-compose.ha.yml"
MASTER_NAME="redis-master"
SENTINEL_NAME="sentinel_1"
PASSWORD="masterpass"

function wait_for_replication() {
  echo "⏳ Waiting for Redis replication to be ready..."
  sleep 20
  docker exec $MASTER_NAME redis-cli -a $PASSWORD PING

  for i in 1 2 3; do
    docker exec slave_$i redis-cli -a $PASSWORD PING
  done

  for i in 1 2 3; do
    docker exec sentinel_$i redis-cli -p 26379 PING
  done
  echo "✅ Replication is ready"
}

function benchmark_master() {
  echo "🚀 Benchmark master (write)..."
  redis-benchmark -h 127.0.0.1 -p 6379 -a $PASSWORD -t set -n 100000 -c 50 -q
}

function benchmark_slave() {
  echo "📖 Benchmark slave_1 (read)..."
  redis-benchmark -h 127.0.0.1 -p 6380 -a $PASSWORD -t get -n 100000 -c 50 -q
}

function benchmark_failover() {
  echo "🔥 Running failover benchmark..."
  redis-benchmark -h 127.0.0.1 -p 6379 -a $PASSWORD -t set -n 1000000 -c 50 -q &
  BENCH_PID=$!

  sleep 5
  echo "🛑 Stopping master..."
  docker stop $MASTER_NAME

  echo "⏳ Waiting for failover..."
  sleep 15

  NEW_MASTER=$(docker exec $SENTINEL_NAME redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster | head -n1)
  echo "✅ New master elected: $NEW_MASTER"

  echo "🚀 Benchmark new master..."
  redis-benchmark -h $NEW_MASTER -p 6379 -a $PASSWORD -t set -n 100000 -c 50 -q

  wait $BENCH_PID || true
}

case "${1:-}" in
  check)
    wait_for_replication
    ;;
  master)
    benchmark_master
    ;;
  slave)
    benchmark_slave
    ;;
  failover)
    benchmark_failover
    ;;
  all|"")
    wait_for_replication
    benchmark_master
    benchmark_slave
    benchmark_failover
    ;;
  *)
    echo "Usage: $0 {check|master|slave|failover|all}"
    exit 1
    ;;
esac
