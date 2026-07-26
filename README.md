# PPFE: Preprocessed Private Function Evaluation

This repository contains the CUDA/C++ implementation of **Preprocessed
Private Function Evaluation: Achieving Sublinear Online Complexity for Lookup
Tables**.

## Artifact scope

The repository reproduces the PPFE implementation and its LAN/WAN experiments.
It does **not** contain the FABLE, SP-LUT, FLORAM, or 2P-DUORAM source trees,
their raw measurements, or the paper's figure-generation scripts. Consequently,
the cross-system speedup claims cannot be independently regenerated from this
repository alone. `run_tests.sh` covers PPFE database sizes from \(2^{10}\)
through \(2^{24}\).

The benchmark uses a deterministic synthetic database and deterministic query
indices so that it can check every returned value. It is an artifact benchmark,
not a production deployment.

## Tested environment

The source-build procedure below was verified from a clean checkout on:

| Component | Tested value |
|---|---|
| OS | Ubuntu 22.04.4 LTS (x86-64) |
| Compiler | GCC/G++ 11.4.0 |
| CMake | 3.22.1 |
| CUDA toolkit | 12.4 |
| NVIDIA driver | 550.90.07 |
| GPU | GeForce RTX 2080 Ti, compute capability 7.5, 11 GB |
| PPFE source | `artifact-v3-fix` branch |
| libOTe commit | `0412d31` |
| cryptoTools submodule | `6290764` |
| coproto fetched by libOTe | `ded64cb` |
| Boost fetched by libOTe | 1.90.0 |

Use CUDA 12.x and a GPU with compute capability 7.0 or newer. Generated
binaries and build trees are deliberately excluded from the repository; the
steps below build them for the target system.

G++ 10 is not supported by this dependency set: current coproto/cryptoTools
requires C++20 library features including `std::bit_cast`. Ubuntu 22.04's
default G++ 11 is the tested compiler.

## 1. Clone the artifact

```bash
git clone https://github.com/sysuWenchao/PPFE.git
cd PPFE
git checkout artifact-v3-fix
```

All later commands use the repository root discovered with `pwd`; no
`/root/PPFE-main` path is required.

## 2. Install system packages

Run as root, or prefix the package commands with `sudo`:

```bash
apt-get update
apt-get install -y \
  build-essential cmake git python3 ninja-build \
  libcrypto++-dev libsodium-dev libssl-dev libzstd-dev \
  libboost-dev libgmp-dev libtool autoconf pkg-config \
  iproute2 iputils-ping util-linux
```

Make CUDA visible and verify the toolchain:

```bash
export CUDA_HOME="${CUDA_HOME:-/usr/local/cuda}"
export OT_PREFIX="${OT_PREFIX:-/usr/local}"
export PATH="$CUDA_HOME/bin:$PATH"

g++ --version
cmake --version
nvcc --version
nvidia-smi
```

If CUDA or the OT libraries are installed elsewhere, set `CUDA_HOME` or
`OT_PREFIX` respectively. The Makefile and benchmark script honor both values.

## 3. Build the OT dependencies

libOTe already pins the compatible cryptoTools revision and its build system
pins coproto, macoro, function2, and other transitive dependencies. Do not
independently clone the moving default branches of those projects.

```bash
cd /tmp
git clone --recursive https://github.com/osu-crypto/libOTe.git
cd libOTe
git checkout 0412d31
git submodule update --init --recursive

cmake -S . -B out/ppfe-release \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$OT_PREFIX" \
  -DCRYPTO_TOOLS_STD_VER=20 \
  -DENABLE_SIMPLESTOT=ON \
  -DENABLE_SODIUM=ON \
  -DFETCH_SODIUM=OFF \
  -DSODIUM_MONTGOMERY=OFF \
  -DENABLE_BOOST=ON \
  -DFETCH_BOOST=ON \
  -DFETCH_AUTO=ON \
  -DPARALLEL_FETCH=8

cmake --build out/ppfe-release --target install -j"$(nproc)"
ldconfig
```

The flags are significant:

- `CRYPTO_TOOLS_STD_VER=20` fixes the `std::bit_cast` compile error.
- `FETCH_AUTO=ON` obtains the pinned transitive dependencies.
- `ENABLE_SIMPLESTOT=ON` enables the base OT used by PPFE.
- `SODIUM_MONTGOMERY=OFF` uses Ubuntu's standard libsodium. Without it,
  cryptoTools expects a nonstandard `crypto_scalarmult_noclamp` function.
- `PARALLEL_FETCH=8` avoids races observed when dependency setup used all 96
  host CPUs.

In this libOTe revision, SimplestOT is part of `liblibOTe.a`; there is no
separate `libSimplestOT.a`.

## 4. Build Troy from source

Return to the PPFE checkout and select the CUDA architecture for the installed
GPU. The tested RTX 2080 Ti uses `75`; common alternatives include `70`, `80`,
and `86`.

```bash
cd /path/to/PPFE

cmake -S troy-nova -B build/troy \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CUDA_COMPILER="$CUDA_HOME/bin/nvcc" \
  -DCMAKE_CUDA_ARCHITECTURES=75 \
  -DTROY_PYBIND=OFF \
  -DTROY_TEST=OFF \
  -DTROY_BENCH=OFF \
  -DTROY_EXAMPLES=OFF \
  -DTROY_ZSTD=OFF

cmake --build build/troy --target troy -j"$(nproc)"
cp build/troy/src/libtroy.so encryption/libtroy.so
```

`TROY_ZSTD=OFF` disables optional ciphertext compression and prevents CMake
from downloading Zstd when Ubuntu's `libzstd-dev` package does not expose the
expected CMake target. PPFE's tested protocol path does not use Troy's optional
Zstd serialization.

## 5. Build PPFE

```bash
cd /path/to/PPFE
make CUDA_HOME="$CUDA_HOME" OT_PREFIX="$OT_PREFIX" -j"$(nproc)"
make check-security
```

The build produces:

- `build/s3pir`
- `build/s3pir_simlargeserver`
- `build/s3pir_server`
- `build/s3pir_client`

Confirm that runtime libraries resolve:

```bash
export LD_LIBRARY_PATH="$PWD/encryption:$CUDA_HOME/lib64:$OT_PREFIX/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
ldd build/s3pir_server | grep "not found" || true
ldd build/s3pir_client | grep "not found" || true
```

Both commands should print nothing.

## 6. Smoke test

Terminal 1:

```bash
cd /path/to/PPFE
export CUDA_HOME="${CUDA_HOME:-/usr/local/cuda}"
export OT_PREFIX="${OT_PREFIX:-/usr/local}"
export LD_LIBRARY_PATH="$PWD/encryption:$CUDA_HOME/lib64:$OT_PREFIX/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
./build/s3pir_server 10 8 18080
```

Terminal 2:

```bash
cd /path/to/PPFE
export CUDA_HOME="${CUDA_HOME:-/usr/local/cuda}"
export OT_PREFIX="${OT_PREFIX:-/usr/local}"
export LD_LIBRARY_PATH="$PWD/encryption:$CUDA_HOME/lib64:$OT_PREFIX/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
./build/s3pir_client 127.0.0.1 18080 smoke.csv
```

Successful output contains:

```text
[Verification] ✓ All correct!
[Client] Completed 32 queries
[Server] Online server computation average: ... ms/query
```

On the tested RTX 2080 Ti host, the \(2^{10}\) smoke test took about 9 seconds:
8.45 seconds of client offline computation plus 0.13 seconds to pre-generate
the required Enc(0) values. Online time was 0.94 ms/query. Timings vary by
hardware and CPU/GPU load.

The client CSV contains:

```text
Variant, Log2 DBSize, EntrySize(Bytes), NumQueries, Offline Time (s), Online Time (ms), Amortized Compute Time Per Query (ms)
```

Offline time now includes Enc(0) pre-generation because each online query
consumes one of those ciphertexts. Results produced by older commits excluded
that work from offline and amortized totals and should not be compared directly.

## 7. Network benchmark

`run_tests.sh` creates Linux network namespaces and applies `tc` limits, so it
requires root, at least two CPU cores, and the `CAP_SYS_ADMIN` and
`CAP_NET_ADMIN` capabilities. Root inside an unprivileged Docker/cloud
container is not sufficient. Use a native host or launch the container with
the required capabilities.

```bash
sudo --preserve-env=CUDA_HOME,OT_PREFIX ./run_tests.sh setup
sudo --preserve-env=CUDA_HOME,OT_PREFIX ./run_tests.sh verify
sudo --preserve-env=CUDA_HOME,OT_PREFIX ./run_tests.sh test
sudo --preserve-env=CUDA_HOME,OT_PREFIX ./run_tests.sh cleanup
```

The four configurations are 800 µs/3 Gbit, 800 µs/1 Gbit, 40 ms/200 Mbit, and
80 ms/100 Mbit. Results and logs are written under `test_results/`.

The default sweep is:

```text
10 12 14 16 18 20 22 24
```

Use a small subset before committing to the complete sweep:

```bash
DB_SIZES="10 16" sudo --preserve-env=CUDA_HOME,OT_PREFIX,DB_SIZES \
  ./run_tests.sh test
```

The full sweep launches 32 protocol runs (8 sizes × 4 networks), and the
\(2^{24}\) runs dominate time and memory. For the tested native build, reserve
at least 30 GB of disk, 16 GB of system RAM, and an NVIDIA GPU with at least
11 GB of VRAM. Exact full-sweep runtime is hardware- and network-dependent;
retain each generated client/server log with the CSV rather than assuming the
paper's machine timings.

## Command-line reference

```text
./build/s3pir_server <Log2DBSize> <EntrySize> <Port>
./build/s3pir_client <ServerIP> <Port> <OutputFile>
```

`EntrySize` is currently required to be 8 bytes. `Log2DBSize=24` means
\(2^{24}\) database entries.

## Reproducibility and security notes

- Always build from source on the target system. The repository no longer
  ships host-specific ELF binaries, shared libraries, or CMake build trees.
- Each client generates a fresh 128-bit PRF key with Crypto++'s OS-backed
  `AutoSeededRandomPool`. Query masks are sampled uniformly in
  \(\mathbb{Z}_q\) by rejection sampling, and selector bits use the same CSPRNG.
- The answer-noise parameter is defined once as
  `PPFE_ANSWER_NOISE_SIGMA = 2^22`, matching Table 2. Sampling uses the
  OS-backed CSPRNG and signed modular addition.
- Enc(0) ciphertext randomizers are consumed once. Exhausting the offline cache
  raises an error instead of silently reusing a ciphertext.
- `make check-security` checks the centralized HE/noise parameters, randomness
  ranges and noise statistics, and rejects fixed keys, `rand()`, Enc(0)
  wraparound, or checked-in generated binaries.
- Database contents and benchmark query indices remain deterministic solely for
  reproducible correctness verification.
- A container is not supplied. A GPU container would still require a compatible
  NVIDIA host driver and NVIDIA Container Toolkit. The native Ubuntu 22.04 /
  CUDA 12.4 procedure above is the environment that was actually verified.

## Troubleshooting

### `error: 'bit_cast' is not a member of 'std'`

Use G++ 11 or newer and configure cryptoTools with
`-DCRYPTO_TOOLS_STD_VER=20`. Do not force Ubuntu 22.04 to G++ 10.

### `crypto_scalarmult_noclamp` static assertion

When using Ubuntu's `libsodium-dev`, add `-DSODIUM_MONTGOMERY=OFF`.

### `cannot find -lSimplestOT`

Use the repository's updated Makefile. Current libOTe includes SimplestOT in
`liblibOTe.a`.

### `cannot find -lboost_system`

Use the updated Makefile. Boost.System 1.90 is header-only.

### `libtroy.so` or `libcudart.so` not found

```bash
export CUDA_HOME="${CUDA_HOME:-/usr/local/cuda}"
export OT_PREFIX="${OT_PREFIX:-/usr/local}"
export LD_LIBRARY_PATH="$PWD/encryption:$CUDA_HOME/lib64:$OT_PREFIX/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
```

### Out of memory during dependency builds

Reduce both `PARALLEL_FETCH` and build parallelism, for example:

```bash
cmake --build out/ppfe-release --target install -j4
```
