#!/bin/sh
set -e

echo "Waiting for redis-master to be healthy..."
until docker exec redis-master redis-cli -a masterpass ping | grep PONG; do sleep 1; done

echo "Waiting for slaves to be available..."
for host in slave_1 slave_2 slave_3; do
  until docker exec $host redis-cli -a masterpass ping | grep PONG; do sleep 1; done
done

echo "Testing master set/get..."
docker exec redis-master redis-cli -a masterpass set testkey testvalue
VALUE=$(docker exec redis-master redis-cli -a masterpass get testkey)
if [ "$VALUE" != "testvalue" ]; then
  echo "Master set/get failed"; exit 1
fi

echo "Testing replication to slaves..."
for host in slave_1 slave_2 slave_3; do
  VALUE=$(docker exec $host redis-cli -a masterpass get testkey)
  if [ "$VALUE" != "testvalue" ]; then
    echo "Replication to $host failed"; exit 1
  fi
done

echo "Simulating master failure..."
docker stop redis-master
sleep 10

echo "Waiting for Sentinel to promote a new master..."
NEW_MASTER=""
for i in $(seq 1 60); do
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
sleep 10

echo "Checking old master is now a slave..."
ROLE=$(docker exec redis-master redis-cli -a masterpass info replication | grep role:slave || true)
if [ "$ROLE" != "role:slave" ]; then
  echo "Old master did not rejoin as slave"; exit 1
fi

echo "All integration tests passed"
exit 0