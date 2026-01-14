#!/bin/bash

<<<<<<< HEAD
# PPFE automated test script (using Network Namespace to realistically simulate network environment)
# Solved the problem of 127.0.0.1 bypassing tc configuration

# Color definitions
=======
# PPFE 自动化测试脚本 (使用 Network Namespace 真实模拟网络环境)
# 解决了 127.0.0.1 绕过 tc 配置的问题

# 颜色定义
>>>>>>> f4a701c (Add files via upload)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

<<<<<<< HEAD
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
=======
# 配置参数
ENTRY_SIZE=8
PORT=8080
SERVER_IP="10.0.0.1"  # 在 network namespace 中的IP
CLIENT_IP="10.0.0.2"
RESULTS_DIR="./test_results"

# CPU核心绑定配置（使用taskset提升性能）
SERVER_CPU_CORE=0  # 服务器绑定到CPU核心0
CLIENT_CPU_CORE=1  # 客户端绑定到CPU核心1

# 设置库路径
export LD_LIBRARY_PATH=/root/troy-nova/build/src:$LD_LIBRARY_PATH

# 数据库大小参数 (Log2DBSize)
DB_SIZES=(10 12 14 16 18 20 22)

# 网络环境配置
# 格式: "网络名称|延迟|带宽"
>>>>>>> f4a701c (Add files via upload)
NETWORK_CONFIGS=(
    "Net1_3gbit|800us|3gbit"
    "Net2_1gbit|800us|1gbit"
    "Net3_200mbit|40ms|200mbit"
    "Net4_100mbit|80ms|100mbit"
)

<<<<<<< HEAD
# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Error: This script requires root privileges to configure the network environment${NC}"
        echo "Please use: sudo ./run_tests.sh"
=======
# 检查是否以root权限运行
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}错误: 此脚本需要root权限来配置网络环境${NC}"
        echo "请使用: sudo ./run_tests_netns.sh"
>>>>>>> f4a701c (Add files via upload)
        exit 1
    fi
}

<<<<<<< HEAD
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
=======
# 检查CPU核心数量
check_cpu_cores() {
    local num_cores=$(nproc)
    echo -e "${BLUE}检查CPU核心数量...${NC}"
    echo -e "  系统CPU核心数: ${num_cores}"
    echo -e "  服务器将使用核心: ${SERVER_CPU_CORE}"
    echo -e "  客户端将使用核心: ${CLIENT_CPU_CORE}"
    
    if [ $num_cores -lt 2 ]; then
        echo -e "${YELLOW}警告: 系统只有${num_cores}个CPU核心，建议至少2个核心以获得最佳性能${NC}"
        echo -e "${YELLOW}服务器和客户端将共享相同的CPU核心${NC}"
    else
        echo -e "${GREEN}✓ CPU核心数量充足，将为服务器和客户端分配独立核心${NC}"
>>>>>>> f4a701c (Add files via upload)
    fi
    echo ""
}

<<<<<<< HEAD
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
=======
# 创建 network namespace 和虚拟网卡
setup_namespaces() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}设置 Network Namespace 环境${NC}"
    echo -e "${CYAN}========================================${NC}"
    
    # 清理可能存在的旧配置
    cleanup_namespaces 2>/dev/null
    
    # 创建两个网络命名空间
    echo -e "${BLUE}创建网络命名空间...${NC}"
    ip netns add server_ns
    ip netns add client_ns
    
    # 创建虚拟网卡对
    echo -e "${BLUE}创建虚拟网卡对 veth0 <-> veth1...${NC}"
    ip link add veth0 type veth peer name veth1
    
    # 分配到命名空间
    ip link set veth0 netns server_ns
    ip link set veth1 netns client_ns
    
    # 配置IP地址
    echo -e "${BLUE}配置IP地址...${NC}"
    ip netns exec server_ns ip addr add ${SERVER_IP}/24 dev veth0
    ip netns exec client_ns ip addr add ${CLIENT_IP}/24 dev veth1
    
    # 启动loopback接口
    ip netns exec server_ns ip link set lo up
    ip netns exec client_ns ip link set lo up
    
    # 启动虚拟网卡
    ip netns exec server_ns ip link set veth0 up
    ip netns exec client_ns ip link set veth1 up
    
    echo -e "${GREEN}✓ Network Namespace 环境配置完成${NC}"
    echo -e "  服务器: server_ns (${SERVER_IP})"
    echo -e "  客户端: client_ns (${CLIENT_IP})"
    echo ""
}

# 清理 network namespace
cleanup_namespaces() {
    echo -e "${BLUE}清理 Network Namespace...${NC}"
    ip netns del server_ns 2>/dev/null
    ip netns del client_ns 2>/dev/null
    echo -e "${GREEN}✓ 清理完成${NC}"
}

# 在客户端配置网络限制
>>>>>>> f4a701c (Add files via upload)
setup_network_in_client() {
    local delay=$1
    local rate=$2
    
<<<<<<< HEAD
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
=======
    echo -e "${BLUE}在客户端配置网络限制: delay=${delay}, rate=${rate}${NC}"
    
    # 先清除已有配置
    ip netns exec client_ns tc qdisc del dev veth1 root 2>/dev/null
    
    # 添加网络限制（在客户端的虚拟网卡上）
    ip netns exec client_ns tc qdisc add dev veth1 root netem delay ${delay} rate ${rate}
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 网络限制配置成功${NC}"
        
        # 验证配置
        echo -e "${CYAN}当前网络配置:${NC}"
        ip netns exec client_ns tc qdisc show dev veth1
        return 0
    else
        echo -e "${RED}✗ 网络限制配置失败${NC}"
>>>>>>> f4a701c (Add files via upload)
        return 1
    fi
}

<<<<<<< HEAD
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
=======
# 清除客户端网络限制
clear_network_in_client() {
    echo -e "${BLUE}清除客户端网络限制...${NC}"
    ip netns exec client_ns tc qdisc del dev veth1 root 2>/dev/null
    echo -e "${GREEN}✓ 网络限制已清除${NC}"
}

# 测试网络连通性
test_connectivity() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}测试网络连通性${NC}"
    echo -e "${CYAN}========================================${NC}"
    
    echo -e "${BLUE}客户端 ping 服务器...${NC}"
    ip netns exec client_ns ping -c 3 ${SERVER_IP}
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 网络连通性正常${NC}"
        return 0
    else
        echo -e "${RED}✗ 网络连通性测试失败${NC}"
>>>>>>> f4a701c (Add files via upload)
        return 1
    fi
}

<<<<<<< HEAD
# Verify if network limits are in effect
=======
# 验证网络限制是否生效
>>>>>>> f4a701c (Add files via upload)
verify_network_limits() {
    local delay=$1
    local rate=$2
    
    echo -e "${CYAN}========================================${NC}"
<<<<<<< HEAD
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
=======
    echo -e "${CYAN}验证网络限制是否生效${NC}"
    echo -e "${CYAN}========================================${NC}"
    
    echo -e "${BLUE}预期配置: delay=${delay}, rate=${rate}${NC}"
    echo -e "${BLUE}使用 ping 测试延迟...${NC}"
    
    # 测试往返延迟（RTT）
    local ping_output=$(ip netns exec client_ns ping -c 10 ${SERVER_IP} | grep "avg")
    echo -e "${CYAN}Ping结果: ${ping_output}${NC}"
    
    # 提取平均延迟
    local avg_rtt=$(echo $ping_output | awk -F'/' '{print $5}')
    echo -e "${YELLOW}平均RTT: ${avg_rtt} ms${NC}"
    
    # 说明：单向延迟 × 2 ≈ RTT
    echo -e "${YELLOW}说明: 配置的单向延迟是 ${delay}，预期RTT应约为 2倍${NC}"
    echo ""
}

# 启动服务器
>>>>>>> f4a701c (Add files via upload)
start_server() {
    local log2dbsize=$1
    local entrysize=$2
    local port=$3
    local logfile=$4
    
<<<<<<< HEAD
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
=======
    echo -e "${BLUE}在 server_ns 中启动服务器...${NC}"
    echo -e "  Log2DBSize: $log2dbsize"
    echo -e "  EntrySize: $entrysize bytes"
    echo -e "  Port: $port"
    echo -e "  日志文件: $logfile"
    echo -e "  CPU核心: ${SERVER_CPU_CORE}"
    
    # 在 server_ns 中启动服务器，并绑定到指定CPU核心
    ip netns exec server_ns taskset -c ${SERVER_CPU_CORE} bash -c "export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}; ./build/PPFE_server $log2dbsize $entrysize $port" > "$logfile" 2>&1 &
    SERVER_PID=$!
    
    # 等待服务器准备就绪（监控日志文件）
    echo -e "${YELLOW}等待服务器准备就绪...${NC}"
>>>>>>> f4a701c (Add files via upload)
    local timeout=3000
    local elapsed=0
    
    while [ $elapsed -lt $timeout ]; do
<<<<<<< HEAD
        # Check if process is still running
        if ! ps -p $SERVER_PID > /dev/null; then
            echo -e "${RED}✗ Server process exited${NC}"
=======
        # 检查进程是否还在运行
        if ! ps -p $SERVER_PID > /dev/null; then
            echo -e "${RED}✗ 服务器进程已退出${NC}"
>>>>>>> f4a701c (Add files via upload)
            cat "$logfile"
            return 1
        fi
        
<<<<<<< HEAD
        # Check if log file contains "Completed: 0%" or similar ready indicator (from main.cpp or server_main.cpp)
        # Using "Waiting for client connection" which is common in server_main
        if grep -q "Waiting for client connection" "$logfile" 2>/dev/null; then
            echo -e "${GREEN}✓ Server is ready, waiting for client connection (PID: $SERVER_PID)${NC}"
=======
        # 检查日志文件是否包含"等待客户端连接"
        if grep -q "等待客户端连接" "$logfile" 2>/dev/null; then
            echo -e "${GREEN}✓ 服务器已准备就绪，正在等待客户端连接 (PID: $SERVER_PID)${NC}"
>>>>>>> f4a701c (Add files via upload)
            return 0
        fi
        
        sleep 0.5
        elapsed=$((elapsed + 1))
    done
    
<<<<<<< HEAD
    # Timeout
    echo -e "${RED}✗ Timeout waiting for server to be ready (${timeout}s)${NC}"
    echo -e "${YELLOW}Server log content:${NC}"
=======
    # 超时
    echo -e "${RED}✗ 等待服务器准备就绪超时（${timeout}秒）${NC}"
    echo -e "${YELLOW}服务器日志内容:${NC}"
>>>>>>> f4a701c (Add files via upload)
    cat "$logfile"
    return 1
}

<<<<<<< HEAD
# Stop server
stop_server() {
    if [ ! -z "$SERVER_PID" ]; then
        echo -e "${BLUE}Stopping server (PID: $SERVER_PID)...${NC}"
        kill $SERVER_PID 2>/dev/null
        wait $SERVER_PID 2>/dev/null
        echo -e "${GREEN}✓ Server stopped${NC}"
=======
# 停止服务器
stop_server() {
    if [ ! -z "$SERVER_PID" ]; then
        echo -e "${BLUE}停止服务器 (PID: $SERVER_PID)...${NC}"
        kill $SERVER_PID 2>/dev/null
        wait $SERVER_PID 2>/dev/null
        echo -e "${GREEN}✓ 服务器已停止${NC}"
>>>>>>> f4a701c (Add files via upload)
        SERVER_PID=""
    fi
}

<<<<<<< HEAD
# Run client
=======
# 运行客户端
>>>>>>> f4a701c (Add files via upload)
run_client() {
    local server_ip=$1
    local port=$2
    local output_file=$3
    local logfile=$4
    
<<<<<<< HEAD
    echo -e "${BLUE}Running client in client_ns...${NC}"
    echo -e "  Connecting to: $server_ip:$port"
    echo -e "  Output file: $output_file"
    echo -e "  Log file: $logfile"
    echo -e "  CPU core: ${CLIENT_CPU_CORE}"
    
    # Run client in client_ns and bind to specified CPU core
=======
    echo -e "${BLUE}在 client_ns 中运行客户端...${NC}"
    echo -e "  连接到: $server_ip:$port"
    echo -e "  输出文件: $output_file"
    echo -e "  日志文件: $logfile"
    echo -e "  CPU核心: ${CLIENT_CPU_CORE}"
    
    # 在 client_ns 中运行客户端，并绑定到指定CPU核心
>>>>>>> f4a701c (Add files via upload)
    ip netns exec client_ns taskset -c ${CLIENT_CPU_CORE} bash -c "export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}; ./build/PPFE_client $server_ip $port $output_file" > "$logfile" 2>&1
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
<<<<<<< HEAD
        echo -e "${GREEN}✓ Client executed successfully${NC}"
        return 0
    else
        echo -e "${RED}✗ Client execution failed (Exit code: $exit_code)${NC}"
        echo -e "${RED}Check log: $logfile${NC}"
=======
        echo -e "${GREEN}✓ 客户端执行成功${NC}"
        return 0
    else
        echo -e "${RED}✗ 客户端执行失败 (退出码: $exit_code)${NC}"
        echo -e "${RED}查看日志: $logfile${NC}"
>>>>>>> f4a701c (Add files via upload)
        return 1
    fi
}

<<<<<<< HEAD
# Run single test
=======
# 运行单个测试
>>>>>>> f4a701c (Add files via upload)
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
<<<<<<< HEAD
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
=======
    echo -e "${CYAN}运行测试: ${test_name}${NC}"
    echo -e "${CYAN}========================================${NC}"
    
    # 配置网络限制
    setup_network_in_client "$delay" "$rate"
    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ 网络配置失败，跳过此测试${NC}"
        return 1
    fi
    
    # 验证网络限制
    verify_network_limits "$delay" "$rate"
    
    # 启动服务器（会自动等待服务器准备就绪）
    start_server "$log2dbsize" "$entrysize" "$PORT" "$server_log"
    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ 服务器启动失败，跳过此测试${NC}"
        return 1
    fi
    
    # 运行客户端
    run_client "$SERVER_IP" "$PORT" "$output_file" "$client_log"
    local client_status=$?
    
    # 停止服务器
    stop_server
    
    # 清除网络限制
    clear_network_in_client
    
    # 等待清理
    sleep 1
    
    if [ $client_status -eq 0 ]; then
        echo -e "${GREEN}✓✓✓ 测试完成: ${test_name} ✓✓✓${NC}"
        echo ""
        return 0
    else
        echo -e "${RED}✗✗✗ 测试失败: ${test_name} ✗✗✗${NC}"
>>>>>>> f4a701c (Add files via upload)
        echo ""
        return 1
    fi
}

<<<<<<< HEAD
# Main test flow
=======
# 主测试流程
>>>>>>> f4a701c (Add files via upload)
run_all_tests() {
    local success_count=0
    local total_count=0
    
    echo -e "${CYAN}========================================"
<<<<<<< HEAD
    echo -e "Start running all tests"
    echo -e "========================================${NC}"
    
    for dbsize in "${DB_SIZES[@]}"; do
        echo -e "${YELLOW}Database size: Log2DBSize=${dbsize}${NC}"
=======
    echo -e "开始运行所有测试"
    echo -e "========================================${NC}"
    
    for dbsize in "${DB_SIZES[@]}"; do
        echo -e "${YELLOW}数据库大小: Log2DBSize=${dbsize}${NC}"
>>>>>>> f4a701c (Add files via upload)
        
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
<<<<<<< HEAD
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
=======
    echo -e "${CYAN}测试完成统计${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "总测试数: ${total_count}"
    echo -e "${GREEN}成功: ${success_count}${NC}"
    echo -e "${RED}失败: $((total_count - success_count))${NC}"
    echo -e "${CYAN}========================================${NC}"
}

# 显示使用说明
show_usage() {
    echo "用法: sudo ./run_tests_netns.sh [选项]"
    echo ""
    echo "选项:"
    echo "  setup     - 仅设置 network namespace"
    echo "  cleanup   - 仅清理 network namespace"
    echo "  test      - 运行所有测试 (默认)"
    echo "  verify    - 设置环境并验证网络配置"
    echo ""
    echo "示例:"
    echo "  sudo ./run_tests_netns.sh           # 运行所有测试"
    echo "  sudo ./run_tests_netns.sh setup     # 仅设置环境"
    echo "  sudo ./run_tests_netns.sh verify    # 验证网络配置"
    echo "  sudo ./run_tests_netns.sh cleanup   # 清理环境"
}

# 检查必要的文件
check_prerequisites() {
    echo -e "${BLUE}检查先决条件...${NC}"
    
    # 检查可执行文件
    if [ ! -f "./build/PPFE_server" ]; then
        echo -e "${RED}错误: 未找到 ./build/PPFE_server${NC}"
        echo "请先编译项目: make"
>>>>>>> f4a701c (Add files via upload)
        exit 1
    fi
    
    if [ ! -f "./build/PPFE_client" ]; then
<<<<<<< HEAD
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
=======
        echo -e "${RED}错误: 未找到 ./build/PPFE_client${NC}"
        echo "请先编译项目: make"
        exit 1
    fi
    
    # 检查库路径
    if [ ! -z "$LD_LIBRARY_PATH" ]; then
        echo -e "${GREEN}✓ 库路径已设置: $LD_LIBRARY_PATH${NC}"
    else
        echo -e "${YELLOW}警告: LD_LIBRARY_PATH 未设置${NC}"
    fi
    
    echo -e "${GREEN}✓ 先决条件检查通过${NC}\n"
}

# 主函数
>>>>>>> f4a701c (Add files via upload)
main() {
    check_root
    check_cpu_cores
    check_prerequisites
    
<<<<<<< HEAD
    # Create results directory
=======
    # 创建结果目录
>>>>>>> f4a701c (Add files via upload)
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
<<<<<<< HEAD
            echo -e "${YELLOW}Testing effect of different network limits:${NC}"
            for net_config in "${NETWORK_CONFIGS[@]}"; do
                IFS='|' read -r network_name delay rate <<< "$net_config"
                echo ""
                echo -e "${CYAN}Configuration: ${network_name}${NC}"
=======
            echo -e "${YELLOW}测试不同网络限制的效果:${NC}"
            for net_config in "${NETWORK_CONFIGS[@]}"; do
                IFS='|' read -r network_name delay rate <<< "$net_config"
                echo ""
                echo -e "${CYAN}配置: ${network_name}${NC}"
>>>>>>> f4a701c (Add files via upload)
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
<<<<<<< HEAD
                echo -e "${RED}Network connectivity test failed, terminating test${NC}"
=======
                echo -e "${RED}网络连通性测试失败，终止测试${NC}"
>>>>>>> f4a701c (Add files via upload)
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

<<<<<<< HEAD
# Trap exit signal to ensure cleanup
trap cleanup_namespaces EXIT

# Run main function
=======
# 捕获退出信号，确保清理
trap cleanup_namespaces EXIT

# 运行主函数
>>>>>>> f4a701c (Add files via upload)
main "$@"

