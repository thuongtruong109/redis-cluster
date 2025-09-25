.PHONY: format commander commander-ha commander-clt ha ha-master ha-slave ha-test-failover ha-test ha-health ha-cli clt clt-create clt-check clt-demo clt-cli clt-test

format:
	@dos2unix Makefile
	@sed -i 's/\r$$//' Makefile ha/sentinel.conf ha/slave.conf ha/master.conf cluster/node.conf

commander:
	@if [ -z "$$CONFIG_PATH" ]; then \
		echo "❌ CONFIG_PATH is not set."; \
		exit 1; \
	fi
	docker compose -f docker-compose.dev.yml up -d --force-recreate commander

commander-ha:
	@$(MAKE) commander CONFIG_PATH=ha.json

commander-clt:
	@$(MAKE) commander CONFIG_PATH=cluster.json

ha:
	docker-compose -f docker-compose.ha.yml down -v
	docker-compose -f docker-compose.ha.yml up -d --force-recreate

ha-master:
	docker exec -it sentinel_1 redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster

ha-slave:
	docker exec -it slave_1 redis-cli -a masterpass info replication

ha-test-failover:
	bash ./tests/ha-failover.sh

ha-test:
	bash ./tests/ha.sh

ha-backup:
	bash ./scripts/backup.sh

ha-health:
	@echo "Flags: --basic, --full --report, --load-test, --metrics-only, --help"
	chmod +x scripts/health.sh
	bash ./scripts/health.sh

ha-cli:
	docker exec -it $$(docker ps -qf "name=master_1") redis-cli -p 6379 -a masterpass

clt:
	docker-compose -f docker-compose.cluster.yml down -v
	docker-compose -f docker-compose.cluster.yml up -d --force-recreate

clt-create:
	docker exec -it node-1 redis-cli -a redispw --cluster create \
		node-1:6379 \
		node-2:6379 \
		node-3:6379 \
		node-4:6379 \
		node-5:6379 \
		node-6:6379 \
		--cluster-replicas 1 --cluster-yes


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

clean:
	docker-compose -f docker-compose.cluster.yml down -v
	docker-compose -f docker-compose.ha.yml down -v
	docker-compose -f docker-compose.dev.yml down -v
	docker volume prune -f