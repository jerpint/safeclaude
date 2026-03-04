# HUMANS.md

## What is this?

A wrapper script that runs [Claude Code](https://docs.anthropic.com/en/docs/claude-code) inside a Docker container. You get full autonomous mode (`--dangerously-skip-permissions`) without giving Claude access to your entire machine.

## Why?

Claude Code with `--dangerously-skip-permissions` is powerful but risky on bare metal — it can see your home dir, SSH keys, other repos, everything. `safeclaude` scopes it to just your git repo inside a container.

## Setup

```bash
# Add to your ~/.zshrc (or ~/.bashrc)
export PATH="$HOME/safeclaude:$PATH"
```

Then from any git repo:

```bash
cd ~/my-project
safeclaude
```

First run builds the Docker image and prompts you to authenticate. Credentials persist to `~/.safeclaude/` — you only auth once.

## How does it work?

```
you run safeclaude from any git repo
        │
        ▼
  detects repo root & worktrees
        │
        ▼
  mounts repo into a Docker container
  (+ Claude credentials)
        │
        ▼
  runs `claude --dangerously-skip-permissions`
  inside the container
        │
        ▼
  Claude can only see your repo
  nothing else from your host
```

## Examples

```bash
safeclaude                          # start claude in current repo
safeclaude "fix the auth bug"       # start with a prompt
safeclaude --resume                 # resume last conversation
safeclaude -p "do the thing"        # pass any claude flags
```

All arguments are forwarded directly to `claude`, so anything that works with `claude` works with `safeclaude`.

Two extra flags for debugging:

- `--shell` — opens a bash shell inside the running container (useful for inspecting the environment, checking git config, etc.)
- `--build` — forces a rebuild of the Docker image (useful after updating safeclaude itself)

Claude commits locally inside the container. You review and push from the host when ready.

## Configuration

Set these in `~/safeclaude/.env` or export them in your shell:

| Env var | Purpose |
|---|---|
| `CLAUDE_CODE_OAUTH_TOKEN` | Skip interactive auth (set once, persists automatically) |
| `SAFECLAUDE_GIT_NAME` | Override git `user.name` (default: your host's git config) |
| `SAFECLAUDE_GIT_EMAIL` | Override git `user.email` (default: your host's git config) |
| `SAFECLAUDE_MOUNT` | Override which directory gets mounted (default: git repo root) |
| `SAFECLAUDE_EXTRA_MOUNTS` | Additional `-v` flags for docker run |

### Session history

By default, each safeclaude container is isolated — sessions and credentials live in `~/.safeclaude/`, separate from your host's `~/.claude/`. This means `claude --resume` on the host won't see safeclaude sessions and vice versa.

To share session history between safeclaude and your host:

```bash
safeclaude --persist-history
```

Or set `SAFECLAUDE_PERSIST_HISTORY=1` in your `.env`. This mounts `~/.claude` read-write so sessions, settings, and credentials are shared with the host. Use this if you want to seamlessly switch between `claude` and `safeclaude`.
