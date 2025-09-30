## 🛠️ To-Do

## 🧪 Testing & CI/CD

- [x] 🔄 Automatically rollback when errors are detected on node (v1.0.0)
- [x] 📈 Add cluster benchmark test & replica benchmark (v1.0.0)
- [x] 🧩 Add integration failover test suite (v1.0.0)
- [x] 🔍 Detect current master dynamically in tests (v0.1.0)
- [x] ⏱️ Auto detect TTL mode during failover (v0.1.0)
- [x] 🔐 Write a script to check data consistency between nodes
- [x] 📝 Script to check data consistency after failover

## 📊 Monitoring & Logging

- [x] ❤️ Cluster health check, retry persistence, rollback integration (v1.0.0)
- [x] 🩺 Integrate health checks for each node (v1.0.0)
- [x] 🕵️ Scripts: memory usage, latency, slowlog checks (v1.0.0)
- [ ] 📜 Script to automatically check logs and detect anomalies
- [x] 📊 Integrate Prometheus + Grafana to monitor Redis
- [ ] 🔔 Alert via Slack, Email, Telegram when a node is down/failover occurs
- [x] 📦 Exporter for Redis (redis_exporter)
- [ ] 📺 Dashboard to display cluster/sentinel status
- [ ] 📰 Integrate centralized logging (ELK stack, Loki, Promtail etc.)
- [ ] 🔥 Automated Chaos Engineering workflows to automatically inject failures (kill node, network partition, disk full, etc.) to test cluster/sentinel self-healing (LitmusChaos, Gremlin, or shell script).
- [ ] 🛠️ Self-Healing Workflow when errors are detected (healthcheck fail, node down), automatically run recovery scripts, send alerts, or rollback.

## 🔒 Security

- [x] 🛡️ Integrate security scan (config, open ports, password check)
- [ ] 🔑 Enable TLS for Redis
- [ ] ⚙️ Optimize maxmemory configuration and eviction policy
- [ ] 🚧 Restrict IP access, firewall
- [ ] 👥 Redis ACL (Access Control List) with user/role
- [ ] ♻️ Rotate secrets/passwords automatically (Vault, Secrets Manager)
- [ ] 📝 Audit log to track access and config changes

## 🧩 Application & Integration

- [x] 🔌 Connect the application to the cluster using a client that supports cluster mode
- [ ] 🧪 Demo a real application using Redis Cluster (cache, pub/sub, queue)
- [ ] 📚 Use clients that support cluster/sentinel (ioredis, redis-py, Jedis, etc.)
- [ ] 🛠️ Write demo app for cache, pub/sub, queue
- [ ] 📡 Integrate Redis as message queue, session store, rate limiter
- [ ] 📝 Write documentation for integrating Redis into popular frameworks
- [ ] 🔄 Demo automatic failover without service interruption
- [ ] 🚀 Build middleware cache with Redis

## ⚙️ Configuration & Performance

- [x] ⚡ Enable cluster mode with replicas (v0.1.0)
- [x] 💾 Backup/import RDB data scripts (v0.1.0)
- [ ] 📊 Monitor `slowlog` & `commandstats` to measure latency
- [x] 🧪 Benchmark & Load testing in CI target with threshold checks (memtier_benchmark, redis-benchmark)
- [ ] 🔧 Demo persistence: compare AOF vs RDB snapshot

## ☸️ Cloud Native & Deployment

- [x] 🌐 Automatically scale out/in and re-balance nodes (v1.0.0)
- [x] 🔨 Initial CI/CD workflows (build, test, integration, split CD stage) (v0.1.0)
- [ ] ☸️ Integrate Redis with Kubernetes (Helm chart, StatefulSet, Operator)
- [ ] ☁️ Automate backup/restore of Redis data to cloud (S3, GCS)
- [ ] 💰 Optimize Redis operating costs on cloud (AWS ElastiCache, Azure Cache for Redis)
- [ ] 🛠️ Automate deployment with Terraform, Ansible, etc.
- [ ] 📊 Evaluate Redis as a Service solutions (Upstash, Redis Cloud, etc.)
- [ ] 📈 Autoscaling Redis on K8s (horizontal scaling with sharding)
- [ ] 🌀 Spot instances test (Redis + persistence to reduce cost)
- [ ] ⏮️ PITR (point-in-time recovery) using AOF/streams
- [ ] 🔄 Blue/Green deployment with HAProxy/nginx for zero-downtime updates
- [ ] 🔄 Integrate ArgoCD or Flux to automatically synchronize system state from Git to the actual environment (Kubernetes, Docker Swarm).
- [ ] 🚀 Automatically Environment Preview per PR create a separate Redis cluster/sentinel environment (using Docker Compose or ephemeral VM/container), and delete it when the PR is closed.
- [ ] 🕵️ Infrastructure Drift Detection: Integrate Driftctl or Terrascan to detect differences between configuration in Git and the actual state (cloud/K8s).

## 📝 Documentation

- 📷 Screenshots / Demo GIFs
  - Grafana Dashboard, Redis Commander, RedisInsight, `redis-cli cluster nodes` output, etc.
  - GIF demo for failover, scale-out/in, slot rebalancing.
- 🧩 Feature Comparison — Sentinel vs Cluster
  - When to use Sentinel vs Cluster? Pros & cons, suitable use-cases.
  - Examples: “Small session cache”, “pub/sub queue”, “large data partitioning”, etc.
- 📂 Example Applications
  - An `examples/` folder with 1–2 small apps (Node.js, Python, Java) using Redis Cluster / Sentinel — show how to configure clients, handle failover fallback, etc.
  - Each example should include a small README with run instructions.
- 🔐 Security & Hardening
  - Use TLS / SSL between clients & Redis nodes (if supported).
  - Configure `requirepass`, `masterauth`, `protected-mode`, firewall / network policies.
  - Restrict access from external IPs, or allow only internal container network.
- 📦 Detailed Backup & Restore
  - Not just backup scripts, but also recovery instructions, backup file management, rotation schedules.
  - Optionally integrate with cloud storage (S3, Google Cloud Storage).
- 📊 Monitoring & Alerts
  - Show how to use Prometheus + Grafana, exporters (e.g., `redis_exporter`), alert rules (e.g., node down, memory threshold, high latency).
  - Provide sample JSON dashboards and import instructions.
- 🌐 Kubernetes / Cloud Deployment
  - Deploy cluster + sentinel on Kubernetes: using Helm charts, StatefulSets, operators.
  - Guide for deploying on cloud platforms (AWS, GCP, Azure) — network config, subnets, IAM, backup, monitoring.
- 🧪 Testing & Benchmarking
  - Benchmark scripts (read, write, throughput) for performance evaluation.
  - Compare latency and throughput during scaling, failover, and rebalancing.
- 📚 References / Learning Resources
  - List Redis articles, books, official documentation, blogs, cheat sheets.
  - Links to Redis docs, Sentinel, Cluster, best practices.
- 🛡️ Maintenance & Support Policy
  - Maintenance period, support scope, how to file issues, PR workflow.
  - Issue templates & contributing guidelines (highlight what already exists).
- [ ] 📚 Automatically generate architecture, config, and API documentation from source code and config files (Documize, MkDocs, Swagger).
- [ ] 🗺️ Integrate tools to automatically visualize dependencies between services, scripts, and workflows in the repo (Graphviz, Mermaid, GitHub Dependency Graph).
