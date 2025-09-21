<div align="center">
   <h1>🚦 Redis Cluster & Sentinel Playground <img src="https://img.shields.io/badge/Redis-Cluster-red?logo=redis" alt="Redis" height="28"/> <img src="https://img.shields.io/badge/Sentinel-HA-blue?logo=redis" alt="Sentinel" height="28"/></h1>
   <p>
      <img src="https://img.shields.io/badge/Docker-Compose-blue?logo=docker" alt="Docker Compose"/>
      <img src="https://img.shields.io/badge/RedisInsight-UI-orange?logo=redis" alt="RedisInsight"/>
      <img src="https://img.shields.io/badge/RedisCommander-UI-green?logo=redis" alt="RedisCommander"/>
      <img src="https://img.shields.io/badge/License-MIT-brightgreen.svg" alt="License"/>
      <img src="https://img.shields.io/github/workflow/status/thuongtruong109/redis-cluster/CI?label=CI" alt="CI Status"/>
   </p>
   <p>
      <img src="https://img.icons8.com/color/48/000000/redis.png" height="40"/>
      <img src="https://img.icons8.com/color/48/000000/docker.png" height="40"/>
      <img src="https://img.icons8.com/color/48/000000/console.png" height="40"/>
   </p>
</div>

# 🚀 Redis Sentinel & Cluster Playground

<p align="center">
   <b>Practice and experiment with High-Availability (HA) and Sharding using Redis, Sentinel, and Cluster via Docker Compose</b>
</p>

---

## 📝 Project Description

This project provides a comprehensive environment for learning, testing, and deploying Redis in two main modes: Redis Sentinel (for High Availability) and Redis Cluster (for Sharding & High Availability). The goal is to help users easily experiment, validate, monitor, optimize, and integrate Redis into real-world systems.

### Key Features

- **Quickly bootstrap Redis Sentinel and Redis Cluster environments** using Docker Compose: includes 1 master, multiple slaves, multiple sentinels, and a 6-node cluster (3 masters, 3 replicas).
- **Automation scripts** for health checks, failover simulation, backup, cluster slot rebalancing, security and performance testing.
- **Integrated monitoring and alerting tools**: Prometheus, Grafana, Redis Commander, RedisInsight, with support for Slack, Email, and Telegram notifications, and centralized logging.
- **CI/CD support**: Easily integrate with GitHub Actions/GitLab CI for automated testing, deployment, rollback, and reporting.
- **Real-world application demos**: Connect Redis to Node.js, Python, Java, etc. Use Redis for caching, pub/sub, queueing, session storage, and rate limiting.
- **Advanced guides and extensions**: Kubernetes integration (Helm, StatefulSet, Operator), automated cloud backup/restore, cost optimization, Sentinel vs Cluster comparison, and evaluation of Redis as a Service solutions.

### Who is this for?

- DevOps engineers, backend developers, system architects, students, or anyone who wants to learn, experiment, or deploy Redis in a practical environment.

---

This project provides a ready-to-run **Redis Sentinel** and **Redis Cluster** environment using Docker Compose. It includes:

- A Sentinel-based Redis HA setup (master, 2 replicas, 3 sentinels)
- A 6-node Redis Cluster (sharding, failover)
- Redis Commander & RedisInsight for management

---

## Table of Contents

1. [Project Structure](#project-structure)
2. [Quick Start](#quick-start)
3. [Sentinel Mode](#sentinel-mode)
4. [Cluster Mode](#cluster-mode)
5. [Failover Test](#failover-test)
6. [Troubleshooting: Line Endings](#troubleshooting-line-endings)
7. [Useful Commands](#useful-commands)

---

## 🗂️ Project Structure

```
redis-cluster/
├── docker-compose.yml            # Sentinel/replica/master/commander
├── docker-compose.cluster.yml    # Redis Cluster (6 nodes)
├── cluster.sh                    # Helper to create cluster
├── test-failover.sh              # Script to test Sentinel failover
├── master/redis.conf             # Master config
├── slave_1/redis.conf            # Replica 1 config
├── slave_2/redis.conf            # Replica 2 config
├── sentinel_1/sentinel.conf      # Sentinel 1 config
├── sentinel_2/sentinel.conf      # Sentinel 2 config
├── sentinel_3/sentinel.conf      # Sentinel 3 config
└── redis-commander/config/       # Redis Commander config
```

---

## ⚡ Quick Start

### 🛡️ 1. Sentinel Mode (HA, failover)

```bash
# Start Sentinel/replica/master/commander
docker-compose up -d
```

### 🗃️ 2. Cluster Mode (sharding, failover)

```bash
# Start 6 Redis nodes + RedisInsight
docker-compose -f docker-compose.cluster.yml up -d
# Create cluster (run once):
chmod +x cluster.sh
./cluster.sh
```

---

## 🛡️ Sentinel Mode

- **Master**: `redis-master` (port 6379, password: `masterpass`)
- **Replicas**: `slave_1` (6380), `slave_2` (6381)
- **Sentinels**: `sentinel_1` (26379), `sentinel_2` (26380), `sentinel_3` (26381)
- **Redis Commander**: [http://localhost:8081](http://localhost:8081)

### 🔑 Access Redis

```
docker exec -it redis-master redis-cli -a masterpass
docker exec -it slave_1 redis-cli -a masterpass
docker exec -it sentinel_1 redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster
```

---

## 🗃️ Cluster Mode

- **Nodes**: `redis-node1` ... `redis-node6` (ports 7001-7006)
- **RedisInsight**: [http://localhost:8001](http://localhost:8001)

### 🛠️ Create Cluster

```
chmod +x cluster.sh
./cluster.sh
```

---

## 🔄 Failover Test (Sentinel)

You can use the provided script to simulate failover:

```bash
# On Linux/WSL/Git Bash:
chmod +x test-failover.sh
./test-failover.sh
# On PowerShell:

```

Or run manually:

1. **Check current master:**
   ```bash
   docker exec -it sentinel_1 redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster
   ```
2. **Stop master:**
   ```bash
   docker stop redis-master
   ```
3. **Check new master:**
   ```bash
   docker exec -it sentinel_1 redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster
   ```
4. **Check replica role:**
   ```bash
   docker exec -it slave_1 redis-cli -a masterpass INFO replication | grep role
   ```
5. **Restart old master:**
   ```bash
   docker start redis-master
   ```

---

## 🧰 Troubleshooting: Line Endings

If you see errors with config files (especially on Windows), ensure files use **LF** (not CRLF) endings.

### On Git Bash / WSL / Linux:

```bash
dos2unix sentinel_1/sentinel.conf sentinel_2/sentinel.conf sentinel_3/sentinel.conf
sed -i 's/\r$//' sentinel_1/sentinel.conf sentinel_2/sentinel.conf sentinel_3/sentinel.conf
```

### On PowerShell:

```powershell
(Get-Content sentinel_1/sentinel.conf -Raw) -replace "`r`n","`n" | Set-Content sentinel_1/sentinel.conf -NoNewline
(Get-Content sentinel_2/sentinel.conf -Raw) -replace "`r`n","`n" | Set-Content sentinel_2/sentinel.conf -NoNewline
(Get-Content sentinel_3/sentinel.conf -Raw) -replace "`r`n","`n" | Set-Content sentinel_3/sentinel.conf -NoNewline
```

Or use Notepad++: Edit → EOL Conversion → Unix (LF) → Save.

---

## 🏷️ Useful Commands

```bash
# Check network
docker network inspect redisnet

# Check container status
docker ps -a --format "table {{.Names}}\t{{.Status}}"

# View logs
docker-compose logs -f sentinel_1

# Access Redis Commander
open http://localhost:8081

# Access RedisInsight
open http://localhost:8001
```
