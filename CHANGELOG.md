# Changelog

## [v0.1.0 - 2025-09-25](https://github.com/thuongtruong109/redis-cluster/releases/tag/v0.1.0)

### CI

- split cd stage
- simplify workflow name and restrict push branches to main
- update script
- add tests script

### Test

- update for ci context
- update scenario for ci
- add integration test

### Fixes

- detect current master dynamically and retry replication checks (integration)
- auto detect ttl mode (failover)
- resolved hang on waiting promote master (integration)

### Chore

- backup and import data (script)
- backup rdb (script)
- enable cluster mode
- convert to internal IP
- setup replicas

### Docs

- update descriptions and scripts

**Full Changelog**: https://github.com/thuongtruong109/redis-cluster/commits/v0.1.0
