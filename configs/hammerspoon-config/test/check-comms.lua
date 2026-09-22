-- Las cuatro ventanas de comunicación: el reloj es lo único que interrumpe.

local H = dofile((os.getenv("TEST_DIR") or ".") .. "/harness.lua")

H.load()
H.flush()

print("C1 · las cuatro horas quedan programadas")
for _, t in ipairs({ "09:30", "11:30", "13:30", "15:30" }) do
    H.check("hay ventana a las " .. t, H.scheduled[t] ~= nil)
end
H.expectRect("de partida, Slack vive a la derecha", "Slack", 1720, 0, 1720, 1440)

print("C2 · con la cámara en uso la ventana espera, no irrumpe")
H.cameraInUse = true
H.scheduled["09:30"]()
H.flush()
H.expectRect("Slack no se ha movido", "Slack", 1720, 0, 1720, 1440)
H.check("y no ha avisado todavía", not H.alertsMatch("Tiempo de Comunicación"))

print("C3 · al colgar, la ventana pospuesta sale")
H.cameraInUse = false
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

-- El caso real que tumbaba el mecanismo: auricular USB conectado y Teams abierto dejan el
-- micro "en uso" todo el día. Si eso cuenta como llamada, las cuatro franjas se descartan a
-- diario y en silencio.
print("C7 · el micro abierto por el auricular ya no pospone")
H.press("F11")             -- volver a work: C6 dejó el modo en kaizen
H.flush()
H.alerts = {}
H.cameraInUse = false
H.micInUse    = true
H.scheduled["09:30"]()
H.flush()
H.check("la ventana sale igualmente", H.alertsMatch("📬 Tiempo de Comunicación"))
H.expectRect("Slack a la izquierda", "Slack", 0, 0, 1720, 1440)

print("C8 · con la cámara en uso se agotan los reintentos y se dice por qué")
H.fireLong(300)            -- cerrar los 10 min de la ventana anterior
H.flush()
H.alerts = {}
H.cameraInUse = true
H.scheduled["11:30"]()
for _ = 1, 13 do           -- 12 posposiciones + la que se rinde
    H.fireLong(60)
    H.flush()
end
H.check("no ha irrumpido", not H.alertsMatch("📬 Tiempo de Comunicación"))
H.check("avisa del descarte con el motivo", H.alertsMatch("descartada (cámara en uso)"))
H.expectRect("Slack sigue en su lado", "Slack", 1720, 0, 1720, 1440)

-- Lo que de verdad tenía muerto el mecanismo: Hammerspoon no retiene los temporizadores, y
-- los de la hora y los del reintento de 2 min se los llevaba el recolector sin un error ni
-- una línea de log. Los cortos de colocar ventanas sobrevivían porque no da tiempo a un GC.
print("C9 · el recolector no se lleva ni la franja ni el reintento")
H.alerts = {}
H.cameraInUse = true
H.scheduled["15:30"]()     -- se pospone: encola el reintento de 2 min
H.collect()
H.cameraInUse = false
H.fireLong(60)             -- el reintento, si sigue vivo
H.flush()
H.check("el reintento sobrevive y la ventana sale", H.alertsMatch("📬 Tiempo de Comunicación"))

H.collect()
local vivas = 0
for _, t in ipairs({ "09:30", "11:30", "13:30", "15:30" }) do
    if H.scheduledTimers[t] ~= nil then vivas = vivas + 1 end
end
H.check("las cuatro franjas siguen programadas tras el GC", vivas == 4, vivas .. "/4")

H.done()
