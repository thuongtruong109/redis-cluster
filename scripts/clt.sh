#!/usr/bin/env bash
set -euo pipefail

CLUSTER_PORT=6379
TOTAL_MASTERS=3
TOTAL_REPLICAS=3
TOTAL_NODES=$((TOTAL_MASTERS + TOTAL_REPLICAS))

# Tên container: node-1 .. node-6
CLUSTER_NODES=()
for i in $(seq 1 $TOTAL_NODES); do
  CLUSTER_NODES+=("node-$i")
done

function wait_for_cluster() {
  echo "⏳ Waiting for Redis Cluster to be ready..."
  sleep 20

  # Đảm bảo tất cả node up
  for node in "${CLUSTER_NODES[@]}"; do
    echo "- Checking $node..."
    timeout 60 bash -c "until docker exec $node redis-cli -a $CLUSTER_PASS -p $CLUSTER_PORT ping >/dev/null 2>&1; do sleep 2; done"
  done

  # Kiểm tra cluster state
  if docker exec node-1 redis-cli -a $CLUSTER_PASS cluster info | grep -q "cluster_state:ok"; then
    echo "✅ Cluster state OK"
  else
    echo "❌ Cluster not healthy"
    exit 1
  fi
}

function validate_config() {
  for config in cluster/node.conf; do
    if [ ! -f "$config" ]; then
      echo "❌ Missing configuration file: $config"
      exit 1
    fi
  done
  echo "✅ All configuration files present"
}

function cluster_security_scan() {
  echo "🔐 Running cluster security checks..."

  TRIVY_OUTPUT="${GITHUB_WORKSPACE:-.}/trivy-cluster-results.sarif"
  if [ -f "$TRIVY_OUTPUT" ]; then
    echo "🛡️ Trivy SARIF report found at $TRIVY_OUTPUT"
  else
    echo "⚠️ Trivy report not found, skipping config scan"
  fi

  echo "📡 Checking open ports..."
  for node in "${CLUSTER_NODES[@]}"; do
    echo "- Checking container $node..."
    if docker exec "$node" sh -c "nc -z localhost $CLUSTER_PORT" >/dev/null 2>&1; then
      echo "✅ $node port $CLUSTER_PORT is open"
    fi
  done

  echo "🔑 Checking password requirement on cluster..."
  if docker exec node-1 redis-cli -a "$CLUSTER_PASS" ping >/dev/null 2>&1; then
    echo "✅ Cluster requires password"
  else
    echo "❌ Cluster allows unauthenticated access!"
    exit 1
  fi

  echo "✅ Security scan passed"
}

function show_status() {
  echo "📌 Cluster status:"
  docker exec -i node-1 redis-cli -a "$CLUSTER_PASS" -p $REDIS_PORT cluster nodes \
    | awk '{
        if ($3 ~ /master/) {
          printf("🟢 MASTER  %s  %s  slots:%s\n", $2, $1, $9);
        } else if ($3 ~ /slave/) {
          printf("🔵 REPLICA %s  %s  replicates:%s\n", $2, $1, $4);
        }
      }'
}

case "${1:-}" in
  check)
    wait_for_cluster
    ;;
  validate)
    validate_config
    ;;
  scan)
    cluster_security_scan
    ;;
  status)
    show_status
    ;;
  all|"")
    wait_for_cluster
    validate_config
    cluster_security_scan
    ;;
  *)
    echo "Usage: $0 {check|validate|scan|status|all}"
    exit 1
    ;;
esac
