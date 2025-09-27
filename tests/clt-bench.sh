#!/usr/bin/env bash
set -euo pipefail

HOST="127.0.0.1"
NODE1_PORT=7001
NODE2_PORT=7002
RESULT_DIR="benchmark-results"

NODES=("node-1" "node-2" "node-3" "node-4" "node-5" "node-6")

mkdir -p "$RESULT_DIR"

function wait_for_cluster() {
  echo "⏳ Waiting for Redis cluster to be ready..."
  sleep 20
  for node in "${NODES[@]}"; do
    docker exec "$node" redis-cli -a "$CLUSTER_PASS" PING
  done
  echo "✅ Cluster is ready"
}

function run_all_benchmarks() {
  wait_for_cluster

  echo "🚀 Running redis-benchmark throughput..."
  redis-benchmark -h "$HOST" -p "$NODE1_PORT" -a "$CLUSTER_PASS" \
    --cluster -t set -n 100000 -c 50 -q | tee "$RESULT_DIR/throughput.txt"

  echo "📖 Running redis-benchmark read..."
  redis-benchmark -h "$HOST" -p "$NODE2_PORT" -a "$CLUSTER_PASS" \
    --cluster -t get -n 100000 -c 50 -q | tee "$RESULT_DIR/read.txt"

  echo "🔥 Running redis-benchmark rebalance..."
  redis-benchmark -h "$HOST" -p "$NODE1_PORT" -a "$CLUSTER_PASS" \
    --cluster -t set -n 500000 -c 50 -q | tee "$RESULT_DIR/rebalance.txt" &

  BENCH_PID=$!
  sleep 5
  echo "🔄 Rebalancing cluster..."
  docker exec node-1 redis-cli -a "$CLUSTER_PASS" \
    --cluster rebalance node-1:6379 \
    --cluster-use-empty-masters --cluster-yes
  wait $BENCH_PID || true
  echo "✅ Rebalance benchmark finished"

  echo "⚡ Running memtier throughput..."
  memtier_benchmark --server="$HOST" --port="$NODE1_PORT" --authenticate="$CLUSTER_PASS" \
    --protocol=redis --threads=4 --clients=50 --data-size=1024 --ratio=0:1 --test-time=30 \
    | tee "$RESULT_DIR/memtier-throughput.txt"

  echo "⚡ Running memtier read..."
  memtier_benchmark --server="$HOST" --port="$NODE2_PORT" --authenticate="$CLUSTER_PASS" \
    --protocol=redis --threads=4 --clients=50 --data-size=1024 --ratio=1:0 --test-time=30 \
    | tee "$RESULT_DIR/memtier-read.txt"

  echo "⚡ Running memtier mixed workload (80% GET / 20% SET)..."
  memtier_benchmark --server="$HOST" --port="$NODE1_PORT" --authenticate="$CLUSTER_PASS" \
    --protocol=redis --threads=4 --clients=50 --data-size=512 --ratio=8:2 --test-time=30 \
    | tee "$RESULT_DIR/memtier-mix.txt"
}

run_all_benchmarks
