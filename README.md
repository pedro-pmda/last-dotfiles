# 🧰 last-dotfiles

Personal dev-environment bootstrap for macOS and Linux: install scripts, dotfiles and window-management config, all plain Bash + Lua. No build step, no package manager. There are two small test suites, both for
things that can't be checked by reading: `configs/wm-linux-config/test/` (Linux-only code, run from
a Mac) and `test/run-interactive-test.py` (the `-i` menu, driven through a real pty).

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
./run -i             # interactive picker over everything under runs/
./run tmux           # only scripts whose path matches "tmux"
./run --dry          # print what would run, execute nothing
./run -i --dry       # pick in the menu, then only print
./run --help
```

### `-i` — interactive mode

Like `--dry` in that it shows you the list first, except you choose from it. Unlike the default
run, it covers **every** folder under `runs/`, not just `bootstrap`, and it **only lists what
applies to the machine you're on** — `install-hammerspoon` doesn't show up on Linux, `install-wm-linux`
doesn't show up on macOS, and a footer tells you what was hidden.

```
   ██╗      █████╗ ███████╗████████╗
   ██║     ██╔══██╗██╔════╝╚══██╔══╝
   ██║     ███████║███████╗   ██║
   ██║     ██╔══██║╚════██║   ██║
   ███████╗██║  ██║███████║   ██║
   ╚══════╝╚═╝  ╚═╝╚══════╝   ╚═╝
   · d o t f i l e s ·  🍎 macOS

  runs/bootstrap/
   ● 2) install-docker                   🐳 Docker Desktop (macOS) / Engine (Linux)
   ○ 3) install-git-config               🔧 ~/.gitconfig* con identidad por directorio
   ● 4) install-hammerspoon              🎯 Hammerspoon — gestión de ventanas y hotkeys
   ...

  ⏭️  Ocultos por no ser de macOS: install-wm-linux

  1-14 alternar   a todos   n ninguno   b solo bootstrap
  ↵  ejecutar    q salir

  ▶ Seleccionados: 2  ›
```

Type numbers (`3`, or `1 3 5`, or `1,3,5`) to toggle, `a`/`n` for all/none, `b` for just the
bootstrap set, Enter to run, `q` to quit. Whatever you pick still runs in `BOOTSTRAP_ORDER`, so
selecting Homebrew and Neovim together installs Homebrew first regardless of the order you ticked
them.

**How a script declares itself.** `run` doesn't hardcode any of this — it reads two headers from
each script, so adding a new one never means editing `run`:

```bash
#!/usr/bin/env bash
# run-os: darwin        # darwin | linux | any   (default: any)
# run-desc: 🎯 Hammerspoon — gestión de ventanas y hotkeys
```

**With no filter it runs `runs/bootstrap/` only**, in this order — which is a contract, not
whatever order the filesystem happens to return:

1. `install-home-brew` — everything downstream needs `brew` on `PATH`
2. `install-zsh`
3. `install-node-version-manager`
4. `install-nvim`
5. `install-tmux`
6. `install-docker`
7. `install-kubernetes`
8. `install-git-config`
9. `install-ghostty`
10. `install-cli-tools`
11. `install-chromium`
12. `install-chrome-canary`
13. `install-freelens`
14. `install-hammerspoon` (macOS; guard-skips on Linux)
15. `install-wm-linux` (Linux; guard-skips on macOS)

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
- `-i` refuses to run without a terminal, rather than hanging on a menu nobody can answer.

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
| `install-zsh` | **Symlinks** `~/.zshrc` and `~/.p10k.zsh` to `configs/zsh-config/` first, then installs zsh + `fzf`, `thefuck`, `autojump`, the MesloLGS Nerd Font, Antigen and `kube-ps1`, and sets zsh as the default shell. | Backs up any real (non-symlink) `~/.zshrc` it would replace. Editing `configs/zsh-config/.zshrc` edits the live shell config directly. The symlink goes first on purpose: it's the one step that must not be left half-done. `chsh` registers the shell in `/etc/shells` if it isn't there (Homebrew's zsh never is), and degrades to a warning instead of aborting. |
| `install-nvim` | `brew install neovim`, then **symlinks** `~/.config/nvim` to `configs/nvim-config/`. | Backs up any real (non-symlink) `~/.config/nvim` it would replace. |
| `install-tmux` | `brew install tmux`, then **symlinks** `~/.config/tmux/{tmux.conf,clipboard.sh}` and `~/.ready-tmux`. On Linux also installs xclip + wl-clipboard. | Prefix remapped to `C-a`, vi copy-mode, `hjkl` pane navigation, `prefix + r` reloads. The clipboard command is chosen at yank time by `clipboard.sh`, so the same conf works on macOS, X11 and Wayland. |
| `install-docker` | macOS: `brew install --cask docker-desktop` and opens Docker Desktop. Linux: installs Docker Engine via the official `get.docker.com` script, enables the systemd service (if `systemctl` exists), and adds you to the `docker` group. | Skips if `docker` is already on `PATH`. On Linux you need to log out/in for the group change to apply. |
| `install-obsidian` | macOS: `brew install --cask obsidian`. Linux: installs from Flathub (`md.obsidian.Obsidian`) via Flatpak, adding the `flathub` remote if it's missing. | Skips if already installed. Flatpak was chosen over snap because Linux Mint blocks snapd by default but ships Flatpak/Flathub out of the box. |
| `install-spotify` | macOS: `brew install --cask spotify`. Linux: installs from Flathub (`com.spotify.Client`) via Flatpak, adding the `flathub` remote if it's missing. | Skips if already installed. Same Flatpak rationale as `install-obsidian`. |
| `install-node-version-manager` | `brew install nvm`, creates `~/.nvm`, then installs the latest Node and sets it as default. | Writes nothing into `~/.zshrc` — that file is a symlink into this repo, so appending machine-specific brew paths to it put the wrong `/opt/homebrew` vs `/home/linuxbrew` path in version control. `.zshrc` loads nvm via `$HOMEBREW_PREFIX` instead. |
| `install-hammerspoon` | macOS only (guard-skips on Linux — see `install-wm-linux` below for its Linux sibling). Installs Hammerspoon if missing, asks which profile you want, and **symlinks** `~/.hammerspoon/init.lua` and `~/.hammerspoon/app_config.lua` into this repo. | Interactive. Backs up any real (non-symlink) file it would replace. See [Hammerspoon](#hammerspoon-config--window-management) below. |
| `install-wm-linux` | Linux only (guard-skips on macOS). Installs `lua-wm`, a custom Lua window-manager daemon that's the Hammerspoon equivalent for Linux: apt packages (`lua5.3`, `lgi`, keybinder/wnck/notify GTK bindings), symlinks `~/.config/lua-wm/{init.lua,app_config.lua}` from `configs/wm-linux-config/`, and registers a `systemd --user` service plus an XDG autostart entry. | Interactive profile picker, same pattern as `install-hammerspoon`. `Shift+F12`-equivalent reload is `systemctl --user restart lua-wm`. The Lua interpreter and the multiarch triplet for `lgi` are discovered, not hardcoded, so it also comes up on arm64. Works without a systemd user session (the XDG autostart entry is the primary boot path anyway). |
| `install-git-config` | **Symlinks** `~/.gitconfig`, `~/.gitconfig_kaizen`, `~/.gitconfig_zooplus` and `~/.gitignore_global` to `configs/git-config/`. | Backs up any real file it replaces. |
| `install-ghostty` | Installs the Ghostty cask on macOS, then **symlinks** `~/.config/ghostty/config`. | Also moves macOS's `~/Library/Application Support/com.mitchellh.ghostty/config` aside, because it takes priority over the XDG path. On Linux there's no official apt package, so it points you at the download page and links the config anyway. |
| `install-gnome-terminal` | Linux only. `dconf load`s `configs/gnome-terminal-config/catppuccin-latte.dconf` into a fixed-UUID profile (the same one the upstream `catppuccin/gnome-terminal` installer uses), then sets it as the default profile. | Not in `BOOTSTRAP_ORDER` (same as `install-obsidian`/`install-spotify`) — run it explicitly with `./run gnome-terminal`. GNOME Terminal keeps profiles in dconf, not a plain file, so this can't be a symlink; the dark profile you already had is left alone and still selectable from Preferences. |
| `install-cli-tools` | Installs `k9s`, `htop`, `glow`, `bat`, `lsd`, `lazygit`, `direnv` and `tree-sitter-cli` with Homebrew if missing, then **symlinks** the configs that exist in the repo (`k9s`, `htop`, `glow`). | Checks with `command -v`, so an apt-installed or hand-compiled copy is respected instead of installing a second one. Entries are `formula:binary:config-dir`, because the binary isn't always named after the formula (`tree-sitter-cli` → `tree-sitter`) and not every tool has a versioned config. |
| `install-kubernetes` | `kubectl`, `kubectx`/`kubens` and `helm`. | Nothing installed `kubectl` before, even though `.zshrc` has five aliases using it and `kube_ps1` in the prompt. `kubectx` moved here from `install-zsh`, where it had ended up only because its aliases live in the shell config. |
| `install-chromium` | Chromium: cask on macOS, apt on Linux (tries `chromium`, then `chromium-browser`). | The window profiles bind a key to it and open a tab set in it, but nothing installed it. |
| `install-chrome-canary` | Google Chrome Canary via cask on macOS. | Canary doesn't exist on Linux; there the equivalent channel is `google-chrome-unstable`, which needs Google's apt repo. The script prints the commands rather than adding a third-party repo behind your back. |
| `install-freelens` | Freelens (the maintained successor to OpenLens): cask on macOS, official `.deb` from GitHub releases on Linux (arch-matched, sha256 verified before `sudo apt install`). | On macOS it needs your password to copy into `/Applications`. |

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

Everything under `configs/` is **symlinked** to where the tool expects it, so editing a file here
edits the live config — no reinstall. Where a file lands, and who links it:

| `configs/` | Symlinked to | Installer |
|---|---|---|
| `zsh-config/.zshrc` | `~/.zshrc` | `install-zsh` |
| `zsh-config/.p10k.zsh` | `~/.p10k.zsh` | `install-zsh` |
| `nvim-config/` | `~/.config/nvim` | `install-nvim` |
| `tmux-config/tmux.conf` | `~/.config/tmux/tmux.conf` | `install-tmux` |
| `tmux-config/clipboard.sh` | `~/.config/tmux/clipboard.sh` | `install-tmux` |
| `tmux-examples/.ready-tmux-default` | `~/.ready-tmux` | `install-tmux` |
| `ghostty-config/config` | `~/.config/ghostty/config` | `install-ghostty` |
| `git-config/.gitconfig` + the two identities + `.gitignore_global` | `~/` | `install-git-config` |
| `cli-config/{k9s,htop,glow}/` | `~/.config/<tool>/` | `install-cli-tools` |
| `hammerspoon-config/{init.lua,profiles/<one>.lua}` | `~/.hammerspoon/{init.lua,app_config.lua}` | `install-hammerspoon` |
| `wm-linux-config/{init.lua,profiles/<one>.lua}` | `~/.config/lua-wm/{init.lua,app_config.lua}` | `install-wm-linux` |

Every installer backs up a real (non-symlink) file it would replace to `<dest>.backup-<timestamp>`
before linking, so the first run on an already-configured machine never destroys anything.

Three things worth knowing about this model:

- **Some files are written back by their tool.** `nvim` updates `lazy-lock.json`, `htop` rewrites
  `htoprc` when you change settings in its UI, `k9s` may rewrite `config.yaml` on exit. Through the
  symlink those land in the repo as normal changes. For the lockfile that's the point; for the other
  two it's just occasional noise to commit or discard.
- **Nothing else is generated any more.** `install-tmux` used to write `tmux.conf` with a heredoc,
  which made it the one config you couldn't edit from the repo. It links now.
- **`tmux-examples/` is still templates** you copy into a project as `.ready-tmux`, except
  `.ready-tmux-default`, which doubles as the symlinked global fallback.

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

The `functionKeys` schema is identical to Hammerspoon's, but the action vocabulary is
smaller: `KAIZEN_MODE`, `RESET_LAYOUT`, `EMOJI`, plus `RELOAD_WM` as a synonym of
`RELOAD_HAMMERSPOON`. No `WORK_MODE` on Linux — `linux-personal.lua` is the only profile
so far, so there's nothing to switch between. Geometry — the fraction table and the
position table — is the same code.

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

### `zsh-config/`

`.zshrc` and `.p10k.zsh` (the Powerlevel10k prompt theme, 89 KB of generated settings — `.zshrc`
sources it, so without versioning it a new machine started with p10k's setup wizard instead of your
prompt).

`.p10k.zsh` sets `POWERLEVEL9K_MODE=nerdfont-v3`, so it needs a Nerd Font to render its icons —
otherwise the prompt is full of tofu boxes. `install-zsh` installs MesloLGS NF for you: the cask on
macOS, and a download into `~/.local/share/fonts` + `fc-cache` on Linux, where casks don't exist.
**You still have to select it as your terminal's font** (in Ghostty: `font-family = MesloLGS NF`).

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

### `tmux-config/`

`tmux.conf` is a single static file that works on both OSes. The only thing that differs between
systems — the clipboard command — isn't decided here: it's delegated to `clipboard.sh`, which picks
`pbcopy` / `wl-copy` / `xclip` **at yank time**.

That timing is the whole point. On Linux `install-tmux` installs xclip *and* wl-clipboard, so
`command -v` finds both and only `$WAYLAND_DISPLAY` can tell them apart — and that depends on the
graphical session you're in, not on the machine. Doing it with `if-shell` inside `tmux.conf` would
resolve it when the tmux server starts, so entering a session of the other type would silently yank
to the wrong clipboard until you reloaded. A wrapper script gets it right every time.

### `ghostty-config/`

`config` is linked to `~/.config/ghostty/config`, which Ghostty honours on macOS *and* Linux, so one
file covers both.

⚠️ On macOS Ghostty also reads `~/Library/Application Support/com.mitchellh.ghostty/config`, and
**that one wins** for any key present in both — verified: a `font-size` set only in the XDG file
had no effect. `install-ghostty` therefore moves it aside to `.backup-<timestamp>`. If it ever
reappears, something recreated it and it's silently overriding this repo. Check what's actually in
effect with:

```bash
ghostty +show-config
```

### `cli-config/`

Small configs for terminal tools, one directory each, linked to `~/.config/<tool>/`: `k9s`
(+ its `aliases.yaml`), `htop`, `glow` — `bat`, `lsd`, `lazygit`, `direnv` and `tree-sitter-cli` are
installed but have no versioned config yet. `install-cli-tools` installs the tools themselves too — the
config and the thing it configures arrive together, so you can't end up with a perfectly linked
`~/.config/glow` and no glow.

`k9s`'s `screenDumpDir` was removed — it hardcoded `/Users/<user>/Library/...`, which is wrong on
Linux; k9s falls back to its own per-platform default.

Not included, deliberately: `lazygit` (empty config), `neofetch` / `zellij` / `bpytop` (untouched
default templates), and `direnv` — its `direnv.toml` isn't a personal preference at all, it's a
`warn_timeout` line written by PostHog's Flox activation hook that references a path inside that
project. Versioning a file another tool regenerates only invites conflicts.

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
- The `.ready-tmux` templates send this repo's zsh aliases (`gl`, `kdev`) into panes, so they assume
  this `.zshrc` is in effect.
- Non-Debian Linux isn't supported: the scripts that need system packages check for `apt-get` and
  exit with a message rather than pretending.

### Fixed, for the record

Things that used to be listed here and no longer apply: the generated `tmux.conf` baking in the
clipboard command (it's a symlinked static file now), `./run` silently doing nothing on macOS
(`find -perm /111` is GNU-only), the bootstrap running in filesystem order, `hooks/commit-msg` never
failing a commit, `hooks/pre-commit` never blocking one, `switch-cluster` dying before its own error
message, `install-node-version-manager` writing brew paths into the versioned `.zshrc`, `repokeys`
being a no-op on Linux, and lua-wm mutating its own profile table.
