format:
	sed -i 's/\r$//' sentinel_1/sentinel.conf sentinel_2/sentinel.conf sentinel_3/sentinel.conf insight/config.json

start:
	docker-compose down -v
	docker-compose up -d --force-recreate

master:
	docker exec -it sentinel_1 redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster

slave:
	docker exec -it slave_1 redis-cli -a slavepass info replication

# master:
# 	docker exec -it sentinel_1 redis-cli -p 26379 sentinel masters
# 	docker exec -it sentinel_1 redis-cli -p 26379 sentinel slaves mymaster

# master-connect:
# 	redis-cli -h localhost -p 6379 -a masterpass

# master-stop:
# 	docker stop master

# cluster:
# 	docker exec -it redis-node1 redis-cli cluster nodes

# cluster-test:
# 	docker exec -it redis-node1 redis-cli set user:1 "Alice"
# 	docker exec -it redis-node2 redis-cli get user:1