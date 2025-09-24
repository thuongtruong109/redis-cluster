.PHONY: format ha ha-master ha-slave ha-test-failover ha-test ha-health clt clt-create clt-check clt-demo clt-test

format:
	@dos2unix Makefile
	@sed -i 's/\r$$//' Makefile ha/sentinel.conf ha/slave.conf ha/master.conf configs/cluster.conf

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