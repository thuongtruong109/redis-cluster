#!/usr/bin/env bash
set -euo pipefail

REDIS_CLI="docker exec -it node-1 redis-cli -a redispw -c"
echo "🚀 Redis Cluster Test Suite"

echo -e "\n[TEST 1] Cluster health check"
$REDIS_CLI cluster info | grep cluster_state

echo -e "\n[TEST 2] Key distribution"
$REDIS_CLI set foo bar
val=$($REDIS_CLI get foo)
echo "foo=$val"

echo -e "\n[TEST 3] Insert multiple keys"
for i in $(seq 1 10); do
  $REDIS_CLI set key$i val$i >/dev/null
done
slot=$($REDIS_CLI cluster keyslot key5)
echo "key5 in slot $slot"
$REDIS_CLI cluster getkeysinslot $slot 10

echo -e "\n[TEST 4] Replica sync"
docker exec -it node-1 redis-cli -a redispw -c set sync-test 123
replica_val=$(docker exec -it node-4 redis-cli -a redispw get sync-test)
echo "Replica node-4 value: $replica_val"

echo -e "\n[TEST 5] Failover (stop node-1)"
docker stop node-1
sleep 8
docker exec -it node-2 redis-cli -a redispw cluster nodes | grep master
docker start node-1
sleep 5

echo -e "\n[TEST 6] Rejoin node-1"
docker exec -it node-1 redis-cli -a redispw cluster info | grep cluster_state

echo -e "\n[TEST 7] Persistence after restart"
docker exec -it node-2 redis-cli -a redispw -c set persist-key hello
docker restart node-2
sleep 5
val=$(docker exec -it node-2 redis-cli -a redispw -c get persist-key)
echo "persist-key=$val"

echo -e "\n✅ All tests completed!"
