# Apply patch
cd minifmm

PATCH_FILE=../minifmm.patch
# Check if the patch has already been applied
if ! git apply --reverse --check "$PATCH_FILE" 2>/dev/null; then
    # The patch has not been applied; apply it
    echo "Applying the patch..."
    if git apply "$PATCH_FILE"; then
        echo "Patch applied successfully!"
    else
        echo "Error: Failed to apply the patch."
    fi
else
    echo "Patch has already been applied."
fi

# Set LLVM path
# ============================================
echo "Setting local LLVM path..."
llvm_build_dir=../../../llvm-build/release-build
llvm_install_dir=../../../llvm-build/install

export PATH=$llvm_install_dir/bin/:$PATH
export LD_LIBRARY_PATH=$llvm_install_dir/lib/:$LD_LIBRARY_PATH
export LIBRARY_PATH=$llvm_install_dir/lib/:$LIBRARY_PATH

# Common environment variables
export LIBOMPTARGET_MEMORY_MANAGER_THRESHOLD=0 # disable memory manager
export LIBOMPTARGET_STRATEGIZER_MIN_SIZE=1
export LIBOMPTARGET_STRATEGIZER_TOPO="topo_smx"
unset OMP_PROC_BIND
unset OMP_NUM_THREADS
unset OMP_PLACES

echo "Compiling with: "
which clang
clang --version

make --always-make compiler=clang++ MODEL=omptarget
