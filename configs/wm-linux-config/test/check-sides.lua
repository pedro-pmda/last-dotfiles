-- linux-personal en el esquema de lados, en la pantalla del iMac (2560px).
-- Mitad = 1280 (x=0 o x=1280) · 2/3 = 1706 centrado (x=426) · completa = 2560.
local r = require("scenario")

print("D1 · donde escribes, a la izquierda; lo que acompaña, a la derecha")
r.expectRect("VS Code",  "code",                  0,    0, 1280, 1440)
r.expectRect("Obsidian", "obsidian",              0,    0, 1280, 1440)
r.expectRect("calibre",  "calibre-gui",           0,    0, 1280, 1440)
r.expectRect("Chrome",   "google-chrome",         1280, 0, 1280, 1440)
r.expectRect("Terminal", "gnome-terminal-server", 1280, 0, 1280, 1440)
r.expectRect("Claude",   "claude",                1280, 0, 1280, 1440)
-- Con la sesión en español su Name= llega traducido ("Navegador web Chromium")
r.expectRect("Chromium", "chromium-browser",      1280, 0, 1280, 1440)

print("D2 · la pareja de Kaizen se ve entera: notas y navegador")
local notas, web = r.frame("obsidian"), r.frame("google-chrome")
r.check("Obsidian y Chrome no se tapan",
        notas and web and notas.x + notas.w <= web.x,
        notas and web and string.format("notas acaban en %d y el navegador empieza en %d",
                                        notas.x + notas.w, web.x))

print("D3 · lo que Kaizen no lanza se coloca al abrirlo a mano")
r.press("F3")                    -- Ferdium: no está en modes.kaizen.launch
r.expectRect("Ferdium a la derecha", "ferdium", 1280, 0, 1280, 1440)

print("D3b · y Files, que en español es \"Archivos\", también tiene tecla")
r.press("F10")
r.expectRect("Files a la derecha", "nemo", 1280, 0, 1280, 1440)

print("D4 · el doble toque expande al centro a 2/3")
r.doublePress("F6")
r.expectRect("VS Code al centro", "code", 426, 0, 1706, 1440)

print("D5 · insistir la devuelve a su mitad")
r.doublePress("F6")
r.expectRect("VS Code vuelve a la izquierda", "code", 0, 0, 1280, 1440)

print("D6 · irse a otra app colapsa sola la expandida")
r.doublePress("F6")
r.expectRect("VS Code expandida otra vez", "code", 426, 0, 1706, 1440)
r.press("F8")                    -- Terminal, toque simple
r.expectRect("VS Code ha vuelto a su mitad", "code", 0, 0, 1280, 1440)

print("D7 · Spotify expande a pantalla completa, no a 2/3")
r.doublePress("F4")
r.expectRect("Spotify ocupa los 2560", "spotify", 0, 0, 2560, 1440)
r.doublePress("F4")
r.expectRect("y vuelve a la derecha", "spotify", 1280, 0, 1280, 1440)

print("D8 · tres toques rápidos no se quedan pegados")
-- La 3ª tiene que contar como simple: expandida + toque suelto no la mueve.
r.press("F9")
r.press("F9", 100)               -- doble: expande
r.press("F9", 100)               -- tercera rápida: simple, no otro doble
r.expectRect("Obsidian sigue expandida", "obsidian", 426, 0, 1706, 1440)

print("D9 · el salvoconducto lo devuelve todo a su sitio")
r.press("F12")
r.expectRect("Obsidian recolocada", "obsidian", 0, 0, 1280, 1440)
r.check("y avisa de cuántas ha movido", r.notifiedMatch("ventanas recolocadas"))

print("D10 · un toque suelto sobre una app ya abierta respeta su tamaño")
TESTFRAMES["google-chrome"] = { x = 50, y = 50, w = 900, h = 700 }
r.press("F1")
r.expectRect("Chrome se queda donde la dejaste", "google-chrome", 50, 50, 900, 700)

r.done()
