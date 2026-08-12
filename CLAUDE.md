# CLAUDE.md

Personal dotfiles / dev-environment bootstrap for macOS **and Linux**. Plain Bash + Lua — no build step, no package manager. Two test suites, both for things you can't verify by reading: `configs/wm-linux-config/test/` (lua-wm only runs on Linux) and `test/run-interactive-test.py` (drives `./run -i` through a real pty). `README.md` documents every script for humans; this file is the working context.

## Map

| Path | What it is |
|---|---|
| `run` | Entrypoint. No filter → `runs/bootstrap/` in `BOOTSTRAP_ORDER`. With a filter → substring match over all of `runs/`. |
| `runs/lib/` | Sourced helpers, **not executable** so `run` skips them: `brew-env.sh` (`ensure_brew`), `apt.sh` (`require_apt`, `apt_install`) |
| `runs/bootstrap/` | Installers: homebrew, zsh, nvm, nvim, tmux, docker, kubernetes, git-config, ghostty, cli-tools, chromium, chrome-canary, freelens, obsidian, spotify, hammerspoon (macOS), wm-linux (Linux). One installer per app, each handling both OSes. |
| `runs/infra/` | `install-k3s` (k3d cluster), `switch-cluster` (kubectl context) |
| `runs/access/` | `repokeys` — loads every private key in `~/.ssh` into an existing ssh-agent |
| `runs/utils/` | `ready-tmux`, `tmux-sessionizer`, `install-git-hooks` |
| `configs/` | **Everything here is symlinked** to where the tool expects it — editing a file here edits the live config. `zsh-config/` (`.zshrc` + `.p10k.zsh`), `nvim-config/`, `tmux-config/`, `tmux-examples/`, `ghostty-config/`, `git-config/`, `cli-config/` (k9s, htop, glow), `hammerspoon-config/` (macOS), `wm-linux-config/` (Linux). Full destination table in `README.md`. |
| `hooks/` | Git hooks installed into a **target** repo by `install-git-hooks`. zooplus conventions (`ZOOB-*` Jira IDs, `MAJOR\|MINOR\|REVISION \| ...`, `ui/` Prettier+ESLint). Not meant to run on this repo. |

## Running tasks

```bash
./run                # runs/bootstrap only, in BOOTSTRAP_ORDER
./run -i             # interactive picker over all of runs/, filtered by OS
./run tmux           # only scripts whose path matches the substring, across all of runs/
./run --dry          # print, execute nothing
./run -i --dry
```

- `--dry` is honored by `run` only. Installers have no dry-run — `./run <filter>` without `--dry` really does `brew install`.
- Scripts must be `chmod +x` or `run` silently ignores them. `runs/lib/` relies on this.
- The bootstrap order in `run` is a **contract** (`install-home-brew` first). `find` doesn't sort, and getting this wrong meant brew wasn't on `PATH` yet for whoever ran next — different per OS and per filesystem.
- Anything imperative or interactive belongs outside `runs/bootstrap/`, so a bare `./run` can't fire it.
- A failing script doesn't stop the rest; `run` summarises failures and exits 1.
- **Every script declares itself in its own header** — `run -i` reads these, so a new script never means editing `run`:
  ```bash
  # run-os: darwin | linux | any     (default: any — controls whether -i lists it here)
  # run-desc: 🎯 Qué hace, una línea
  ```
  Keep `run-os` honest: it's what makes the menu show `install-hammerspoon` on macOS and `install-wm-linux` on Linux. The in-script `uname` guard stays too — the header controls the menu, the guard protects a direct call.
- Selections from `-i` still run through `BOOTSTRAP_ORDER`, so picking Homebrew and Neovim installs Homebrew first whatever order you ticked them.

## Conventions

- Bash: `#!/usr/bin/env bash` + `set -euo pipefail`, emoji-prefixed `echo` progress lines.
- Messages mix Spanish and English — **match the file you're editing**, don't normalize.
- Installers must be idempotent: check `command -v` / existing dirs, don't fail on re-run.
- **Configs are applied by symlink, never generated and never copied.** Adding a config means: file into `configs/<thing>/`, then an installer that links it and backs up a real file it would replace to `<dest>.backup-<timestamp>`. `install-tmux` used to generate its `tmux.conf` with a heredoc; that's what made it the one config you couldn't edit from the repo, and it was fixed rather than kept as a pattern.
- Anything OS-dependent inside a config gets resolved **at use time, not at install time** — `tmux-config/clipboard.sh` picks the clipboard command on every yank, because `$WAYLAND_DISPLAY` describes the session, not the machine. Baking the choice in at install time is what made the old `tmux.conf` non-portable.
- Strip user-specific absolute paths when versioning someone's live config (`k9s`'s `screenDumpDir` held `/Users/<user>/Library/...`). Prefer letting the tool use its own per-platform default.
- Some tools write their own config back (nvim's `lazy-lock.json`, `htoprc`, k9s's `config.yaml`). Through a symlink that shows up as repo changes — expected, not a bug.
- Homebrew assumed on both OSes (Linuxbrew on Linux). **Never hardcode a prefix**: in scripts `source runs/lib/brew-env.sh` and call `ensure_brew`; in `.zshrc` use `$HOMEBREW_PREFIX` (exported by `brew shellenv`) rather than forking `brew --prefix` on every shell start. The candidate list lives in one place now — `.zshrc` keeps an inline copy only because it can't source a path inside the repo.
- System packages on Linux go through `runs/lib/apt.sh`, never a bare `sudo apt-get install`: it does the `apt-get update` that was missing and fails readably on non-Debian.
- Prefer POSIX over GNU-isms in anything that runs on both: `find -perm -111` not `/111`, `command -v` not `which`, `grep -q -E` not `--quiet --extended-regexp`. macOS ships BSD userland and bash 3.2 — no `mapfile`, no `declare -A`, and iterating `"${arr[@]}"` on an empty array under `set -u` is an error, so guard with a length check.
- Cross-platform scripts follow one of two idioms, matching `install-home-brew` / `install-wm-linux`:
  1. **Branch inside one script** with `[[ "$(uname -s)" == "Linux" ]]` when both OSes need real (if different) logic — e.g. `install-docker`, `install-zsh`, `install-tmux`. (`install-k3s` has no `uname` at all: k3d and Docker behave the same either way.)
  2. **Guard-and-skip, one script per OS** when the tool itself only exists on one platform — e.g. `install-hammerspoon` (Darwin-only) / `install-wm-linux` (Linux-only), a symmetric pair.
- Every script derives the repo root from `${BASH_SOURCE[0]}`. Only the `.zshrc` aliases hardcode `~/last-dotfiles`.
- Third-party GUI apps on Linux (`install-obsidian`, `install-spotify`) install via **Flatpak/Flathub**, not snap — Linux Mint blocks snapd by default (`nosnap.pref`) but ships Flatpak enabled out of the box. macOS side still uses `brew install --cask`.
- Commits: Conventional Commits + emoji — `feat(hammerspoon): 🎯 update config layout`, `fix(zsh): 🐛 ...`.

## Ghostty

`configs/ghostty-config/config` → `~/.config/ghostty/config`, a path Ghostty honours on both OSes.

The trap: on macOS Ghostty *also* reads `~/Library/Application Support/com.mitchellh.ghostty/config`, and **that file wins** for any key set in both (verified — a `font-size` in the XDG file had no effect). `install-ghostty` moves it aside with a backup; without that the symlink is decoration. If it reappears, something recreated it and is silently overriding the repo. `ghostty +show-config` shows what's actually in effect.

Linux has no official apt package, so the installer links the config and points at the download page instead of guessing.

## Hammerspoon

`configs/hammerspoon-config/init.lua` is the whole window/hotkey system: F1–F12 launch or focus apps, `F11` Work mode, `F12` reset layout, `Shift+F11` Kaizen mode, `Shift+F12` reload, `Shift+F10` emoji picker (per `mac-work.lua` — each profile binds its own keys). On startup it runs Work mode. Layouts (app, `"1/3"`-style width/height fractions, position) and browser tab sets live in the config table, never in `init.lua`.

`init.lua` does `require("app_config")`. `app_config.lua` is not in the repo — it's a symlink into `configs/hammerspoon-config/profiles/`, one self-contained file per machine (`mac-work.lua`, `mac-personal.lua`). `install-hammerspoon` lists them, asks which one, and symlinks both `init.lua` and the chosen profile into `~/.hammerspoon`. A new machine is a new `.lua` in `profiles/`; keep new options in sync across all of them.

Since they're symlinks, editing a profile edits the live config — no re-install needed, just `Shift+F12`.

Apps outside `/Applications` need an entry in `appPaths` (only `mac-work.lua` has one today) — `hs.application.launchOrFocus` won't find them.

`install-hammerspoon` guard-skips on Linux (`uname -s != Darwin`) — Hammerspoon itself is macOS-only.

The **app-name vocabulary is per-OS and can't be shared**: macOS uses `.app` names (plus `appIds` bundle IDs), Linux uses the `.desktop` `Name=` matched against `WM_CLASS`. They coincide by luck for vendor apps and diverge otherwise — `IntelliJ IDEA Ultimate` (Linux) vs `IntelliJ IDEA` (macOS).

### Layout schema

A layout entry is `{ name, position, width, vertical, height, screen? }`. Fractions are looked up in `getSizeFraction` — only thirds, quarters and `"2/2"` exist; anything else silently falls back to the full screen size.

- `screen` is `"primary"` (default) or `"secondary"`. `resolveScreen` picks the first screen whose `id()` isn't the primary's, and **falls back to the primary when there's no second display** so windows never land off-screen.
- `minWidthForTiling` (default 2000) is the tiling threshold. `shouldTile()` compares it against the primary screen's width; below it, `moveWindow` overrides every entry to centered fullscreen. This is decided per call, in locals — the profile table is never mutated, so docking/undocking needs no reload. Don't go back to matching `screen:name()`: the built-in display is `"Built-in Liquid Retina XDR Display"` on M-series MacBook Pros but `"Built-in Retina Display"` elsewhere.
- Because `center` is symmetric, a three-column split forces the left and right columns to be equal — `1/4 · 2/4 · 1/4` is the only one the current fractions allow. `mac-work.lua` uses it on a 3440px ultrawide: comms left, work surface center, **AI chats alone in the right column** (they stop being always-visible the moment anything else shares that slot).

## Linux window manager (lua-wm)

`configs/wm-linux-config/init.lua` is the Hammerspoon equivalent for Linux: same `app_config.lua`-symlink-per-profile pattern (`profiles/linux-personal.lua` today, no `linux-work.lua` yet), but running as a `lua5.3` daemon via `lgi`/GTK, `Wnck` (window management), `Keybinder` (hotkeys) and `libnotify`, since there's no Hammerspoon-style accessibility API on Linux. `install-wm-linux` guard-skips on macOS, installs the apt packages, symlinks the config, and registers both a `systemd --user` service and an XDG autostart entry (Cinnamon/LightDM don't reliably fire `graphical-session.target` on login, so autostart is the primary boot path — systemd is for manual restart/logs). Reload after editing a profile with `systemctl --user restart lua-wm`; logs via `journalctl --user -u lua-wm -f`.

Parity with Hammerspoon: same `functionKeys` schema, same actions (`WORK_MODE`, `KAIZEN_MODE`, `RESET_LAYOUT`, `EMOJI`, `RELOAD_WM`≡`RELOAD_HAMMERSPOON`) and the same geometry code. Still unimplemented: `appIds`/`appPaths` (macOS concepts) and `screen = "secondary"`.

The tiling decision is taken **in locals, per window**, exactly as on macOS — never written into the profile table. That's the fix for a bug where mutating it lost the original fractions until the service was restarted. The threshold is `minWidthForTiling` by geometry; `xrandr` is only a fallback for when Gdk won't give a workarea.

The Lua interpreter and `lgi`'s multiarch triplet are discovered in `install-wm-linux` (`dpkg-architecture` / `gcc -print-multiarch`): hardcoding `x86_64-linux-gnu` meant the daemon never came up on arm64.

`configs/wm-linux-config/test/suite.sh` stubs `lgi` and runs the real `init.lua` under `luajit` from macOS. If you touch `init.lua`, run the suite against the previous version too and check that it **fails**.

## tmux

`tmux-sessionizer` fzf-picks a dir under `~/kaizen` or `~/zooplus`, creates/attaches a session named after it, and runs `ready-tmux` inside. `ready-tmux` executes `./.ready-tmux` from the project dir if present, else `~/.ready-tmux` — the per-project layout hook. Templates in `configs/tmux-examples/`.

## nvim & zsh

Same symlink idiom as Hammerspoon, no profiles: `install-nvim` symlinks `configs/nvim-config` to `~/.config/nvim`, and `install-zsh` symlinks `configs/zsh-config/.zshrc` to `~/.zshrc`. `configs/zsh-config/.zshrc` is the single source of truth — editing it edits the live shell config directly, no re-run needed. Both installers derive the repo root from the script's own location (not an assumed `~/last-dotfiles`) and back up any pre-existing real file to `<dest>.backup-<timestamp>` before linking.

## Known rough edges

Don't "fix" these silently — they're documented in `README.md`; mention them if a change touches them.

- `install-git-hooks` must be run from inside the target repo (it writes to that repo's hooks dir). It lives in `runs/utils/` so a bare `./run` won't fire it.
- The generated `~/.config/tmux/tmux.conf` bakes the clipboard command in at install time, so it isn't portable between machines — re-run `./run tmux` per machine.
- `install-zsh` installs `autojump` but nothing sources it; the `rupa/z` bundle already covers it.
- lua-wm ignores `screen = "secondary"`.
- Non-Debian Linux is unsupported by design: `runs/lib/apt.sh` exits with a message.
