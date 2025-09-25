#!/usr/bin/env bash
set -euo pipefail

HA_COMPOSE_FILE="docker-compose.ha.yml"
HA_MASTER_NAME="redis-master"
HA_SENTINEL_NAME="sentinel_1"
HA_PASSWORD="masterpass"

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

  if command -v trivy >/dev/null 2>&1; then
    echo "🛡️ Scanning docker-compose with Trivy..."
    trivy config --exit-code 1 --severity HIGH,CRITICAL $HA_COMPOSE_FILE || {
      echo "❌ Security issues found in config"
      exit 1
    }
  else
    echo "⚠️ Trivy not installed, skipping config scan"
  fi

  for container in $HA_MASTER_NAME slave_1 slave_2 slave_3 sentinel_1 sentinel_2 sentinel_3; do
    echo "📡 Checking open ports in $container..."
    docker exec $container netstat -tuln | grep -E '6379|6380|26379' || {
      echo "❌ Unexpected open ports in $container"
      exit 1
    }
  done

  echo "🔑 Checking password requirement..."
  if docker exec $HA_MASTER_NAME redis-cli ping >/dev/null 2>&1; then
    echo "❌ Redis master allows unauthenticated access!"
    exit 1
  else
    echo "✅ Redis master requires password"
  fi

  echo "✅ Security scan passed"
}

case "${1:-}" in
  ha-check)
    wait_for_replication
    ;;
  validate)
    validate_config
    ;;
  ha-scan)
    replication_security_scan
    ;;
  all|"")
    wait_for_replication
    validate_config
    replication_security_scan
    ;;
  *)
    echo "Usage: $0 {ha-check|validate|ha-scan|all}"
    exit 1
    ;;
esac
