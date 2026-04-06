FROM pytorch/pytorch:2.4.0-cuda12.1-cudnn9-runtime

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /app

RUN apt-get update && apt-get install -y \
    curl wget git vim tmux htop ca-certificates unzip build-essential \
    openssh-server openssh-client \
    nodejs npm \
    && rm -rf /var/lib/apt/lists/*

# SSH
RUN mkdir -p /var/run/sshd /root/.ssh && chmod 700 /root/.ssh

# uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Claude Code
RUN curl -fsSL https://claude.ai/install.sh | bash || true

# Codex CLI
RUN npm install -g @openai/codex

# Paths
ENV PATH="/app/.venv/bin:/root/.local/bin:/root/.claude/local:${PATH}"
ENV HF_HOME=/workspace/cache/huggingface
ENV TRANSFORMERS_CACHE=/workspace/cache/huggingface
ENV HF_DATASETS_CACHE=/workspace/cache/datasets
ENV UV_CACHE_DIR=/workspace/cache/uv
ENV WANDB_DIR=/workspace/wandb

# Copy repo
COPY . /app

# Install deps from pyproject only (do NOT install project itself)
RUN if [ -f /app/pyproject.toml ]; then \
      cd /app && uv sync --no-install-project; \
    fi

# Extra tools
RUN pip install --no-cache-dir wandb jupyterlab ipykernel

EXPOSE 22
EXPOSE 8888

COPY start.sh /start.sh
RUN chmod +x /start.sh

CMD ["/start.sh"]