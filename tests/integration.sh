#!/bin/sh
set -e

echo "Waiting for redis-master to be healthy..."
until docker exec redis-master redis-cli -a masterpass ping | grep PONG; do sleep 1; done

echo "Waiting for slaves to be available..."
for host in slave_1 slave_2 slave_3; do
  until docker exec $host redis-cli -a masterpass ping | grep PONG; do sleep 1; done
done

echo "Waiting for sentinels to be available..."
for sentinel in sentinel_1 sentinel_2 sentinel_3; do
  until docker exec $sentinel redis-cli -p 26379 ping | grep PONG; do sleep 1; done
done

echo "Testing master set/get..."
success=0
for host in redis-master slave_1 slave_2 slave_3; do
  if docker exec $host redis-cli -a masterpass set testkey testvalue 2>&1 | grep -vq "READONLY"; then
    VALUE=$(docker exec $host redis-cli -a masterpass get testkey)
    if [ "$VALUE" = "testvalue" ]; then
      NEW_MASTER=$host
      success=1
      break
    fi
  fi
done

if [ $success -ne 1 ]; then
  echo "No writable master found at test start"
  exit 1
fi

echo "Detected current master: $NEW_MASTER"


echo "Testing replication to slaves..."
for host in slave_1 slave_2 slave_3; do
  success=0
  for i in $(seq 1 10); do
    VALUE=$(docker exec $host redis-cli -a masterpass get testkey)
    if [ "$VALUE" = "testvalue" ]; then
      success=1
      break
    fi
    echo "Waiting for replication to $host..."
    sleep 1
  done
  if [ $success -ne 1 ]; then
    echo "Replication to $host failed"
    exit 1
  fi
done


echo "Simulating master failure..."
docker stop redis-master
sleep 30

echo "Waiting for Sentinel to promote a new master..."
NEW_MASTER=""
for i in $(seq 1 90); do  # Increased iterations for longer timeout
  for host in slave_1 slave_2 slave_3; do
    ROLE=$(docker exec $host redis-cli -a masterpass info replication | grep role:master || true)
    if [ "$ROLE" = "role:master" ]; then
      NEW_MASTER=$host
      break 2
    fi
  done
  sleep 2
done

if [ -z "$NEW_MASTER" ]; then
  echo "No new master was promoted"; exit 1
fi

echo "New master is $NEW_MASTER"
echo "Testing set/get on new master..."
docker exec $NEW_MASTER redis-cli -a masterpass set failoverkey failovervalue
VALUE=$(docker exec $NEW_MASTER redis-cli -a masterpass get failoverkey)
if [ "$VALUE" != "failovervalue" ]; then
  echo "New master set/get failed"; exit 1
fi

echo "Testing replication from new master to other slaves..."
for host in slave_1 slave_2 slave_3; do
  if [ "$host" != "$NEW_MASTER" ]; then
    success=0
    for i in $(seq 1 10); do
      VALUE=$(docker exec $host redis-cli -a masterpass get failoverkey)
      if [ "$VALUE" = "failovervalue" ]; then
        success=1
        break
      fi
      sleep 1
    done
    if [ $success -ne 1 ]; then
      echo "Replication to $host after failover failed"; exit 1
    fi
  fi
done

echo "Restarting old master..."
docker start redis-master

echo "Waiting for old master to rejoin as slave..."
for i in $(seq 1 30); do
  ROLE=$(docker exec redis-master redis-cli -a masterpass info replication | grep role:slave || true)
  if [ "$ROLE" = "role:slave" ]; then
    break
  fi
  sleep 2
done

if [ "$ROLE" != "role:slave" ]; then
  echo "Old master did not rejoin as slave"; exit 1
fi

echo "All integration tests passed"
exit 0