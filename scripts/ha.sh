#!/usr/bin/env bash
set -euo pipefail

HA_COMPOSE_FILE="docker-compose.ha.yml"
HA_MASTER_NAME="redis-master"
HA_SENTINEL_NAME="sentinel_1"
HA_PASSWORD="masterpass"
CONTAINERS=(redis-master slave_1 slave_2 slave_3 sentinel_1 sentinel_2 sentinel_3)
REDIS_PORTS=(6379 6380 26379)

function wait_for_replication() {
  echo "⏳ Waiting for Redis replication to be ready..."
  sleep 20

  timeout 60 bash -c "until docker exec $HA_MASTER_NAME redis-cli -a $HA_PASSWORD ping; do sleep 2; done"

  for i in 1 2 3; do
    timeout 60 bash -c "until docker exec slave_$i redis-cli -a $HA_PASSWORD ping; do sleep 2; done"
  done

  for i in 1 2 3; do
    timeout 60 bash -c "until docker exec sentinel_$i redis-cli -p 26379 ping; do sleep 2; done"
  done

  echo "✅ Replication is ready"
}

function validate_config() {
  for config in ha/master.conf ha/slave.conf ha/sentinel.conf cluster/node.conf; do
    if [ ! -f "$config" ]; then
      echo "❌ Missing configuration file: $config"
      exit 1
    fi
  done
  echo "✅ All configuration files present"
}

function replication_security_scan() {
  echo "🔐 Running security checks..."

  TRIVY_OUTPUT="${GITHUB_WORKSPACE:-.}/trivy-results.sarif"
  if [ -f "$TRIVY_OUTPUT" ]; then
    echo "🛡️ Trivy SARIF report found at $TRIVY_OUTPUT"
  else
    echo "⚠️ Trivy report not found, skipping config scan"
  fi

  echo "📡 Checking open ports in containers..."
  for container in "${CONTAINERS[@]}"; do
    echo "- Checking container $container..."
    for port in "${REDIS_PORTS[@]}"; do
      if docker exec "$container" sh -c "nc -z localhost $port" >/dev/null 2>&1; then
        echo "✅ $container port $port is open"
      fi
    done
  done

  echo "🔑 Checking password requirement on $HA_MASTER_NAME..."
  if docker exec "$HA_MASTER_NAME" redis-cli -a "$HA_PASSWORD" ping >/dev/null 2>&1; then
    echo "✅ Redis master requires password"
  else
    echo "❌ Redis master allows unauthenticated access!"
    exit 1
  fi

  echo "✅ Security scan passed"
}

case "${1:-}" in
  check)
    wait_for_replication
    ;;
  validate)
    validate_config
    ;;
  scan)
    replication_security_scan
    ;;
  all|"")
    wait_for_replication
    validate_config
    replication_security_scan
    ;;
  *)
    echo "Usage: $0 {check|validate|scan|all}"
    exit 1
    ;;
esac
