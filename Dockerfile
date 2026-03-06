# safeclaude — Claude Code in a container
# Autonomous Claude scoped to your git worktrees

FROM node:22-slim

RUN apt-get update && apt-get install -y \
    curl \
    git \
    jq \
    make \
    ripgrep \
    tmux \
    openssh-client \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# gh CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && apt-get install -y gh && \
    rm -rf /var/lib/apt/lists/*

# Claude Code
RUN npm install -g @anthropic-ai/claude-code

RUN mkdir -p /workspace

# Non-root user required for --dangerously-skip-permissions
RUN chown -R node:node /workspace /home/node

USER node

# uv (Python package manager)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/home/node/.local/bin:$PATH"

COPY --chown=node:node entrypoint.sh setup-claude-config.py /home/node/
RUN chmod +x /home/node/entrypoint.sh

WORKDIR /workspace

ENTRYPOINT ["/home/node/entrypoint.sh"]
CMD ["bash"]
