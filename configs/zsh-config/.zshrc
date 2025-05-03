eval "$(/opt/homebrew/bin/brew shellenv)"

# Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ─── Antigen Setup ──────────────────────────────────────────────
source $HOME/.antigen.zsh
antigen use oh-my-zsh

# ─── Temas ──────────────────────────────────────────────────────
antigen theme romkatv/powerlevel10k

# ─── Plugins Zsh Core ───────────────────────────────────────────
antigen bundle git
antigen bundle docker
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


antigen apply


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
alias kprod="$HOME/last-dotfiles/runs/infra/./switch-cluster arn:aws:eks:eu-central-1:480143891137:cluster/zoobrain-eks-prod"
alias kdev="$HOME/last-dotfiles/runs/infra/./switch-cluster arn:aws:eks:eu-central-1:880682651209:cluster/zoobrain-eks-dev" 
alias kpfbd="kubectl -n zoobrain-system port-forward tcp-forwarder-zoobrain-web 5432:5432 > /dev/null 2>&1 &"
alias repokeys="$HOME/last-dotfiles/runs/access/./repokeys"
alias run="$HOME/last-dotfiles/run"
alias session="$HOME/last-dotfiles/runs/utils/tmux-sessionizer"
alias ready-tmux="$HOME/last-dotfiles/runs/utils/ready-tmux"

# ─── The Fuck ───────────────────────────────────────────────────
eval "$(thefuck --alias)"

# ─── Powerlevel10k config ───────────────────────────────────────
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ─── Configuración de fzf ───────────────────────────────────────
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

# ─── Language Environment ───────────────────────────────────────
export LANG=en_US.UTF-8

# ─── Path Setup ─────────────────────────────────────────────────
export PATH=$HOME/bin:/usr/local/bl:wqn:$PATH

export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && . "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && . "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/zp2391/.cache/lm-studio/bin"

export XDG_CONFIG_HOME="$HOME/.config"
export EDITOR="nvim"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"






