# 📝 Changelog

## [v1.0.0 (2025-09-29)](https://github.com/thuongtruong109/redis-cluster/releases/tag/v1.0.0)

### ✨ Features

- cluster: Add health check, retry persistence, and rollback integration
- cluster: Integrate health checks for each node

### 🐛 Bug Fixes

- ci: Add auto rollback and retry mechanism in health check
- cmd: Patch version and CI directory name
- compose: Dynamic binding hostname to cluster node
- Automatically scale out/in and re-balance nodes
- using container names and network in Redis Cluster benchmarks CI tests

### 🛠️ CI/CD

- Cluster automatically rollback when errors are detected on node
- Change build context, Fix condition run
- Build and publish image
- safely upload Trivy SARIF skip if missing in security scan
- refactor and enhance workflow for replica/cluster tests, security scans, health checks, and notifications
- make cluster-health-check retry count safe if artifact missing
- Lint and analyze code score

### 🧪 Tests

- ci: Add cluster benchmark test
- ha: Integrate security scan config, check open ports, check password
- Benchmark for replicas
- cluster: Add integration failover test suite

### 🧹 Chores

- script: |
  - Scale cluster
  - Prepare run with bash
  - check cluster memory usage, latency, slowlog
- compose: Start commander container in dev
- Integrate health checks for each node
- config yamllint to validate YAML files
- setup devcontainer in VSCode dev environment
- using .env file for environment variables

### 📚 Documentation

- Update description
- Update assets
- Update README.md

### 🏗️ Build

    config: Change context dir

**Full Changelog**: https://github.com/thuongtruong109/redis-cluster/commits/v1.0.0

## [v0.1.0 (2025-09-25)](https://github.com/thuongtruong109/redis-cluster/releases/tag/v0.1.0)

### 🛠️ CI/CD

- split cd stage
- simplify workflow name and restrict push branches to main
- update script
- add tests script
- add integration test for failover

### 🧪 Tests

- update for ci context
- update scenario for ci
- add integration test

### 🐛 Bug Fixes

- detect current master dynamically and retry replication checks (integration)
- auto detect ttl mode (failover)
- resolved hang on waiting promote master (integration)

### 🧹 Chores

- backup and import data (script)
- backup rdb (script)
- enable cluster mode
- convert to internal IP
- setup replicas

### 📚 Documentation

- update descriptions and scripts

**Full Changelog**: https://github.com/thuongtruong109/redis-cluster/commits/v0.1.0
