#!/usr/bin/env bash
set -e

mkdir -p /run/sshd /root/.ssh
chmod 700 /root/.ssh
ssh-keygen -A

if [ -n "${SSH_PUBLIC_KEY:-}" ]; then
  printf '%s\n' "${SSH_PUBLIC_KEY}" > /root/.ssh/authorized_keys
elif [ -n "${PUBLIC_KEY:-}" ]; then
  printf '%s\n' "${PUBLIC_KEY}" > /root/.ssh/authorized_keys
fi

chmod 600 /root/.ssh/authorized_keys 2>/dev/null || true

mkdir -p /workspace/cache/huggingface
mkdir -p /workspace/cache/datasets
mkdir -p /workspace/cache/uv
mkdir -p /workspace/wandb
mkdir -p /workspace/models
mkdir -p /workspace/data
mkdir -p /workspace/ckpt

/usr/sbin/sshd

exec "$@"