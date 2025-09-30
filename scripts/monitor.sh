#!/bin/bash

REDIS_NODES=(node-1 node-2 node-3 node-4 node-5 node-6)
EXPORTER_URL="http://localhost:9121/metrics"
PROM_URL="http://localhost:9090/-/ready"
GRAFANA_URL="http://localhost:3000/api/health"

mkdir -p $LOG_DIR
LOGFILE="$LOG_DIR/health-check.log"

exec > >(tee -a $LOGFILE) 2>&1

docker exec -it node-1 redis-cli -a $REDIS_PASSWORD cluster info > $LOG_DIR/cluster-info.txt 2>&1 || true
docker exec -it node-1 redis-cli -a $REDIS_PASSWORD cluster nodes > $LOG_DIR/cluster-nodes.txt 2>&1 || true

echo "==== Redis Exporter Check ===="
if curl -s --fail $EXPORTER_URL >/dev/null; then
  echo "✅ Exporter metrics reachable at $EXPORTER_URL"
else
  echo "❌ Exporter metrics NOT reachable"
fi

echo "==== Prometheus Check ===="
if curl -s --fail $PROM_URL >/dev/null; then
  echo "✅ Prometheus ready at $PROM_URL"
else
  echo "❌ Prometheus NOT ready"
fi

echo "==== Grafana Check ===="
if curl -s --fail $GRAFANA_URL >/dev/null; then
  echo "✅ Grafana ready at $GRAFANA_URL"
else
  echo "❌ Grafana NOT ready"
fi