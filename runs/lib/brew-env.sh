#!/usr/bin/env bash
# Pone Homebrew en el PATH de este proceso.
#
# Se necesita porque el instalador de Homebrew solo añade `brew shellenv` a
# ~/.zshrc: dentro del mismo ./run que acaba de instalarlo, los scripts que
# vienen detrás siguen sin tenerlo en el PATH.
#
# El prefix se descubre, nunca se asume: Apple Silicon (/opt/homebrew), Intel Mac
# (/usr/local), Linuxbrew de sistema (/home/linuxbrew/.linuxbrew) y Linuxbrew de
# usuario sin sudo (~/.linuxbrew) son cuatro sitios distintos.
#
# Uso:  source "$(dirname "${BASH_SOURCE[0]}")/../lib/brew-env.sh"
#       ensure_brew            # deja brew en el PATH, o falla con un mensaje claro
#       ensure_brew --optional # igual, pero devuelve 1 en vez de abortar

ensure_brew() {
  local optional=0
  [[ "${1:-}" == "--optional" ]] && optional=1

  if command -v brew &>/dev/null; then
    return 0
  fi

  local brew_bin
  for brew_bin in \
    /opt/homebrew/bin/brew \
    /usr/local/bin/brew \
    /home/linuxbrew/.linuxbrew/bin/brew \
    "$HOME/.linuxbrew/bin/brew"
  do
    if [[ -x "$brew_bin" ]]; then
      eval "$("$brew_bin" shellenv)"
      return 0
    fi
  done

  if [[ $optional -eq 1 ]]; then
    return 1
  fi

  echo "❌ Homebrew no está instalado o no se encuentra. Ejecuta primero:"
  echo "   ./run home-brew"
  exit 1
}
