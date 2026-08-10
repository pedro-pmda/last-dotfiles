# CLAUDE.md

Personal dotfiles / dev-environment bootstrap for macOS **and Linux**. Plain Bash + Lua — no build step, no package manager, no tests. `README.md` documents every script for humans; this file is the working context.

## Map

| Path | What it is |
|---|---|
| `run` | Entrypoint. Finds every executable under `runs/` and runs it. |
| `runs/bootstrap/` | Installers: zsh, nvim, tmux, docker, hammerspoon (macOS), wm-linux (Linux), homebrew, nvm, git-hooks |
| `runs/infra/` | `install-k3s` (k3d cluster), `switch-cluster` (kubectl context) |
| `runs/access/` | `repokeys` — loads every private key in `~/.ssh` into ssh-agent |
| `runs/utils/` | `ready-tmux`, `tmux-sessionizer` |
| `configs/` | Files copied to their real homes: `hammerspoon-config/` (macOS), `wm-linux-config/` (Linux), `nvim-config/`, `zsh-config/`, `git-config/`, `tmux-examples/` |
| `hooks/` | Git hooks installed into a **target** repo by `install-git-hooks`. zooplus conventions (`ZOOB-*` Jira IDs, `MAJOR\|MINOR\|REVISION \| ...`, `ui/` Prettier+ESLint). Not meant to run on this repo. |

## Running tasks

```bash
./run                # everything under runs/
./run tmux           # only scripts whose path matches the substring
./run --dry          # print, execute nothing
./run tmux --dry
```

- `--dry` is honored by `run` only. Installers have no dry-run — `./run <filter>` without `--dry` really does `brew install`.
- Scripts must be `chmod +x` or `run` silently ignores them.

## Conventions

- Bash: `#!/usr/bin/env bash` + `set -euo pipefail`, emoji-prefixed `echo` progress lines.
- Messages mix Spanish and English — **match the file you're editing**, don't normalize.
- Installers must be idempotent: check `command -v` / existing dirs, don't fail on re-run.
- Homebrew assumed on both OSes (Linuxbrew on Linux). Resolve its prefix dynamically — `brew shellenv` / `$(brew --prefix <formula>)` — never hardcode `/opt/homebrew` or `/home/linuxbrew/.linuxbrew`.
- Cross-platform scripts follow one of two idioms, matching `install-home-brew` / `install-wm-linux`:
  1. **Branch inside one script** with `[[ "$(uname -s)" == "Linux" ]]` when both OSes need real (if different) logic — e.g. `install-docker`, `install-zsh`, `install-tmux`, `install-k3s`.
  2. **Guard-and-skip, one script per OS** when the tool itself only exists on one platform — e.g. `install-hammerspoon` (Darwin-only) / `install-wm-linux` (Linux-only), a symmetric pair.
- Several scripts assume the repo is cloned at `~/last-dotfiles`.
- Commits: Conventional Commits + emoji — `feat(hammerspoon): 🎯 update config layout`, `fix(zsh): 🐛 ...`.

## Hammerspoon

`configs/hammerspoon-config/init.lua` is the whole window/hotkey system: F1–F12 launch or focus apps, `Shift+F11` Kaizen mode, `Shift+F12` reload, `Shift+F6` emoji picker. On startup it runs Work mode. Layouts (app, `"1/3"`-style width/height fractions, position) and browser tab sets live in the config table, never in `init.lua`.

`init.lua` does `require("app_config")`. `app_config.lua` is not in the repo — it's a symlink into `configs/hammerspoon-config/profiles/`, one self-contained file per machine (`mac-work.lua`, `mac-personal.lua`). `install-hammerspoon` lists them, asks which one, and symlinks both `init.lua` and the chosen profile into `~/.hammerspoon`. A new machine is a new `.lua` in `profiles/`; keep new options in sync across all of them.

Since they're symlinks, editing a profile edits the live config — no re-install needed, just `Shift+F12`.

Apps outside `/Applications` need an entry in `appPaths` (only `mac-work.lua` has one today) — `hs.application.launchOrFocus` won't find them.

`install-hammerspoon` guard-skips on Linux (`uname -s != Darwin`) — Hammerspoon itself is macOS-only.

### Layout schema

A layout entry is `{ name, position, width, vertical, height, screen? }`. Fractions are looked up in `getSizeFraction` — only thirds, quarters and `"2/2"` exist; anything else silently falls back to the full screen size.

- `screen` is `"primary"` (default) or `"secondary"`. `resolveScreen` picks the first screen whose `id()` isn't the primary's, and **falls back to the primary when there's no second display** so windows never land off-screen.
- `minWidthForTiling` (default 2000) is the tiling threshold. `shouldTile()` compares it against the primary screen's width; below it, `moveWindow` overrides every entry to centered fullscreen. This is decided per call, in locals — the profile table is never mutated, so docking/undocking needs no reload. Don't go back to matching `screen:name()`: the built-in display is `"Built-in Liquid Retina XDR Display"` on M-series MacBook Pros but `"Built-in Retina Display"` elsewhere.
- Because `center` is symmetric, a three-column split forces the left and right columns to be equal — `1/4 · 2/4 · 1/4` is the only one the current fractions allow. `mac-work.lua` uses it on a 3440px ultrawide: comms left, work surface center, **AI chats alone in the right column** (they stop being always-visible the moment anything else shares that slot).

## Linux window manager (lua-wm)

`configs/wm-linux-config/init.lua` is the Hammerspoon equivalent for Linux: same `app_config.lua`-symlink-per-profile pattern (`profiles/linux-personal.lua` today, no `linux-work.lua` yet), but running as a `lua5.3` daemon via `lgi`/GTK, `Wnck` (window management), `Keybinder` (hotkeys) and `libnotify`, since there's no Hammerspoon-style accessibility API on Linux. `install-wm-linux` guard-skips on macOS, installs the apt packages, symlinks the config, and registers both a `systemd --user` service and an XDG autostart entry (Cinnamon/LightDM don't reliably fire `graphical-session.target` on login, so autostart is the primary boot path — systemd is for manual restart/logs). Reload after editing a profile with `systemctl --user restart lua-wm`; logs via `journalctl --user -u lua-wm -f`.

## tmux

`tmux-sessionizer` fzf-picks a dir under `~/kaizen` or `~/zooplus`, creates/attaches a session named after it, and runs `ready-tmux` inside. `ready-tmux` executes `./.ready-tmux` from the project dir if present, else `~/.ready-tmux` — the per-project layout hook. Templates in `configs/tmux-examples/`.

## nvim & zsh

Same symlink idiom as Hammerspoon, no profiles: `install-nvim` symlinks `configs/nvim-config` to `~/.config/nvim`, and `install-zsh` symlinks `configs/zsh-config/.zshrc` to `~/.zshrc`. `configs/zsh-config/.zshrc` is the single source of truth — editing it edits the live shell config directly, no re-run needed. Both installers derive the repo root from the script's own location (not an assumed `~/last-dotfiles`) and back up any pre-existing real file to `<dest>.backup-<timestamp>` before linking.

## Known rough edges

Don't "fix" these silently — they're documented in `README.md`; mention them if a change touches them.

- `hooks/commit-msg` is inert: `head -n 1 ""` lost its `$1` and the guard reads `if [ 0 -ne 0 ]`.
- `switch-cluster` under `set -u` dies with "unbound variable" when called with no argument, before its own error message.
- `install-git-hooks` must be run from inside the target repo (it writes to `./.git/hooks`), so `./run git-hooks` from here installs the zooplus hooks onto *this* repo.
