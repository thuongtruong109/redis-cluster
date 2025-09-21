#!/bin/bash

# Redis auth
PASSWORD="mypassword"

echo "=== Step 1: Master hiện tại ==="
docker exec -it sentinel1 redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster

echo
echo "=== Step 2: Stop master ==="
docker stop redis-master
sleep 10   # đợi sentinel phát hiện và failover

echo
echo "=== Step 3: Master mới sau failover ==="
docker exec -it sentinel1 redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster

echo
echo "=== Step 4: Kiểm tra role của replica1 ==="
docker exec -it redis-replica1 redis-cli -a $PASSWORD INFO replication | grep role

echo
echo "=== Step 5: Khởi động lại master cũ ==="
docker start redis-master
sleep 5

echo
echo "=== Step 6: Kiểm tra lại cluster ==="
docker exec -it sentinel1 redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster
docker exec -it redis-master redis-cli -a $PASSWORD INFO replication | grep role

echo
echo "=== DONE ==="
