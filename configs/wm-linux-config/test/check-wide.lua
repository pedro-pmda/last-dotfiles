local r = require("scenario")
local fails = 0
local function check(n, ok, d) if ok then print("  ✅ "..n) else fails=fails+1; print("  ❌ "..n..(d and ("  → "..d) or "")) end end

check("la tabla del perfil NO se muta", #r.mutated == 0, table.concat(r.mutated, ", "))
local tiled = false
for _, g in ipairs(r.log.geometry) do if g.w < 3440 then tiled = true end end
check("reparte ventanas (alguna con ancho < pantalla)", tiled)
local hasExternal = false
for _, m in ipairs(r.log.notified) do if m:match("External screen") then hasExternal = true end end
check("avisa 'External screen → multi-window'", hasExternal)
local unq = 0
for _, c in ipairs(r.log.popen) do if (c:match("new%-tab") or c:match("xdg%-open")) and not c:match("'https?://") then unq = unq + 1 end end
check("URLs citadas en el shell", unq == 0, "sin citar: "..unq)
os.exit(fails == 0 and 0 or 1)
