<<<<<<< HEAD
# Toolchain
=======
# 工具链
>>>>>>> f4a701c (Add files via upload)
CXX := g++
CXXFLAGS := -Ofast -std=c++20 -lcryptopp -fopenmp -mpclmul -no-pie 

TARGET := build/PPFE
INCLUDE := src/include
<<<<<<< HEAD
TROY_INCLUDE := encryption# Directory where troy.h is located
TROY_LIB := encryption/libtroy.so

# Ensure build directory exists
$(shell mkdir -p build)

# CUDA runtime path
CUDA_INCLUDE := -I/usr/local/cuda/include
CUDA_LIB := -L/usr/local/cuda/lib64 -lcudart

# libOTe, cryptoTools, coproto, libsodium, SimplestOT library paths
OT_LIB_DIR := -L/usr/local/lib
OT_LIBS := -l:liblibOTe.a -lSimplestOT -lcryptoTools -lcoproto -lsodium -lpthread

# Source files
SRC := src/client.cpp src/server.cpp src/main.cpp src/utils.cpp
NEW_SRC := src/new_client.cpp src/new_server.cpp src/new_main.cpp src/utils.cpp

# Separated client/server source files
SERVER_SRC := src/server.cpp src/server_main.cpp src/utils.cpp src/network.cpp
CLIENT_SRC := src/client.cpp src/client_main.cpp src/server.cpp src/utils.cpp src/network.cpp

# Header file dependencies
=======
TROY_INCLUDE := encryption# troy.h 所在目录
TROY_LIB := encryption/libtroy.so

# CUDA runtime 路径
CUDA_INCLUDE := -I/usr/local/cuda/include
CUDA_LIB := -L/usr/local/cuda/lib64 -lcudart

# libOTe, cryptoTools, coproto, libsodium, SimplestOT 库路径
OT_LIB_DIR := -L/usr/local/lib
OT_LIBS := -l:liblibOTe.a -lSimplestOT -lcryptoTools -lcoproto -lsodium -lpthread

# 源文件
SRC := src/client.cpp src/server.cpp src/main.cpp src/utils.cpp
NEW_SRC := src/new_client.cpp src/new_server.cpp src/new_main.cpp src/utils.cpp

# 分离的客户端/服务器源文件
SERVER_SRC := src/server.cpp src/server_main.cpp src/utils.cpp src/network.cpp
CLIENT_SRC := src/client.cpp src/client_main.cpp src/server.cpp src/utils.cpp src/network.cpp

# 头文件依赖
>>>>>>> f4a701c (Add files via upload)
DEPS := src/include/client.h src/include/server.h src/include/utils.h $(TROY_INCLUDE)/troy.h
NEW_DEPS := src/include/new_client.h src/include/new_server.h src/include/utils.h $(TROY_INCLUDE)/troy.h
NETWORK_DEPS := src/include/network.h $(DEPS)

all: $(TARGET) $(TARGET)_simlargeserver build/PPFE_server build/PPFE_client

debug: $(TARGET)_debug

clean: 
	rm -f build/*

.PHONY: all clean debug

<<<<<<< HEAD
# Normal version
$(TARGET): $(SRC) $(DEPS)
	$(CXX) -o $(TARGET) -I $(INCLUDE) -I $(TROY_INCLUDE) $(CUDA_INCLUDE) $(SRC) $(CXXFLAGS) $(TROY_LIB) $(CUDA_LIB) $(OT_LIB_DIR) $(OT_LIBS)

# Debug version
$(TARGET)_debug: $(SRC) $(DEPS)
	$(CXX) -DDEBUG -o $(TARGET)_debug -I $(INCLUDE) -I $(TROY_INCLUDE) $(CUDA_INCLUDE) $(SRC) $(CXXFLAGS) $(TROY_LIB) $(CUDA_LIB) $(OT_LIB_DIR) $(OT_LIBS)

# SimLargeServer version
$(TARGET)_simlargeserver: $(SRC) $(DEPS)
	$(CXX) -DSimLargeServer -o $(TARGET)_simlargeserver -I $(INCLUDE) -I $(TROY_INCLUDE) $(CUDA_INCLUDE) $(SRC) $(CXXFLAGS) $(TROY_LIB) $(CUDA_LIB) $(OT_LIB_DIR) $(OT_LIBS)

# New version
new_$(TARGET): $(NEW_SRC) $(NEW_DEPS)
	$(CXX) -o new_$(TARGET) -I $(INCLUDE) -I $(TROY_INCLUDE) $(CUDA_INCLUDE) $(NEW_SRC) $(CXXFLAGS) $(TROY_LIB) $(CUDA_LIB) $(OT_LIB_DIR) $(OT_LIBS)

# Separated server
build/PPFE_server: $(SERVER_SRC) $(NETWORK_DEPS)
	$(CXX) -o build/PPFE_server -I $(INCLUDE) -I $(TROY_INCLUDE) $(CUDA_INCLUDE) $(SERVER_SRC) $(CXXFLAGS) $(TROY_LIB) $(CUDA_LIB) $(OT_LIB_DIR) $(OT_LIBS)

# Separated client
=======
# 普通版本
$(TARGET): $(SRC) $(DEPS)
	$(CXX) -o $(TARGET) -I $(INCLUDE) -I $(TROY_INCLUDE) $(CUDA_INCLUDE) $(SRC) $(CXXFLAGS) $(TROY_LIB) $(CUDA_LIB) $(OT_LIB_DIR) $(OT_LIBS)

# Debug 版本
$(TARGET)_debug: $(SRC) $(DEPS)
	$(CXX) -DDEBUG -o $(TARGET)_debug -I $(INCLUDE) -I $(TROY_INCLUDE) $(CUDA_INCLUDE) $(SRC) $(CXXFLAGS) $(TROY_LIB) $(CUDA_LIB) $(OT_LIB_DIR) $(OT_LIBS)

# SimLargeServer 版本
$(TARGET)_simlargeserver: $(SRC) $(DEPS)
	$(CXX) -DSimLargeServer -o $(TARGET)_simlargeserver -I $(INCLUDE) -I $(TROY_INCLUDE) $(CUDA_INCLUDE) $(SRC) $(CXXFLAGS) $(TROY_LIB) $(CUDA_LIB) $(OT_LIB_DIR) $(OT_LIBS)

# 新版本
new_$(TARGET): $(NEW_SRC) $(NEW_DEPS)
	$(CXX) -o new_$(TARGET) -I $(INCLUDE) -I $(TROY_INCLUDE) $(CUDA_INCLUDE) $(NEW_SRC) $(CXXFLAGS) $(TROY_LIB) $(CUDA_LIB) $(OT_LIB_DIR) $(OT_LIBS)

# 分离的服务器
build/PPFE_server: $(SERVER_SRC) $(NETWORK_DEPS)
	$(CXX) -o build/PPFE_server -I $(INCLUDE) -I $(TROY_INCLUDE) $(CUDA_INCLUDE) $(SERVER_SRC) $(CXXFLAGS) $(TROY_LIB) $(CUDA_LIB) $(OT_LIB_DIR) $(OT_LIBS)

# 分离的客户端
>>>>>>> f4a701c (Add files via upload)
build/PPFE_client: $(CLIENT_SRC) $(NETWORK_DEPS)
	$(CXX) -o build/PPFE_client -I $(INCLUDE) -I $(TROY_INCLUDE) $(CUDA_INCLUDE) $(CLIENT_SRC) $(CXXFLAGS) $(TROY_LIB) $(CUDA_LIB) $(OT_LIB_DIR) $(OT_LIBS)
