# HUMANS.md

## What is this?

A wrapper script that runs [Claude Code](https://docs.anthropic.com/en/docs/claude-code) inside a Docker container. You get full autonomous mode (`--dangerously-skip-permissions`) without giving Claude access to your entire machine.

## Why?

Claude Code with `--dangerously-skip-permissions` is powerful but risky on bare metal — it can see your home dir, SSH keys, other repos, everything. `safeclaude` scopes it to just your git repo inside a container.

## How do I use it?

```bash
cd ~/my-project
~/safeclaude/safeclaude
```

That's it. First run builds the Docker image and prompts you to authenticate.

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
