-- El doble toque: 50% → 2/3 centrado → 50%.
-- En 3440: mitad = 1720 (x=0 o x=1720) · 2/3 = 2293 centrado (x=573).

local H = dofile((os.getenv("TEST_DIR") or ".") .. "/harness.lua")

H.load()
H.flush()

print("B1 · el doble toque expande al centro a 2/3")
H.doublePress("F5")
H.flush()
H.expectRect("IntelliJ al centro", "IntelliJ IDEA", 573, 0, 2293, 1440)

print("B2 · insistir devuelve la ventana a su mitad")
H.doublePress("F5")
H.flush()
H.expectRect("IntelliJ vuelve a la izquierda", "IntelliJ IDEA", 0, 0, 1720, 1440)

print("B3 · irse a otra app colapsa sola la expandida")
H.doublePress("F5")
H.flush()
H.expectRect("IntelliJ expandida otra vez", "IntelliJ IDEA", 573, 0, 2293, 1440)
H.press("F8")                    -- Ghostty, toque simple
H.flush()
H.expectRect("IntelliJ ha vuelto a su mitad", "IntelliJ IDEA", 0, 0, 1720, 1440)
H.expectRect("Ghostty en la suya",           "Ghostty",       1720, 0, 1720, 1440)

print("B4 · Canary expande a pantalla completa, no a 2/3")
H.doublePress("shift+F1")
H.flush()
H.expectRect("Canary ocupa los 3440", "Google Chrome Canary", 0, 0, 3440, 1440)

print("B5 · y vuelve a su mitad como todas")
H.doublePress("shift+F1")
H.flush()
H.expectRect("Canary a la derecha", "Google Chrome Canary", 1720, 0, 1720, 1440)

print("B6 · tres toques rápidos no se quedan pegados")
-- La 3ª pulsación tiene que contar como un simple nuevo: al consumir la marca del
-- doble, lo que queda es expandida + un toque suelto, que no la mueve de sitio.
H.press("F6")
H.press("F6", 100)               -- doble: expande
H.press("F6", 100)               -- tercera rápida: simple, no otro doble
H.flush()
H.expectRect("VS Code sigue expandida", "Visual Studio Code", 573, 0, 2293, 1440)

print("B7 · el salvoconducto lo devuelve todo a su sitio")
H.press("F12")
H.flush()
H.expectRect("VS Code recolocada", "Visual Studio Code", 0, 0, 1720, 1440)
H.check("y avisa de cuántas ha movido", H.alertsMatch("ventanas recolocadas"))

H.done()
