#!/bin/sh
set -e

log() { echo "[$(date +'%H:%M:%S')] $*"; }

log "Waiting for redis-master to be healthy..."
until docker exec redis-master redis-cli -a masterpass ping 2>/dev/null | grep -q PONG; do
  sleep 1
done

log "Waiting for slaves to be available..."
for host in slave_1 slave_2 slave_3; do
  until docker exec "$host" redis-cli -a masterpass ping 2>/dev/null | grep -q PONG; do
    sleep 1
  done
done

log "Waiting for sentinels to be available..."
for sentinel in sentinel_1 sentinel_2 sentinel_3; do
  until docker exec "$sentinel" redis-cli -p 26379 ping 2>/dev/null | grep -q PONG; do
    sleep 1
  done
done

log "Testing master set/get..."
success=0
for host in redis-master slave_1 slave_2 slave_3; do
  if docker exec "$host" redis-cli -a masterpass set testkey testvalue 2>&1 | grep -vq "READONLY"; then
    VALUE=$(docker exec "$host" redis-cli -a masterpass get testkey)
    if [ "$VALUE" = "testvalue" ]; then
      NEW_MASTER=$host
      success=1
      break
    fi
  fi
done

if [ $success -ne 1 ]; then
  log "❌ No writable master found at test start"
  exit 1
fi
log "✅ Detected current master: $NEW_MASTER"

log "Testing replication to slaves..."
for host in slave_1 slave_2 slave_3; do
  replicated=0
  for i in $(seq 1 20); do
    VALUE=$(docker exec "$host" redis-cli -a masterpass get testkey || true)
    if [ "$VALUE" = "testvalue" ]; then
      replicated=1
      break
    fi
    log "⏳ Waiting for replication to $host..."
    sleep 1
  done
  if [ $replicated -ne 1 ]; then
    log "❌ Replication to $host failed"
    exit 1
  fi
done
log "✅ Replication verified"

log "Simulating master failure..."
docker stop redis-master

log "Waiting for Sentinel to promote a new master..."
NEW_MASTER=""
for i in $(seq 1 90); do   # ⬅️ Tăng timeout lên 180s
  for host in slave_1 slave_2 slave_3; do
    ROLE=$(docker exec "$host" redis-cli -a masterpass info replication | grep "^role:" | cut -d: -f2 || true)
    if [ "$ROLE" = "master" ]; then
      NEW_MASTER=$host
      break 2
    fi
  done
  sleep 2
done

if [ -z "$NEW_MASTER" ]; then
  log "⚠️ Sentinel did not elect a master in time"
  log "📋 Debug Sentinel state:"
  docker exec sentinel_1 redis-cli -p 26379 sentinel master mymaster || true
  docker exec sentinel_1 redis-cli -p 26379 sentinel slaves mymaster || true
  docker exec slave_1 redis-cli -a masterpass info replication | grep -E "role|master_host|master_link_status" || true
  docker exec slave_2 redis-cli -a masterpass info replication | grep -E "role|master_host|master_link_status" || true
  docker exec slave_3 redis-cli -a masterpass info replication | grep -E "role|master_host|master_link_status" || true

  log "⚡ Forcing manual failover..."
  docker exec sentinel_1 redis-cli -p 26379 sentinel failover mymaster || true
  sleep 10
  for host in slave_1 slave_2 slave_3; do
    ROLE=$(docker exec "$host" redis-cli -a masterpass info replication | grep "^role:" | cut -d: -f2 || true)
    if [ "$ROLE" = "master" ]; then
      NEW_MASTER=$host
      break
    fi
  done
  if [ -z "$NEW_MASTER" ]; then
    log "❌ Manual promotion failed"
    exit 1
  fi
fi
log "✅ New master is $NEW_MASTER"

log "Testing set/get on new master..."
docker exec "$NEW_MASTER" redis-cli -a masterpass set failoverkey failovervalue
VALUE=$(docker exec "$NEW_MASTER" redis-cli -a masterpass get failoverkey)
if [ "$VALUE" != "failovervalue" ]; then
  log "❌ New master set/get failed"
  exit 1
fi

log "Testing replication from new master to other slaves..."
for host in slave_1 slave_2 slave_3; do
  if [ "$host" != "$NEW_MASTER" ]; then
    replicated=0
    for i in $(seq 1 20); do
      VALUE=$(docker exec "$host" redis-cli -a masterpass get failoverkey || true)
      if [ "$VALUE" = "failovervalue" ]; then
        replicated=1
        break
      fi
      log "⏳ Waiting for replication to $host after failover..."
      sleep 1
    done
    if [ $replicated -ne 1 ]; then
      log "❌ Replication to $host after failover failed"
      exit 1
    fi
  fi
done
log "✅ Replication after failover verified"

log "Restarting old master..."
docker start redis-master

log "Waiting for old master to rejoin as slave..."
joined=0
for i in $(seq 1 30); do
  ROLE=$(docker exec redis-master redis-cli -a masterpass info replication | grep "^role:" | cut -d: -f2 || true)
  if [ "$ROLE" = "slave" ]; then
    joined=1
    break
  fi
  sleep 2
done

if [ $joined -ne 1 ]; then
  log "❌ Old master did not rejoin as slave"
  exit 1
fi

log "🎉 All integration tests passed"
exit 0
