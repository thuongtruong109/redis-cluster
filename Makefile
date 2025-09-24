.PHONY: format start master slave failover integration backup health

format:
	@dos2unix Makefile
	@sed -i 's/\r$$//' Makefile ha/sentinel.conf ha/slave.conf ha/master.conf

replica:
	docker-compose down -v
	docker-compose up -d --force-recreate

master:
	docker exec -it sentinel_1 redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster

slave:
	docker exec -it slave_1 redis-cli -a masterpass info replication

failover:
	bash ./tests/failover.sh

integration:
	bash ./tests/integration.sh

backup:
	bash ./scripts/backup.sh

health:
	@echo "Flags: --basic, --full --report, --load-test, --metrics-only, --help"
	chmod +x scripts/health.sh
	bash ./scripts/health.sh

cluster:
	docker-compose down -v
	docker-compose -f docker-compose.cluster.yml up -d --force-recreate

cluster-create:
# 	docker exec -it node-1 redis-cli --cluster create node-1:6379 node-2:6379 node-3:6379 node-4:6379 node-5:6379 node-6:6379 --cluster-replicas 1
	docker exec -it node-1 redis-cli -a redispw --cluster create \
		172.28.0.11:6379 \
		172.28.0.12:6379 \
		172.28.0.13:6379 \
		172.28.0.14:6379 \
		172.28.0.15:6379 \
		172.28.0.16:6379 \
		--cluster-replicas 1


cluster-verify:
	docker exec -it node-1 redis-cli -a redispw cluster info
	docker exec -it node-1 redis-cli -a redispw cluster nodes

cluster-test:
	docker exec -it node-1 redis-cli -a redispw set foo bar
	docker exec -it node-2 redis-cli -a redispw get foo