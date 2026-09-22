# CLAUDE.md

Personal dotfiles / dev-environment bootstrap for macOS **and Linux**. Plain Bash + Lua — no build step, no package manager. Three test suites, all for things you can't verify by reading: `configs/wm-linux-config/test/` (lua-wm only runs on Linux), `configs/hammerspoon-config/test/` (which pixels each window actually lands on) and `test/run-interactive-test.py` (drives `./run -i` through a real pty). The two window-manager suites share a trick: stub the platform API, run the real `init.lua` under `luajit`. `README.md` documents every script for humans; this file is the working context.

## Map

| Path | What it is |
|---|---|
| `run` | Entrypoint. No filter → `runs/bootstrap/` in `BOOTSTRAP_ORDER`. With a filter → substring match over all of `runs/`. |
| `runs/lib/` | Sourced helpers, **not executable** so `run` skips them: `brew-env.sh` (`ensure_brew`), `apt.sh` (`require_apt`, `apt_install`) |
| `runs/bootstrap/` | Installers: homebrew, zsh, nvm, nvim, tmux, docker, kubernetes, git-config, ghostty, cli-tools, chromium, chrome-canary, freelens, calibre, obsidian, spotify, hammerspoon (macOS), wm-linux (Linux), gnome-terminal (Linux), nas-mount (Linux). One installer per app, each handling both OSes unless noted otherwise. |
| `runs/infra/` | `install-k3s` (k3d cluster), `switch-cluster` (kubectl context) |
| `runs/access/` | `repokeys` — loads every private key in `~/.ssh` into an existing ssh-agent |
| `runs/utils/` | `ready-tmux`, `tmux-sessionizer`, `install-git-hooks` |
| `configs/` | **Everything here is symlinked** to where the tool expects it — editing a file here edits the live config. `zsh-config/` (`.zshrc` + `.p10k.zsh`), `nvim-config/`, `tmux-config/`, `tmux-examples/`, `ghostty-config/`, `git-config/`, `cli-config/` (k9s, htop, glow, bat, lsd), `hammerspoon-config/` (macOS), `wm-linux-config/` (Linux), `gnome-terminal-config/` (Linux — not a symlink, it's the one exception, see Conventions below). Full destination table in `README.md`. |
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
- **Configs are applied by symlink, never generated and never copied.** Adding a config means: file into `configs/<thing>/`, then an installer that links it and backs up a real file it would replace to `<dest>.backup-<timestamp>`. `install-tmux` used to generate its `tmux.conf` with a heredoc; that's what made it the one config you couldn't edit from the repo, and it was fixed rather than kept as a pattern. `gnome-terminal-config/catppuccin-latte.dconf` is the one deliberate exception — GNOME Terminal keeps profiles in `dconf`, not a file, so `install-gnome-terminal` `dconf load`s it into a fixed-UUID profile instead of symlinking.
- Anything OS-dependent inside a config gets resolved **at use time, not at install time** — `tmux-config/clipboard.sh` picks the clipboard command on every yank, because `$WAYLAND_DISPLAY` describes the session, not the machine. Baking the choice in at install time is what made the old `tmux.conf` non-portable.
- Strip user-specific absolute paths when versioning someone's live config (`k9s`'s `screenDumpDir` held `/Users/<user>/Library/...`). Prefer letting the tool use its own per-platform default.
- Some tools write their own config back (nvim's `lazy-lock.json`, `htoprc`, k9s's `config.yaml`). Through a symlink that shows up as repo changes — expected, not a bug.
- Homebrew assumed on both OSes (Linuxbrew on Linux). **Never hardcode a prefix**: in scripts `source runs/lib/brew-env.sh` and call `ensure_brew`; in `.zshrc` use `$HOMEBREW_PREFIX` (exported by `brew shellenv`) rather than forking `brew --prefix` on every shell start. The candidate list lives in one place now — `.zshrc` keeps an inline copy only because it can't source a path inside the repo.
- System packages on Linux go through `runs/lib/apt.sh`, never a bare `sudo apt-get install`: it does the `apt-get update` that was missing and fails readably on non-Debian.
- Prefer POSIX over GNU-isms in anything that runs on both: `find -perm -111` not `/111`, `command -v` not `which`, `grep -q -E` not `--quiet --extended-regexp`. macOS ships BSD userland and bash 3.2 — no `mapfile`, no `declare -A`, and iterating `"${arr[@]}"` on an empty array under `set -u` is an error, so guard with a length check.
- Cross-platform scripts follow one of two idioms, matching `install-home-brew` / `install-wm-linux`:
  1. **Branch inside one script** with `[[ "$(uname -s)" == "Linux" ]]` when both OSes need real (if different) logic — e.g. `install-docker`, `install-zsh`, `install-tmux`. (`install-k3s` has no `uname` at all: k3d and Docker behave the same either way.)
  2. **Guard-and-skip, one script per OS** when the tool itself only exists on one platform — e.g. `install-hammerspoon` (Darwin-only) / `install-wm-linux` (Linux-only), a symmetric pair.
- Every script derives the repo root from `${BASH_SOURCE[0]}`. The `.zshrc` aliases derive it too, via `DOTFILES_ROOT` (resolved from the `~/.zshrc` symlink target) — they used to hardcode `~/last-dotfiles`, which broke for anyone who clones the repo elsewhere (e.g. `~/kaizen/last-dotfiles`).
- Third-party GUI apps on Linux (`install-obsidian`, `install-spotify`) install via **Flatpak/Flathub**, not snap — Linux Mint blocks snapd by default (`nosnap.pref`) but ships Flatpak enabled out of the box. macOS side still uses `brew install --cask`.
- Commits: Conventional Commits + emoji — `feat(hammerspoon): 🎯 update config layout`, `fix(zsh): 🐛 ...`.

## Ghostty

`configs/ghostty-config/config` → `~/.config/ghostty/config`, a path Ghostty honours on both OSes.

The trap: on macOS Ghostty *also* reads `~/Library/Application Support/com.mitchellh.ghostty/config`, and **that file wins** for any key set in both (verified — a `font-size` in the XDG file had no effect). `install-ghostty` moves it aside with a backup; without that the symlink is decoration. If it reappears, something recreated it and is silently overriding the repo. `ghostty +show-config` shows what's actually in effect.

Linux has no official apt package, so the installer links the config and points at the download page instead of guessing.

## Hammerspoon

`configs/hammerspoon-config/init.lua` is the whole window/hotkey system: F1–F12 launch or focus apps, `F11` Work mode, `F12` reset layout, `Shift+F11` Kaizen mode, `Shift+F12` reload, `Shift+F10` emoji picker (per `mac-work.lua` — each profile binds its own keys). On startup it runs Work mode. Layouts and browser tab sets live in the config table, never in `init.lua`.

**Two profile schemas coexist**, chosen by what the profile declares — there is no flag:

- **Sides** (`mac-work.lua`, declares `leftApps`/`rightApps`): everything lives at 50%, and a double tap expands to 2/3 centred. See below.
- **Grid** (`mac-personal.lua`, declares `workAppLayout`): the original per-app `{position, width, …}` table. Untouched, and the suite's scenario E proves it behaves identically before and after the sides work.

`init.lua` does `require("app_config")`. `app_config.lua` is not in the repo — it's a symlink into `configs/hammerspoon-config/profiles/`, one self-contained file per machine (`mac-work.lua`, `mac-personal.lua`). `install-hammerspoon` lists them, asks which one, and symlinks both `init.lua` and the chosen profile into `~/.hammerspoon`. A new machine is a new `.lua` in `profiles/`; keep new options in sync across all of them.

Since they're symlinks, editing a profile edits the live config — no re-install needed, just `Shift+F12`.

Apps outside `/Applications` need an entry in `appPaths` (only `mac-work.lua` has one today) — `hs.application.launchOrFocus` won't find them.

`install-hammerspoon` guard-skips on Linux (`uname -s != Darwin`) — Hammerspoon itself is macOS-only.

The **app-name vocabulary is per-OS and can't be shared**: macOS uses `.app` names (plus `appIds` bundle IDs), Linux uses the `.desktop` `Name=` matched against `WM_CLASS`. They coincide by luck for vendor apps and diverge otherwise — `IntelliJ IDEA Ultimate` (Linux) vs `IntelliJ IDEA` (macOS).

### Sides schema (`mac-work.lua`)

The profile is two lists of names — `leftApps` and `rightApps` — and `init.lua` derives the geometry (`buildSideLayout`). Everything sits at 50%; there are no coordinates in the profile.

- **The side decides what you can see at once.** Two apps on the same side always cover each other, so the criterion is which pairs you need simultaneously, not where each looks nicest. Left is the writing surface (IDEs, DBeaver, Obsidian — genuinely mutually exclusive); right is everything that accompanies it. That makes editor+terminal, editor+browser, editor+AI and notes+browser all work.
- **A double tap expands to 2/3 centred, and again returns it to its half.** `expandFull` overrides the expanded size to full screen (only Chrome Canary, for demos).
- **The rung is measured, not remembered.** `isExpanded` compares the window's real width against the expanded width, so moving windows by hand or with Rectangle can't desync it. Only the *name* of the expanded app is kept, and it's verified by measuring before use.
- `hs.window.animationDuration = 0` is a **correctness requirement**, not cosmetics: while animating, `win:frame()` returns the *destination* frame, so every measurement would lie.
- Don't write `lastPressAt[name] = double and nil or now` — in Lua that yields `now` when `double` is true (`nil` is falsy, so `or` wins). That exact bug made a third rapid tap read as another double; scenario B6 locks it down.
- **`modes` separates "where each app goes" from "what this mode launches"**, which the grid schema conflated — that's why Kaizen used to leave 10 of 18 keys unplaced.

### Layout schema (grid, `mac-personal.lua`)

A layout entry is `{ name, position, width, vertical, height, screen? }`. Fractions are looked up in `getSizeFraction` — only thirds, quarters and `"2/2"` exist; anything else silently falls back to the full screen size.

- `screen` is `"primary"` (default) or `"secondary"`. `resolveScreen` picks the first screen whose `id()` isn't the primary's, and **falls back to the primary when there's no second display** so windows never land off-screen.
- `minWidthForTiling` (default 2000) is the tiling threshold. `shouldTile()` compares it against the primary screen's width; below it, `moveWindow` overrides every entry to centered fullscreen. This is decided per call, in locals — the profile table is never mutated, so docking/undocking needs no reload. Don't go back to matching `screen:name()`: the built-in display is `"Built-in Liquid Retina XDR Display"` on M-series MacBook Pros but `"Built-in Retina Display"` elsewhere.
- Because `center` is symmetric, a three-column split forces the left and right columns to be equal — `1/4 · 2/4 · 1/4` is the only one the current fractions allow. `mac-work.lua` used to run it on the ultrawide; it now uses the sides schema instead.

### Comms windows

Four times a day (09:30 / 11:30 / 13:30 / 15:30, weekdays), work mode only, `mac-work.lua`'s `modes.work.comms`. Two apps come up at 50/50 — Slack always on the left, since it's what you triage first — with a **📬 Tiempo de Comunicación** alert, and after 10 minutes `resetLayout()` puts everything back. Reusing the same function as `F12` is the point: nothing has to remember what was there before, it's recomputed.

**Postponed while the camera or mic is in use** (`hs.camera` / `hs.audiodevice`) — a window landing on top of a shared screen is a disaster. Retries every 2 minutes up to a cap, and the give-up path shows a **visible** alert, not a `debugPrint` nobody sees.

### Tests

`configs/hammerspoon-config/test/suite.sh` stubs `hs` wholesale and runs the real `init.lua` under `luajit` (Hammerspoon not required), the same trick as the lua-wm suite. Five scenarios: the 50/50 split, the expand/collapse cycle, the comms windows (including the postpone-in-a-call path), the laptop-only fallback, and that the grid schema still behaves for `mac-personal.lua`. The harness pins `os.date("*t").wday` — otherwise the weekday filter would pass Monday to Friday and fail on Saturday. If you touch `init.lua`, run the suite against the previous version too and check that it **fails** — scenario E is the exception: it must pass against both, because that's what proves `mac-personal.lua` didn't change.

## Linux window manager (lua-wm)

`configs/wm-linux-config/init.lua` is the Hammerspoon equivalent for Linux: same `app_config.lua`-symlink-per-profile pattern (`profiles/linux-personal.lua` today, no `linux-work.lua` yet), but running as a `lua5.3` daemon via `lgi`/GTK, `Wnck` (window management), `Keybinder` (hotkeys) and `libnotify`, since there's no Hammerspoon-style accessibility API on Linux. `install-wm-linux` guard-skips on macOS, installs the apt packages, symlinks the config, and registers both a `systemd --user` service and an XDG autostart entry (Cinnamon/LightDM don't reliably fire `graphical-session.target` on login, so autostart is the primary boot path — systemd is for manual restart/logs). Reload after editing a profile with `systemctl --user restart lua-wm`; logs via `journalctl --user -u lua-wm -f`.

Parity with Hammerspoon: same `functionKeys` schema and the same geometry code. The action vocabulary is smaller though — `KAIZEN_MODE`, `RESET_LAYOUT`, `EMOJI`, `RELOAD_WM`≡`RELOAD_HAMMERSPOON` — no `WORK_MODE`: Linux has only one profile (`linux-personal.lua`) for now, so init.lua doesn't carry Work Mode at all (macOS still does). Still unimplemented: `appIds`/`appPaths` (macOS concepts) and `screen = "secondary"`.

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
