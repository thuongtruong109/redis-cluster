# olf -> lf

Nếu bạn dùng Git Bash / WSL / Linux:

dos2unix sentinel1.conf sentinel2.conf sentinel3.conf
sed -i 's/\r$//' sentinel1.conf sentinel2.conf sentinel3.conf

Nếu bạn dùng PowerShell:

# chạy trong folder redis-cluster

(Get-Content sentinel1.conf -Raw) -replace "`r`n","`n" | Set-Content sentinel1.conf -NoNewline
(Get-Content sentinel2.conf -Raw) -replace "`r`n","`n" | Set-Content sentinel2.conf -NoNewline
(Get-Content sentinel3.conf -Raw) -replace "`r`n","`n" | Set-Content sentinel3.conf -NoNewline

Hoặc mở file bằng Notepad++ → Edit → EOL Conversion → Unix (LF) → Save.

6. Test Failover

Dừng master:

docker stop redis-master

→ Sentinel sẽ bầu chọn 1 replica thành master mới.

docker exec -it redis-master redis-cli -a mypassword INFO replication
Replica:

bash
Copy code
docker exec -it redis-replica1 redis-cli -a mypassword INFO replication

Sentinel: check current master

bash
Copy code
docker exec -it sentinel1 redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster

Bạn sẽ thấy:

1. "172.28.0.10"
2. "6379"

3. Stop master
   docker stop redis-master

4. Xem log sentinel

Mở log của sentinel1 để theo dõi failover:

docker logs -f sentinel1

Bạn sẽ thấy các dòng như:

+switch-master mymaster 172.28.0.10 6379 172.28.0.11 6379

→ tức là sentinel đã bầu redis-replica1 thành master mới.

4. Xác nhận master mới

Chạy lại lệnh:

docker exec -it sentinel1 redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster

Kết quả giờ sẽ trỏ sang 172.28.0.11 (hoặc .12 nếu replica2 được chọn).

5. Kiểm tra role trên replica

Ví dụ kiểm tra replica1:

docker exec -it redis-replica1 redis-cli -a mypassword INFO replication

Bạn sẽ thấy:

role:master

6. Khởi động lại master cũ
   docker start redis-master

Redis cũ sẽ tự động trở thành replica của master mới, Sentinel vẫn giữ cụm ở trạng thái ổn định.

Kiểm tra network:

docker network inspect redisnet

Xem container status & logs:

docker ps -a --format "table {{.Names}}\t{{.Status}}"
docker-compose logs -f sentinel1

<!-- run shell script -->

Cho quyền chạy (Linux/WSL/Git Bash):

chmod +x test-failover.sh
./test-failover.sh

Nếu trên PowerShell thì chạy:

bash ./test-failover.sh
