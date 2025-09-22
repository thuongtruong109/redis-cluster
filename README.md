<div align="center">
  <p>
    <img src="https://img.shields.io/badge/Redis-Cluster-red?logo=redis" alt="Redis" height="28"/>
    <img src="https://img.shields.io/badge/Sentinel-HA-blue?logo=redis" alt="Sentinel" height="28"/>
  </p>
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
   <h1>Redis Cluster HA simulator</h1>
   <p>A complete, ready-to-run Redis Sentinel & Cluster environment with Docker Compose for learning, testing, and deploying Redis in real-world scenarios.</p>
</div>

## 📝 Overview

This project provides a comprehensive, ready-to-run environment for learning, testing, and deploying Redis in two main modes:

- **Redis Sentinel** (for High Availability)
- **Redis Cluster** (for Sharding & High Availability)

**Goal:** Help users easily experiment, validate, monitor, optimize, and integrate Redis into real-world systems.

## ✨ Features

- **Quick Bootstrap:** Launch Redis Sentinel and Cluster environments with Docker Compose.
- **Automation Scripts:** Health checks, failover simulation, backup, cluster slot rebalancing, security, and performance testing.
- **Integrated Monitoring:** Prometheus, Grafana, Redis Commander, RedisInsight, with Slack, Email, Telegram notifications, and centralized logging.
- **CI/CD Ready:** Integrate with GitHub Actions/GitLab CI for automated testing, deployment, rollback, and reporting.
- **Real-World Demos:** Connect Redis to Node.js, Python, Java, etc. Use Redis for caching, pub/sub, queueing, session storage, and rate limiting.
- **Advanced Guides:** Kubernetes integration (Helm, StatefulSet, Operator), automated cloud backup/restore, cost optimization, Sentinel vs Cluster comparison, and evaluation of Redis as a Service solutions.

## 👤 Who Is This For?

- DevOps engineers, backend developers, system architects, students, or anyone wanting to learn, experiment, or deploy Redis in a practical environment.

## 📁 Project Structure

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

## 🏗️ Architecture

```
                ┌──────────────┐
                │  Sentinel 1  │
                └──────┬───────┘
                       │
 ┌───────────────┐ ┌────▼─────┐ ┌───────────────┐
 │  Sentinel 2   │ │  Master  │ │  Sentinel 3   │
 └───────────────┘ │redis-6379│ └───────────────┘
                   │ password │
                   └────┬─────┘
                        │
         ┌──────────────┴──────────────┐
         │                             │
    ┌────▼──────┐                ┌─────▼─────┐
    │  Slave 1  │                │  Slave 2  │
    │redis-6380 │                │redis-6381 │
    └───────────┘                └───────────┘
```

## 📚 Table of Contents

1. [Quick Start](#-quick-start)
2. [Sentinel Mode](#-sentinel-mode)
3. [Cluster Mode](#-cluster-mode)
4. [Failover Test](#-failover-test-sentinel)
5. [Troubleshooting: Line Endings](#-troubleshooting-line-endings)
6. [Useful Commands](#-useful-commands)

## ⚡ Quick Start

### 1️⃣ Sentinel Mode (HA, failover)

```bash
# Start Sentinel/replica/master/commander
docker-compose up -d
```

### 2️⃣ Cluster Mode (sharding, failover)

```bash
# Start 6 Redis nodes + RedisInsight
docker-compose -f docker-compose.cluster.yml up -d

# Create cluster (run once):
chmod +x cluster.sh
./cluster.sh
```

## 🛡️ Sentinel Mode

- **Master:** `redis-master` (port 6379, password: `masterpass`)
- **Replicas:** `slave_1` (6380), `slave_2` (6381)
- **Sentinels:** `sentinel_1` (26379), `sentinel_2` (26380), `sentinel_3` (26381)
- **Redis Commander:** [http://localhost:8081](http://localhost:8081)

### 🔑 Access Redis

```bash
docker exec -it redis-master redis-cli -a masterpass
docker exec -it slave_1 redis-cli -a masterpass
docker exec -it sentinel_1 redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster
```

## 🗃️ Cluster Mode

- **Nodes:** `redis-node1` ... `redis-node6` (ports 7001-7006)
- **RedisInsight:** [http://localhost:8001](http://localhost:8001)

### 🛠️ Create Cluster

```bash
chmod +x cluster.sh
./cluster.sh
```

## 🔄 Failover Test (Sentinel)

You can use the provided script to simulate failover:

```bash
# On Linux/WSL/Git Bash:
chmod +x test-failover.sh
./test-failover.sh

# On PowerShell:
# (Manual steps below)
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

## 🏷️ Useful Commands

```bash
# Check network
docker network inspect redisnet

# Check container status
docker ps -a --format "table {{.Names}}\t{{.Status}}"

# View logs
docker-compose logs -f sentinel_1

# Access Redis Commander
start http://localhost:8081

# Access RedisInsight
start http://localhost:8001
```

## 📢 Tips

- **Windows users:** Prefer WSL or Git Bash for scripts. For PowerShell, use manual steps.
- **Security:** Change default passwords before using in production.
- **Extend:** Add your own application containers to test integration with Redis.

## 📄 License

[MIT](LICENSE)

<!-- https://medium.com/@jielim36/basic-docker-compose-and-build-a-redis-cluster-with-docker-compose-0313f063afb6 -->
<!-- https://dev.to/hedgehog/set-up-redis-diskless-replication-359 -->
