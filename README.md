# PPFE:Preprocessed Private Function Evaluation: Achieving Sublinear Online Complexity for Lookup Tables

Preprocessed Private Function Evaluation: Achieving Sublinear Online Complexity for Lookup Tables

## Table of Contents

- [System Requirements](#system-requirements)
- [Dependencies](#dependencies)
  - [System Packages](#system-packages)
  - [Troy Homomorphic Encryption Library](#troy-homomorphic-encryption-library)
  - [Oblivious Transfer Libraries](#oblivious-transfer-libraries)
- [Compilation](#compilation)
  - [1. Build libtroy.so](#1-build-libtroyso)
  - [2. Build the Server and Client](#2-build-the-server-and-client)
- [Usage](#usage)
  - [Start the Server](#start-the-server)
  - [Run the Client](#run-the-client)
  - [Automated Testing](#automated-testing)
  - [Performance Output](#performance-output)
- [Environment Variables](#environment-variables)

---

## System Requirements

| Component | Requirement |
|-----------|-------------|
| **Operating System** | Linux (tested on Ubuntu 22.04 / Debian-based) |
| **Compiler** | g++ 10.0+ with C++20 support |
| **Build Tools** | CMake 3.16+, GNU Make |
| **CUDA Toolkit** | CUDA 11.3+ |
| **NVIDIA Driver** | 515+ |
| **GPU** | NVIDIA GPU with Compute Capability 7.0+ |

---

## Dependencies

### System Packages

Install the required system libraries and build tools:

```bash
apt-get update

# Build tools
apt-get install -y build-essential cmake g++-10 gcc-10

# Cryptographic and compression libraries
apt-get install -y libcrypto++-dev libsodium-dev libssl-dev libzstd-dev libboost-dev
```

Set g++-10 as the default compiler:

```bash
update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-10 100
update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-10 100
update-alternatives --set g++ /usr/bin/g++-10
update-alternatives --set gcc /usr/bin/gcc-10
```

Verify:

```bash
g++ --version | head -1
# Expected: g++ (Ubuntu 10.5.0-...) 10.5.0
```

### Troy Homomorphic Encryption Library

Troy is a CUDA-based GPU implementation of RLWE homomorphic encryption schemes (BFV, CKKS, BGV). The project includes Troy source code in two directories:

| Directory | Description |
|-----------|-------------|
| `encryption/` | Troy library customized for PPFE |
| `troy-nova/` | Newer Troy implementation with pre-compiled build artifacts |

The `troy-nova/build/` directory contains pre-compiled CUDA object files (`.o`) that are used to build `libtroy.so` on the target system. See the [compilation section](#1-build-libtroyso) for the build procedure.

### Oblivious Transfer Libraries

The project requires the following libraries for oblivious transfer communication:

| Library | Repository | Purpose |
|---------|-----------|---------|
| **cryptoTools** | `github.com/ladnir/cryptoTools` | Base cryptographic utilities (PRNG, BitVector, Timer) |
| **coproto** | `github.com/ladnir/coproto` | Asynchronous socket-based communication |
| **libOTe** | `github.com/osu-crypto/libOTe` | Oblivious transfer protocol implementations (SimplestOT included) |

Clone and build each library:

```bash
# Build order matters: cryptoTools → coproto → libOTe
mkdir -p /root/ot-libs && cd /root/ot-libs

git clone https://github.com/ladnir/cryptoTools.git
cd cryptoTools && mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local && make -j$(nproc) && make install

cd /root/ot-libs
git clone https://github.com/ladnir/coproto.git
cd coproto && mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local && make -j$(nproc) && make install

cd /root/ot-libs
git clone https://github.com/osu-crypto/libOTe.git
cd libOTe && mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local -DWITH_SimplestOT=ON && make -j$(nproc) && make install
```



---

---

## Compilation

### 1. Build libtroy.so

The Troy library must be built before compiling PPFE. The procedure links pre-compiled CUDA object files from `troy-nova/build/` against the system's native libraries.

#### Step 1.1 — Set up CUDA environment

```bash
export PATH=/usr/local/cuda/bin:$PATH
export CUDA_HOME=/usr/local/cuda
```

Verify CUDA availability:

```bash
nvcc --version
# Expected: Cuda compilation tools, release 11.x or 12.x
```

#### Step 1.2 — Build the library

```bash
cd /root/PPFE-main

# Collect all pre-compiled CUDA object files
OBJS=$(find troy-nova/build/src/CMakeFiles/troy.dir -name "*.o")

# Link into a shared library
g++ -Ofast -std=c++17 -fPIC -shared \
  $OBJS \
  -L${CUDA_HOME}/lib64 -lcudart \
  -o encryption/libtroy.so \
  -lpthread -lcryptopp -lsodium -lzstd
```

#### Step 1.3 — Verify

```bash
# Check symbol count (expect 1400+)
nm -D encryption/libtroy.so | wc -l

# Verify no unresolved shared library dependencies
ldd encryption/libtroy.so | grep "not found"
# Should produce NO output
```

### 2. Build the Server and Client

> **Prerequisite**: OT libraries must be installed. See [Oblivious Transfer Libraries](#oblivious-transfer-libraries).

Use the provided Makefile to build all targets:

```bash
cd /root/PPFE-main
export PATH=/usr/local/cuda/bin:$PATH

make
```

This produces the following binaries in `build/`:

| Binary | Source Files | Description |
|--------|-------------|-------------|
| `build/s3pir_server` | `server_main.cpp`, `server.cpp`, `utils.cpp`, `network.cpp` | Standalone server |
| `build/s3pir_client` | `client_main.cpp`, `client.cpp`, `server.cpp`, `utils.cpp`, `network.cpp` | Standalone client |

To clean the build:

```bash
make clean
```

---

## Usage

### Start the Server

```bash
export LD_LIBRARY_PATH=/root/PPFE-main/encryption:/usr/local/cuda/lib64:$LD_LIBRARY_PATH

cd /root/PPFE-main

# Syntax
./build/s3pir_server <Log2DBSize> <EntrySize> <Port>
```

| Parameter | Description | Constraints |
|-----------|-------------|-------------|
| `Log2DBSize` | log₂ of the number of database entries | e.g., 10 → 1,024 entries; 16 → 65,536 entries |
| `EntrySize` | Size of each database entry in bytes | Must be **8**, and a multiple of 8 |
| `Port` | TCP port to listen on | e.g., 8080 |

**Example**:

```bash
./build/s3pir_server 16 8 8080
```

The server will wait for a client connection and process queries.

### Run the Client

```bash
export LD_LIBRARY_PATH=/root/PPFE-main/encryption:/usr/local/cuda/lib64:$LD_LIBRARY_PATH

cd /root/PPFE-main

# Syntax
./build/s3pir_client <ServerIP> <Port> <OutputFile>
```

| Parameter | Description |
|-----------|-------------|
| `ServerIP` | IP address of the server |
| `Port` | Port the server is listening on |
| `OutputFile` | Path for performance statistics output (CSV) |

**Example**:

```bash
./build/s3pir_client 127.0.0.1 8080 results.csv
```

### Automated Testing

The `run_tests.sh` script runs the server and client under simulated network conditions using Linux network namespaces. It evaluates protocol performance across various database sizes and network configurations (latency, bandwidth).

> **Important**: This script requires the server and client binaries to be compiled first. **Requires root privileges** for network namespace manipulation.

```bash
sudo ./run_tests.sh test       # Run all network configuration tests
sudo ./run_tests.sh setup      # Set up network namespaces only
sudo ./run_tests.sh verify     # Verify network connectivity and limits
sudo ./run_tests.sh cleanup    # Remove simulated network environments
```

The script runs through these combinations:

- **Database sizes** (Log2DBSize): 10, 12, 14, 16, 18, 20, 22
- **Network conditions**: 800μs/3Gbit, 800μs/1Gbit, 40ms/200Mbit, 80ms/100Mbit

Results are saved under `./test_results/`.

### Performance Output

Upon completion, the client outputs detailed performance metrics to the specified CSV file:

| Metric | Description |
|--------|-------------|
| **Offline Time** | Pre-processing and hint generation time |
| **Online Time** | Query construction, server computation, and response unmasking |
| **Cost Per Query** | Average online time per individual query |
| **Amortized Compute Time** | Predicted per-query cost in long-running scenarios (amortizes offline work) |

**CSV format**:

```csv
Variant, Log2 DBSize, EntrySize(Bytes), NumQueries, Offline Time (s), Online Time (ms), Amortized Compute Time Per Query (ms)
One server, 10, 8, 32, 8.801, 0.25, 18.5854
```

---

## Environment Variables

| Variable | Value | Purpose |
|----------|-------|---------|
| `PATH` | Include `/usr/local/cuda/bin` | Makes `nvcc` and CUDA tools available |
| `LD_LIBRARY_PATH` | `encryption/:${CUDA_HOME}/lib64` | Runtime shared library search path |
| `CUDA_HOME` | `/usr/local/cuda` | CUDA Toolkit installation root |

---

## References

- [Troy](https://github.com/v6p/Troy) — GPU-accelerated homomorphic encryption library
- [libOTe](https://github.com/osu-crypto/libOTe) — Oblivious transfer library
- [cryptoTools](https://github.com/ladnir/cryptoTools) — Cryptographic utility library
- [coproto](https://github.com/ladnir/coproto) — Communication protocol library
- [Crypto++](https://www.cryptopp.com/) — C++ cryptographic library
- [libsodium](https://doc.libsodium.org/) — Modern cryptography library
