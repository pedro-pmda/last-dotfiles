-- Las cuatro ventanas de comunicación: el reloj es lo único que interrumpe.

local H = dofile((os.getenv("TEST_DIR") or ".") .. "/harness.lua")

H.load()
H.flush()

print("C1 · las cuatro horas quedan programadas")
for _, t in ipairs({ "09:30", "11:30", "13:30", "15:30" }) do
    H.check("hay ventana a las " .. t, H.scheduled[t] ~= nil)
end
H.expectRect("de partida, Slack vive a la derecha", "Slack", 1720, 0, 1720, 1440)

print("C2 · en reunión la ventana espera, no irrumpe")
H.inCall = true
H.scheduled["09:30"]()
H.flush()
H.expectRect("Slack no se ha movido", "Slack", 1720, 0, 1720, 1440)
H.check("y no ha avisado todavía", not H.alertsMatch("Tiempo de Comunicación"))

print("C3 · al colgar, la ventana pospuesta sale")
H.inCall = false
H.fireLong(60)          -- el reintento de los 2 min
H.flush()
H.check("avisa con el aviso acordado", H.alertsMatch("📬 Tiempo de Comunicación"))
H.expectRect("Slack a la izquierda", "Slack",             0, 0, 1720, 1440)
H.expectRect("Outlook a la derecha", "Microsoft Outlook", 1720, 0, 1720, 1440)

print("C4 · al vencer, todo vuelve a su sitio")
H.fireLong(300)         -- los 10 minutos
H.flush()
H.check("avisa del final", H.alertsMatch("Fin del tiempo de comunicación"))
H.expectRect("Slack vuelve a su lado", "Slack", 1720, 0, 1720, 1440)

print("C5 · en fin de semana no suena")
H.alerts = {}
H.wday = 7              -- sábado
H.scheduled["11:30"]()
H.flush()
H.check("sábado no hay ventana", not H.alertsMatch("Tiempo de Comunicación"))

print("C6 · y en Kaizen tampoco")
H.wday = 3
H.press("shift+F11")
H.flush()
H.alerts = {}
H.scheduled["13:30"]()
H.flush()
H.check("los horarios de trabajo no entran en kaizen",
        not H.alertsMatch("Tiempo de Comunicación"))

H.done()
