#!/bin/bash

# PPFE automated test script (using Network Namespace to realistically simulate network environment)
# Solved the problem of 127.0.0.1 bypassing tc configuration

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration parameters
ENTRY_SIZE=8
PORT=8080
SERVER_IP="10.0.0.1"  # IP in network namespace
CLIENT_IP="10.0.0.2"
RESULTS_DIR="./test_results"

# CPU core affinity configuration (using taskset to improve performance)
SERVER_CPU_CORE=0  # Server bound to CPU core 0
CLIENT_CPU_CORE=1  # Client bound to CPU core 1

# Set library path
export LD_LIBRARY_PATH=/root/troy-nova/build/src:$LD_LIBRARY_PATH

# Database size parameters (Log2DBSize)
DB_SIZES=(10 12 14 16 18 20 22)

# Network environment configuration
# Format: "Network Name|Latency|Bandwidth"
NETWORK_CONFIGS=(
    "Net1_3gbit|800us|3gbit"
    "Net2_1gbit|800us|1gbit"
    "Net3_200mbit|40ms|200mbit"
    "Net4_100mbit|80ms|100mbit"
)

# Check if running as root
check_root() {
        echo -e "${RED}Error: This script requires root privileges to configure the network environment${NC}"
        echo "Please use: sudo ./run_tests.sh"
        exit 1
    fi
}

# Check number of CPU cores
check_cpu_cores() {
    local num_cores=$(nproc)
    echo -e "${BLUE}Checking CPU core count...${NC}"
    echo -e "  System CPU cores: ${num_cores}"
    echo -e "  Server will use core: ${SERVER_CPU_CORE}"
    echo -e "  Client will use core: ${CLIENT_CPU_CORE}"
    
    if [ $num_cores -lt 2 ]; then
        echo -e "${YELLOW}Warning: System only has ${num_cores} CPU cores, at least 2 are recommended for best performance${NC}"
        echo -e "${YELLOW}Server and client will share the same CPU core${NC}"
    else
        echo -e "${GREEN}✓ Sufficient CPU cores, independent cores will be assigned to server and client${NC}"
    fi
    echo ""
}

# Create network namespace and virtual pair
setup_namespaces() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}Setup Network Namespace Environment${NC}"
    echo -e "${CYAN}========================================${NC}"
    
    # Cleanup possible existing configurations
    cleanup_namespaces 2>/dev/null
    
    # Create two network namespaces
    echo -e "${BLUE}Creating network namespaces...${NC}"
    ip netns add server_ns
    ip netns add client_ns
    
    # Create virtual network card pair
    echo -e "${BLUE}Creating virtual ethernet pair veth0 <-> veth1...${NC}"
    ip link add veth0 type veth peer name veth1
    
    # Assign to namespace
    ip link set veth0 netns server_ns
    ip link set veth1 netns client_ns
    
    # Configure IP addresses
    echo -e "${BLUE}Configuring IP addresses...${NC}"
    ip netns exec server_ns ip addr add ${SERVER_IP}/24 dev veth0
    ip netns exec client_ns ip addr add ${CLIENT_IP}/24 dev veth1
    
    # Bring up loopback interface
    ip netns exec server_ns ip link set lo up
    ip netns exec client_ns ip link set lo up
    
    # Bring up virtual network card
    ip netns exec server_ns ip link set veth0 up
    ip netns exec client_ns ip link set veth1 up
    
    echo -e "${GREEN}✓ Network Namespace environment setup complete${NC}"
    echo -e "  Server: server_ns (${SERVER_IP})"
    echo -e "  Client: client_ns (${CLIENT_IP})"
    echo ""
}

# Cleanup network namespace
cleanup_namespaces() {
    echo -e "${BLUE}Cleaning up Network Namespace...${NC}"
    ip netns del server_ns 2>/dev/null
    ip netns del client_ns 2>/dev/null
    echo -e "${GREEN}✓ Cleanup complete${NC}"
}

# Configure network limits in client namespace
setup_network_in_client() {
    local delay=$1
    local rate=$2
    
    echo -e "${BLUE}Configuring network limits in client: delay=${delay}, rate=${rate}${NC}"
    
    # Clear existing configuration first
    ip netns exec client_ns tc qdisc del dev veth1 root 2>/dev/null
    
    # Add network limits (on the virtual ethernet card of the client)
    ip netns exec client_ns tc qdisc add dev veth1 root netem delay ${delay} rate ${rate}
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Network limits configured successfully${NC}"
        
        # Verify configuration
        echo -e "${CYAN}Current network configuration:${NC}"
        ip netns exec client_ns tc qdisc show dev veth1
        return 0
    else
        echo -e "${RED}✗ Failed to configure network limits${NC}"
        return 1
    fi
}

# Clear client network limits
clear_network_in_client() {
    echo -e "${BLUE}Clearing client network limits...${NC}"
    ip netns exec client_ns tc qdisc del dev veth1 root 2>/dev/null
    echo -e "${GREEN}✓ Network limits cleared${NC}"
}

# Test network connectivity
test_connectivity() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}Test Network Connectivity${NC}"
    echo -e "${CYAN}========================================${NC}"
    
    echo -e "${BLUE}Client pinging server...${NC}"
    ip netns exec client_ns ping -c 3 ${SERVER_IP}
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Network connectivity normal${NC}"
        return 0
    else
        echo -e "${RED}✗ Network connectivity test failed${NC}"
        return 1
    fi
}

# Verify if network limits are in effect
verify_network_limits() {
    local delay=$1
    local rate=$2
    
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}Verify if network limits are in effect${NC}"
    echo -e "${CYAN}========================================${NC}"
    
    echo -e "${BLUE}Expected configuration: delay=${delay}, rate=${rate}${NC}"
    echo -e "${BLUE}Testing latency with ping...${NC}"
    
    # Test Round Trip Time (RTT)
    local ping_output=$(ip netns exec client_ns ping -c 10 ${SERVER_IP} | grep "avg")
    echo -e "${CYAN}Ping results: ${ping_output}${NC}"
    
    # Extract average latency
    local avg_rtt=$(echo $ping_output | awk -F'/' '{print $5}')
    echo -e "${YELLOW}Average RTT: ${avg_rtt} ms${NC}"
    
    # Note: One-way delay × 2 ≈ RTT
    echo -e "${YELLOW}Note: Configured one-way delay is ${delay}, expected RTT should be around 2x${NC}"
    echo ""
}

# Start server
start_server() {
    local log2dbsize=$1
    local entrysize=$2
    local port=$3
    local logfile=$4
    
    echo -e "${BLUE}Starting server in server_ns...${NC}"
    echo -e "  Log2DBSize: $log2dbsize"
    echo -e "  EntrySize: $entrysize bytes"
    echo -e "  Port: $port"
    echo -e "  Log file: $logfile"
    echo -e "  CPU core: ${SERVER_CPU_CORE}"
    
    # Start server in server_ns and bind to specified CPU core
    ip netns exec server_ns taskset -c ${SERVER_CPU_CORE} bash -c "export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}; ./build/PPFE_server $log2dbsize $entrysize $port" > "$logfile" 2>&1 &
    SERVER_PID=$!
    
    # Wait for server to be ready (monitor log file)
    echo -e "${YELLOW}Waiting for server to be ready...${NC}"
    local timeout=3000
    local elapsed=0
    
    while [ $elapsed -lt $timeout ]; do
        # Check if process is still running
        if ! ps -p $SERVER_PID > /dev/null; then
            echo -e "${RED}✗ Server process exited${NC}"
            cat "$logfile"
            return 1
        fi
        
        # Check if log file contains "Completed: 0%" or similar ready indicator (from main.cpp or server_main.cpp)
        # Using "Waiting for client connection" which is common in server_main
        if grep -q "Waiting for client connection" "$logfile" 2>/dev/null; then
            echo -e "${GREEN}✓ Server is ready, waiting for client connection (PID: $SERVER_PID)${NC}"
            return 0
        fi
        
        sleep 0.5
        elapsed=$((elapsed + 1))
    done
    
    # Timeout
    echo -e "${RED}✗ Timeout waiting for server to be ready (${timeout}s)${NC}"
    echo -e "${YELLOW}Server log content:${NC}"
    cat "$logfile"
    return 1
}

# Stop server
stop_server() {
    if [ ! -z "$SERVER_PID" ]; then
        echo -e "${BLUE}Stopping server (PID: $SERVER_PID)...${NC}"
        kill $SERVER_PID 2>/dev/null
        wait $SERVER_PID 2>/dev/null
        echo -e "${GREEN}✓ Server stopped${NC}"
        SERVER_PID=""
    fi
}

# Run client
run_client() {
    local server_ip=$1
    local port=$2
    local output_file=$3
    local logfile=$4
    
    echo -e "${BLUE}Running client in client_ns...${NC}"
    echo -e "  Connecting to: $server_ip:$port"
    echo -e "  Output file: $output_file"
    echo -e "  Log file: $logfile"
    echo -e "  CPU core: ${CLIENT_CPU_CORE}"
    
    # Run client in client_ns and bind to specified CPU core
    ip netns exec client_ns taskset -c ${CLIENT_CPU_CORE} bash -c "export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}; ./build/PPFE_client $server_ip $port $output_file" > "$logfile" 2>&1
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}✓ Client executed successfully${NC}"
        return 0
    else
        echo -e "${RED}✗ Client execution failed (Exit code: $exit_code)${NC}"
        echo -e "${RED}Check log: $logfile${NC}"
        return 1
    fi
}

# Run single test
run_single_test() {
    local network_name=$1
    local delay=$2
    local rate=$3
    local log2dbsize=$4
    local entrysize=$5
    
    local test_name="${network_name}_log2db${log2dbsize}_entry${entrysize}"
    local output_file="${RESULTS_DIR}/${test_name}.csv"
    local server_log="${RESULTS_DIR}/${test_name}_server.log"
    local client_log="${RESULTS_DIR}/${test_name}_client.log"
    
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}Running test: ${test_name}${NC}"
    echo -e "${CYAN}========================================${NC}"
    
    # Configure network limits
    setup_network_in_client "$delay" "$rate"
    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ Network configuration failed, skipping this test${NC}"
        return 1
    fi
    
    # Verify network limits
    verify_network_limits "$delay" "$rate"
    
    # Start server (automatically waits for server to be ready)
    start_server "$log2dbsize" "$entrysize" "$PORT" "$server_log"
    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ Server start failed, skipping this test${NC}"
        return 1
    fi
    
    # Run client
    run_client "$SERVER_IP" "$PORT" "$output_file" "$client_log"
    local client_status=$?
    
    # Stop server
    stop_server
    
    # Clear network limits
    clear_network_in_client
    
    # Wait for cleanup
    sleep 1
    
    if [ $client_status -eq 0 ]; then
        echo -e "${GREEN}✓✓✓ Test Complete: ${test_name} ✓✓✓${NC}"
        echo ""
        return 0
    else
        echo -e "${RED}✗✗✗ Test Failed: ${test_name} ✗✗✗${NC}"
        echo ""
        return 1
    fi
}

# Main test flow
run_all_tests() {
    local success_count=0
    local total_count=0
    
    echo -e "${CYAN}========================================"
    echo -e "Start running all tests"
    echo -e "========================================${NC}"
    
    for dbsize in "${DB_SIZES[@]}"; do
        echo -e "${YELLOW}Database size: Log2DBSize=${dbsize}${NC}"
        
        for net_config in "${NETWORK_CONFIGS[@]}"; do
            IFS='|' read -r network_name delay rate <<< "$net_config"
            
            total_count=$((total_count + 1))
            
            run_single_test "$network_name" "$delay" "$rate" "$dbsize" "$ENTRY_SIZE"
            
            if [ $? -eq 0 ]; then
                success_count=$((success_count + 1))
            fi
        done
    done
    
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}Test Completion Statistics${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "Total tests: ${total_count}"
    echo -e "${GREEN}Success: ${success_count}${NC}"
    echo -e "${RED}Failed: $((total_count - success_count))${NC}"
    echo -e "${CYAN}========================================${NC}"
}

# Show usage instructions
show_usage() {
    echo "Usage: sudo ./run_tests.sh [options]"
    echo ""
    echo "Options:"
    echo "  setup     - Only setup network namespace"
    echo "  cleanup   - Only cleanup network namespace"
    echo "  test      - Run all tests (default)"
    echo "  verify    - Setup environment and verify network configuration"
    echo ""
    echo "Example:"
    echo "  sudo ./run_tests.sh           # Run all tests"
    echo "  sudo ./run_tests.sh setup     # Setup environment only"
    echo "  sudo ./run_tests.sh verify    # Verify network configuration"
    echo "  sudo ./run_tests.sh cleanup   # Cleanup environment"
}

# Check prerequisites
check_prerequisites() {
    echo -e "${BLUE}Checking prerequisites...${NC}"
    
    # Check executable files
    if [ ! -f "./build/PPFE_server" ]; then
        echo -e "${RED}Error: ./build/PPFE_server not found${NC}"
        echo "Please compile the project first: make"
        exit 1
    fi
    
    if [ ! -f "./build/PPFE_client" ]; then
        echo -e "${RED}Error: ./build/PPFE_client not found${NC}"
        echo "Please compile the project first: make"
        exit 1
    fi
    
    # Check library path
    if [ ! -z "$LD_LIBRARY_PATH" ]; then
        echo -e "${GREEN}✓ Library path set: $LD_LIBRARY_PATH${NC}"
    else
        echo -e "${YELLOW}Warning: LD_LIBRARY_PATH is not set${NC}"
    fi
    
    echo -e "${GREEN}✓ Prerequisites check passed${NC}\n"
}

# Main function
main() {
    check_root
    check_cpu_cores
    check_prerequisites
    
    # Create results directory
    mkdir -p "$RESULTS_DIR"
    
    local command=${1:-test}
    
    case $command in
        setup)
            setup_namespaces
            ;;
        cleanup)
            cleanup_namespaces
            ;;
        verify)
            setup_namespaces
            test_connectivity
            echo ""
            echo -e "${YELLOW}Testing effect of different network limits:${NC}"
            for net_config in "${NETWORK_CONFIGS[@]}"; do
                IFS='|' read -r network_name delay rate <<< "$net_config"
                echo ""
                echo -e "${CYAN}Configuration: ${network_name}${NC}"
                setup_network_in_client "$delay" "$rate"
                verify_network_limits "$delay" "$rate"
                clear_network_in_client
                sleep 1
            done
            ;;
        test)
            setup_namespaces
            test_connectivity
            if [ $? -eq 0 ]; then
                run_all_tests
            else
                echo -e "${RED}Network connectivity test failed, terminating test${NC}"
                cleanup_namespaces
                exit 1
            fi
            cleanup_namespaces
            ;;
        *)
            show_usage
            exit 1
            ;;
    esac
}

# Trap exit signal to ensure cleanup
trap cleanup_namespaces EXIT

# Run main function
main "$@"

