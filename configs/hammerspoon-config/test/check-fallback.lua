-- F11 con el atajo ocupado por otro proceso.
--
-- macOS no comparte atajos globales: quien registra primero se queda la tecla y a
-- hs.hotkey.bind le devuelve nil. Aquí se simula ese rechazo justo en F11 —lo que
-- pasa en la máquina de verdad— y se comprueba que Work Mode entra igualmente por el
-- eventtap, sin tocar el resto de teclas.

local H = dofile((os.getenv("TEST_DIR") or ".") .. "/harness.lua")

H.reject("F11")        -- lo mismo que RegisterEventHotKey fallando con -9878
H.load()
H.flush()

print("F1 · la tecla rechazada no se registra como atajo")
H.check("F11 no está en los bindings", H.bindings["F11"] == nil)
H.check("⇧F11 sí sigue estándolo",     H.bindings["shift+F11"] ~= nil)

print("F2 · pero F11 entra en Work Mode igualmente")
H.press("shift+F11")   -- salir de work: el arranque ya deja el modo puesto
H.flush()
H.alerts = {}
local via = H.press("F11")
H.flush()
H.check("la pulsación la atiende el eventtap", via == "eventtap", tostring(via))
H.check("entra en Work Mode",                  H.alertsMatch("Work Mode"))

print("F3 · y la tecla no sigue su camino hacia quien tenga el atajo")
H.check("el evento se consume", H.tap("F11") == true)

print("F4 · una tecla que nadie ocupa no pasa por el repuesto")
H.alerts = {}
H.check("F12 sigue yendo por hs.hotkey", H.press("F12") == "hotkey")

print("F5 · el modificador cuenta: F11 no dispara con ⇧ puesto")
H.check("⇧F11 no lo atiende el tap de F11", H.tap("shift+F11") == false)

H.done()
