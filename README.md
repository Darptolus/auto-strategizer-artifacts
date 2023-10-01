# AutoStrategizer Artifacts

## Artifact Identification
The AutoStrategizer is an automated framework that utilizes complex hardware links while preserving the simplified abstraction level for the user. Through the decomposition of user-issued memory operations into architecture-aware subtasks, we automatically exploit generally underused connections of the system.

This artifact contains three sections:
1. Initial Experiments
2. AutoStrategizer Library
3. LLVM-OpenMP Integration

Each section includes instructions on how to compile and run the experiments, as well as instructions on how to generate the plots.

The contributions of the paper are:
- A novel data-centric runtime extension that considers memory operations (i.e., memory tasks) and their execution
- A new API for collective operations in multi-device systems, suitable for LLVM integration
- A preliminary integration within the vendor-agnostic LLVM OpenMP runtime, including preliminary evaluation results.

### Clone repository
```sh
git clone --recursive -j8 https://github.com/Darptolus/auto-strategizer-artifacts.git --shallow-submodules
```

## 1. Initial Experiments

Requirements:
- llvm/release-15.0.0
- cuda/11.0.2

Hardware used:
- DGX-1 system: 2 CPUs Intel(R) Xeon(R) E5-2698 v4 @ 2.20GHz + 8 GPUs Nvidia Tesla V100-SXM2-16GB

Expected execution time per experiment (12 iterations per run):
- Around 200s

Expected results:
- The user should be able to obtain a graphical representation of the execution time for the experiments using different payload sizes 


### Compile the Experiments

```sh
cd AutoStrategizer
./runme.sh
```
Broadcast
```sh
cd build/tests/old_tests/Broadcast/
./run_all.sh 
```
D2D (No NUMA)
```sh
cd build/tests/old_tests/D2D/
./run_all_NoNUMA.sh 
```

D2D (NUMA)
```sh
cd build/tests/old_tests/D2D/
./run_all_NUMA.sh 
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

Start the notebook, change the filename to read the output of your choice. Then, simply run all the cells.

```sh
jupyter notebook Broadcast_plot.ipynb
jupyter notebook D2D_plot_a.ipynb
jupyter notebook D2D_plot_b.ipynb
```
Note: The output file for the experiments is in the 'results' directory

## 2. AutoStrategizer Library

```sh
cd build/tests
```
Run test
```sh
./main_auto
```


## 3. LLVM-OpenMP Integration
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
