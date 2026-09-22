-- mac-personal después de migrar de rejilla a lados.
--
-- Lo que se comprueba es lo que la rejilla no daba: que el lado de cada app sea el mismo
-- en los dos modos, y que una app que Kaizen no lanza se coloque igual al abrirla a mano
-- (antes caía donde quisiera, porque solo existía la tabla del modo).

local H = dofile((os.getenv("TEST_DIR") or ".") .. "/harness.lua")

H.load()
H.flush()

print("G1 · donde escribes, a la izquierda")
H.expectRect("IntelliJ",  "IntelliJ IDEA",      0, 0, 1720, 1440)
H.expectRect("VS Code",   "Visual Studio Code", 0, 0, 1720, 1440)
H.expectRect("Obsidian",  "Obsidian",           0, 0, 1720, 1440)
H.expectRect("Mural",     "Mural",              0, 0, 1720, 1440)

print("G2 · lo que acompaña, a la derecha")
H.expectRect("Ghostty",   "Ghostty",            1720, 0, 1720, 1440)
H.expectRect("Chrome",    "Google Chrome",      1720, 0, 1720, 1440)
H.expectRect("Slack",     "Slack",              1720, 0, 1720, 1440)
H.expectRect("Outlook",   "Microsoft Outlook",  1720, 0, 1720, 1440)

print("G3 · la pareja de Kaizen se ve entera: notas y navegador")
H.press("shift+F11")
H.flush()
local notas, web = H.rect("Obsidian"), H.rect("Google Chrome")
H.check("Obsidian y Chrome no se tapan",
        notas.x + notas.w <= web.x + 2,
        string.format("notas acaban en %.0f y el navegador empieza en %.0f",
                      notas.x + notas.w, web.x))

print("G4 · y lo que Kaizen no lanza se coloca al abrirlo a mano")
H.press("F5")              -- IntelliJ: no está en el launch de kaizen
H.flush()
H.expectRect("IntelliJ se coloca igualmente", "IntelliJ IDEA", 0, 0, 1720, 1440)
H.press("shift+F5")        -- DBeaver: antes ni siquiera tenía tecla
H.flush()
H.expectRect("DBeaver también", "DBeaver", 0, 0, 1720, 1440)

print("G5 · el doble toque expande al centro a 2/3")
H.doublePress("F6")
H.flush()
H.expectRect("VS Code al centro", "Visual Studio Code", 573, 0, 2293, 1440)

H.done()
