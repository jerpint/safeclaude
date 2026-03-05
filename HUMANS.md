# HUMANS.md

> **NOTE:** This is an experimental repo, work is in progress, pull regularly and use at your own risk.

## What is this?

A wrapper script that runs [Claude Code](https://docs.anthropic.com/en/docs/claude-code) inside a Docker container. You get full autonomous mode (`--dangerously-skip-permissions`) without giving Claude access to your entire machine.

## Why?

Claude Code with `--dangerously-skip-permissions` is powerful but risky on bare metal -it can see your home dir, SSH keys, other repos, everything. `safeclaude` scopes it to just your git repo inside a container.

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

First run builds the Docker image and prompts you to authenticate. Credentials persist inside the container -you only auth once.

**Note:** safeclaude must be run from inside a git repo -it uses the repo root to determine what gets mounted into the container. Running it outside a repo will error.

## How does it work?

```
you run safeclaude from any git repo
        │
        ▼
  detects repo root & worktrees
        │
        ▼
  mounts repo into a Docker container
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

- `--shell` -opens a bash shell inside the running container (useful for inspecting the environment, checking git config, etc.)
- `--restart` -destroys the container and creates a fresh one (useful when mounts or env vars change)
- `--build` -destroys the container and rebuilds the Docker image (useful after updating safeclaude itself)

Claude commits locally inside the container. You review and push from the host when ready.

## Configuration

Set these in `~/safeclaude/.env` or export them in your shell:

| Env var | Purpose |
|---|---|
| `SAFECLAUDE_GIT_NAME` | Override git `user.name` (default: your host's git config) |
| `SAFECLAUDE_GIT_EMAIL` | Override git `user.email` (default: your host's git config) |
| `SAFECLAUDE_MOUNT` | Override which directory gets mounted (default: git repo root) |
| `SAFECLAUDE_HOST_NETWORK` | Set to `1` to expose host localhost as `host.docker.internal` |
| `SAFECLAUDE_PERSIST_HISTORY` | Set to `1` to share `~/.claude` (sessions, settings) with host |
| `SAFECLAUDE_EXTRA_MOUNTS` | Additional `-v` flags for docker run |

### Container lifecycle

By default, the container is fully isolated -sessions, credentials, and history live only inside it. State persists across runs (exit and come back, everything is still there). Running `--build` destroys the container and starts fresh.

### Session history

By default, `claude --resume` on the host won't see safeclaude sessions and vice versa. To share session history, use `safeclaude --persist` (or set `SAFECLAUDE_PERSIST_HISTORY=1`). This mounts `~/.claude` read-write so sessions, settings, and credentials are shared with the host.

## What can go wrong?

This project is **experimental**. Claude runs with full autonomous permissions inside the container. Here's what it can and can't touch:

**Safe** -your home directory, SSH keys, other repos, system files, and everything else on your host are not mounted. A rogue `rm -rf /` inside the container can't reach them.

**At risk** -your mounted git repo (code + `.git` metadata) is read-write. Claude can modify or delete files, corrupt git refs, or mess with branches. In worktrees, the shared `.git` dir is also writable (required for `git add`/`git commit` to work).

**Recoverable** -since there's no push access by default, nothing leaves your machine. `git fetch` from the remote recovers everything. Worst case you lose uncommitted local work in that one repo.

The container limits the blast radius, but doesn't eliminate risk. Review commits before pushing.
