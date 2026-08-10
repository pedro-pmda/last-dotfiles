local r = require("scenario")
local fails = 0
local function check(n, ok, d) if ok then print("  ✅ "..n) else fails=fails+1; print("  ❌ "..n..(d and ("  → "..d) or "")) end end

-- ESTE es el test de la regresión: el código viejo mutaba la tabla aquí
check("la tabla del perfil NO se muta (ni con pantalla de portátil)", #r.mutated == 0,
      "mutadas: "..table.concat(r.mutated, ", "))
local allFull = #r.log.geometry > 0
for _, g in ipairs(r.log.geometry) do if g.w ~= 1512 then allFull = false end end
check("todas las ventanas a pantalla completa (1512px)", allFull,
      "geometrías: "..#r.log.geometry)
local hasLaptop = false
for _, m in ipairs(r.log.notified) do if m:match("Laptop screen") then hasLaptop = true end end
check("avisa 'Laptop screen → fullscreen'", hasLaptop)
os.exit(fails == 0 and 0 or 1)
