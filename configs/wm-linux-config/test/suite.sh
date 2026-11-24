#!/usr/bin/env bash
# Corre la suite contra un init.lua concreto (por defecto el del repo).
# Uso: ./suite.sh [ruta-al-directorio-wm-linux-config]
set -uo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WM_REPO="${1:-$(cd "$TEST_DIR/.." && pwd)}"
cd "$TEST_DIR"

fails=0
run() { # run <nombre> <SCREEN_W> <XRANDR_COUNT> <perfil> <script-lua> [VAR=valor...]
  local name="$1" w="$2" xr="$3" prof="$4" script="$5"
  shift 5
  local out
  out=$(env TEST_DIR="$TEST_DIR" WM_REPO="$WM_REPO" WM_PROFILE="$prof" SCREEN_W="$w" SCREEN_H=1440 \
        XRANDR_COUNT="$xr" "$@" luajit "$script" 2>&1)
  local rc=$?
  echo "$out"
  [[ $rc -ne 0 ]] && fails=$((fails + 1))
  return 0
}

echo "════ init.lua bajo prueba: $WM_REPO ════"
echo
# A y B corren contra el linux-personal de antes de los lados, congelado: ningún
# perfil usa ya la rejilla, pero init.lua la sigue entendiendo y esto lo demuestra.
echo "─── A. Rejilla · pantalla ancha, 3440px (debe tilear) ───"
run A 3440 0 "$TEST_DIR/profile-grid.lua" check-wide.lua
echo
echo "─── B. Rejilla · pantalla de portátil, 1512px + eDP presente (debe ir fullscreen) ───"
run B 1512 1 "$TEST_DIR/profile-grid.lua" check-laptop.lua
echo
echo "─── C. Dispatcher: KAIZEN_MODE y RESET_LAYOUT ───"
run C 3440 0 "$TEST_DIR/profile-modes.lua" check-dispatch.lua
echo
echo "─── D. linux-personal en lados, 2560px: 50/50, doble toque, salvoconducto ───"
run D 2560 0 "$WM_REPO/profiles/linux-personal.lua" check-sides.lua
echo
echo "─── F. Un atajo que ya tiene otro proceso ───"
run F 2560 0 "$WM_REPO/profiles/linux-personal.lua" check-busy.lua BUSY_KEYS=F3
echo
if [[ $fails -eq 0 ]]; then
  echo "════ TODO OK ════"
else
  echo "════ $fails escenarios con fallos ════"
fi
exit $fails
