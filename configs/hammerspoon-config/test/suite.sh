#!/usr/bin/env bash
# Corre la suite contra un init.lua concreto (por defecto el del repo).
# Uso: ./suite.sh [ruta-al-directorio-hammerspoon-config]
#
# Necesita luajit o lua en el PATH (brew install luajit). Hammerspoon no hace
# falta: el harness sustituye `hs` entero.
#
# Al tocar init.lua: corre la suite también contra la versión anterior y comprueba
# que FALLA. Un test que pasa con el bug dentro no está probando nada.
set -uo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HS_REPO="${1:-$(cd "$TEST_DIR/.." && pwd)}"
PROFILES="$HS_REPO/profiles"
cd "$TEST_DIR"

LUA=$(command -v luajit || command -v lua5.4 || command -v lua5.3 || command -v lua || true)
if [[ -z "$LUA" ]]; then
  echo "❌ No hay intérprete de Lua. brew install luajit"
  exit 127
fi

fails=0
run() { # run <SCREEN_W> <SCREEN_H> <SCREENS> <perfil> <script>
  local w="$1" h="$2" screens="$3" prof="$4" script="$5"
  local out rc
  out=$(TEST_DIR="$TEST_DIR" HS_REPO="$HS_REPO" HS_PROFILE="$prof" \
        SCREEN_W="$w" SCREEN_H="$h" SCREENS="$screens" "$LUA" "$script" 2>&1)
  rc=$?
  echo "$out" | grep -v '^[0-9][0-9]:[0-9][0-9]:[0-9][0-9] · '
  [[ $rc -ne 0 ]] && fails=$((fails + 1))
  return 0
}

echo "════ init.lua bajo prueba: $HS_REPO ($(basename "$LUA")) ════"
echo
echo "─── A. Reparto 50/50, ultrawide 3440px ───"
run 3440 1440 1 "$PROFILES/mac-work.lua" check-sides.lua
echo
echo "─── B. Doble toque: expandir y colapsar ───"
run 3440 1440 1 "$PROFILES/mac-work.lua" check-expand.lua
echo
echo "─── C. Ventanas de comunicación ───"
run 3440 1440 1 "$PROFILES/mac-work.lua" check-comms.lua
echo
echo "─── D. Portátil solo, 1512px ───"
run 1512 982 1 "$PROFILES/mac-work.lua" check-laptop.lua
echo
echo "─── E. Esquema antiguo intacto (mac-personal) ───"
run 3440 1440 1 "$PROFILES/mac-personal.lua" check-classic.lua
echo
if [[ $fails -eq 0 ]]; then
  echo "════ TODO OK ════"
else
  echo "════ $fails escenarios con fallos ════"
fi
exit $fails
