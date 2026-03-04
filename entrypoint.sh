#!/bin/bash
set -e

# --- Auth: env token > persisted credentials > interactive OAuth flow ---
mkdir -p /home/node/.claude
if [ -n "$CLAUDE_CODE_OAUTH_TOKEN" ]; then
  printf '{"claudeAiOauth":{"accessToken":"%s","expiresAt":9999999999999}}' \
    "$CLAUDE_CODE_OAUTH_TOKEN" > /home/node/.claude/.credentials.json
  chmod 600 /home/node/.claude/.credentials.json
fi

# --- Skip first-run onboarding ---
python3 /home/node/setup-claude-config.py "$(pwd)" 2>/dev/null || {
  echo '{"hasCompletedOnboarding":true}' > /home/node/.claude.json
}

# --- Git ---
git config --global --add safe.directory '*'
[ -n "$GIT_USER_NAME" ]  && git config --global user.name  "$GIT_USER_NAME"
[ -n "$GIT_USER_EMAIL" ] && git config --global user.email "$GIT_USER_EMAIL"

# --- Alias ---
echo 'alias cc="claude --dangerously-skip-permissions"' >> /home/node/.bashrc

exec "$@"
