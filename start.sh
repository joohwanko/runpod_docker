#!/usr/bin/env bash
set -euo pipefail

export JAX_PLATFORMS="${JAX_PLATFORMS:-cuda}"
export XLA_PYTHON_CLIENT_PREALLOCATE="${XLA_PYTHON_CLIENT_PREALLOCATE:-false}"
export PYTORCH_CUDA_ALLOC_CONF="${PYTORCH_CUDA_ALLOC_CONF:-expandable_segments:True}"

mkdir -p /run/sshd /root/.ssh
chmod 700 /root/.ssh
ssh-keygen -A >/dev/null 2>&1 || true

if [[ -n "${SSH_PUBLIC_KEY:-}" ]]; then
  printf '%s\n' "${SSH_PUBLIC_KEY}" > /root/.ssh/authorized_keys
elif [[ -n "${PUBLIC_KEY:-}" ]]; then
  printf '%s\n' "${PUBLIC_KEY}" > /root/.ssh/authorized_keys
fi

chmod 600 /root/.ssh/authorized_keys 2>/dev/null || true

mkdir -p \
  /workspace/cache/huggingface \
  /workspace/cache/datasets \
  /workspace/cache/uv \
  /workspace/wandb \
  /workspace/models \
  /workspace/data \
  /workspace/ckpt

echo "[start] Python: $(python --version 2>&1)"
echo "[start] uv: $(uv --version 2>&1 || true)"
echo "[start] nvidia-smi:"
nvidia-smi || true

/usr/sbin/sshd

exec "$@"
