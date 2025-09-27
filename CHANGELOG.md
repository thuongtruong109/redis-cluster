# 📝 Changelog

## [v1.0.0 (2025-09-27)](https://github.com/thuongtruong109/redis-cluster/releases/tag/v1.0.0)

### ✨ Features

- cluster: Add health check, retry persistence, and rollback integration
- cluster: Integrate health checks for each node

### 🐛 Bug Fixes

- ci: Add auto rollback and retry mechanism in health check
- cmd: Patch version and CI directory name
- compose: Dynamic binding hostname to cluster node
- Automatically scale out/in and re-balance nodes

### 🛠️ CI/CD

- cluster: Automatically rollback when errors are detected on node
- workflow: Change build context
- workflow: Fix condition run
- workflow: Build and publish image

### 🧪 Tests

- ci: Add cluster benchmark test
- ha: Integrate security scan config, check open ports, check password
- Benchmark for replicas
- cluster: Add integration failover test suite

### 🧹 Chores

- script: Scale cluster
- script: Prepare run with bash
- compose: Start commander container in dev
- Integrate health checks for each node

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
