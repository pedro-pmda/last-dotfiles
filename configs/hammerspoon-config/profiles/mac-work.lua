return {
    appLaunchDelay = 5,
    debugMode = false,

    -- Por debajo de este ancho en la pantalla principal no se reparten ventanas:
    -- todo va a pantalla completa. El ultrawide (3440) tilea, la interna (1512) no.
    minWidthForTiling = 2000,

    -- Dos pulsaciones de la misma tecla dentro de esta ventana cuentan como doble toque.
    doubleTapMs = 400,

    -- Una tecla = un dominio. Sin modificador la app principal, con shift la variante.
    -- Bloques: F1-F4 comunicar · F5-F8 construir · F9-F12 personal/meta
    functionKeys = {
        -- Comunicar
        { key = "F1",  modifiers = {},        action = "Google Chrome" },
        { key = "F1",  modifiers = {"shift"}, action = "Google Chrome Canary" },
        { key = "F2",  modifiers = {},        action = "Claude" },
        { key = "F2",  modifiers = {"shift"}, action = "Chromium" },
        -- F2 es la tecla de la IA y ya no caben más variantes con shift
        { key = "F2",  modifiers = {"alt"},   action = "LM Studio" },
        { key = "F3",  modifiers = {},        action = "Slack" },
        { key = "F3",  modifiers = {"shift"}, action = "Microsoft Teams" },
        { key = "F4",  modifiers = {},        action = "Microsoft 365 Copilot" },
        { key = "F4",  modifiers = {"shift"}, action = "Microsoft Outlook" },

        -- Construir
        { key = "F5",  modifiers = {},        action = "IntelliJ IDEA" },
        { key = "F5",  modifiers = {"shift"}, action = "DBeaver" },
        { key = "F6",  modifiers = {},        action = "Visual Studio Code" },
        { key = "F6",  modifiers = {"shift"}, action = "Kiro" },
        { key = "F7",  modifiers = {},        action = "OpenLens" },
        { key = "F7",  modifiers = {"shift"}, action = "Docker" },
        { key = "F8",  modifiers = {},        action = "Ghostty" },
        { key = "F8",  modifiers = {"shift"}, action = "Cyberduck" },

        -- Personal y meta
        { key = "F9",  modifiers = {},        action = "Obsidian" },
        { key = "F9",  modifiers = {"shift"}, action = "WebPomodoro" },
        { key = "F10", modifiers = {},        action = "Finder" },
        { key = "F10", modifiers = {"shift"}, action = "EMOJI" },
        { key = "F11", modifiers = {},        action = "WORK_MODE" },
        { key = "F11", modifiers = {"shift"}, action = "KAIZEN_MODE" },
        { key = "F12", modifiers = {},        action = "RESET_LAYOUT" },
        { key = "F12", modifiers = {"shift"}, action = "RELOAD_HAMMERSPOON" }
    },

    ---------------------------------------------------------------------------
    -- El mapa de lados
    ---------------------------------------------------------------------------
    -- Todo vive al 50% (1720 px en el ultrawide). Un único mapa para los dos modos:
    -- así F1 pone Chrome a la derecha estés donde estés, y es imposible que trabajo
    -- y kaizen coloquen distinto.
    --
    -- El criterio no es estético: el lado decide QUÉ PUEDES VER A LA VEZ, porque dos
    -- apps del mismo lado se tapan entre sí siempre. Los pares que de verdad usas
    -- (editor+terminal, editor+navegador, editor+IA, notas+navegador) tienen todos la
    -- superficie de escritura como constante, así que esa se queda a la izquierda y
    -- todo lo que la acompaña a la derecha.

    -- Izquierda: donde escribes. Son alternativas de verdad — no editas en IntelliJ y
    -- en VS Code a la vez, así que taparse entre ellas no cuesta nada.
    leftApps = {
        "IntelliJ IDEA",
        "Visual Studio Code",
        "Kiro",
        "DBeaver",
        "Obsidian"
    },

    -- Derecha: lo que acompaña a lo que escribes. Aquí caen también las notificaciones
    -- de macOS (arriba a la derecha), y es mucho menos dañino que tapen una consulta.
    rightApps = {
        "Ghostty",
        "Google Chrome",
        "Google Chrome Canary",
        "Claude",
        "Chromium",
        "LM Studio",
        "Slack",
        "Microsoft Teams",
        "Microsoft 365 Copilot",
        "Microsoft Outlook",
        "OpenLens",
        "Docker",
        "Cyberduck",
        "Finder",
        "WebPomodoro"
    },

    -- El doble toque expande al centro a 2/3. Estas van a pantalla completa en su
    -- lugar: una demo o una prueba de navegador no cabe en dos tercios.
    expandFull = { "Google Chrome Canary" },

    ---------------------------------------------------------------------------
    -- Los dos modos
    ---------------------------------------------------------------------------
    -- Solo cambian qué apps se lanzan y qué pestañas se abren. Los lados y las teclas
    -- son los mismos, que es lo que impide que un modo descoloque respecto al otro.
    modes = {
        work = {
            launch = {
                "IntelliJ IDEA", "Visual Studio Code", "Kiro", "DBeaver", "Obsidian",
                "Ghostty", "Google Chrome", "Google Chrome Canary", "Claude", "Chromium",
                "LM Studio", "Slack", "Microsoft Teams", "Microsoft 365 Copilot",
                "Microsoft Outlook", "OpenLens", "WebPomodoro", "Finder"
            },
            foreground = { "Google Chrome", "IntelliJ IDEA" },

            chrome = {
                urls = {
                    "https://zooplus.atlassian.net/jira/software/c/projects/DPF/boards/525",
                    "https://src.private.zooplus.net/dashboard",
                    "https://zpl.awsapps.com/start/#/?tab=accounts",
                    "https://dna-jenkins.cicdk8sp.int.aws.zooplus.io/job/Zoobrain/job/DZB/job/zoobrain/",
                    "https://sonarqube.private.zooplus.net/dashboard?id=dzb%3Azoobrain%3Aui",
                    "https://zoobrain.private.zooplus.net",
                    "https://grafana.dnap.int.aws.zooplus.io/login",
                    "https://zooplus.atlassian.net/wiki/spaces/DAC/overview",
                    "https://app.mural.co/t/zooplus8237/home"
                }
            },

            chromium = {
                urls = {
                    "https://gemini.google.com/app?hl=es-ES"
                }
            },

            -- Lo único que interrumpe es el reloj. Slack va siempre a la izquierda
            -- porque es el que trías primero; correo y Teams se alternan para que
            -- ninguno se acumule más de cuatro horas. Al vencer, RESET_LAYOUT.
            comms = {
                windows = {
                    { time = "09:30", left = "Slack", right = "Microsoft Outlook" },
                    { time = "11:30", left = "Slack", right = "Microsoft Teams" },
                    { time = "13:30", left = "Slack", right = "Microsoft Outlook" },
                    { time = "15:30", left = "Slack", right = "Microsoft Teams" }
                },
                durationMinutes = 10,
                weekdaysOnly = true,
                -- Una ventana saltando encima de una pantalla compartida es un
                -- desastre: si hay cámara o micro en uso, se pospone y reintenta.
                postponeMinutes = 2,
                maxPostpones = 12
            }
        },

        kaizen = {
            launch = {
                "Google Chrome", "Visual Studio Code", "Ghostty", "Chromium",
                "Obsidian", "WebPomodoro", "LM Studio", "Google Chrome Canary"
            },
            foreground = { "Google Chrome", "Obsidian" },

            chrome = {
                urls = {
                    "https://mail.google.com/mail/u/0/#inbox",
                    "https://calendar.google.com/calendar/u/0/r",
                    "https://master.dev/dashboard/",
                    "https://anthropic.skilljar.com/",
                    "https://englishonline.britishcouncil.org/platform/nui/reactui/build/index.html?dd613#/login",
                    "https://monkeytype.com/"
                }
            },

            chromium = {
                urls = {
                    "https://gemini.google.com/app?hl=es-ES",
                    "https://claude.ai/new"
                }
            }
            -- Sin `comms`: los horarios de trabajo no suenan en kaizen.
        }
    },

    -- Apps installed outside the standard /Applications folders need an explicit path
    -- so hs.application.open() can find them (launchOrFocus only searches standard locations).
    appPaths = {
        ["WebPomodoro"] = "/Volumes/SecondBrain/Applications/WebPomodoro.app"
    },

    -- Apps que corren con un nombre distinto al de su .app, o cuyo nombre es prefijo de
    -- otro: hs.application.get() hace match por subcadena, así que sin el bundle ID
    -- "Google Chrome" puede resolver a "Google Chrome Canary".
    appIds = {
        ["Visual Studio Code"] = "com.microsoft.VSCode",
        ["Google Chrome"]      = "com.google.Chrome",
        ["Google Chrome Canary"] = "com.google.Chrome.canary"
    }
}
