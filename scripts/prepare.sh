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
    docker exec sentinel_$i redis-cli -p 26379 PING
    timeout 60 bash -c "until docker exec sentinel_$i redis-cli -p 26379 ping; do sleep 2; done"
  done
  echo "✅ Replication is ready"
}

function validate_config() {
	@for config in ha/master.conf ha/slave.conf ha/sentinel.conf cluster/node.conf; do \
		if [ ! -f "$$config" ]; then \
			echo "❌ Missing configuration file: $$config"; \
			exit 1; \
		fi; \
	done
	@echo "✅ All configuration files present"
}

case "${1:-}" in
  ha-check)
    wait_for_replication
    ;;
  validate)
    validate_config
    ;;
  all|"")
    wait_for_replication
    ;;
  *)
    echo "Usage: $0 {ha-check|validate|all}"
    exit 1
    ;;
esac
