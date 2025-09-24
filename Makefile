.PHONY: format start master slave failover integration

format:
	sed -i 's/\r$//' ha/sentinel.conf

start:
	docker-compose down -v
	docker-compose up -d --force-recreate

ci:
	docker-compose down -v || true
	docker-compose -f docker-compose.ci.yml up -d

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
	chmod +x scripts/health.sh

	bash ./scripts/health.sh

# 	./tests/health.sh --basic
# 	./tests/health.sh --full --report
# 	./tests/health.sh --load-test
# 	./tests/health.sh --metrics-only
# 	./tests/health.sh --help

# cluster:
# 	docker-compose -f docker-compose.cluster.yml up -d --force-recreate

# cluster-create:
# 	docker exec -it redis-node1 redis-cli --cluster create \
# 	  redis-node1:6379 redis-node2:6379 redis-node3:6379 \
# 	  redis-node4:6379 redis-node5:6379 redis-node6:6379 \
# 	  --cluster-replicas 1

# cluster-nodes:
# 	docker exec -it redis-node1 redis-cli cluster nodes

# cluster-test:
# 	docker exec -it redis-node1 redis-cli set user:1 "Alice"
# 	docker exec -it redis-node2 redis-cli get user:1