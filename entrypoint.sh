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
CONTAINER_CWD="$(pwd)"
python3 -c "
import json, sys, os
p = '/home/node/.claude.json'
data = {}
if os.path.exists(p):
    with open(p) as f:
        data = json.load(f)
data['hasCompletedOnboarding'] = True
if 'projects' not in data:
    data['projects'] = {}
cwd = sys.argv[1]
if cwd not in data['projects']:
    data['projects'][cwd] = {}
proj = data['projects'][cwd]
proj['hasTrustDialogAccepted'] = True
if 'mcpServers' not in proj:
    proj['mcpServers'] = {}
proj['mcpServers']['linear'] = {
    'type': 'http',
    'url': 'https://mcp.linear.app/mcp'
}
with open(p, 'w') as f:
    json.dump(data, f, indent=2)
" "$CONTAINER_CWD" 2>/dev/null || {
  echo '{"hasCompletedOnboarding":true}' > /home/node/.claude.json
}

# --- Git ---
git config --global --add safe.directory '*'
[ -n "$GIT_USER_NAME" ]  && git config --global user.name  "$GIT_USER_NAME"
[ -n "$GIT_USER_EMAIL" ] && git config --global user.email "$GIT_USER_EMAIL"

# --- Alias ---
echo 'alias cc="claude --dangerously-skip-permissions"' >> /home/node/.bashrc

exec "$@"
