#!/usr/bin/env bash
set -euo pipefail

# NODE_HOSTS="node-1:6379,node-2:6379,node-3:6379"
NODE_HOSTS="127.0.0.1:7001,127.0.0.1:7002,127.0.0.1:7003,127.0.0.1:7004,127.0.0.1:7005,127.0.0.1:7006"


mkdir -p "$RESULT_DIR"

IFS=',' read -r -a NODES <<< "$NODE_HOSTS"

echo "🚀 Running throughput benchmark on first node..."
host="${NODES[0]%%:*}"
port="${NODES[0]##*:}"
redis-benchmark -h "$host" -p "$port" -a "$CLUSTER_PASS" --cluster -t set -n 100000 -c 50 | tee "$RESULT_DIR/throughput.txt"

echo "📖 Running read benchmark on second node..."
host="${NODES[1]%%:*}"
port="${NODES[1]##*:}"
redis-benchmark -h "$host" -p "$port" -a "$CLUSTER_PASS" --cluster -t get -n 100000 -c 50 | tee "$RESULT_DIR/read.txt"

echo "🔥 Running rebalance benchmark on first node..."
host="${NODES[0]%%:*}"
port="${NODES[0]##*:}"
redis-benchmark -h "$host" -p "$port" -a "$CLUSTER_PASS" --cluster -t set -n 500000 -c 50 | tee "$RESULT_DIR/rebalance.txt" &

BENCH_PID=$!
sleep 5

redis-cli -h "$host" -p "$port" -a "$CLUSTER_PASS" --cluster rebalance "$host:$port" --cluster-use-empty-masters --cluster-yes
wait $BENCH_PID || true

echo "⚡ Memtier throughput..."
memtier_benchmark --server="${NODES[0]%%:*}" --port="${NODES[0]##*:}" --authenticate="$CLUSTER_PASS" \
  --protocol=redis --threads=4 --clients=50 --data-size=1024 --ratio=0:1 --test-time=30 | tee "$RESULT_DIR/memtier-throughput.txt"

echo "⚡ Memtier read..."
memtier_benchmark --server="${NODES[1]%%:*}" --port="${NODES[1]##*:}" --authenticate="$CLUSTER_PASS" \
  --protocol=redis --threads=4 --clients=50 --data-size=1024 --ratio=1:0 --test-time=30 | tee "$RESULT_DIR/memtier-read.txt"

echo "⚡ Memtier mixed (80% GET / 20% SET)..."
memtier_benchmark --server="${NODES[0]%%:*}" --port="${NODES[0]##*:}" --authenticate="$CLUSTER_PASS" \
  --protocol=redis --threads=4 --clients=50 --data-size=512 --ratio=8:2 --test-time=30 | tee "$RESULT_DIR/memtier-mix.txt"

echo "✅ All benchmarks completed"