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
	chmod +x scripts/prepare.sh
	bash scripts/prepare.sh validate

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

ha: validate
	docker-compose -f $(HA_COMPOSE_FILE) up -d --force-recreate

ha-check: ha
	chmod +x scripts/prepare.sh
	bash scripts/prepare.sh ha-check

ha-master: ha
	docker exec -it sentinel_1 redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster

ha-slave: ha
	docker exec -it slave_1 redis-cli -a masterpass info replication

ha-test-failover: ha
	chmod +x tests/ha-failover.sh
	bash ./tests/ha-failover.sh

ha-test: ha
	chmod +x tests/ha.sh
	bash ./tests/ha.sh

ha-bench: ha
	chmod +x scripts/ha-benchmark.sh
	bash scripts/ha-benchmark.sh all
	$(MAKE) clean

ha-bench-master: ha
	chmod +x scripts/ha-benchmark.sh
	bash scripts/ha-benchmark.sh master
	$(MAKE) clean

ha-bench-slave: ha
	chmod +x scripts/ha-benchmark.sh
	bash scripts/ha-benchmark.sh slave
	$(MAKE) clean

ha-bench-failover: ha
	chmod +x scripts/ha-benchmark.sh
	bash scripts/ha-benchmark.sh failover
	$(MAKE) clean

ha-backup: ha
	chmod +x scripts/backup.sh
	bash ./scripts/backup.sh

ha-health: ha-check
	@echo "Flags: --basic, --full --report, --load-test, --metrics-only, --help"
	chmod +x scripts/health.sh
	bash ./scripts/health.sh --basic

ha-cli: ha
	docker exec -it $$(docker ps -qf "name=master_1") redis-cli -p 6379 -a masterpass

clt: validate
	docker-compose -f $(CLT_COMPOSE_FILE) up -d --force-recreate

clt-create: clt
	docker exec -it node-1 redis-cli -a redispw --cluster create \
		node-1:6379 \
		node-2:6379 \
		node-3:6379 \
		node-4:6379 \
		node-5:6379 \
		node-6:6379 \
		--cluster-replicas 1 --cluster-yes


clt-check: clt-create
	@echo "Checking the cluster status..."
	docker exec -it node-1 redis-cli -a redispw cluster info
	docker exec -it node-1 redis-cli -a redispw cluster nodes
	@echo "Run demo..."
	docker exec -it node-1 redis-cli -a redispw -c set foo bar
	docker exec -it node-2 redis-cli -a redispw -c get foo

clt-test: clt clt-create clt-check
	chmod +x tests/clt.sh
	bash ./tests/clt.sh

clt-cli: clt
	docker exec -it $$(docker ps -qf "name=node-1") redis-cli -c -p 6379 -a redispw

clean:
	docker-compose -f $(CLT_COMPOSE_FILE) down -v
	docker-compose -f $(HA_COMPOSE_FILE) down -v
	docker-compose -f $(DEV_COMPOSE_FILE) down -v
	docker volume prune -f