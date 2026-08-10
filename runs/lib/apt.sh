#!/usr/bin/env bash
# Instalación de paquetes de sistema en Linux, para lo que Homebrew no puede dar:
# el zsh registrado en /etc/shells, los bindings GTK de lua-wm y el clipboard.
#
# Resuelve dos cosas que estaban repetidas y mal en install-zsh, install-tmux e
# install-wm-linux: nadie hacía `apt-get update` (así que en una imagen recién
# creada el install falla con listas vacías), y en una distro sin apt el
# "command not found" mataba el script con set -e antes de escribir ninguna config.
#
# Uso:  source "$(dirname "${BASH_SOURCE[0]}")/../lib/apt.sh"
#       require_apt          # aborta con un mensaje claro si no hay apt-get
#       apt_install zsh ...  # hace update una sola vez por ./run, luego instala

require_apt() {
  if ! command -v apt-get &>/dev/null; then
    echo "❌ Esta parte necesita apt-get (Debian/Ubuntu) y aquí no está."
    echo "   Instala a mano el equivalente en tu distro y vuelve a ejecutarlo."
    exit 1
  fi
}

# El marcador vive en /tmp para que un ./run que llame a tres instaladores
# seguidos refresque las listas una vez, no tres.
_APT_UPDATED_MARKER="/tmp/.last-dotfiles-apt-updated"

apt_update_once() {
  require_apt
  if [[ -f "$_APT_UPDATED_MARKER" ]]; then
    return 0
  fi
  echo "🔄 apt-get update..."
  sudo apt-get update
  touch "$_APT_UPDATED_MARKER"
}

apt_install() {
  apt_update_once
  echo "📦 apt-get install: $*"
  sudo apt-get install -y "$@"
}
