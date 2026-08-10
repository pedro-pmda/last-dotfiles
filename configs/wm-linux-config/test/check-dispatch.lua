local r = require("scenario")
local fails = 0
local function check(n, ok, d) if ok then print("  ✅ "..n) else fails=fails+1; print("  ❌ "..n..(d and ("  → "..d) or "")) end end

check("F11 (WORK_MODE) enlazada",  r.log.bindings["F11"] ~= nil)
check("F12 (RESET_LAYOUT) enlazada", r.log.bindings["F12"] ~= nil)
check("<Shift>F11 (KAIZEN_MODE) enlazada", r.log.bindings["<Shift>F11"] ~= nil)

-- Pulsar F12: RESET_LAYOUT debe notificar "ventanas recolocadas", no lanzar una app
local n0 = #r.log.notified
if r.log.bindings["F12"] then r.log.bindings["F12"]() end
local sawReset = false
for i = n0 + 1, #r.log.notified do
  if r.log.notified[i]:match("recolocadas") then sawReset = true end
end
check("F12 ejecuta resetLayout (no lo trata como nombre de app)", sawReset,
      "notificaciones nuevas: "..(#r.log.notified - n0))

-- Pulsar F11: WORK_MODE debe entrar en modo trabajo
local n1 = #r.log.notified
if r.log.bindings["F11"] then r.log.bindings["F11"]() end
local sawWork = false
for i = n1 + 1, #r.log.notified do
  if r.log.notified[i]:match("Work Mode") then sawWork = true end
end
check("F11 ejecuta workMode", sawWork)
os.exit(fails == 0 and 0 or 1)
