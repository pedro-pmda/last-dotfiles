# 🧰 last-dotfiles

Personal macOS dev-environment bootstrap: install scripts, dotfiles and window-management config, all plain Bash + Lua. No build step, no package manager, no tests.

Inspired by [Frontend Masters — Developer Productivity 2](https://frontendmasters.com/courses/developer-productivity/).

---

## ⚡ Getting started

```bash
git clone https://github.com/<your-username>/last-dotfiles.git ~/last-dotfiles
cd ~/last-dotfiles
./run --dry          # see what would run
./run home-brew      # then install piece by piece
```

> ⚠️ Clone it at `~/last-dotfiles`. Several scripts and shell aliases hardcode that path.
> ⚠️ Run things **one filter at a time**. A bare `./run` installs everything and rewrites `~/.zshrc`.

---

## 🏃 The task runner

`run` finds every executable file under `runs/` and executes it.

```bash
./run                # run everything
./run tmux           # only scripts whose path matches "tmux"
./run --dry          # print what would run, execute nothing
./run tmux --dry     # combine both
```

- The filter is a plain substring match against the script path.
- Scripts that don't match are listed at the end under `🔎 Scripts filtrados`.
- **A script must be executable** (`chmod +x`) to be picked up — otherwise it's silently skipped.
- `--dry` is only understood by `run` itself and by `runs/utils/copy-configs`. Everything else runs for real.

---

## 📜 Scripts

### `runs/bootstrap/` — installers

| Script | What it does | Notes |
|---|---|---|
| `install-home-brew` | Installs Homebrew if `brew` isn't on `PATH`. Works on macOS and Linux. | Idempotent. Run this first. |
| `install-zsh` | Installs zsh + `fzf`, `kubectx`, `thefuck`, `autojump`; installs Antigen and `kube-ps1`; writes a fresh `~/.zshrc`; sets zsh as the default shell (`chsh`). | ⚠️ **Overwrites `~/.zshrc`.** The heredoc inside the script has drifted from `configs/zsh-config/.zshrc` — the latter is the current one. Back up before running. |
| `install-nvim` | `brew install neovim`. | One-liner; the config lives in `configs/nvim-config/`. |
| `install-tmux` | `brew install tmux` and writes `~/.config/tmux/tmux.conf`. | Prefix remapped to `C-a`, vi copy-mode with `pbcopy`, `hjkl` pane navigation, `prefix + r` reloads. Overwrites the existing conf. |
| `install-docker` | `brew install --cask docker` and opens Docker Desktop. | Fails early with a clear message if Homebrew is missing. |
| `install-node-version-manager` | `brew install nvm`, creates `~/.nvm`, appends the `NVM_DIR` block to `~/.zshrc` if absent, then installs the latest Node and sets it as default. | Apple Silicon paths (`/opt/homebrew`) hardcoded. |
| `install-hammerspoon` | Installs Hammerspoon if missing, asks which profile you want, and **symlinks** `~/.hammerspoon/init.lua` and `~/.hammerspoon/app_config.lua` into this repo. | Interactive. Backs up any real (non-symlink) file it would replace. See [Hammerspoon](#hammerspoon-config--window-management) below. |
| `install-git-hooks` | Copies everything in `hooks/` into `./.git/hooks` and makes it executable. | ⚠️ Acts on the **current directory's** repo — `cd` into the target project first. Running it from here installs the zooplus hooks onto this repo. |

### `runs/infra/`

| Script | What it does | Notes |
|---|---|---|
| `install-k3s` | `brew install k3d`, checks Docker is running, then creates a local cluster `peter-cluster` with 2 agents and `8080:80` on the load balancer. | Verify with `kubectl get nodes`. |
| `switch-cluster <arn>` | `kubectl config use-context <arn>`. | Takes one argument. With none, `set -u` aborts before the friendly error. Wrapped by the `kdev` / `kprod` aliases. |

### `runs/access/`

| Script | What it does |
|---|---|
| `repokeys` | Starts `ssh-agent` if it isn't running, then `ssh-add`s every private key in `~/.ssh` (skipping `*.pub` and `known_hosts*`), reporting each one. |

### `runs/utils/`

| Script | What it does | Notes |
|---|---|---|
| `tmux-sessionizer` | fzf-picks a directory under `~/kaizen` or `~/zooplus`, creates or attaches a tmux session named after it, and runs `ready-tmux` inside. | Aliased to `session`. Works both inside and outside tmux. |
| `ready-tmux` | Runs `./.ready-tmux` from the current directory if it's executable, else `~/.ready-tmux`. | The per-project session-layout hook. Templates in `configs/tmux-examples/`. |
| `copy-configs` | Generic config copier with `--dry` support. | ⚠️ Currently points at `.config/` and `.specialconfig`, neither of which exists in this repo — leftover from the course. Not usable as-is. |

---

## 🗂️ Configs

Files under `configs/` are copied out to their real homes.

### `hammerspoon-config/` — 🎯 window management

`init.lua` is the whole system. On load it runs **Work mode**; the hotkeys are:

| Key | Action |
|---|---|
| `F1`–`F12` | Launch or focus the app bound to that key |
| `Shift+F6` | Emoji picker (`Ctrl+Cmd+Space`) |
| `Shift+F11` | Kaizen mode |
| `Shift+F12` | Reload Hammerspoon |

**Work mode** and **Kaizen mode** both: adapt the layout to the current screen (laptop display → everything fullscreen; external display → the multi-window layout), close every app except Hammerspoon, relaunch the configured apps, tile them, open the configured Chrome/Chromium tab sets, and bring the foreground apps up.

All of it is driven by `app_config.lua`. That file isn't in the repo either — it's a **symlink** to one
of the per-machine profiles in `profiles/`, created by the installer:

```bash
./run hammerspoon
```

```
🖥  ¿Qué perfil de Hammerspoon quieres instalar?
1) mac-personal
2) mac-work
#? 2
🔗 ~/.hammerspoon/init.lua       -> configs/hammerspoon-config/init.lua
🔗 ~/.hammerspoon/app_config.lua -> configs/hammerspoon-config/profiles/mac-work.lua
```

Because they're symlinks, **editing a profile in this repo edits the live config** — `Shift+F12` to
reload. Adding a third machine is just dropping a `.lua` into `profiles/`; it shows up in the menu.
Re-running the installer switches profiles. The first run backs up any real file it replaces to
`~/.hammerspoon/<file>.backup-<timestamp>`.

The installer only prompts when it has a terminal. Inside an unattended `./run`, it keeps the
profile that's already linked, or skips with a notice if the machine was never configured.

The config table holds:

- `functionKeys` — key + modifiers + action (an app name, or `EMOJI` / `KAIZEN_MODE` / `RELOAD_HAMMERSPOON`)
- `workAppLayout` / `kaizenAppLayout` — per-app `position` (`left|center|right`), `vertical` (`top|center|bottom`) and `width`/`height` as fractions (`"1/3"`, `"2/3"`, `"3/4"`, `"4/4"`…)
- `workChromeConfig` / `workChromiumConfig` / `kaizenChromeConfig` / `kaizenChromiumConfig` — the tab sets each mode opens
- `foregroundApps` — what ends up on top per mode
- `appPaths` — explicit `.app` paths for apps outside `/Applications` (`launchOrFocus` can't find those)
- `appLaunchDelay`, `debugMode`

`profiles/mac-work.lua` and `profiles/mac-personal.lua` are self-contained per-machine profiles —
**keep new options in sync across all of them**.

### `zsh-config/.zshrc`

The current shell config: Antigen + oh-my-zsh, Powerlevel10k, autosuggestions/completions/syntax-highlighting, `z`, fzf-tab, `kube-ps1` in the prompt, nvm, SDKMAN, and the aliases below.

| Alias | Expands to |
|---|---|
| `run` | the task runner in this repo |
| `session` | `tmux-sessionizer` |
| `ready-tmux` | `ready-tmux` |
| `repokeys` | `repokeys` |
| `k`, `kgp`, `kaf`, `kn`, `kc` | kubectl / kubens / kubectx shorthands |
| `kdev`, `kprod` | `switch-cluster` against the zoobrain EKS clusters |
| `kpfbd` | background port-forward to the zoobrain DB |
| `gst`, `gl` | `git status`, pretty `git log` |
| `dpsp` | `docker ps` as a compact table |
| `tf`, `cls` | `terraform`, `clear` |

### `git-config/`

`.gitconfig` uses `includeIf "gitdir:…"` to switch identity per directory: `~/zooplus/` pulls in `.gitconfig_zooplus` (work email), `~/kaizen/` pulls in `.gitconfig_kaizen` (personal email). Both set `pull.rebase = true` and a shared global ignore file.

### `nvim-config/init.lua`

A [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) config, single file, heavily commented. Copy to `~/.config/nvim/init.lua`.

### `tmux-examples/`

Templates for the per-project `.ready-tmux` hook — copy one into a project as `.ready-tmux` (and `chmod +x`), or to `~/.ready-tmux` as the global default:

- `.ready-tmux-default` — editor / frontend / backend / infra / git windows with documented splits
- `.ready-tmux-example-1` — minimal editor / shell / logs / git
- `.ready-tmux-example-2` — project-specific: runs the UI dev server and `kdev && kgp`

---

## 🪝 Git hooks

`hooks/` is **not** for this repo — `install-git-hooks` copies these into a target project. They encode zooplus conventions:

| Hook | What it enforces |
|---|---|
| `prepare-commit-msg` | Extracts a `ZOOB-<n>` id from the branch name and pre-fills the message as `REVISION \| ZOOB-<n>:`. |
| `commit-msg` | Meant to require `<MAJOR\|MINOR\|REVISION> \| [<STORY>:] <MESSAGE>`. ⚠️ Currently inert — `head -n 1 ""` lost its `$1` and the guard is `if [ 0 -ne 0 ]`. |
| `pre-commit` | For staged `.vue`/`.ts` files under `ui/` (excluding `__tests__/`): runs `npm run format` and `npm run lint:fix`, re-stages them, and blocks the commit on lint errors. |

Commits **in this repo** instead follow Conventional Commits with an emoji:

```
feat(hammerspoon): 🎯 update config layout
fix(zsh): 🐛 correct PATH export
```

---

## 🐛 Known rough edges

Documented rather than silently patched:

- `install-zsh` overwrites `~/.zshrc` with a version that has drifted from `configs/zsh-config/.zshrc`.
- Both zshrc variants contain a broken `PATH` entry: `/usr/local/bl:wqn`.
- `copy-configs` points at paths that don't exist in this repo.
- `hooks/commit-msg` never fails a commit.
- `switch-cluster` with no argument dies on `set -u` before printing its own error.
- Apple Silicon (`/opt/homebrew`) and the `~/last-dotfiles` clone path are hardcoded in several places.
