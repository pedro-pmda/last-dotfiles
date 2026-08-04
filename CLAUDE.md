# CLAUDE.md

Personal macOS dotfiles / dev-environment bootstrap. Plain Bash + Lua — no build step, no package manager, no tests. `README.md` documents every script for humans; this file is the working context.

## Map

| Path | What it is |
|---|---|
| `run` | Entrypoint. Finds every executable under `runs/` and runs it. |
| `runs/bootstrap/` | Installers: zsh, nvim, tmux, docker, hammerspoon, homebrew, nvm, git-hooks |
| `runs/infra/` | `install-k3s` (k3d cluster), `switch-cluster` (kubectl context) |
| `runs/access/` | `repokeys` — loads every private key in `~/.ssh` into ssh-agent |
| `runs/utils/` | `copy-configs`, `ready-tmux`, `tmux-sessionizer` |
| `configs/` | Files copied to their real homes: `hammerspoon-config/`, `nvim-config/`, `zsh-config/`, `git-config/`, `tmux-examples/` |
| `hooks/` | Git hooks installed into a **target** repo by `install-git-hooks`. zooplus conventions (`ZOOB-*` Jira IDs, `MAJOR\|MINOR\|REVISION \| ...`, `ui/` Prettier+ESLint). Not meant to run on this repo. |

## Running tasks

```bash
./run                # everything under runs/
./run tmux           # only scripts whose path matches the substring
./run --dry          # print, execute nothing
./run tmux --dry
```

- `--dry` is honored by `run` and `runs/utils/copy-configs` only. Installers have no dry-run — `./run <filter>` without `--dry` really does `brew install`.
- Scripts must be `chmod +x` or `run` silently ignores them.

## Conventions

- Bash: `#!/usr/bin/env bash` + `set -euo pipefail`, emoji-prefixed `echo` progress lines.
- Messages mix Spanish and English — **match the file you're editing**, don't normalize.
- Installers must be idempotent: check `command -v` / existing dirs, don't fail on re-run.
- Homebrew assumed; Apple Silicon paths (`/opt/homebrew`) hardcoded in several places.
- Several scripts assume the repo is cloned at `~/last-dotfiles`.
- Commits: Conventional Commits + emoji — `feat(hammerspoon): 🎯 update config layout`, `fix(zsh): 🐛 ...`.

## Hammerspoon

`configs/hammerspoon-config/init.lua` is the whole window/hotkey system: F1–F12 launch or focus apps, `Shift+F11` Kaizen mode, `Shift+F12` reload, `Shift+F6` emoji picker. On startup it runs Work mode. Layouts (app, `"1/3"`-style width/height fractions, position) and browser tab sets live in the config table, never in `init.lua`.

`init.lua` does `require("app_config")`. `app_config.lua` is not in the repo — it's a symlink into `configs/hammerspoon-config/profiles/`, one self-contained file per machine (`mac-work.lua`, `mac-personal.lua`). `install-hammerspoon` lists them, asks which one, and symlinks both `init.lua` and the chosen profile into `~/.hammerspoon`. A new machine is a new `.lua` in `profiles/`; keep new options in sync across all of them.

Since they're symlinks, editing a profile edits the live config — no re-install needed, just `Shift+F12`.

Apps outside `/Applications` need an entry in `appPaths` (only `mac-work.lua` has one today) — `hs.application.launchOrFocus` won't find them.

## tmux

`tmux-sessionizer` fzf-picks a dir under `~/kaizen` or `~/zooplus`, creates/attaches a session named after it, and runs `ready-tmux` inside. `ready-tmux` executes `./.ready-tmux` from the project dir if present, else `~/.ready-tmux` — the per-project layout hook. Templates in `configs/tmux-examples/`.

## Known rough edges

Don't "fix" these silently — they're documented in `README.md`; mention them if a change touches them.

- `install-zsh` **overwrites `~/.zshrc`** with an inline heredoc that has drifted from `configs/zsh-config/.zshrc` (which is the real, current one). Both contain a broken `PATH` entry: `/usr/local/bl:wqn`.
- `copy-configs` targets `.config/` and `.specialconfig`, neither of which exists here — leftover from the Frontend Masters course.
- `hooks/commit-msg` is inert: `head -n 1 ""` lost its `$1` and the guard reads `if [ 0 -ne 0 ]`.
- `switch-cluster` under `set -u` dies with "unbound variable" when called with no argument, before its own error message.
- `install-git-hooks` must be run from inside the target repo (it writes to `./.git/hooks`), so `./run git-hooks` from here installs the zooplus hooks onto *this* repo.
