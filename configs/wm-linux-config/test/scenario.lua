-- Ejecuta el init.lua indicado con el perfil indicado y devuelve el registro.
local REPO = assert(os.getenv("WM_REPO"), "WM_REPO sin definir: usa suite.sh")
local PROFILE = os.getenv("WM_PROFILE") or (REPO .. "/profiles/linux-personal.lua")

package.path = (os.getenv("TEST_DIR") or ".") .. "/?.lua;" .. REPO .. "/?.lua;" .. package.path
require("harness")

package.preload["app_config"] = function() return assert(loadfile(PROFILE))() end
local profile = require("app_config")

local originals = {}
for _, key in ipairs({"workAppLayout", "kaizenAppLayout"}) do
  for _, cfg in ipairs(profile[key] or {}) do
    originals[key .. "/" .. cfg.name] = { w = cfg.width, h = cfg.height,
                                          pos = cfg.position, vert = cfg.vertical }
  end
end

TESTOPEN["code"] = true
TESTOPEN["google-chrome"] = true

assert(loadfile(REPO .. "/init.lua"))()

local mutated = {}
for _, key in ipairs({"workAppLayout", "kaizenAppLayout"}) do
  for _, cfg in ipairs(profile[key] or {}) do
    local o = originals[key .. "/" .. cfg.name]
    if cfg.width ~= o.w or cfg.height ~= o.h
       or cfg.position ~= o.pos or cfg.vertical ~= o.vert then
      table.insert(mutated, key .. "/" .. cfg.name)
    end
  end
end

return { profile = profile, mutated = mutated, log = TESTLOG }
