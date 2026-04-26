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
    XLA_PYTHON_CLIENT_PREALLOCATE=false \
    PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility

WORKDIR /opt/app

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget gnupg unzip \
    git git-lfs vim nano tmux htop procps \
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

RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
      | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" \
      > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_UNMANAGED_INSTALL="/usr/local/bin" sh

RUN curl -fsSL https://claude.ai/install.sh | bash || true
RUN npm install -g @openai/codex

ENV PATH="/opt/app/.venv/bin:/usr/local/bin:/root/.local/bin:/root/.claude/local:${PATH}"

COPY pyproject.toml /opt/app/pyproject.toml
COPY README.md /opt/app/README.md

RUN uv python install 3.13 \
    && uv venv /opt/app/.venv --python 3.13 \
    && uv sync --no-install-project --python 3.13 \
    && python -c "import sys; print('python:', sys.version)"

# Set CUDA/JAX runtime preference only after build-time dependency install.
# GitHub Actions runners do not have NVIDIA GPUs, so do not import JAX with JAX_PLATFORMS=cuda during build.
ENV JAX_PLATFORMS=cuda

COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

WORKDIR /workspace

EXPOSE 22
EXPOSE 8888

ENTRYPOINT ["/usr/local/bin/start.sh"]
CMD ["bash", "-lc", "sleep infinity"]
