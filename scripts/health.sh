#!/bin/bash

# Redis Cluster Health Check Script
# Fixed version with proper shell formatting

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MASTER_HOST="172.28.0.10"
MASTER_PORT="6379"
MASTER_PASS="masterpass"

SLAVE_HOSTS=("172.28.0.11" "172.28.0.12" "172.28.0.13")
SLAVE_PORTS=("6379" "6379" "6379")
SLAVE_PASS="masterpass"

SENTINEL_HOSTS=("172.28.0.20" "172.28.0.21" "172.28.0.22")
SENTINEL_PORTS=("26379" "26379" "26379")

MASTER_NAME="mymaster"
LOG_FILE="/tmp/redis_health_check.log"
METRICS_FILE="/tmp/redis_metrics.json"

# Functions
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

print_status() {
    local status="$1"
    local message="$2"
    if [ "$status" = "OK" ]; then
        echo -e "${GREEN}✅ $message${NC}"
        log "OK: $message"
    elif [ "$status" = "WARN" ]; then
        echo -e "${YELLOW}⚠️  $message${NC}"
        log "WARN: $message"
    else
        echo -e "${RED}❌ $message${NC}"
        log "ERROR: $message"
    fi
}

check_redis_connection() {
    local host="$1"
    local port="$2"
    local password="$3"
    local name="$4"

    if docker exec redis-master redis-cli -h "$host" -p "$port" -a "$password" ping &>/dev/null; then
        print_status "OK" "$name connection successful"
        return 0
    else
        print_status "ERROR" "$name connection failed"
        return 1
    fi
}

check_replication() {
    log "Checking replication status..."

    # Set a test key on master
    local test_key="health_check_$(date +%s)"
    local test_value="health_check_value_$(date +%s)"

    if ! docker exec redis-master redis-cli -a "$MASTER_PASS" set "$test_key" "$test_value" &>/dev/null; then
        print_status "ERROR" "Failed to write test key to master"
        return 1
    fi

    # Wait a moment for replication
    sleep 2

    # Check if replicated to all slaves
    local failed_slaves=0
    for i in "${!SLAVE_HOSTS[@]}"; do
        local slave_host="${SLAVE_HOSTS[$i]}"
        local slave_port="${SLAVE_PORTS[$i]}"
        local slave_num=$((i + 1))

        local replicated_value
        replicated_value=$(docker exec "slave_$slave_num" redis-cli -a "$SLAVE_PASS" get "$test_key" 2>/dev/null || echo "ERROR")

        if [ "$replicated_value" = "$test_value" ]; then
            print_status "OK" "Replication working on slave_$slave_num"
        else
            print_status "ERROR" "Replication failed on slave_$slave_num (got: $replicated_value)"
            ((failed_slaves++))
        fi
    done

    # Cleanup
    docker exec redis-master redis-cli -a "$MASTER_PASS" del "$test_key" &>/dev/null

    if [ $failed_slaves -eq 0 ]; then
        print_status "OK" "All slaves are properly replicating"
        return 0
    else
        print_status "ERROR" "$failed_slaves slaves failed replication test"
        return 1
    fi
}

check_sentinel_status() {
    log "Checking Sentinel status..."

    local failed_sentinels=0
    for i in "${!SENTINEL_HOSTS[@]}"; do
        local sentinel_host="${SENTINEL_HOSTS[$i]}"
        local sentinel_port="${SENTINEL_PORTS[$i]}"
        local sentinel_num=$((i + 1))

        # Check sentinel ping
        if docker exec "sentinel_$sentinel_num" redis-cli -h "$sentinel_host" -p "$sentinel_port" ping &>/dev/null; then
            print_status "OK" "Sentinel_$sentinel_num is responding"

            # Check master discovery
            local master_info
            master_info=$(docker exec "sentinel_$sentinel_num" redis-cli -p 26379 sentinel get-master-addr-by-name "$MASTER_NAME" 2>/dev/null || echo "ERROR")

            if echo "$master_info" | grep -q "$MASTER_HOST"; then
                print_status "OK" "Sentinel_$sentinel_num correctly identifies master"
            else
                print_status "WARN" "Sentinel_$sentinel_num master discovery issue"
                ((failed_sentinels++))
            fi
        else
            print_status "ERROR" "Sentinel_$sentinel_num is not responding"
            ((failed_sentinels++))
        fi
    done

    if [ $failed_sentinels -eq 0 ]; then
        print_status "OK" "All sentinels are healthy"
        return 0
    else
        print_status "WARN" "$failed_sentinels sentinels have issues"
        return 1
    fi
}

check_memory_usage() {
    log "Checking memory usage..."

    # Check master memory
    local master_memory
    master_memory=$(docker exec redis-master redis-cli -a "$MASTER_PASS" info memory | grep "used_memory_human" | cut -d: -f2 | tr -d '\r')
    print_status "OK" "Master memory usage: $master_memory"

    # Check slave memory
    for i in "${!SLAVE_HOSTS[@]}"; do
        local slave_num=$((i + 1))
        local slave_memory
        slave_memory=$(docker exec "slave_$slave_num" redis-cli -a "$SLAVE_PASS" info memory | grep "used_memory_human" | cut -d: -f2 | tr -d '\r')
        print_status "OK" "Slave_$slave_num memory usage: $slave_memory"
    done
}

check_replication_lag() {
    log "Checking replication lag..."

    for i in "${!SLAVE_HOSTS[@]}"; do
        local slave_num=$((i + 1))
        local lag_info
        lag_info=$(docker exec "slave_$slave_num" redis-cli -a "$SLAVE_PASS" info replication | grep "master_last_io_seconds_ago" | cut -d: -f2 | tr -d '\r')

        if [ -n "$lag_info" ] && [ "$lag_info" -lt 10 ]; then
            print_status "OK" "Slave_$slave_num replication lag: ${lag_info}s"
        else
            print_status "WARN" "Slave_$slave_num replication lag: ${lag_info}s (high)"
        fi
    done
}

check_container_health() {
    log "Checking container health..."

    local containers=("redis-master" "slave_1" "slave_2" "slave_3" "sentinel_1" "sentinel_2" "sentinel_3" "commander")

    for container in "${containers[@]}"; do
        if docker ps --filter "name=$container" --filter "status=running" | grep -q "$container"; then
            print_status "OK" "Container $container is running"
        else
            print_status "ERROR" "Container $container is not running"
        fi
    done
}

collect_metrics() {
    log "Collecting metrics..."

    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local metrics="{\"timestamp\": \"$timestamp\", \"services\": {"

    # Master metrics
    local master_connected_clients
    master_connected_clients=$(docker exec redis-master redis-cli -a "$MASTER_PASS" info clients | grep "connected_clients" | cut -d: -f2 | tr -d '\r')

    local master_total_commands
    master_total_commands=$(docker exec redis-master redis-cli -a "$MASTER_PASS" info stats | grep "total_commands_processed" | cut -d: -f2 | tr -d '\r')

    metrics="$metrics\"master\": {\"connected_clients\": $master_connected_clients, \"total_commands\": $master_total_commands}"

    # Slave metrics
    metrics="$metrics, \"slaves\": ["
    for i in "${!SLAVE_HOSTS[@]}"; do
        local slave_num=$((i + 1))
        local slave_connected_clients
        slave_connected_clients=$(docker exec "slave_$slave_num" redis-cli -a "$SLAVE_PASS" info clients | grep "connected_clients" | cut -d: -f2 | tr -d '\r')

        if [ $i -gt 0 ]; then
            metrics="$metrics, "
        fi
        metrics="$metrics{\"slave_$slave_num\": {\"connected_clients\": $slave_connected_clients}}"
    done
    metrics="$metrics]"

    metrics="$metrics}}"

    echo "$metrics" > "$METRICS_FILE"
    print_status "OK" "Metrics collected and saved to $METRICS_FILE"
}

perform_load_test() {
    log "Performing basic load test..."

    # Simple load test - write 1000 keys
    local start_time=$(date +%s)

    for i in {1..1000}; do
        docker exec redis-master redis-cli -a "$MASTER_PASS" set "load_test_key_$i" "load_test_value_$i" &>/dev/null
    done

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local ops_per_second=$((1000 / duration))

    print_status "OK" "Load test completed: $ops_per_second ops/sec"

    # Cleanup
    docker exec redis-master redis-cli -a "$MASTER_PASS" eval "for _,k in ipairs(redis.call('keys', 'load_test_key_*')) do redis.call('del', k) end" 0 &>/dev/null

    if [ $ops_per_second -gt 100 ]; then
        print_status "OK" "Performance is acceptable"
    else
        print_status "WARN" "Performance is below expected threshold"
    fi
}

cleanup_old_logs() {
    # Keep only last 10 log files
    find /tmp -name "redis_health_check*.log" -type f -mtime +7 -delete 2>/dev/null || true
    find /tmp -name "redis_metrics*.json" -type f -mtime +7 -delete 2>/dev/null || true
}

generate_report() {
    local report_file="/tmp/redis_health_report_$(date +%Y%m%d_%H%M%S).txt"

    cat << EOF > "$report_file"
Redis Cluster Health Report
==========================
Generated: $(date)
Log file: $LOG_FILE
Metrics file: $METRICS_FILE

Summary:
- Master Status: $(check_redis_connection "$MASTER_HOST" "$MASTER_PORT" "$MASTER_PASS" "Master" && echo "OK" || echo "ERROR")
- Container Status: $(check_container_health && echo "OK" || echo "ERROR")

See detailed logs in: $LOG_FILE
EOF

    echo -e "\n${BLUE}📊 Health report generated: $report_file${NC}"
}

show_usage() {
    cat << EOF
Redis Cluster Health Check Script

Usage: $0 [OPTIONS]

OPTIONS:
    --basic         Run basic health checks only
    --full          Run comprehensive health checks (default)
    --load-test     Include load testing
    --metrics-only  Only collect metrics
    --report        Generate detailed report
    --help          Show this help message

EXAMPLES:
    $0                    # Run full health check
    $0 --basic           # Run basic checks only
    $0 --load-test       # Include performance testing
    $0 --metrics-only    # Just collect metrics

EOF
}

main() {
    local mode="full"
    local include_load_test=false
    local metrics_only=false
    local generate_report_flag=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --basic)
                mode="basic"
                shift
                ;;
            --full)
                mode="full"
                shift
                ;;
            --load-test)
                include_load_test=true
                shift
                ;;
            --metrics-only)
                metrics_only=true
                shift
                ;;
            --report)
                generate_report_flag=true
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    # Initialize
    cleanup_old_logs
    > "$LOG_FILE"  # Clear log file

    echo -e "${BLUE}🏥 Redis Cluster Health Check Starting...${NC}"
    log "Health check started with mode: $mode"

    if [ "$metrics_only" = true ]; then
        collect_metrics
        exit 0
    fi

    local overall_status=0

    # Basic checks
    echo -e "\n${BLUE}🔍 Basic Health Checks${NC}"
    check_container_health || overall_status=1
    check_redis_connection "$MASTER_HOST" "$MASTER_PORT" "$MASTER_PASS" "Master" || overall_status=1

    for i in "${!SLAVE_HOSTS[@]}"; do
        local slave_num=$((i + 1))
        check_redis_connection "${SLAVE_HOSTS[$i]}" "${SLAVE_PORTS[$i]}" "$SLAVE_PASS" "Slave_$slave_num" || overall_status=1
    done

    # Full checks
    if [ "$mode" = "full" ]; then
        echo -e "\n${BLUE}🔄 Replication Checks${NC}"
        check_replication || overall_status=1
        check_replication_lag

        echo -e "\n${BLUE}👁️  Sentinel Checks${NC}"
        check_sentinel_status || overall_status=1

        echo -e "\n${BLUE}📊 System Metrics${NC}"
        check_memory_usage
        collect_metrics
    fi

    # Load test
    if [ "$include_load_test" = true ]; then
        echo -e "\n${BLUE}⚡ Performance Testing${NC}"
        perform_load_test
    fi

    # Generate report
    if [ "$generate_report_flag" = true ]; then
        generate_report
    fi

    # Final status
    echo -e "\n${BLUE}📋 Health Check Summary${NC}"
    if [ $overall_status -eq 0 ]; then
        print_status "OK" "All health checks passed"
        echo -e "${GREEN}🎉 Redis cluster is healthy!${NC}"
    else
        print_status "ERROR" "Some health checks failed"
        echo -e "${RED}⚠️  Redis cluster has issues - check the logs!${NC}"
    fi

    echo -e "\n${BLUE}📝 Logs saved to: $LOG_FILE${NC}"
    exit $overall_status
}

# Run main function with all arguments
main "$@"