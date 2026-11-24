-- Ejecuta el init.lua indicado con el perfil indicado y devuelve el registro.
local REPO = assert(os.getenv("WM_REPO"), "WM_REPO sin definir: usa suite.sh")
local PROFILE = os.getenv("WM_PROFILE") or (REPO .. "/profiles/linux-personal.lua")

package.path = (os.getenv("TEST_DIR") or ".") .. "/?.lua;" .. REPO .. "/?.lua;" .. package.path
require("harness")

package.preload["app_config"] = function() return assert(loadfile(PROFILE))() end
local profile = require("app_config")

local originals = {}
for _, key in ipairs({"kaizenAppLayout"}) do
  for _, cfg in ipairs(profile[key] or {}) do
    originals[key .. "/" .. cfg.name] = { w = cfg.width, h = cfg.height,
                                          pos = cfg.position, vert = cfg.vertical }
  end
end

-- Ventanas abiertas antes de arrancar (WM_OPEN="code,google-chrome" por defecto)
for cls in (os.getenv("WM_OPEN") or "code,google-chrome"):gmatch("[^,]+") do
  TESTOPEN[cls] = true
end

assert(loadfile(REPO .. "/init.lua"))()

local mutated = {}
for _, key in ipairs({"kaizenAppLayout"}) do
  for _, cfg in ipairs(profile[key] or {}) do
    local o = originals[key .. "/" .. cfg.name]
    if cfg.width ~= o.w or cfg.height ~= o.h
       or cfg.position ~= o.pos or cfg.vertical ~= o.vert then
      table.insert(mutated, key .. "/" .. cfg.name)
    end
  end
end

-- Helpers para los escenarios de teclas
local r = { profile = profile, mutated = mutated, log = TESTLOG, fails = 0 }

-- Pulsa un atajo tras `gapMs` (1s por defecto: lejos de cualquier doble toque)
function r.press(accel, gapMs)
  TESTCLOCK = TESTCLOCK + (gapMs or 1000) * 1000
  local fn = TESTLOG.bindings[accel]
  if not fn then error("sin binding para " .. accel) end
  fn()
end

function r.doublePress(accel)
  r.press(accel)
  r.press(accel, 150)
end

function r.frame(cls) return TESTFRAMES[cls] end

function r.check(name, ok, detail)
  if ok then print("  ✅ " .. name)
  else r.fails = r.fails + 1; print("  ❌ " .. name .. (detail and ("  → " .. detail) or "")) end
end

function r.expectRect(name, cls, x, y, w, h)
  local f = TESTFRAMES[cls]
  local ok = f and f.x == x and f.y == y and f.w == w and f.h == h
  r.check(name, ok, f and string.format("está en x=%d y=%d w=%d h=%d", f.x, f.y, f.w, f.h)
                        or "nunca se colocó")
end

function r.notifiedMatch(pat)
  for _, m in ipairs(TESTLOG.notified) do if m:match(pat) then return true end end
  return false
end

function r.done() os.exit(r.fails == 0 and 0 or 1) end

return r
