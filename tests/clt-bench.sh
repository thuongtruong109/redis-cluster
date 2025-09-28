#!/usr/bin/env bash
set -euo pipefail

mkdir -p "$RESULT_DIR"

echo "🚀 Running redis-benchmark throughput..."
redis-benchmark -h node-1 -p 6379 -a "$CLUSTER_PASS" --cluster -t set -n 100000 -c 50 | tee "$RESULT_DIR/throughput.txt"

echo "📖 Running redis-benchmark read..."
redis-benchmark -h node-2 -p 6379 -a "$CLUSTER_PASS" --cluster -t get -n 100000 -c 50 | tee "$RESULT_DIR/read.txt"

echo "🔥 Running redis-benchmark rebalance..."
redis-benchmark -h node-1 -p 6379 -a "$CLUSTER_PASS" --cluster -t set -n 500000 -c 50 | tee "$RESULT_DIR/rebalance.txt" &
BENCH_PID=$!
sleep 5
docker exec node-1 redis-cli -a "$CLUSTER_PASS" --cluster rebalance node-1:6379 --cluster-use-empty-masters --cluster-yes
wait $BENCH_PID || true

# Memtier workloads
echo "⚡ Running memtier throughput..."
memtier_benchmark --server=node-1 --port=6379 --authenticate="$CLUSTER_PASS" --protocol=redis --threads=4 --clients=50 --data-size=1024 --ratio=0:1 --test-time=30 | tee "$RESULT_DIR/memtier-throughput.txt"

echo "⚡ Running memtier read..."
memtier_benchmark --server=node-2 --port=6379 --authenticate="$CLUSTER_PASS" --protocol=redis --threads=4 --clients=50 --data-size=1024 --ratio=1:0 --test-time=30 | tee "$RESULT_DIR/memtier-read.txt"

echo "⚡ Running memtier mixed workload (80% GET / 20% SET)..."
memtier_benchmark --server=node-1 --port=6379 --authenticate="$CLUSTER_PASS" --protocol=redis --threads=4 --clients=50 --data-size=512 --ratio=8:2 --test-time=30 | tee "$RESULT_DIR/memtier-mix.txt"

echo "✅ All benchmarks completed"
