#!/bin/sh
set -e

log() { echo "[$(date +'%H:%M:%S')] $*"; }

wait_for_ready() {
  CONTAINER=$1
  PORT=$2
  log "⏳ Waiting for $CONTAINER to be ready on port $PORT..."
  for i in $(seq 1 60); do
    if docker ps --filter "name=$CONTAINER" --filter "status=running" --format '{{.Names}}' | grep -q "$CONTAINER"; then
      PONG=$(docker exec "$CONTAINER" redis-cli -a masterpass -p "$PORT" ping 2>/dev/null || true)
      if [ "$PONG" = "PONG" ]; then
        ROLE=$(docker exec "$CONTAINER" redis-cli -a masterpass -p "$PORT" info replication | grep "^role:" | cut -d: -f2 | tr -d '[:space:]' || true)
        if [ "$ROLE" = "slave" ]; then
          MASTER_HOST=$(docker exec "$CONTAINER" redis-cli -a masterpass -p "$PORT" info replication | grep "^master_host:" | cut -d: -f2 | tr -d '[:space:]' || true)
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

# --- Trigger manual failover ---
log "Triggering manual failover..."
docker exec sentinel_1 redis-cli -p 26379 sentinel failover mymaster || true

# --- Detect new master ---
NEW_MASTER=""
for i in $(seq 1 60); do
  for host in slave_1 slave_2 slave_3; do
    ROLE=$(docker exec "$host" redis-cli -a masterpass info replication | grep "^role:" | cut -d: -f2 | tr -d '[:space:]' || true)
    if [ "$ROLE" = "master" ]; then
      NEW_MASTER=$host
      break 2
    fi
  done
  log "⏳ Waiting for Sentinel to promote a new master..."
  sleep 2
done

if [ -z "$NEW_MASTER" ]; then
  log "❌ Failover failed: no new master detected"
  docker exec sentinel_1 redis-cli -p 26379 sentinel master mymaster || true
  docker exec sentinel_1 redis-cli -p 26379 sentinel slaves mymaster || true
  exit 1
fi
log "✅ New master is $NEW_MASTER"

# --- Ensure all slaves are replicating from new master ---
for host in slave_1 slave_2 slave_3; do
  if [ "$host" != "$NEW_MASTER" ]; then
    linked=0
    for i in $(seq 1 60); do
      ROLE=$(docker exec "$host" redis-cli -a masterpass info replication | grep "^role:" | cut -d: -f2 | tr -d '[:space:]' || true)
      LINK_STATUS=$(docker exec "$host" redis-cli -a masterpass info replication | grep "^master_link_status:" | cut -d: -f2 | tr -d '[:space:]' || true)
      if [ "$ROLE" = "slave" ] && [ "$LINK_STATUS" = "up" ]; then
        log "✅ $host is following $NEW_MASTER with replication up"
        linked=1
        break
      fi
      log "⏳ Waiting for $host to follow $NEW_MASTER (role=$ROLE, link=$LINK_STATUS)..."
      sleep 1
    done
    if [ $linked -ne 1 ]; then
      log "❌ $host did not attach to $NEW_MASTER properly"
      docker exec "$host" redis-cli -a masterpass info replication || true
      exit 1
    fi
  fi
done

# --- Test write on new master ---
log "Testing set/get on new master..."
docker exec "$NEW_MASTER" redis-cli -a masterpass set failoverkey failovervalue
VALUE=$(docker exec "$NEW_MASTER" redis-cli -a masterpass get failoverkey)
if [ "$VALUE" != "failovervalue" ]; then
  log "❌ New master set/get failed"
  exit 1
fi

# --- Verify replication of failoverkey ---
for host in slave_1 slave_2 slave_3; do
  if [ "$host" != "$NEW_MASTER" ]; then
    replicated=0
    for i in $(seq 1 60); do
      VALUE=$(docker exec "$host" redis-cli -a masterpass get failoverkey || true)
      if [ "$VALUE" = "failovervalue" ]; then
        log "✅ $host successfully replicated failoverkey from $NEW_MASTER"
        replicated=1
        break
      fi
      log "⏳ Waiting for replication to $host after failover..."
      sleep 1
    done
    if [ $replicated -ne 1 ]; then
      log "❌ Replication to $host after failover failed"
      docker exec "$host" redis-cli -a masterpass info replication || true
      exit 1
    fi
  fi
done
log "✅ Replication after failover verified"

# --- Restart old master ---
log "Restarting old master..."
docker start redis-master

# --- Ensure old master rejoins as slave ---
joined=0
for i in $(seq 1 60); do
  ROLE=$(docker exec redis-master redis-cli -a masterpass info replication | grep "^role:" | cut -d: -f2 | tr -d '[:space:]' || true)
  if [ "$ROLE" = "slave" ]; then
    log "✅ Old master rejoined as slave"
    joined=1
    break
  fi
  log "⏳ Waiting for old master to rejoin as slave..."
  sleep 2
done

if [ $joined -ne 1 ]; then
  log "❌ Old master did not rejoin as slave"
  docker exec redis-master redis-cli -a masterpass info replication || true
  exit 1
fi

log "🎉 All integration tests passed"
exit 0
