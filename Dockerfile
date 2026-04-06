FROM pytorch/pytorch:2.4.0-cuda12.1-cudnn9-runtime

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /app

# Base packages + SSH
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget gnupg unzip \
    git vim tmux htop build-essential \
    openssh-server openssh-client iproute2 \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /run/sshd /root/.ssh \
    && chmod 700 /root/.ssh \
    && ssh-keygen -A \
    && sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config \
    && sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config

# Node 22 for Codex CLI
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

# Claude Code
RUN curl -fsSL https://claude.ai/install.sh | bash || true

# Codex CLI
RUN npm install -g @openai/codex

# Paths
ENV PATH="/app/.venv/bin:/usr/local/bin:/root/.local/bin:/root/.claude/local:${PATH}"
ENV HF_HOME=/workspace/cache/huggingface
ENV TRANSFORMERS_CACHE=/workspace/cache/huggingface
ENV HF_DATASETS_CACHE=/workspace/cache/datasets
ENV UV_CACHE_DIR=/workspace/cache/uv
ENV WANDB_DIR=/workspace/wandb

# Copy project
COPY . /app

# Install only dependencies from pyproject/uv.lock if present
RUN if [ -f /app/pyproject.toml ]; then \
      cd /app && uv sync --no-install-project; \
    fi

EXPOSE 22
EXPOSE 8888

COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

ENTRYPOINT ["/usr/local/bin/start.sh"]
CMD ["bash", "-lc", "sleep infinity"]