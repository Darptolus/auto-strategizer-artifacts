# auto-strategizer-artifacts

```sh
git clone --recursive -j8 https://github.com/rodrigo-ceccato/auto-strategizer-artifacts.git
```

From the cloned root folder, run:

```sh
cmake -S./llvm-strategizer/llvm -B./llvm-build/release-build \
        -GNinja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=./llvm-build/install \
        -DLLVM_ENABLE_PROJECTS=clang-tools-extra\;compiler-rt\;clang \
        -DLLVM_ENABLE_RUNTIMES=libcxx\;openmp\;libcxxabi \
        -DLLVM_TARGETS_TO_BUILD=AMDGPU\;X86\;NVPTX \
        -DCLANG_VENDOR=LLVM-Auto-Strategyzer \
        -DLIBOMPTARGET_ENABLE_DEBUG=1 \
        -DLLVM_ENABLE_ASSERTIONS=On \
        -DCMAKE_EXPORT_COMPILE_COMMANDS=On \
        -DLLVM_INCLUDE_BENCHMARKS=Off \
        -DLIBOMPTARGET_ENABLE_PROFILER=1 \
        -DOPENMP_STANDALONE_BUILD=0 \
        -DLLVM_CCACHE_BUILD=ON \
        -DBUILD_SHARED_LIBS=1 \
        -DLLVM_USE_SPLIT_DWARF=1 \
        -DAUTO_STRATEGIZER_LOCATION=./AutoStrategyzer
```

The scripts for benchmarks assume that these relative paths are respected, so do not change them.

```sh
cmake --build ./llvm-build/release-build -j 79
```

```sh
cmake --install ./llvm-build/release-build --prefix ./llvm-build/install
```

## Running benchmarks

This benchmarks should be run on an NVIDIA SMX system. Some applications have a build script that applies a patch before compiling, to ensure that OpenMP offload is enabled.

First, enter the benchmarks folder:

```sh
cd benchmarks
```

### Simple offload

```sh
cd simple-offload
./benchmark.sh
```

### MiniFMM

```sh
cd minifmm-setup
./minifmm_build.sh
./minifmm_benchmark.sh
```

### XSBench

```sh
cd xsbench-setup
./xsbench_build.sh
./xsbench_benchmark.sh
```

### RSBench

```sh
cd rsbench-setup
./rsbench_build.sh
./rsbench_benchmark.sh
```

### Plotting

Create a Python virtual environment and use pip to install the required packages in requirements.txt:

```sh
python3 -m virtualenv venv
```

```sh
source .venv/bin/activate
```

```sh
pip install -r requirements.txt

```

Start the notebook, change the first cell to read the benchmark output of your choice. Then, simply run all the cells.

```sh
jupyter notebook plot.ipynb
```


## Artifacts scripts authors

Participated in the writing and testing of these benchmark scripts, applications patches and plotting notebook:

- Rodrigo Ceccato (@rodrigo-ceccato)
- Diego Roa (@Darptolus)
