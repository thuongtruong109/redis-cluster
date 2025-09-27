#!/usr/bin/env bash
set -euo pipefail

HOST="127.0.0.1"
NODE1_PORT=7001
NODE2_PORT=7002

NODES=("node-1" "node-2" "node-3" "node-4" "node-5" "node-6")

function wait_for_cluster() {
  echo "⏳ Waiting for Redis cluster to be ready..."
  sleep 20
  for node in "${NODES[@]}"; do
    docker exec "$node" redis-cli -a "$CLUSTER_PASS" PING
  done
  echo "✅ Cluster is ready"
}

function benchmark_throughput() {
  echo "🚀 Benchmark cluster (SET throughput)..."
  redis-benchmark -h "$HOST" -p "$NODE1_PORT" -a "$CLUSTER_PASS" -t set -n 100000 -c 50 -q
}

function benchmark_read() {
  echo "📖 Benchmark replica (GET read)..."
  redis-benchmark -h "$HOST" -p "$NODE2_PORT" -a "$CLUSTER_PASS" -t get -n 100000 -c 50 -q
}

function benchmark_rebalance() {
  echo "🔥 Running rebalance benchmark..."
  redis-benchmark -h "$HOST" -p "$NODE1_PORT" -a "$CLUSTER_PASS" -t set -n 500000 -c 50 -q &
  BENCH_PID=$!

  sleep 5
  echo "🔄 Rebalancing cluster..."
  docker exec node-1 redis-cli -a "$CLUSTER_PASS" \
    --cluster rebalance node-1:6379 \
    --cluster-use-empty-masters --cluster-yes

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
