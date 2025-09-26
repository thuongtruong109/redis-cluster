#!/bin/bash
set -euo pipefail

CLUSTER_PASS=${CLUSTER_PASS:-"redispw"}
MAX_RETRY=${MAX_RETRY:-3}
STATE_FILE=".rollback-state.json"
LOG_FILE="/tmp/redis_cluster_rollback.log"

mkdir -p /tmp
touch "$LOG_FILE"

init_state() {
  if [ ! -f "$STATE_FILE" ]; then
    echo "{}" > "$STATE_FILE"
  fi
}

get_retry_count() {
  local node=$1
  jq -r --arg node "$node" '.[$node] // 0' "$STATE_FILE"
}

increment_retry_count() {
  local node=$1
  local current=$(get_retry_count "$node")
  local new=$((current + 1))
  jq --arg node "$node" --argjson val "$new" '.[$node]=$val' "$STATE_FILE" > tmp.$$.json
  mv tmp.$$.json "$STATE_FILE"
}

rollback_node() {
  local node=$1
  local retry_count=$(get_retry_count "$node")

  echo "[INFO] Rollback node $node (retry $retry_count/$MAX_RETRY)" | tee -a "$LOG_FILE"

  if (( retry_count >= MAX_RETRY )); then
    echo "[WARN] Node $node reached max retry limit ($MAX_RETRY). Skipping rollback." | tee -a "$LOG_FILE"
    return
  fi

  docker stop "$node" || true
  docker rm "$node" || true
  docker compose -f docker-compose.cluster.yml up -d "$node"

  sleep 5
  if docker exec -i node-1 redis-cli -a "$CLUSTER_PASS" --cluster add-node "$node:6379" node-1:6379 --cluster-yes; then
    docker exec -i node-1 redis-cli -a "$CLUSTER_PASS" --cluster rebalance node-1:6379 --cluster-use-empty-masters --cluster-yes
    echo "[OK] Node $node rollback successfully." | tee -a "$LOG_FILE"
    jq "del(.\"$node\")" "$STATE_FILE" > tmp.$$.json && mv tmp.$$.json "$STATE_FILE"
  else
    echo "[ERROR] Rollback failed for $node" | tee -a "$LOG_FILE"
    increment_retry_count "$node"
  fi
}

rollback_multiple_nodes() {
  local nodes=("$@")
  for node in "${nodes[@]}"; do
    rollback_node "$node"
  done
}

main() {
  init_state
  if [ $# -eq 0 ]; then
    echo "Usage: $0 node-1 node-2 ..."
    exit 1
  fi
  rollback_multiple_nodes "$@"
}

main "$@"
