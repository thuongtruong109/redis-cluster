#!/bin/sh
set -e

log() { echo "[$(date +'%H:%M:%S')] $*"; }

wait_for_ready() {
  CONTAINER=$1
  PORT=$2
  log "⏳ Waiting for $CONTAINER to be ready on port $PORT..."
  for i in $(seq 1 60); do      # tăng số vòng chờ
    if docker ps --filter "name=$CONTAINER" --filter "status=running" --format '{{.Names}}' | grep -q "$CONTAINER"; then
      PONG=$(docker exec "$CONTAINER" redis-cli -a masterpass -p "$PORT" ping 2>/dev/null || true)
      if [ "$PONG" = "PONG" ]; then
        ROLE=$(docker exec "$CONTAINER" redis-cli -a masterpass -p "$PORT" info replication | grep "^role:" | cut -d: -f2 || true)
        if [ "$ROLE" = "slave" ]; then
          MASTER_HOST=$(docker exec "$CONTAINER" redis-cli -a masterpass -p "$PORT" info replication | grep "^master_host:" | cut -d: -f2 || true)
          if [ -n "$MASTER_HOST" ] && [ "$MASTER_HOST" != "?" ]; then
            log "✅ $CONTAINER is ready (role=slave, master=$MASTER_HOST)"
            return 0
          fi
        else
          log "✅ $CONTAINER is ready (role=$ROLE)"
          return 0
        fi
      fi
    fi
    sleep 2
  done
  log "❌ $CONTAINER did not become ready"
  docker logs "$CONTAINER" || true
  exit 1
}

# --- Wait all services ready ---
wait_for_ready redis-master 6379
wait_for_ready slave_1 6379
wait_for_ready slave_2 6379
wait_for_ready slave_3 6379
wait_for_ready sentinel_1 26379
wait_for_ready sentinel_2 26379
wait_for_ready sentinel_3 26379

# --- Test master write ---
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

# --- Check replication ---
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

# --- Simulate master failure ---
log "Simulating master failure..."
docker stop redis-master

log "Waiting for Sentinel to promote a new master..."
NEW_MASTER=""
for i in $(seq 1 60); do
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
  log "⚠️ Sentinel did not elect a master in time, forcing manual failover..."

  # Đợi Sentinel bỏ redis-master (s_down) ra khỏi danh sách slaves
  for i in $(seq 1 20); do
    if ! docker exec sentinel_1 redis-cli -p 26379 sentinel slaves mymaster | grep -q "redis-master:6379"; then
      log "ℹ️ redis-master removed from slave list"
      break
    fi
    log "⏳ Waiting for redis-master to be purged from Sentinel state..."
    sleep 3
  done

  # Ép failover
  docker exec sentinel_1 redis-cli -p 26379 sentinel failover mymaster || true

  # Chờ slave được promote
  for i in $(seq 1 45); do
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
    log "❌ Manual promotion failed"
    log "🔍 Sentinel master state:"
    docker exec sentinel_1 redis-cli -p 26379 sentinel master mymaster || true
    log "🔍 Sentinel slaves state:"
    docker exec sentinel_1 redis-cli -p 26379 sentinel slaves mymaster || true
    exit 1
  fi
fi

log "✅ New master is $NEW_MASTER"

# --- Test write on new master ---
log "Testing set/get on new master..."
docker exec "$NEW_MASTER" redis-cli -a masterpass set failoverkey failovervalue
VALUE=$(docker exec "$NEW_MASTER" redis-cli -a masterpass get failoverkey)
if [ "$VALUE" != "failovervalue" ]; then
  log "❌ New master set/get failed"
  exit 1
fi

# --- Replication after failover ---
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

# --- Restart old master ---
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
log "✅ Old master rejoined as slave"

log "🎉 All integration tests passed"
exit 0
