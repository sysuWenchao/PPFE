CXX := g++
CXXFLAGS := -Ofast -std=c++20 -lcryptopp -fopenmp -mpclmul -no-pie

BUILD_DIR := build
TARGET := $(BUILD_DIR)/s3pir
INCLUDE := src/include
TROY_INCLUDE := encryption
TROY_LIB := encryption/libtroy.so

CUDA_HOME ?= /usr/local/cuda
OT_PREFIX ?= /usr/local
CUDA_INCLUDE := -I$(CUDA_HOME)/include
CUDA_LIB := -L$(CUDA_HOME)/lib64 -lcudart

OT_LIB_DIR := -L$(OT_PREFIX)/lib
# SimplestOT is part of liblibOTe.a in current libOTe releases. Boost.System
# is header-only in the tested Boost 1.90 build.
OT_LIBS := -l:liblibOTe.a -lcryptoTools -lcoproto -lsodium \
	-lboost_thread -lboost_regex -lboost_atomic -lpthread

SRC := src/client.cpp src/server.cpp src/main.cpp src/utils.cpp

SERVER_SRC := src/server.cpp src/server_main.cpp src/utils.cpp src/network.cpp
CLIENT_SRC := src/client.cpp src/client_main.cpp src/server.cpp src/utils.cpp src/network.cpp

DEPS := src/include/client.h src/include/server.h src/include/utils.h $(TROY_INCLUDE)/troy.h
NETWORK_DEPS := src/include/network.h $(DEPS)
SECURITY_TEST := $(BUILD_DIR)/security_parameters_test
PPFE_BINARIES := $(TARGET) $(TARGET)_debug $(TARGET)_simlargeserver \
	$(BUILD_DIR)/s3pir_server $(BUILD_DIR)/s3pir_client $(SECURITY_TEST)

all: $(TARGET) $(TARGET)_simlargeserver $(BUILD_DIR)/s3pir_server $(BUILD_DIR)/s3pir_client

debug: $(TARGET)_debug

check-security: $(SECURITY_TEST)
	./$(SECURITY_TEST)
	bash tests/check_security_invariants.sh

clean:
	rm -f $(PPFE_BINARIES)

.PHONY: all clean debug check-security

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(TARGET): $(SRC) $(DEPS) $(TROY_LIB) | $(BUILD_DIR)
	$(CXX) -o $(TARGET) -I $(INCLUDE) -I $(TROY_INCLUDE) $(CUDA_INCLUDE) $(SRC) $(CXXFLAGS) $(TROY_LIB) $(CUDA_LIB) $(OT_LIB_DIR) $(OT_LIBS)

$(TARGET)_debug: $(SRC) $(DEPS) $(TROY_LIB) | $(BUILD_DIR)
	$(CXX) -DDEBUG -o $(TARGET)_debug -I $(INCLUDE) -I $(TROY_INCLUDE) $(CUDA_INCLUDE) $(SRC) $(CXXFLAGS) $(TROY_LIB) $(CUDA_LIB) $(OT_LIB_DIR) $(OT_LIBS)

$(TARGET)_simlargeserver: $(SRC) $(DEPS) $(TROY_LIB) | $(BUILD_DIR)
	$(CXX) -DSimLargeServer -o $(TARGET)_simlargeserver -I $(INCLUDE) -I $(TROY_INCLUDE) $(CUDA_INCLUDE) $(SRC) $(CXXFLAGS) $(TROY_LIB) $(CUDA_LIB) $(OT_LIB_DIR) $(OT_LIBS)

$(BUILD_DIR)/s3pir_server: $(SERVER_SRC) $(NETWORK_DEPS) $(TROY_LIB) | $(BUILD_DIR)
	$(CXX) -o $(BUILD_DIR)/s3pir_server -I $(INCLUDE) -I $(TROY_INCLUDE) $(CUDA_INCLUDE) $(SERVER_SRC) $(CXXFLAGS) $(TROY_LIB) $(CUDA_LIB) $(OT_LIB_DIR) $(OT_LIBS)

$(BUILD_DIR)/s3pir_client: $(CLIENT_SRC) $(NETWORK_DEPS) $(TROY_LIB) | $(BUILD_DIR)
	$(CXX) -o $(BUILD_DIR)/s3pir_client -I $(INCLUDE) -I $(TROY_INCLUDE) $(CUDA_INCLUDE) $(CLIENT_SRC) $(CXXFLAGS) $(TROY_LIB) $(CUDA_LIB) $(OT_LIB_DIR) $(OT_LIBS)

$(SECURITY_TEST): tests/security_parameters_test.cpp src/utils.cpp src/include/utils.h | $(BUILD_DIR)
	$(CXX) -std=c++20 -O2 -I $(INCLUDE) tests/security_parameters_test.cpp src/utils.cpp -lcryptopp -o $(SECURITY_TEST)
