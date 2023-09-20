#!/bin/zsh

target_successful_executions=10
timeout_seconds=300

# Set LLVM path
# ============================================
echo "Setting local LLVM path..."
llvm_build_dir=../../llvm-build/release-build
llvm_install_dir=../../llvm-build/install

export PATH=$llvm_install_dir/bin/:$PATH
export LD_LIBRARY_PATH=$llvm_install_dir/lib/:$LD_LIBRARY_PATH
export LIBRARY_PATH=$llvm_install_dir/lib/:$LIBRARY_PATH

echo "LLVM in path: "
which clang
clang --version

# Common environment variables
export LIBOMPTARGET_MEMORY_MANAGER_THRESHOLD=0 # disable memory manager
# export LIBOMPTARGET_STRATEGIZER_MIN_SIZE=1
export LIBOMPTARGET_STRATEGIZER_MIN_SIZE=1000000
export LIBOMPTARGET_STRATEGIZER_TOPO="topo_smx"
# unset OMP_PROC_BIND
export OMP_PROC_BIND=spread
export OMP_NUM_THREADS=24
# unset OMP_PLACES
export PAYLOAD_SIZE="none" # not used in this benchmark, but here so we can re-use the same script for plotting

echo " " >benchmark_results.txt

fmm_args="-n 5000000 -m 2000 -e 0.66 -t 90 -c 256 --plummer"

# Loop over LIBOMPTARGET_USE_STRATEGIZER values (0 and 1)
for use_strategizer in 0 1; do
    # Set the environment variable
    export LIBOMPTARGET_USE_STRATEGIZER=$use_strategizer

    # Loop over LIBOMPTARGET_STRATEGIZER_STRATEGY values if LIBOMPTARGET_USE_STRATEGIZER is 1
    if [ "$use_strategizer" -eq 1 ]; then
        # Loop over payload_size values

        for strategy in DVT MXF P2P; do
        # for strategy in DVT; do
            # Print the this strategy and payload_size
            echo "Strategy: $strategy, Payload Size: $payload_size"
            # Set the additional environment variable
            export LIBOMPTARGET_STRATEGIZER_STRATEGY=$strategy

            # Execute the command until target_successful_executions is reached
            successful_executions=0
            while [ "$successful_executions" -lt "$target_successful_executions" ]; do
                echo "Running"
                start_time=$(date +%s.%3N)
                output=$(timeout $timeout_seconds ./minifmm/fmm.omptarget $fmm_args 2>&1)
                exit_code=$?
                end_time=$(date +%s.%3N)
                execution_time=$(echo "$end_time - $start_time" | bc)
                total_time=$(echo "$output" | grep -o 'Total Time (s) * *[0-9.]*')
                total_time_value=$(echo "$total_time" | sed 's/Total Time (s)//' | tr -d ' ')
                data_time=$total_time_value

                if [ "$exit_code" -eq 0 ]; then
                    ((successful_executions++))
                    echo "$execution_time,$data_time,$PAYLOAD_SIZE,$LIBOMPTARGET_USE_STRATEGIZER,$LIBOMPTARGET_STRATEGIZER_STRATEGY,$LIBOMPTARGET_STRATEGIZER_TOPO,$LIBOMPTARGET_STRATEGIZER_MIN_SIZE,$exit_code"
                    echo "$execution_time,$data_time,$PAYLOAD_SIZE,$LIBOMPTARGET_USE_STRATEGIZER,$LIBOMPTARGET_STRATEGIZER_STRATEGY,$LIBOMPTARGET_STRATEGIZER_TOPO,$LIBOMPTARGET_STRATEGIZER_MIN_SIZE,$exit_code" >>benchmark_results.txt
                fi
            done
        done

    else
        # Execute the command until target_successful_executions is reached
        # Print the this strategy and payload_size
        echo "Strategy: BASELINE, Payload Size: $payload_size"
        export LIBOMPTARGET_STRATEGIZER_STRATEGY="none"
        successful_executions=0
        while [ "$successful_executions" -lt "$target_successful_executions" ]; do
            echo "Running"
            start_time=$(date +%s.%3N)
            output=$(timeout $timeout_seconds ./minifmm/fmm.omptarget $fmm_args 2>&1)
            exit_code=$?
            end_time=$(date +%s.%3N)
            execution_time=$(echo "$end_time - $start_time" | bc)
            total_time=$(echo "$output" | grep -o 'Total Time (s) * *[0-9.]*')
            total_time_value=$(echo "$total_time" | sed 's/Total Time (s)//' | tr -d ' ')
            data_time=$total_time_value

            if [ "$exit_code" -eq 0 ]; then
                ((successful_executions++))
                echo "$execution_time,$data_time,$PAYLOAD_SIZE,$LIBOMPTARGET_USE_STRATEGIZER,$LIBOMPTARGET_STRATEGIZER_STRATEGY,$LIBOMPTARGET_STRATEGIZER_TOPO,$LIBOMPTARGET_STRATEGIZER_MIN_SIZE,$exit_code"
                echo "$execution_time,$data_time,$PAYLOAD_SIZE,$LIBOMPTARGET_USE_STRATEGIZER,$LIBOMPTARGET_STRATEGIZER_STRATEGY,$LIBOMPTARGET_STRATEGIZER_TOPO,$LIBOMPTARGET_STRATEGIZER_MIN_SIZE,$exit_code" >>benchmark_results.txt
            fi
        done
    fi
done
