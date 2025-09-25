# Changelog

# [v1.0.0 (2025-09-25)](https://github.com/thuongtruong109/redis-cluster/releases/tag/v1.0.0)

### CI

- ci(workflow): build and publish image

### Documentation

- docs: update description and assets (logo, banner)

### Tests

- test(cluster): add integration failover test suite

### Bug Fixes

- fix(compose): dynamic binding hostname to cluster node

### Chore

- chore(compose): setup cluster script

**Full Changelog**: https://github.com/thuongtruong109/redis-cluster/commits/v1.0.0

## [v0.1.0 (2025-09-25)](https://github.com/thuongtruong109/redis-cluster/releases/tag/v0.1.0)

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
