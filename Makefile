master:
	docker exec -it sentinel_1 redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster
master-connect:
	redis-cli -h localhost -p 6379 -a masterpass

master-stop:
	docker stop master
