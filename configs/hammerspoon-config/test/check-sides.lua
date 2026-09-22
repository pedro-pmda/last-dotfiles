-- El reparto 50/50 en el ultrawide: 1720 px por lado.
-- Izquierda = donde escribes · derecha = lo que acompaña.

local H = dofile((os.getenv("TEST_DIR") or ".") .. "/harness.lua")

H.load()
H.flush()          -- corre el arranque de Work Mode: lanza y coloca

print("A1 · lo que escribes, a la izquierda")
H.expectRect("IntelliJ",   "IntelliJ IDEA",      0, 0, 1720, 1440)
H.expectRect("VS Code",    "Visual Studio Code", 0, 0, 1720, 1440)
H.expectRect("Obsidian",   "Obsidian",           0, 0, 1720, 1440)
H.expectRect("DBeaver",    "DBeaver",            0, 0, 1720, 1440)

print("A2 · lo que acompaña, a la derecha")
H.expectRect("Ghostty",    "Ghostty",            1720, 0, 1720, 1440)
H.expectRect("Chrome",     "Google Chrome",      1720, 0, 1720, 1440)
H.expectRect("Slack",      "Slack",              1720, 0, 1720, 1440)
H.expectRect("Claude",     "Claude",             1720, 0, 1720, 1440)
H.expectRect("WebPomodoro","WebPomodoro",        1720, 0, 1720, 1440)

print("A3 · el par más frecuente del día se ve entero")
local izq, der = H.rect("IntelliJ IDEA"), H.rect("Ghostty")
H.check("editor y terminal no se solapan",
        izq.x + izq.w <= der.x + 2,
        string.format("editor acaba en %.0f y terminal empieza en %.0f", izq.x + izq.w, der.x))

print("A4 · ninguna app se come el ultrawide entero")
local anchas = {}
for _, name in ipairs({ "Obsidian", "WebPomodoro", "LM Studio" }) do
    local r = H.rect(name)
    if r and r.w > 1800 then table.insert(anchas, name) end
end
H.check("Obsidian, WebPomodoro y LM Studio ya no van a 3440",
        #anchas == 0, table.concat(anchas, ", ") .. " siguen a pantalla completa")

print("A5 · Kaizen coloca las mismas apps en los mismos lados")
H.press("shift+F11")
H.flush()
H.expectRect("VS Code sigue a la izquierda", "Visual Studio Code", 0, 0, 1720, 1440)
H.expectRect("Chrome sigue a la derecha",    "Google Chrome",      1720, 0, 1720, 1440)

print("A6 · y una app que Kaizen no lanza conserva su lado al abrirla a mano")
H.press("F5")                  -- IntelliJ: no está en el launch de kaizen
H.flush()
H.expectRect("IntelliJ se coloca igualmente", "IntelliJ IDEA", 0, 0, 1720, 1440)

H.done()
