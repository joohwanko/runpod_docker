#!/usr/bin/env bash
set -e

mkdir -p /root/.ssh
chmod 700 /root/.ssh

if [ -n "${PUBLIC_KEY}" ]; then
  echo "${PUBLIC_KEY}" >> /root/.ssh/authorized_keys
fi

chmod 600 /root/.ssh/authorized_keys || true

mkdir -p /workspace/cache/huggingface
mkdir -p /workspace/cache/datasets
mkdir -p /workspace/cache/uv
mkdir -p /workspace/wandb
mkdir -p /workspace/models
mkdir -p /workspace/data
mkdir -p /workspace/ckpt

/usr/sbin/sshd -D &
sleep infinity