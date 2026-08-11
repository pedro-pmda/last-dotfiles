# ─── Homebrew (must be before p10k instant prompt, silenced) ────
# Se busca el prefix en vez de hardcodearlo: Apple Silicon, Intel Mac y Linuxbrew
# (con y sin sudo) lo ponen en sitios distintos. shellenv exporta $HOMEBREW_PREFIX,
# que el resto del fichero reutiliza para no volver a llamar a brew.
if command -v brew &>/dev/null; then
  eval "$(brew shellenv)" 2>/dev/null
else
  for brew_bin in \
    /opt/homebrew/bin/brew \
    /usr/local/bin/brew \
    /home/linuxbrew/.linuxbrew/bin/brew \
    "$HOME/.linuxbrew/bin/brew"
  do
    [[ -x "$brew_bin" ]] && eval "$("$brew_bin" shellenv)" 2>/dev/null && break
  done
fi

# ─── Powerlevel10k instant prompt ───────────────────────────────
# Keep this near the top. All console output before this will cause warnings.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ─── Antigen Setup ──────────────────────────────────────────────
# Sin el guard, una máquina donde install-zsh no ha corrido escupe un error aquí
# y otros trece más ("command not found: antigen") en los bundles de abajo.
if [[ -f $HOME/.antigen.zsh ]]; then
  source $HOME/.antigen.zsh
  antigen use oh-my-zsh

  # ─── Temas ────────────────────────────────────────────────────
  antigen theme romkatv/powerlevel10k

  # ─── Plugins Zsh Core ─────────────────────────────────────────
  antigen bundle git
  antigen bundle node
  antigen bundle golang
  antigen bundle command-not-found
  antigen bundle zsh-users/zsh-autosuggestions
  antigen bundle zsh-users/zsh-completions
  antigen bundle zsh-users/zsh-history-substring-search
  antigen bundle rupa/z
  antigen bundle zsh-users/zsh-syntax-highlighting
  antigen bundle unixorn/fzf-zsh-plugin
  antigen bundle Aloxaf/fzf-tab

  # ─── Docker completions ───────────────────────────────────────
  # Solo existe con Docker Desktop (macOS); en Linux el paquete ya las registra.
  if [[ -d /Applications/Docker.app/Contents/Resources/etc ]]; then
    fpath=(/Applications/Docker.app/Contents/Resources/etc $fpath)
  fi

  antigen apply
else
  echo "⚠️  Falta ~/.antigen.zsh — ejecuta: ./run zsh"
fi

# ─── kube-ps1 (Kubernetes context) ──────────────────────────────
if [[ -f $HOME/.kube-ps1/kube-ps1.sh ]]; then
  source $HOME/.kube-ps1/kube-ps1.sh
  PROMPT='$(kube_ps1)'$PROMPT
fi

# ─── Historial Zsh ──────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt INC_APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_FIND_NO_DUPS EXTENDED_HISTORY

# ─── Auto CD (type directory name to navigate) ──────────────────
setopt AUTO_CD

# ─── Alias útiles ───────────────────────────────────────────────
alias k='kubectl'
alias kgp='kubectl get pods'
alias kaf='kubectl apply -f'
alias kn='kubens'
alias kc='kubectx'
alias gst='git status'
alias gl='git log --oneline --graph --decorate'
alias cls='clear'
alias tf='terraform'
alias kprod="$HOME/last-dotfiles/runs/infra/switch-cluster arn:aws:eks:eu-central-1:480143891137:cluster/zoobrain-eks-prod"
alias kdev="$HOME/last-dotfiles/runs/infra/switch-cluster arn:aws:eks:eu-central-1:880682651209:cluster/zoobrain-eks-dev"
alias kpfbd="kubectl -n zoobrain-system port-forward tcp-forwarder-zoobrain-web 5432:5432 > /dev/null 2>&1 &"
alias repokeys="$HOME/last-dotfiles/runs/access/repokeys"
alias run="$HOME/last-dotfiles/run"
alias session="$HOME/last-dotfiles/runs/utils/tmux-sessionizer"
alias ready-tmux="$HOME/last-dotfiles/runs/utils/ready-tmux"
alias dpsp='docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"'

# ─── The Fuck (lazy-loaded to avoid init output) ────────────────
if command -v thefuck &>/dev/null; then
  thefuck_init() { eval "$(thefuck --alias)"; }
  thefuck_init 2>/dev/null
fi

# ─── Powerlevel10k config ────────────────────────────────────────
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ─── Configuración de fzf ────────────────────────────────────────
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

# ─── Language Environment ────────────────────────────────────────
# En una Debian recién instalada este locale no está generado, y ponerlo a ciegas
# hace que git/perl avisen de "cannot change locale" en cada invocación.
if [[ "$(uname -s)" == "Darwin" ]] || [[ -d /usr/lib/locale/en_US.utf8 ]]; then
  export LANG=en_US.UTF-8
fi

# ─── Path Setup ──────────────────────────────────────────────────
# Nada de /usr/local/bin a mano: es el prefix de brew en un Mac Intel y colarlo
# por delante de lo que puso `brew shellenv` cambia qué binario gana según el OS.
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

# ─── NVM ─────────────────────────────────────────────────────────
# Vía $HOMEBREW_PREFIX en vez de `brew --prefix nvm`: mismo resultado en Linuxbrew,
# Apple Silicon e Intel, pero sin hacer fork de brew en cada arranque de shell (y
# sin escupir "No available formula" si la formula no está instalada).
export NVM_DIR="$HOME/.nvm"
if [[ -n "${HOMEBREW_PREFIX:-}" ]]; then
  [ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ] && . "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
  [ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ] && . "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm"
fi

export XDG_CONFIG_HOME="$HOME/.config"
export EDITOR="nvim"

# ─── LM Studio CLI (lms) ─────────────────────────────────────────
[[ -d "$HOME/.cache/lm-studio/bin" ]] && export PATH="$PATH:$HOME/.cache/lm-studio/bin"

# ─── bun ─────────────────────────────────────────────────────────
export BUN_INSTALL="$HOME/.bun"
[[ -d "$BUN_INSTALL/bin" ]] && export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# ─── Kiro shell integration ──────────────────────────────────────
if [[ "$TERM_PROGRAM" == "kiro" ]] && command -v kiro &>/dev/null; then
  . "$(kiro --locate-shell-integration-path zsh)"
fi


#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
