#!/usr/bin/env bash
set -euo pipefail

LOCAL_MODE="${LOCAL_MODE:-false}" # True: use hostname container, else 127.0.0.1

mkdir -p "$RESULT_DIR"

NODES=(node-1 node-2 node-3 node-4 node-5 node-6)

# Detect host/port for benchmark
declare -A NODE_ADDR
for i in "${!NODES[@]}"; do
  node="${NODES[$i]}"
  if [[ "$LOCAL_MODE" == "true" ]]; then
    NODE_ADDR["$node"]="$node"       # hostname on network
  else
    port=$((7001 + i))
    NODE_ADDR["$node"]="127.0.0.1:$port"  # port map on CI
  fi
done

echo "🚀 Throughput benchmark..."
host_port="${NODE_ADDR[node-1]}"
host="${host_port%%:*}"
port="${host_port##*:}"
redis-benchmark -h "$host" -p "$port" -a "$CLUSTER_PASS" --cluster -t set -n 100000 -c 50 | tee "$RESULT_DIR/throughput.txt"

echo "📖 Read benchmark..."
host_port="${NODE_ADDR[node-2]}"
host="${host_port%%:*}"
port="${host_port##*:}"
redis-benchmark -h "$host" -p "$port" -a "$CLUSTER_PASS" --cluster -t get -n 100000 -c 50 | tee "$RESULT_DIR/read.txt"

echo "🔥 Rebalance benchmark..."
host_port="${NODE_ADDR[node-1]}"
host="${host_port%%:*}"
port="${host_port##*:}"
redis-benchmark -h "$host" -p "$port" -a "$CLUSTER_PASS" --cluster -t set -n 500000 -c 50 | tee "$RESULT_DIR/rebalance.txt" &

BENCH_PID=$!
sleep 5

redis-cli -h "$host" -p "$port" -a "$CLUSTER_PASS" --cluster rebalance "$host:$port" --cluster-use-empty-masters --cluster-yes
wait $BENCH_PID || true

echo "⚡ Memtier throughput..."
memtier_benchmark --server="${NODE_ADDR[node-1]%%:*}" --port=6379 --authenticate="$CLUSTER_PASS" --protocol=redis --threads=4 --clients=50 --data-size=1024 --ratio=0:1 --test-time=30 | tee "$RESULT_DIR/memtier-throughput.txt"

echo "⚡ Memtier read..."
memtier_benchmark --server="${NODE_ADDR[node-2]%%:*}" --port=6379 --authenticate="$CLUSTER_PASS" --protocol=redis --threads=4 --clients=50 --data-size=1024 --ratio=1:0 --test-time=30 | tee "$RESULT_DIR/memtier-read.txt"

echo "⚡ Memtier mixed..."
memtier_benchmark --server="${NODE_ADDR[node-1]%%:*}" --port=6379 --authenticate="$CLUSTER_PASS" --protocol=redis --threads=4 --clients=50 --data-size=512 --ratio=8:2 --test-time=30 | tee "$RESULT_DIR/memtier-mix.txt"

echo "✅ All benchmarks completed"
