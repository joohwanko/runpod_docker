FROM pytorch/pytorch:2.4.0-cuda12.1-cudnn9-runtime

ENV DEBIAN_FRONTEND=noninteractive

# code lives here
WORKDIR /app

RUN apt-get update && apt-get install -y \
    curl wget git vim tmux htop ca-certificates unzip build-essential \
    openssh-server openssh-client \
    nodejs npm \
    && rm -rf /var/lib/apt/lists/*

# ssh
RUN mkdir -p /var/run/sshd /root/.ssh && chmod 700 /root/.ssh

# uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

# Claude Code
RUN curl -fsSL https://claude.ai/install.sh | bash || true
ENV PATH="/root/.local/bin:/root/.claude/local:${PATH}"

# Codex CLI
RUN npm install -g @openai/codex

# copy repo into image
COPY . /app

# install project if pyproject exists
RUN if [ -f /app/pyproject.toml ]; then uv pip install --system -e /app; fi

# common tools
RUN uv pip install --system wandb jupyterlab ipykernel

# cache/data/checkpoint paths on mounted volume
ENV HF_HOME=/workspace/cache/huggingface
ENV TRANSFORMERS_CACHE=/workspace/cache/huggingface
ENV HF_DATASETS_CACHE=/workspace/cache/datasets
ENV UV_CACHE_DIR=/workspace/cache/uv
ENV WANDB_DIR=/workspace/wandb

EXPOSE 22

COPY start.sh /start.sh
RUN chmod +x /start.sh

CMD ["/start.sh"]