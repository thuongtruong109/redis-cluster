.PHONY: help format start stop restart master slave cluster cluster-nodes cluster-test failover logs clean

help:
	@echo "\nUsage: make <target>\n"
	@echo "Available targets:"
	@echo "  format         Fix line endings for sentinel configs (LF)"
	@echo "  start          Start Sentinel/replica/master/commander stack"
	@echo "  stop           Stop all containers"
	@echo "  restart        Restart all containers"
	@echo "  master         Show current Redis master (Sentinel)"
	@echo "  slave          Show replica info (Sentinel)"
	@echo "  cluster        Start Redis Cluster stack"
	@echo "  cluster-nodes  Show cluster nodes"
	@echo "  cluster-test   Test cluster set/get"
	@echo "  failover       Run failover test script"
	@echo "  logs           Show logs for all containers"
	@echo "  clean          Remove all containers & volumes"

format:
	sed -i 's/\r$//' sentinel_1/sentinel.conf sentinel_2/sentinel.conf sentinel_3/sentinel.conf

start:
	docker-compose down -v
	docker-compose up -d --force-recreate

stop:
	docker-compose down

restart:
	$(MAKE) stop
	$(MAKE) start

master:
	docker exec -it sentinel_1 redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster

slave:
	docker exec -it slave_1 redis-cli -a masterpass info replication

failover:
	bash ./test-failover.sh

logs:
	docker-compose logs -f

clean:
	docker-compose down -v
	docker-compose -f docker-compose.cluster.yml down -v

cluster:
	docker-compose -f docker-compose.cluster.yml up -d --force-recreate

cluster-create:
	docker exec -it redis-node1 redis-cli --cluster create \
	  redis-node1:6379 redis-node2:6379 redis-node3:6379 \
	  redis-node4:6379 redis-node5:6379 redis-node6:6379 \
	  --cluster-replicas 1

cluster-nodes:
	docker exec -it redis-node1 redis-cli cluster nodes

cluster-test:
	docker exec -it redis-node1 redis-cli set user:1 "Alice"
	docker exec -it redis-node2 redis-cli get user:1