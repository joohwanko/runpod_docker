FROM pytorch/pytorch:2.4.0-cuda12.1-cudnn9-runtime

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl wget git vim tmux htop ca-certificates unzip build-essential \
    openssh-server openssh-client iproute2 \
    nodejs npm \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /run/sshd /root/.ssh \
    && chmod 700 /root/.ssh \
    && ssh-keygen -A \
    && sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config \
    && sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config

# uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Claude Code
RUN curl -fsSL https://claude.ai/install.sh | bash || true

# Codex CLI
RUN npm install -g @openai/codex

ENV PATH="/app/.venv/bin:/root/.local/bin:/root/.claude/local:${PATH}"
ENV HF_HOME=/workspace/cache/huggingface
ENV TRANSFORMERS_CACHE=/workspace/cache/huggingface
ENV HF_DATASETS_CACHE=/workspace/cache/datasets
ENV UV_CACHE_DIR=/workspace/cache/uv
ENV WANDB_DIR=/workspace/wandb

COPY . /app

# pyproject/uv.lock 기준으로 dependency만 설치
RUN if [ -f /app/pyproject.toml ]; then \
      cd /app && uv sync --no-install-project; \
    fi

# common extras
RUN pip install --no-cache-dir wandb jupyterlab ipykernel

EXPOSE 22
EXPOSE 8888

COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

ENTRYPOINT ["/usr/local/bin/start.sh"]
CMD ["bash", "-lc", "sleep infinity"]