FROM nvidia/cuda:13.0.2-cudnn-devel-ubuntu24.04

SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC \
    UV_PYTHON=3.13 \
    UV_CACHE_DIR=/workspace/cache/uv \
    HF_HOME=/workspace/cache/huggingface \
    TRANSFORMERS_CACHE=/workspace/cache/huggingface \
    HF_DATASETS_CACHE=/workspace/cache/datasets \
    WANDB_DIR=/workspace/wandb \
    JAX_PLATFORMS=cuda \
    XLA_PYTHON_CLIENT_PREALLOCATE=false \
    PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility

WORKDIR /opt/app

# Base packages + SSH + dev tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget gnupg unzip \
    git git-lfs vim nano tmux htop nvtop procps \
    build-essential pkg-config cmake ninja-build \
    openssh-server openssh-client iproute2 net-tools rsync \
    less tree jq lsof psmisc \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /run/sshd /root/.ssh /workspace \
    && chmod 700 /root/.ssh \
    && ssh-keygen -A \
    && sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config \
    && sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config \
    && git config --global --add safe.directory '*'

# Node 22 for Codex CLI / Claude tooling
RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
      | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" \
      > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# uv
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_UNMANAGED_INSTALL="/usr/local/bin" sh

# Claude Code + Codex CLI
RUN curl -fsSL https://claude.ai/install.sh | bash || true
RUN npm install -g @openai/codex

ENV PATH="/opt/app/.venv/bin:/usr/local/bin:/root/.local/bin:/root/.claude/local:${PATH}"

# Install Python 3.13 project deps from pyproject.toml.
# This intentionally matches amort_debug: torch>=2.10 + numpyro[cuda13].
COPY pyproject.toml /opt/app/pyproject.toml
RUN touch /opt/app/README.md \
    && uv python install 3.13 \
    && uv venv /opt/app/.venv --python 3.13 \
    && uv sync --no-install-project --python 3.13 \
    && python - <<'PY'
import sys
print("python:", sys.version)

import torch
print("torch:", torch.__version__)
print("torch cuda:", torch.version.cuda)

import jax
print("jax:", jax.__version__)

import numpyro
print("numpyro:", numpyro.__version__)
PY

COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

WORKDIR /workspace

EXPOSE 22
EXPOSE 8888

ENTRYPOINT ["/usr/local/bin/start.sh"]
CMD ["bash", "-lc", "sleep infinity"]
