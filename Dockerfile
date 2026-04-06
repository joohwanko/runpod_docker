FROM pytorch/pytorch:2.4.0-cuda12.1-cudnn9-runtime

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /workspace

RUN apt-get update && apt-get install -y \
    curl wget git vim tmux htop ca-certificates unzip build-essential \
    nodejs npm openssh-client \
    && rm -rf /var/lib/apt/lists/*

# uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

# Claude Code
RUN curl -fsSL https://claude.ai/install.sh | bash || true
ENV PATH="/root/.local/bin:/root/.claude/local:${PATH}"

# Codex CLI
RUN npm install -g @openai/codex

# project install
COPY pyproject.toml /workspace/pyproject.toml
RUN uv pip install --system -e /workspace || true

# useful defaults
RUN uv pip install --system wandb jupyterlab ipykernel

# cache paths on Runpod volume
ENV HF_HOME=/workspace/cache/huggingface
ENV TRANSFORMERS_CACHE=/workspace/cache/huggingface
ENV HF_DATASETS_CACHE=/workspace/cache/datasets
ENV UV_CACHE_DIR=/workspace/cache/uv
ENV WANDB_DIR=/workspace/wandb

CMD ["bash", "-lc", "sleep infinity"]