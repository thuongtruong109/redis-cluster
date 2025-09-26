.PHONY: format commander commander-ha commander-clt ha ha-master ha-slave ha-test-failover ha-test ha-health ha-cli clt clt-create clt-check clt-demo clt-cli clt-test

HA_COMPOSE_FILE = docker-compose.ha.yml
CLT_COMPOSE_FILE = docker-compose.cluster.yml
DEV_COMPOSE_FILE = docker-compose.dev.yml

format:
	@dos2unix Makefile
	@sed -i 's/\r$$//' Makefile ha/sentinel.conf ha/slave.conf ha/master.conf cluster/node.conf

validate:
	docker compose -f $(HA_COMPOSE_FILE) config --quiet
	docker compose -f $(CLT_COMPOSE_FILE) config --quiet
	@echo "✅ Docker Compose files are valid"
	chmod +x scripts/ha.sh
	bash scripts/ha.sh validate

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

ha-check:
	chmod +x scripts/ha.sh
	bash scripts/ha.sh check

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

ha-bench:
	chmod +x tests/ha-bench.sh
	bash tests/ha-bench.sh all
	$(MAKE) clean

ha-bench-master:
	chmod +x tests/ha-bench.sh
	bash tests/ha-bench.sh master
	$(MAKE) clean

ha-bench-slave:
	chmod +x tests/ha-bench.sh
	bash tests/ha-bench.sh slave
	$(MAKE) clean

ha-bench-failover:
	chmod +x tests/ha-bench.sh
	bash tests/ha-bench.sh failover
	$(MAKE) clean

ha-backup:
	chmod +x scripts/ha-backup.sh
	bash ./scripts/ha-backup.sh

ha-health:
	@echo "Flags: --basic, --full --report, --load-test, --metrics-only, --help"
	chmod +x scripts/ha-health.sh
	bash ./scripts/ha-health.sh --basic

ha-cli:
	docker exec -it $$(docker ps -qf "name=master_1") redis-cli -p 6379 -a masterpass

clt:
	docker compose -f $(CLT_COMPOSE_FILE) up -d --force-recreate node-1 node-2 node-3 node-4 node-5 node-6

clt-init:
	chmod +x scripts/clt.sh
	CLUSTER_PASS="redispw" bash ./scripts/clt.sh init

clt-status:
	chmod +x scripts/clt.sh
	CLUSTER_PASS="redispw" bash ./scripts/clt.sh status

clt-check:
	@echo "Checking the cluster status..."
	docker exec -it node-1 redis-cli -a redispw cluster info
	docker exec -it node-1 redis-cli -a redispw cluster nodes
	@echo "Run demo..."
	docker exec -it node-1 redis-cli -a redispw -c set foo bar
	docker exec -it node-2 redis-cli -a redispw -c get foo

clt-test:
	chmod +x tests/clt.sh
	bash ./tests/clt.sh

clt-cli:
	docker exec -it $$(docker ps -qf "name=node-1") redis-cli -c -p 6379 -a redispw

clt-scale:
	docker-compose -f $(CLT_COMPOSE_FILE) up -d node-7
	chmod +x scripts/clt.sh
	CLUSTER_PASS="redispw" bash ./scripts/clt.sh add node-7
	CLUSTER_PASS="redispw" bash ./scripts/clt.sh remove node-6
	CLUSTER_PASS="redispw" bash ./scripts/clt.sh rebalance

clt-health:
	chmod +x scripts/clt-health.sh
	set +e
	bash ./scripts/clt-health.sh --report

clean:
	docker compose -f $(CLT_COMPOSE_FILE) down -v
	docker compose -f $(HA_COMPOSE_FILE) down -v
	docker compose -f $(DEV_COMPOSE_FILE) down -v
	docker volume prune -f