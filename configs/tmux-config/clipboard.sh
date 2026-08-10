#!/usr/bin/env sh
# Puente al portapapeles del sistema para el yank de tmux.
#
# La elección se hace aquí, en cada copia, y no al instalar: $WAYLAND_DISPLAY
# depende de la sesión gráfica en la que estés, no de la máquina, y en Linux
# install-tmux instala xclip y wl-clipboard a la vez. Decidirlo al arrancar el
# servidor tmux (con if-shell) fallaría al entrar en una sesión del otro tipo.

if command -v pbcopy >/dev/null 2>&1; then
  pbcopy
elif [ -n "$WAYLAND_DISPLAY" ] && command -v wl-copy >/dev/null 2>&1; then
  wl-copy
elif command -v xclip >/dev/null 2>&1; then
  xclip -selection clipboard -i
else
  # Sin portapapeles disponible: consumir la entrada para no romper el pipe
  cat >/dev/null
fi
