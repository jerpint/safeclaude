# safeclaude

Drop-in replacement for `claude` that runs inside a Docker container.

## Tech Stack

- **Runtime**: Docker (node:22-slim base)
- **Language**: Bash + Python (entrypoint config helper)
- **Dependencies**: git, gh, tmux, python3, claude-code (npm)

## Project Structure

```
safeclaude              # Main command — flag parsing, mount resolution, docker run
Dockerfile              # Container image: node:22 + git + gh + tmux + python3 + claude-code
entrypoint.sh           # Container init: auth, onboarding skip, git identity
setup-claude-config.py  # Patches ~/.claude.json to skip onboarding + accept trust dialog
HUMANS.md               # User-facing docs
CLAUDE.md               # This file
.env                    # CLAUDE_CODE_OAUTH_TOKEN (gitignored)
.env.example            # Template
```

## Architecture

### Flow

```
safeclaude [args]
  ├─ Parse flags: --build, --shell, --persist (consumed)
  │   All other args → CLAUDE_PASSTHROUGH (forwarded to claude)
  │
  ├─ --shell? → docker exec into running container, exit
  │
  ├─ Detect git root, resolve mount root (env > marker file > git root)
  │
  ├─ --build? → docker build --no-cache
  │   No image? → docker build (auto first run)
  │
  ├─ Set up mounts (repo, worktree .git)
  │
  ├─ Container exists? → docker start + docker exec (reuse)
  │   Container running? → docker exec (reuse)
  │
  └─ No container → docker run → entrypoint.sh → claude --dangerously-skip-permissions [passthrough args]
```

### Entrypoint (container startup)

1. Write OAuth credentials if `CLAUDE_CODE_OAUTH_TOKEN` is set
2. Patch `~/.claude.json` — skip onboarding, accept trust dialog for working directory
3. Configure git — safe.directory, user.name/email from env vars
4. Alias `cc="claude --dangerously-skip-permissions"`
5. `exec "$@"` (run claude or bash)

### Mount Strategy

| Mount | Mode | Condition |
|---|---|---|
| Git repo/worktree | read-write | Always |
| Main .git dir (worktrees) | read-only | When in a worktree |
| `~/.claude` → `/home/node/.claude-host` | read-only | Default (host settings reference) |
| `~/.claude` → `/home/node/.claude` | read-write | `--persist` (shared sessions) |

Container path matches host absolute path so Claude session keys are portable.

### Container Naming

`safeclaude-<basename of mount root>` — one container per repo. Running safeclaude again reuses the existing container (start + exec if stopped, exec if running). `--build` destroys it and starts fresh. `--shell` execs bash into it.

## Configuration

| Env var | Purpose |
|---|---|
| `CLAUDE_CODE_OAUTH_TOKEN` | Skip interactive auth |
| `SAFECLAUDE_MOUNT` | Override mount root |
| `SAFECLAUDE_IMAGE` | Override Docker image name (default: `safeclaude`) |
| `SAFECLAUDE_PERSIST_HISTORY` | `1` to mount `~/.claude` read-write for shared session history |
| `SAFECLAUDE_GIT_NAME` | Override git `user.name` (default: host `git config user.name`) |
| `SAFECLAUDE_GIT_EMAIL` | Override git `user.email` (default: host `git config user.email`) |
| `SAFECLAUDE_EXTRA_MOUNTS` | Additional `-v` flags for docker run |

### Mount Scoping (priority order)

1. `SAFECLAUDE_MOUNT` env var — explicit path
2. `.safeclaude-mount` marker file — walk up from cwd, contents = mount path
3. Git repo/worktree root — default

## Design Principles

- **Ephemeral by default** — no host mounts for credentials; state lives in the container, `--build` resets it
- **Minimal surface** — only mount the repo, nothing else from the host
- **Zero config by default** — auto-builds image, inherits host git identity, auto-detects repo
- **Commit inside, push outside** — no SSH keys or GitHub tokens in the container
- **MCP from repo** — no MCP servers injected; use `.claude/settings.json` in your repo
- **Passthrough** — all unknown flags forwarded to claude as-is

## Key Files

- `HUMANS.md` — user-facing quickstart and examples. Keep in sync when changing flags or usage.
