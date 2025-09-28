.PHONY: format validate commander commander-ha commander-clt ha ha-cli ha-ready ha-scan ha-master ha-slave ha-test-failover ha-test ha-bench ha-backup ha-health clt clt-cli clt-init clt-ready clt-monitor clt-scan clt-test clt-bench clt-rollback clt-scale clt-health clean ci

HA_COMPOSE_FILE = docker-compose.ha.yml
CLT_COMPOSE_FILE = docker-compose.cluster.yml
DEV_COMPOSE_FILE = docker-compose.dev.yml

CLT_BENCH_DIR := benchmark-results
# CLUSTER_PASS ?= redispw

format:
	@dos2unix Makefile
	@sed -i 's/\r$$//' Makefile configs/ha/sentinel/sentinel.conf configs/ha/replica/slave.conf configs/ha/replica/master.conf configs/cluster/node.conf

validate:
	docker compose -f $(HA_COMPOSE_FILE) config --quiet
	docker compose -f $(CLT_COMPOSE_FILE) config --quiet

	chmod +x scripts/ha.sh
	bash scripts/ha.sh validate

	chmod +x scripts/clt.sh
	bash scripts/clt.sh validate

commander:
	@if [ -z "$$CONFIG_PATH" ]; then \
		echo "❌ CONFIG_PATH is not set."; \
		exit 1; \
	fi
	docker compose -f $(DEV_COMPOSE_FILE) up -d --force-recreate commander

commander-ha:
	@$(MAKE) commander CONFIG_PATH=ha.json

commander-clt:
	@$(MAKE) commander CONFIG_PATH=cluster.json

ha:
	docker compose -f $(HA_COMPOSE_FILE) up -d --force-recreate

ha-cli:
	docker exec -it $$(docker ps -qf "name=master_1") redis-cli -p 6379 -a masterpass

ha-ready:
	chmod +x scripts/ha.sh
	bash scripts/ha.sh ready

ha-scan:
	chmod +x scripts/ha.sh
	bash scripts/ha.sh scan

ha-master:
	docker exec -it sentinel_1 redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster

ha-slave:
	docker exec -it slave_1 redis-cli -a masterpass info replication

ha-test-failover:
	chmod +x tests/ha-failover.sh
	bash ./tests/ha-failover.sh

ha-test:
	chmod +x tests/ha.sh
	bash ./tests/ha.sh

# current only support on CI
ha-bench:
	chmod +x tests/ha-bench.sh
	MASTER_PASS="masterpass" bash tests/ha-bench.sh all

ha-backup:
	chmod +x scripts/ha-backup.sh
	bash ./scripts/ha-backup.sh

ha-health:
	@echo "Flags: --basic, --full --report, --load-test, --metrics-only, --help"
	chmod +x scripts/ha-health.sh
	bash ./scripts/ha-health.sh --basic

clt:
	docker compose -f $(CLT_COMPOSE_FILE) up -d --force-recreate node-1 node-2 node-3 node-4 node-5 node-6

clt-cli:
	docker exec -it $$(docker ps -qf "name=node-1") redis-cli -c -p 6379 -a redispw

clt-init:
	chmod +x scripts/clt-scale.sh
	CLUSTER_PASS="redispw" bash ./scripts/clt-scale.sh init

clt-ready:
	chmod +x scripts/clt.sh
	CLUSTER_PASS="redispw" bash ./scripts/clt.sh ready

clt-monitor:
	chmod +x scripts/clt.sh
	CLUSTER_PASS="redispw" bash ./scripts/clt.sh status
	CLUSTER_PASS="redispw" bash ./scripts/clt.sh monitor

clt-scan:
	chmod +x scripts/clt.sh
	CLUSTER_PASS="redispw" bash scripts/clt.sh scan

clt-test:
	chmod +x tests/clt.sh
	bash ./tests/clt.sh

# current only support on CI
# Flags: Local: NODE_HOSTS="node-1:6379,node-2:6379,node-3:6379"
clt-bench:
	chmod +x tests/clt-bench.sh
	CLUSTER_PASS="redispw" RESULT_DIR=$(CLT_BENCH_DIR) bash ./tests/clt-bench.sh

clt-rollback:
	chmod +x scripts/clt-rollback.sh
	CLUSTER_PASS="redispw" bash ./scripts/clt-rollback.sh

clt-scale:
	docker-compose -f $(CLT_COMPOSE_FILE) up -d node-7
	chmod +x scripts/clt-scale.sh
	CLUSTER_PASS="redispw" bash ./scripts/clt-scale.sh add node-7
	CLUSTER_PASS="redispw" bash ./scripts/clt-scale.sh remove node-6
	CLUSTER_PASS="redispw" bash ./scripts/clt-scale.sh rebalance

clt-health:
	chmod +x scripts/clt-health.sh
	set +e
	bash ./scripts/clt-health.sh --report

clean:
	docker compose -f $(CLT_COMPOSE_FILE) down -v
	docker compose -f $(HA_COMPOSE_FILE) down -v
	docker compose -f $(DEV_COMPOSE_FILE) down -v
	docker volume prune -f
	rm -rf $(RESULT_DIR)

# 	Flags: -j <job_name>
ci:
	act -W .github/workflows/ci.yml --rm --pull=false --secret DOCKER_USERNAME= --secret DOCKER_PASSWORD=