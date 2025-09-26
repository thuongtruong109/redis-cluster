#!/bin/bash
set -e

REDIS_PORT=6379
CHECK_INTERVAL=5
TOTAL_NODES=6           # initial nodes (node-1..node-6)

get_nodes() {
  docker ps --format '{{.Names}}' | grep node- | xargs -I {} echo "{}:$REDIS_PORT"
}

get_master_count() {
  docker exec -i node-1 redis-cli -a "$CLUSTER_PASS" -p $REDIS_PORT cluster nodes \
    | grep "master" | grep -v "fail" | wc -l
}

add_node() {
  local host=$1
  local master_count=$(get_master_count)

  if [ "$master_count" -lt 3 ]; then
    echo "👉 Cluster có $master_count master, thêm $host làm master"
    docker exec -i node-1 redis-cli -a "$CLUSTER_PASS" --cluster add-node $host node-1:$REDIS_PORT --cluster-yes
    docker exec -i node-1 redis-cli -a "$CLUSTER_PASS" --cluster rebalance node-1:$REDIS_PORT --cluster-use-empty-masters --cluster-yes
  else
    echo "👉 Cluster đã có $master_count master, thêm $host làm replica"
    # chọn master có ít replica nhất
    target_master=$(docker exec -i node-1 redis-cli -a "$CLUSTER_PASS" -p $REDIS_PORT cluster nodes \
      | grep "master" | grep -v "fail" | awk '{print $1}' | head -n1)

    docker exec -i node-1 redis-cli -a "$CLUSTER_PASS" --cluster add-node $host node-1:$REDIS_PORT --cluster-slave --cluster-master-id $target_master --cluster-yes
  fi
}

remove_node() {
  local node_id=$1
  echo "Removing node ID: $node_id"
  docker exec -i node-1 redis-cli -a "$CLUSTER_PASS" --cluster del-node node-1:$REDIS_PORT $node_id
}

init_cluster() {
  echo "Creating initial cluster..."
  NODE_LIST=""
  for i in $(seq 1 $TOTAL_NODES); do
    NODE_LIST="$NODE_LIST node-$i:$REDIS_PORT"
  done
  echo "yes" | docker exec -i node-1 redis-cli -a "$CLUSTER_PASS" --cluster create $NODE_LIST --cluster-replicas 1
}

show_status() {
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

case $1 in
  init)
    init_cluster
    ;;
  add)
    if [ -z "$2" ]; then
      echo "Usage: $0 add <node-name>"
      exit 1
    fi
    add_node "$2:$REDIS_PORT"
    ;;
  remove)
    if [ -z "$2" ]; then
      echo "Usage: $0 remove <node-name>"
      exit 1
    fi
    NODE_ID=$(docker exec -i node-1 redis-cli -a "$CLUSTER_PASS" -p $REDIS_PORT cluster nodes | grep $2 | awk '{print $1}')
    remove_node $NODE_ID
    ;;
  rebalance)
    docker exec -i node-1 redis-cli -a "$CLUSTER_PASS" --cluster rebalance node-1:$REDIS_PORT --cluster-use-empty-masters --cluster-yes
    ;;
  status)
    show_status
    ;;
  *)
    echo "Usage: $0 {init|add <node>|remove <node>|rebalance|status}"
    exit 1
    ;;
esac
