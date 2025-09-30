<div align="center">
  <p>
    <img src="https://img.shields.io/github/actions/workflow/status/thuongtruong109/redis-cluster/ci.yml?label=CI&logo=github" alt="CI Status" height="28"/>
    <!-- <img src="https://img.shields.io/badge/Docker-Compose-brightgreen?logo=docker&logoColor=white" alt="Docker Compose" height="28"/> -->
    <a href="https://hub.docker.com/r/thuongtruong1009/reluster" alt="Pull count"> <img src="https://img.shields.io/docker/pulls/thuongtruong1009/reluster?label=Image%20pull&logo=docker&logoColor=white&color=brightgreen" alt="Pull count" height="28"/> </a>
    <img src="https://img.shields.io/badge/Cluster-Sharding-brightgreen?logo=redis&logoColor=white" alt="Redis" height="28"/>
    <img src="https://img.shields.io/badge/Sentinel-HA-brightgreen?logo=redis&logoColor=white" alt="Sentinel" height="28"/>
    <img src="https://img.shields.io/badge/Commander-UI-brightgreen?logo=redis&logoColor=white" alt="Commander" height="28"/>
    <a href="https://opensource.org/licenses/Apache-2.0" alt="License"><img src="https://img.shields.io/badge/License-Apache%202.0-brightgreen?logo=apache&logoColor=white" alt="License" height="28"/></a>
  </p>

   <img src="./.github/assets/banner.webp" alt="Redis Cluster Banner" />

   <p><b>A complete, ready-to-run Redis Sentinel & Cluster playground with Docker Compose for <br/> learning, testing, and deploying Redis in real-world scenarios.</b></p>
</div>

## 📝 Overview

This project provides a **hands-on Redis lab** that covers both **Sentinel** and **Cluster** modes:

- ⚡ **Redis Sentinel** → High Availability & Automatic Failover
- 📦 **Redis Cluster** → Sharding + High Availability

🎯 **Goal**: Help developers, DevOps, and students **experiment, validate, monitor, and integrate Redis** into production-like environments.

## ✨ Features

- ✔ Quick Bootstrap – Start Sentinel & Cluster in seconds with Docker Compose
- ✔ Automation Scripts – Health checks, failover tests, backups, slot rebalancing
- ✔ CI/CD Ready – GitHub Actions/GitLab CI for automated testing & deployment
- ✔ Configurable – Easily adjust number of nodes, replicas, memory limits, persistence
- ✔ Comprehensive Docs – Setup guides, architecture explanations, usage examples
- ✔ Realistic Workloads – Simulate traffic with redis-benchmark and custom scripts
- ✔ Data Persistence – RDB/AOF configurations for durability testing
- ✔ Backup & Restore – Automated backup scripts and restore procedures
- ✔ Failover Testing – Simulate node failures and observe automatic recovery
- ✔ Scaling – Add/remove nodes and reshard data with minimal downtime

<!-- - ✔ Security – Basic auth, TLS setup examples -->
<!-- - ✔ Multi-Platform – Works on Linux, macOS, Windows (WSL2/Docker Desktop) -->
<!-- - ✔ Web UIs – Redis Commander, RedisInsight for easy data management & monitoring -->
<!-- - ✔ Monitoring Stack – RedisInsight, Redis Commander, Prometheus, Grafana, Alerts (Slack/Email/Telegram)
- ✔ Real-World Demos – Integration with Node.js, Python, Java, Go, etc. (caching, pub/sub, queues, sessions)
- ✔ Advanced Guides – Kubernetes (Helm, StatefulSet, Operator), Cloud Backup/Restore, TLS/Security -->

## 👤 Who Is This For?

- 👨‍💻 Backend Developers – Learn caching, pub/sub, queues, session storage
- 🛠️ DevOps / SREs – Practice HA, failover recovery, monitoring, scaling
- 🎓 Students / Learners – Experiment with Redis concepts in a safe sandbox
- 🏗️ System Architects – Validate Redis as a distributed system building block

## 🏗️ Architecture

### 🔹 Sentinel Mode (HA + Failover)

```mermaid
flowchart TD
   S1["🛰️ Sentinel 1"]
   S2["🛰️ Sentinel 2"]
   S3["🛰️ Sentinel 3"]
   M["🟥 Master (6379)"]
   R1["🟦 Replica 1 (6380)"]
   R2["🟦 Replica 2 (6381)"]

   S1 --> M
   S2 --> M
   S3 --> M
   M --> R1
   M --> R2
```

### 🔹 Cluster Mode (Sharding + Replication)

```mermaid
flowchart LR
   M1["🟥 Master #1 (Slots 0–5460)"] --> R1["🟦 Replica #1"]
   M2["🟥 Master #2 (Slots 5461–10922)"] --> R2["🟦 Replica #2"]
   M3["🟥 Master #3 (Slots 10923–16383)"] --> R3["🟦 Replica #3"]
```

## 🤝 Contributing

We welcome you to contribute and help improve Reluster 💚

Fork → Hack → Test → PR. Here are a few ways you can get involved:

- **🐛 Reporting Bugs:** If you come across any bugs or issues, please check out the [reporting bugs guide](https://github.com/thuongtruong109/reluster/issues) to learn how to submit a bug report.
- **✨ Suggestions:** Have ideas to enhance features? We'd love to hear them! Check out the [contribution guide](.github/CONTRIBUTING.md) to share your suggestions.
- **❓ Questions:** If you have questions or need assistance, open [discussions](https://github.com/thuongtruong109/reluster/discussions) or join our to connect with other users and contributors.

## 📝 License

Distributed under the [Apache 2.0](LICENSE) license. Copyright (c) 2025 Thuong Truong.

<!-- https://github.com/ChickenBenny/redis-cluster-docker -->
<!-- https://github.com/ahmed-226/redis-monitor-dashboard -->
<!-- https://medium.com/@jielim36/basic-docker-compose-and-build-a-redis-cluster-with-docker-compose-0313f063afb6 -->
<!-- https://dev.to/hedgehog/set-up-redis-diskless-replication-359 -->
