#!/bin/zsh

target_successful_executions=10
timeout_seconds=300

# Set LLVM path
# ============================================
echo "Setting local LLVM path..."
llvm_build_dir=../../../llvm-build/release-build
llvm_install_dir=../../../llvm-build/install

# replace with real path
llvm_build_dir=$(realpath $llvm_build_dir)
llvm_install_dir=$(realpath $llvm_install_dir)

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

#use an array to define the bash arguments
rsbench_args=("-m" "event" "-p" "1000000" "-P" "5000" "-l" "900")

# Loop over LIBOMPTARGET_USE_STRATEGIZER values (0 and 1)
for use_strategizer in 1 0; do
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
                output=$(timeout $timeout_seconds ./RSBench/openmp-offload/rsbench "${rsbench_args[@]}" 2>&1)
                exit_code=$?
                echo "$exit_code"
                # echo "$output"
                end_time=$(date +%s.%3N)
                execution_time=$(echo "$end_time - $start_time" | bc)
                data_time=$(echo "$output" | grep "Runtime:" | awk '{print $2}')

                # Check if we have "Simulation Complete" in the output text
                # If we do, then we have a successful execution even if the exit code is not 0
                # since hash verification does not work when -g is specified
                if [[ "$output" == *"Simulation Complete"* ]]; then
                    echo "Simulation Complete was complete, treating as successful execution"
                    exit_code=0
                fi

                if [ "$exit_code" -eq 0 ]; then
                    ((successful_executions++))
                    echo "$execution_time,$data_time,$PAYLOAD_SIZE,$LIBOMPTARGET_USE_STRATEGIZER,$LIBOMPTARGET_STRATEGIZER_STRATEGY,$LIBOMPTARGET_STRATEGIZER_TOPO,$LIBOMPTARGET_STRATEGIZER_MIN_SIZE,$exit_code"
                    echo "$execution_time,$data_time,$PAYLOAD_SIZE,$LIBOMPTARGET_USE_STRATEGIZER,$LIBOMPTARGET_STRATEGIZER_STRATEGY,$LIBOMPTARGET_STRATEGIZER_TOPO,$LIBOMPTARGET_STRATEGIZER_MIN_SIZE,$exit_code" >>benchmark_results.txt
                else
                    echo "Error: $exit_code"
                    echo "$output" | tail -n 3
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
            output=$(timeout $timeout_seconds ./RSBench/openmp-offload/rsbench "${rsbench_args[@]}" 2>&1)
            exit_code=$?

            end_time=$(date +%s.%3N)
            execution_time=$(echo "$end_time - $start_time" | bc)
            data_time=$(echo "$output" | grep "Runtime:" | awk '{print $2}')
            # Check if we have "Simulation Complete" in the output text
            # If we do, then we have a successful execution even if the exit code is not 0
            # since hash verification does not work when -g is specified
            if [[ "$output" == *"Simulation Complete"* ]]; then
                echo "Simulation Complete was complete, treating as successful execution"
                exit_code=0
            fi

            if [ "$exit_code" -eq 0 ]; then
                ((successful_executions++))
                echo "$execution_time,$data_time,$PAYLOAD_SIZE,$LIBOMPTARGET_USE_STRATEGIZER,$LIBOMPTARGET_STRATEGIZER_STRATEGY,$LIBOMPTARGET_STRATEGIZER_TOPO,$LIBOMPTARGET_STRATEGIZER_MIN_SIZE,$exit_code"
                echo "$execution_time,$data_time,$PAYLOAD_SIZE,$LIBOMPTARGET_USE_STRATEGIZER,$LIBOMPTARGET_STRATEGIZER_STRATEGY,$LIBOMPTARGET_STRATEGIZER_TOPO,$LIBOMPTARGET_STRATEGIZER_MIN_SIZE,$exit_code" >>benchmark_results.txt
            fi
        done
    fi
done
