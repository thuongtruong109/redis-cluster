#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="docker-compose.cluster.yml"
PASSWORD="redispw"
NODES=("node-1" "node-2" "node-3" "node-4" "node-5" "node-6")

function wait_for_cluster() {
  echo "⏳ Waiting for Redis cluster to be ready..."
  sleep 20
  for node in "${NODES[@]}"; do
    docker exec "$node" redis-cli -a "$PASSWORD" PING
  done
  echo "✅ Cluster is ready"
}

function benchmark_throughput() {
  echo "🚀 Benchmark cluster (SET throughput)..."
  redis-benchmark -h 127.0.0.1 -p 6379 -a "$PASSWORD" -t set -n 100000 -c 50 -q
}

function benchmark_read() {
  echo "📖 Benchmark replica (GET read)..."
  # pick node-2 as replica
  redis-benchmark -h 127.0.0.1 -p 6380 -a "$PASSWORD" -t get -n 100000 -c 50 -q
}

function benchmark_rebalance() {
  echo "🔥 Running rebalance benchmark..."
  redis-benchmark -h 127.0.0.1 -p 6379 -a "$PASSWORD" -t set -n 500000 -c 50 -q &
  BENCH_PID=$!

  sleep 5
  echo "🔄 Rebalancing cluster..."
  docker exec node-1 redis-cli -a "$PASSWORD" --cluster rebalance node-1:6379 --cluster-use-empty-masters --cluster-yes

  wait $BENCH_PID || true
  echo "✅ Rebalance benchmark finished"
}

case "${1:-}" in
  check)
    wait_for_cluster
    ;;
  throughput)
    benchmark_throughput
    ;;
  read)
    benchmark_read
    ;;
  rebalance)
    benchmark_rebalance
    ;;
  all|"")
    wait_for_cluster
    benchmark_throughput
    benchmark_read
    benchmark_rebalance
    ;;
  *)
    echo "Usage: $0 {check|throughput|read|rebalance|all}"
    exit 1
    ;;
esac
