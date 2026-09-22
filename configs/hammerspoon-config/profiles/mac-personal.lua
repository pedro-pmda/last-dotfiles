return {
    appLaunchDelay = 5,
    debugMode = false,

    -- Por debajo de este ancho en la pantalla principal no se reparten ventanas:
    -- todo va a pantalla completa.
    minWidthForTiling = 2000,

    -- Dos pulsaciones de la misma tecla dentro de esta ventana cuentan como doble toque.
    doubleTapMs = 400,

    -- Mismo vocabulario que mac-work para las apps que existen en las dos máquinas: la
    -- memoria muscular no debería depender de en cuál estés sentado. Lo que solo hay aquí
    -- (Mural) ocupa un hueco que allí no se usa; F2 y F4 se quedan libres porque sus apps
    -- (Claude, Copilot) no están instaladas en esta máquina.
    -- Bloques: F1-F4 comunicar · F5-F8 construir · F9-F12 personal/meta
    functionKeys = {
        -- Comunicar
        { key = "F1",  modifiers = {},        action = "Google Chrome" },
        { key = "F1",  modifiers = {"shift"}, action = "Google Chrome Canary" },
        { key = "F2",  modifiers = {"shift"}, action = "Chromium" },
        { key = "F3",  modifiers = {},        action = "Slack" },
        { key = "F3",  modifiers = {"shift"}, action = "Microsoft Teams" },
        { key = "F4",  modifiers = {"shift"}, action = "Microsoft Outlook" },

        -- Construir
        { key = "F5",  modifiers = {},        action = "IntelliJ IDEA" },
        { key = "F5",  modifiers = {"shift"}, action = "DBeaver" },
        { key = "F6",  modifiers = {},        action = "Visual Studio Code" },
        { key = "F7",  modifiers = {},        action = "OpenLens" },
        { key = "F8",  modifiers = {},        action = "Ghostty" },

        -- Personal y meta
        { key = "F9",  modifiers = {},        action = "Obsidian" },
        -- Mural es la libreta visual: va al lado de las notas, no de los navegadores.
        { key = "F9",  modifiers = {"shift"}, action = "Mural" },
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
    -- Todo al 50%, un único mapa para los dos modos. El criterio es el mismo que en
    -- mac-work y no es estético: el lado decide QUÉ SE VE A LA VEZ, porque dos apps del
    -- mismo lado se tapan siempre. Editor+terminal, editor+navegador y notas+navegador
    -- funcionan; a cambio Obsidian y el IDE ya no conviven —son las dos superficies
    -- donde escribes, y esa es la pareja que se sacrifica.

    -- Izquierda: donde escribes. Son alternativas de verdad entre sí.
    leftApps = {
        "IntelliJ IDEA",
        "Visual Studio Code",
        "DBeaver",
        "Obsidian",
        "Mural"
    },

    -- Derecha: lo que acompaña. Aquí caen también las notificaciones de macOS
    -- (arriba a la derecha), que molestan mucho menos sobre un navegador.
    rightApps = {
        "Ghostty",
        "Google Chrome",
        "Google Chrome Canary",
        "Chromium",
        "Slack",
        "Microsoft Teams",
        "Microsoft Outlook",
        "OpenLens",
        "Finder"
    },

    -- El doble toque expande al centro a 2/3. Canary va a pantalla completa en su lugar:
    -- una prueba de navegador no cabe en dos tercios.
    expandFull = { "Google Chrome Canary" },

    ---------------------------------------------------------------------------
    -- Los dos modos
    ---------------------------------------------------------------------------
    -- Solo cambian qué se lanza y qué pestañas se abren. Los lados son los mismos, así
    -- que una app que este modo no lance se coloca igual al abrirla a mano — que es lo
    -- que la rejilla anterior no hacía: en Kaizen, todo lo que no estuviera en su tabla
    -- caía donde quisiera.
    --
    -- Sin `comms`: las ventanas de comunicación son cosa de la máquina de trabajo.
    modes = {
        work = {
            launch = {
                "IntelliJ IDEA", "Visual Studio Code", "DBeaver", "Obsidian", "Mural",
                "Ghostty", "Google Chrome", "Google Chrome Canary", "Chromium",
                "Slack", "Microsoft Teams", "Microsoft Outlook", "OpenLens"
            },
            foreground = { "Google Chrome", "IntelliJ IDEA" },

            chrome = {
                urls = {
                    "https://tracker.zooplus.de/secure/RapidBoard.jspa?rapidView=6963&projectKey=DPF",
                    "https://src.private.zooplus.net/dashboard",
                    "https://zpl.awsapps.com/start/#/?tab=accounts",
                    "https://dna-jenkins.cicdk8sp.int.aws.zooplus.io/job/Zoobrain/job/DZB/job/zoobrain/",
                    "https://sonarqube.private.zooplus.net/dashboard?id=dzb%3Azoobrain%3Aui",
                    "https://zoobrain.private.zooplus.net",
                    "https://grafana.dnap.int.aws.zooplus.io/login",
                    "https://zooplus.atlassian.net/wiki/spaces/DAC/overview"
                }
            },

            chromium = {
                urls = {
                    "https://m365.cloud.microsoft/chat/",
                    "https://claude.ai/new",
                    "https://gemini.google.com/app?hl=es-ES"
                }
            }
        },

        kaizen = {
            launch = {
                "Google Chrome", "Google Chrome Canary", "Chromium",
                "Visual Studio Code", "Obsidian", "Ghostty"
            },
            foreground = { "Google Chrome", "Obsidian" },

            chrome = {
                urls = {
                    "https://mail.google.com/mail/u/0/#inbox",
                    "https://calendar.google.com/calendar/u/0/r",
                    "https://frontendmasters.com/login/?return=%2Fmy-account%2Flibrary%2F",
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
        }
    },

    -- Apps que corren con un nombre distinto al de su .app, o cuyo nombre es prefijo de
    -- otro: hs.application.get() hace match por subcadena, así que sin el bundle ID
    -- "Google Chrome" puede resolver a "Google Chrome Canary" y colocarse la que no es.
    appIds = {
        ["Visual Studio Code"]   = "com.microsoft.VSCode",
        ["Google Chrome"]        = "com.google.Chrome",
        ["Google Chrome Canary"] = "com.google.Chrome.canary"
    }
}
