# safeclaude

> **WARNING: This project is EXPERIMENTAL. Use at your own risk.**

Drop-in replacement for `claude` that runs inside a Docker container with `--dangerously-skip-permissions`. Fully autonomous Claude, scoped to your git repo.

## Why

Running Claude Code with `--dangerously-skip-permissions` on your host gives it access to everything. `safeclaude` runs it inside a container where it can only see your repo, nothing else.

## Quick start

```bash
# Build the image
docker build -t safeclaude ~/safeclaude/

# Run from any git repo
cd ~/my-project
~/safeclaude/safeclaude
```

First run will prompt you to authenticate via browser. Credentials persist to `~/.safeclaude/` automatically — you only auth once.

## Usage

```bash
safeclaude                          # start claude in current repo
safeclaude "fix the auth bug"       # start with a prompt
safeclaude --resume                 # resume last conversation
safeclaude -p "do the thing"        # pass any claude flags
safeclaude --github                  # enable GitHub CLI access
safeclaude --persist-history          # mount ~/.claude for session history
```

## What it has access to

| Mount | Container path | Mode | Purpose |
|---|---|---|---|
| Git repo / worktree parent | `/workspace` | read/write | Your code |
| `~/.config/gh` | `/home/node/.config/gh` | read/write | GitHub CLI auth (opt-in: `SAFECLAUDE_GH=1`) |
| `~/.claude` | `/home/node/.claude-host` | read-only | Host Claude settings reference (default) |
| `~/.claude` | `/home/node/.claude` | read/write | Shared session history (opt-in: `SAFECLAUDE_PERSIST_HISTORY=1`) |
| `~/.safeclaude/` | `/home/node/.claude` | read/write | Isolated credentials persistence (default) |

Network is unrestricted (GitHub API, Linear MCP, Claude API, etc).

**Nothing else.** No home dir, no ssh keys, no other repos, no dotfiles.

## Mount scoping

`safeclaude` detects what to mount in priority order:

1. **`SAFECLAUDE_MOUNT` env var** — explicit mount root
   ```bash
   SAFECLAUDE_MOUNT=~/my-project safeclaude
   ```

2. **`.safeclaude-mount` marker file** — drop in any parent directory, contents = mount path
   ```bash
   echo ~/my-project > ~/my-project/.safeclaude-mount
   # Now any `safeclaude` run under this dir uses that mount root
   ```

3. **Git repo / worktree root** — mounts just the current repo or worktree

## Auth

Three options, in priority order:

1. **`CLAUDE_CODE_OAUTH_TOKEN` env var** — set in `~/safeclaude/.env` or export it
2. **Persisted credentials** — stored in `~/.safeclaude/.credentials.json` after first interactive auth
3. **Interactive OAuth** — Claude prompts you to authenticate via browser on first run

## Adding to PATH

```bash
# In ~/.zshrc
export PATH="$HOME/safeclaude:$PATH"
```

Then just `safeclaude` from anywhere.

## Configuration

| Env var | Purpose |
|---|---|
| `CLAUDE_CODE_OAUTH_TOKEN` | Skip interactive auth |
| `SAFECLAUDE_MOUNT` | Override mount root |
| `SAFECLAUDE_IMAGE` | Override Docker image name (default: `safeclaude`) |
| `SAFECLAUDE_GH` | Set to `1` to mount GitHub CLI auth (off by default) |
| `SAFECLAUDE_PERSIST_HISTORY` | Set to `1` to mount `~/.claude` read-write for shared session history |
| `SAFECLAUDE_GIT_NAME` | Override git `user.name` inside the container (default: host `git config user.name`) |
| `SAFECLAUDE_GIT_EMAIL` | Override git `user.email` inside the container (default: host `git config user.email`) |
| `SAFECLAUDE_EXTRA_MOUNTS` | Additional `-v` flags |

## MCP servers

Linear MCP (`https://mcp.linear.app/mcp`) is configured automatically by the entrypoint. First use of a Linear tool will prompt OAuth in the browser.

## Files

```
~/safeclaude/
  Dockerfile        # node:22 + git + gh + tmux + python3 + claude-code
  entrypoint.sh     # Auth, onboarding skip, Linear MCP, git config
  safeclaude        # The command
  .env              # Your token (gitignored)
  .env.example      # Template
```
