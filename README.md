# 🧰 last-dotfiles

Personal dev-environment bootstrap for macOS and Linux: install scripts, dotfiles and window-management config, all plain Bash + Lua. No build step, no package manager. The only tests are in `configs/wm-linux-config/test/`, and they exist because that code only runs on Linux.

Inspired by [Frontend Masters — Developer Productivity 2](https://frontendmasters.com/courses/developer-productivity/).

---

## ⚡ Getting started

```bash
git clone https://github.com/<your-username>/last-dotfiles.git ~/last-dotfiles
cd ~/last-dotfiles
./run --dry          # see the bootstrap order, execute nothing
./run                # then run the whole bootstrap
```

> ⚠️ Clone it at `~/last-dotfiles`. The shell aliases in `.zshrc` hardcode that path (the scripts
> themselves don't — they derive the repo root from their own location).
> ⚠️ A bare `./run` **rewrites `~/.zshrc`, `~/.config/nvim` and `~/.gitconfig*`**, backing up
> whatever it replaces to `<file>.backup-<timestamp>`.

---

## 🏃 The task runner

`run` finds executable files under `runs/` and executes them.

```bash
./run                # the whole bootstrap, in order
./run tmux           # only scripts whose path matches "tmux"
./run --dry          # print what would run, execute nothing
./run tmux --dry     # combine both
```

**With no filter it runs `runs/bootstrap/` only**, in this order — which is a contract, not
whatever order the filesystem happens to return:

1. `install-home-brew` — everything downstream needs `brew` on `PATH`
2. `install-zsh`
3. `install-node-version-manager`
4. `install-nvim`
5. `install-tmux`
6. `install-docker`
7. `install-git-config`
8. `install-hammerspoon` (macOS; guard-skips on Linux)
9. `install-wm-linux` (Linux; guard-skips on macOS)

`runs/infra/`, `runs/access/` and `runs/utils/` need an explicit filter, because they're imperative
or interactive rather than idempotent installers: `install-k3s` creates a cluster, `tmux-sessionizer`
opens an fzf picker, `switch-cluster` wants an argument, `install-git-hooks` writes into the current
directory's repo.

- The filter is a plain substring match against the script path, and widens the search to all of
  `runs/`.
- Scripts that don't match are listed at the end under `🔎 Scripts filtrados`.
- **A script must be executable** (`chmod +x`) to be picked up — otherwise it's silently skipped.
  That's how `runs/lib/` stays out: it holds sourced helpers, not runnable scripts.
- `--dry` is only understood by `run` itself. Everything else runs for real.
- A failing script no longer stops the rest; failures are summarised at the end and `run` exits 1.

### `runs/lib/`

Sourced by the installers, never executed on its own.

| File | What it gives you |
|---|---|
| `brew-env.sh` | `ensure_brew` — puts Homebrew on `PATH` by discovering its prefix (Apple Silicon, Intel Mac, system Linuxbrew, user Linuxbrew). Needed because within a single `./run` the installer that just installed brew only added it to `~/.zshrc`. |
| `apt.sh` | `require_apt` / `apt_install` — runs `apt-get update` once per `./run` and fails with a readable message on distros without apt. |

---

## 📜 Scripts

### `runs/bootstrap/` — installers

| Script | What it does | Notes |
|---|---|---|
| `install-home-brew` | Installs Homebrew if `brew` isn't on `PATH`. Works on macOS and Linux. | Idempotent. Run this first. |
| `install-zsh` | **Symlinks** `~/.zshrc` to `configs/zsh-config/.zshrc` first, then installs zsh + `fzf`, `kubectx`, `thefuck`, `autojump`, Antigen and `kube-ps1`, and sets zsh as the default shell. | Backs up any real (non-symlink) `~/.zshrc` it would replace. Editing `configs/zsh-config/.zshrc` edits the live shell config directly. The symlink goes first on purpose: it's the one step that must not be left half-done. `chsh` registers the shell in `/etc/shells` if it isn't there (Homebrew's zsh never is), and degrades to a warning instead of aborting. |
| `install-nvim` | `brew install neovim`, then **symlinks** `~/.config/nvim` to `configs/nvim-config/`. | Backs up any real (non-symlink) `~/.config/nvim` it would replace. |
| `install-tmux` | `brew install tmux` and writes `~/.config/tmux/tmux.conf`. | Prefix remapped to `C-a`, vi copy-mode (`pbcopy` on macOS, `xclip`/`wl-copy` on Linux depending on the session), `hjkl` pane navigation, `prefix + r` reloads. Backs up an existing conf before overwriting it. |
| `install-docker` | macOS: `brew install --cask docker-desktop` and opens Docker Desktop. Linux: installs Docker Engine via the official `get.docker.com` script, enables the systemd service (if `systemctl` exists), and adds you to the `docker` group. | Skips if `docker` is already on `PATH`. On Linux you need to log out/in for the group change to apply. |
| `install-node-version-manager` | `brew install nvm`, creates `~/.nvm`, then installs the latest Node and sets it as default. | Writes nothing into `~/.zshrc` — that file is a symlink into this repo, so appending machine-specific brew paths to it put the wrong `/opt/homebrew` vs `/home/linuxbrew` path in version control. `.zshrc` loads nvm via `$HOMEBREW_PREFIX` instead. |
| `install-hammerspoon` | macOS only (guard-skips on Linux — see `install-wm-linux` below for its Linux sibling). Installs Hammerspoon if missing, asks which profile you want, and **symlinks** `~/.hammerspoon/init.lua` and `~/.hammerspoon/app_config.lua` into this repo. | Interactive. Backs up any real (non-symlink) file it would replace. See [Hammerspoon](#hammerspoon-config--window-management) below. |
| `install-wm-linux` | Linux only (guard-skips on macOS). Installs `lua-wm`, a custom Lua window-manager daemon that's the Hammerspoon equivalent for Linux: apt packages (`lua5.3`, `lgi`, keybinder/wnck/notify GTK bindings), symlinks `~/.config/lua-wm/{init.lua,app_config.lua}` from `configs/wm-linux-config/`, and registers a `systemd --user` service plus an XDG autostart entry. | Interactive profile picker, same pattern as `install-hammerspoon`. `Shift+F12`-equivalent reload is `systemctl --user restart lua-wm`. The Lua interpreter and the multiarch triplet for `lgi` are discovered, not hardcoded, so it also comes up on arm64. Works without a systemd user session (the XDG autostart entry is the primary boot path anyway). |
| `install-git-config` | **Symlinks** `~/.gitconfig`, `~/.gitconfig_kaizen`, `~/.gitconfig_zooplus` and `~/.gitignore_global` to `configs/git-config/`. | Backs up any real file it replaces. |

### `runs/infra/`

| Script | What it does | Notes |
|---|---|---|
| `install-k3s` | `brew install k3d`, checks Docker is running (`docker info`, works whether Docker is a macOS app or a Linux systemd service), then creates a local cluster `peter-cluster` with 2 agents and `8080:80` on the load balancer. | Idempotent: skips k3d and the cluster if they already exist. Verify with `kubectl get nodes`. |
| `switch-cluster <arn>` | `kubectl config use-context <arn>`. | Takes one argument; prints usage if you omit it. Wrapped by the `kdev` / `kprod` aliases. |

### `runs/access/`

| Script | What it does | Notes |
|---|---|---|
| `repokeys` | `ssh-add`s every private key in `~/.ssh` (skipping `*.pub`, `known_hosts*`, `config`, certs) into the agent you already have, reporting each one. Uses `--apple-use-keychain` on macOS. | Won't start an agent itself: this script is executed, not sourced, so an agent started here would die with it — which is exactly why it used to be a silent no-op on Linux. If there's no agent it tells you to run `eval "$(ssh-agent -s)"` in your shell. |

### `runs/utils/`

| Script | What it does | Notes |
|---|---|---|
| `tmux-sessionizer` | fzf-picks a directory under `~/kaizen` or `~/zooplus`, creates or attaches a tmux session named after it, and runs `ready-tmux` inside. | Aliased to `session`. Works both inside and outside tmux. |
| `ready-tmux` | Runs `./.ready-tmux` from the current directory if it's executable, else `~/.ready-tmux`. | The per-project session-layout hook. Templates in `configs/tmux-examples/`. |
| `install-git-hooks` | Copies everything in `hooks/` into the current repo's hooks dir and makes it executable. | ⚠️ Acts on the **current directory's** repo — `cd` into the target project first. It lives here rather than in `bootstrap/` precisely so a bare `./run` doesn't install the zooplus hooks onto whatever repo you're standing in. |

---

## 🗂️ Configs

Files under `configs/` are symlinked out to their real homes.

### `hammerspoon-config/` — 🎯 window management

`init.lua` is the whole system. On load it runs **Work mode**; the hotkeys are:

| Key | Action |
|---|---|
| `F1`–`F12` | Launch or focus the app bound to that key |
| `F11` | Work mode |
| `F12` | Reset layout — re-place the windows that are already open |
| `Shift+F10` | Emoji picker (`Ctrl+Cmd+Space`) |
| `Shift+F11` | Kaizen mode |
| `Shift+F12` | Reload Hammerspoon |

These are `mac-work.lua`'s bindings; each profile assigns its own keys, so check the profile you
actually have linked.

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

- `functionKeys` — key + modifiers + action (an app name, or `EMOJI` / `WORK_MODE` / `KAIZEN_MODE` / `RESET_LAYOUT` / `RELOAD_HAMMERSPOON`)
- `workAppLayout` / `kaizenAppLayout` — per-app `position` (`left|center|right`), `vertical` (`top|center|bottom`) and `width`/`height` as fractions (`"1/3"`, `"2/3"`, `"3/4"`, `"4/4"`…)
- `workChromeConfig` / `workChromiumConfig` / `kaizenChromeConfig` / `kaizenChromiumConfig` — the tab sets each mode opens
- `foregroundApps` — what ends up on top per mode
- `onDemandAppLayout` — apps that no mode launches, but that still get a position when you press their key
- `appPaths` — explicit `.app` paths for apps outside `/Applications` (`launchOrFocus` can't find those)
- `appIds` — bundle IDs for apps whose running name differs from the `.app` name (`Visual Studio Code` runs as `Code`)
- `minWidthForTiling` — below this primary-screen width, everything goes centred fullscreen instead (default 2000)
- `appLaunchDelay`, `debugMode`

`profiles/mac-work.lua` and `profiles/mac-personal.lua` are self-contained per-machine profiles —
**keep new options in sync across all of them**.

### `wm-linux-config/` — 🐧 window management (Linux)

The Hammerspoon equivalent for Linux: `init.lua` runs as a `lua5.3` daemon (via `lgi`/GTK, `Wnck`,
`Keybinder`, `libnotify`) instead of relying on a macOS-only accessibility API. Same shape as
`hammerspoon-config/`: `app_config.lua` is a symlink into `profiles/`, installed and reloaded via

```bash
./run wm-linux
```

Reload after editing a profile with `systemctl --user restart lua-wm` (bound the same way
`Shift+F12` reloads Hammerspoon on macOS). Logs: `journalctl --user -u lua-wm -f`. Currently only
`profiles/linux-personal.lua` exists (no `linux-work.lua` counterpart yet).

The `functionKeys` schema is identical to Hammerspoon's, and so is the action vocabulary
(`WORK_MODE`, `KAIZEN_MODE`, `RESET_LAYOUT`, `EMOJI`, plus `RELOAD_WM` as a synonym of
`RELOAD_HAMMERSPOON`). Geometry — the fraction table and the position table — is the same code.

**The app *names* are not portable, though**, and can't be: on macOS they're `.app` names resolved
through `hs.application`, on Linux they're the `Name=` field of a `.desktop` file matched against
`WM_CLASS` via Wnck. They coincide for vendor apps (`Slack`, `Obsidian`, `Google Chrome`) and
diverge whenever the packaging differs — `IntelliJ IDEA Ultimate` on Linux vs `IntelliJ IDEA` on
macOS. To find the right string:

```bash
grep -r '^Name=' /usr/share/applications/ | grep -i <app>
xprop WM_CLASS      # then click the window
```

Two things are macOS-only by nature and the Linux side ignores them: `appIds` (CFBundleIdentifiers)
and `appPaths` (`.app` paths). Multi-monitor placement (`screen = "secondary"`) is also
macOS-only for now — lua-wm always uses the primary monitor.

Tests for all this live in `configs/wm-linux-config/test/` — see its README.

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

Installed by `./run git-config`. `.gitconfig` uses `includeIf "gitdir:…"` to switch identity per
directory: `~/zooplus/` pulls in `.gitconfig_zooplus` (work email), `~/kaizen/` and
`~/last-dotfiles/` pull in `.gitconfig_kaizen` (personal email). Both set `pull.rebase = true` and
share `.gitignore_global`, which is in this repo too.

The Sourcetree diff/merge tools are macOS-only paths, kept in the shared file because they're inert
elsewhere — git only touches them if you ask for `-t sourcetree` explicitly.

### `nvim-config/init.lua`

A [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) config, single file, heavily
commented, plus the `lazy-lock.json` that pins the plugin versions. `./run nvim` symlinks the whole
directory to `~/.config/nvim` — editing it here edits the live config, and Lazy writes the lockfile
straight into this repo.

Two consequences of keeping only those two files, rather than a full kickstart clone:

- There's no `git pull` from upstream. Porting upstream changes is a manual diff, which is why the
  file keeps upstream's formatting (2 spaces, single quotes) instead of being run through stylua.
- **The `require 'kickstart.plugins.*'` lines must stay commented out.** They're upstream scaffolding
  that lives in a `lua/` directory this repo doesn't carry, so uncommenting one breaks startup.

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
| `commit-msg` | Requires `<MAJOR\|MINOR\|REVISION> \| [<STORY>:] <MESSAGE>`. |
| `pre-commit` | For staged `.vue`/`.ts` files under `ui/` (excluding `__tests__/`): runs `npm run format` and `npm run lint:fix`, re-stages them, and blocks the commit on lint errors. |

Commits **in this repo** instead follow Conventional Commits with an emoji:

```
feat(hammerspoon): 🎯 update config layout
fix(zsh): 🐛 correct PATH export
```

---

## 🐛 Known rough edges

Documented rather than silently patched:

- The `~/last-dotfiles` clone path is hardcoded in the `.zshrc` aliases. Every script derives the
  repo root from its own location instead, so only the aliases care where you cloned it.
- `wm-linux-config/` only has a `linux-personal.lua` profile; there's no `linux-work.lua` counterpart
  to `mac-work.lua` yet.
- lua-wm ignores `screen = "secondary"`: multi-monitor placement is macOS-only so far.
- `install-zsh` installs `autojump`, but nothing ever sources it — the `rupa/z` antigen bundle
  already covers that, so it's a dead dependency rather than a broken one.
- The `unixorn/fzf-zsh-plugin` antigen bundle **has never installed**:
  `~/.antigen/bundles/unixorn/` is empty and antigen reports `Installing... Error!` whenever its
  cache is invalidated (then stays quiet until the next invalidation, which is why it goes
  unnoticed). The upstream repo is fine — `git clone` of it works by hand — so it's something in
  antigen's fetch. `Aloxaf/fzf-tab` is installed and covers fzf completion; what's missing is the
  extra fzf keybindings/aliases. Predates the cross-platform work and is unrelated to it.
- The generated `~/.config/tmux/tmux.conf` bakes in the clipboard command at install time, so it is
  **not** portable between a Mac and a Linux box: copying it over yields `pbcopy: command not found`
  on every yank. Re-run `./run tmux` on each machine instead.
- The `.ready-tmux` templates send this repo's zsh aliases (`gl`, `kdev`) into panes, so they assume
  this `.zshrc` is in effect.
- Non-Debian Linux isn't supported: the scripts that need system packages check for `apt-get` and
  exit with a message rather than pretending.

### Fixed, for the record

Things that used to be listed here and no longer apply: `./run` silently doing nothing on macOS
(`find -perm /111` is GNU-only), the bootstrap running in filesystem order, `hooks/commit-msg` never
failing a commit, `hooks/pre-commit` never blocking one, `switch-cluster` dying before its own error
message, `install-node-version-manager` writing brew paths into the versioned `.zshrc`, `repokeys`
being a no-op on Linux, and lua-wm mutating its own profile table.
