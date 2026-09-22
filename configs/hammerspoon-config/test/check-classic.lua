-- mac-personal.lua usa el esquema antiguo y NO debe cambiar de comportamiento:
-- su rejilla sigue igual y la tecla sigue siendo puro focus, sin expandir nada.

local H = dofile((os.getenv("TEST_DIR") or ".") .. "/harness.lua")

H.load()
H.flush()

print("E1 · arranca en Work Mode, como siempre")
H.check("anuncia Work Mode", H.alertsMatch("Work Mode"))

print("E2 · la rejilla coloca donde decía el perfil")
H.expectRect("IntelliJ a la derecha, 2/3", "IntelliJ IDEA", 1147, 0, 2293, 1440)
H.expectRect("Slack a la izquierda, 1/3",  "Slack",         0,    0, 1147, 1440)

print("E3 · el doble toque no existe en el esquema antiguo")
H.doublePress("F5")
H.flush()
H.expectRect("IntelliJ no se ha expandido", "IntelliJ IDEA", 1147, 0, 2293, 1440)

print("E4 · y Kaizen sigue teniendo su propia rejilla")
H.press("shift+F11")
H.flush()
H.expectRect("Chromium a la izquierda en kaizen", "Chromium", 0, 0, 1147, 1440)

H.done()
