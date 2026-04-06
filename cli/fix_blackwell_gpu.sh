#!/bin/bash
DRV=$(find /usr/lib/wsl/drivers -name "nv_dispig.inf_amd64_*" | head -n 1)
V_NV="/data/.venv/lib/python3.12/site-packages/nvidia"
FIX_DIR="/data/lib_fix"

# 1. Mandatory Host Driver Links (Always run if $DRV exists)
if [ -d "$DRV" ]; then
    echo "   ===== Linking Blackwell Host Drivers ====="
    mkdir -p "$FIX_DIR"
    ln -sf "$DRV/libcuda.so.1.1" "$FIX_DIR/libcuda.so.1"
    ln -sf "$DRV/libnvidia-ml.so.1" "$FIX_DIR/libnvidia-ml.so.1"
    ln -sf "$DRV/libnvidia-ptxjitcompiler.so.1" "$FIX_DIR/libnvidia-ptxjitcompiler.so.1"
    
    # 2. Conditional .venv Links (Only run if .venv is already built)
    if [ -d "$V_NV" ]; then
        echo "   ===== Linking .venv CUDA Toolkits ====="
        ln -sf "$V_NV/cuda_nvrtc/lib/libnvrtc.so.12" "$FIX_DIR/libnvrtc.so.12"
        ln -sf "$V_NV/cuda_nvrtc/lib/libnvrtc-builtins.so.12."* "$FIX_DIR/"
    else
        echo "   ℹ️  ${V_NV} not found in .venv. Skipping toolkit links (Run setup_python_venv next)."
    fi

    # 3. Always update the path so the system knows where to look
    export LD_LIBRARY_PATH="$FIX_DIR:$DRV:$V_NV/cuda_nvrtc/lib:$V_NV/cuda_cupti/lib:$V_NV/cusolver/lib:/usr/lib/x86_64-linux-gnu"
fi

# 4. Mandatory for setup_python_venv detection
mkdir -p /dev && touch /dev/nvidia0 /dev/nvidiactl

# Standard Blackwell Flags
export TF_CUDA_COMPUTE_CAPABILITIES="12.0"
export XLA_FLAGS="--xla_gpu_cuda_data_dir=/usr/local/cuda"

[ "$#" -gt 0 ] && exec "$@"