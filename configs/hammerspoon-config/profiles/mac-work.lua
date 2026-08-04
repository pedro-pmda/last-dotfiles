return {
    appLaunchDelay = 5,
    debugMode = false,

    -- Por debajo de este ancho en la pantalla principal no se reparten ventanas:
    -- todo va a pantalla completa. El ultrawide (3440) tilea, la interna (1512) no.
    minWidthForTiling = 2000,

    -- Una tecla = un dominio. Sin modificador la app principal, con shift la variante.
    -- Bloques: F1-F4 comunicar · F5-F8 construir · F9-F12 personal/meta
    functionKeys = {
        -- Comunicar
        { key = "F1",  modifiers = {},        action = "Google Chrome" },
        { key = "F1",  modifiers = {"shift"}, action = "Google Chrome Canary" },
        { key = "F2",  modifiers = {},        action = "Claude" },
        { key = "F2",  modifiers = {"shift"}, action = "Chromium" },
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

    workChromeConfig = {
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

    workChromiumConfig = {
        urls = {
            "https://gemini.google.com/app?hl=es-ES"
        }
    },

    kaizenChromeConfig = {
        urls = {
            "https://mail.google.com/mail/u/0/#inbox",
            "https://calendar.google.com/calendar/u/0/r",
            "https://master.dev/dashboard/",
            "https://anthropic.skilljar.com/",
            "https://englishonline.britishcouncil.org/platform/nui/reactui/build/index.html?dd613#/login",
            "https://www.edclub.com/sportal/",            
        }
    },

    kaizenChromiumConfig = {
        urls = {
            "https://gemini.google.com/app?hl=es-ES",
            "https://claude.ai/new"
        }
    },
        
    -- Tres columnas en el ultrawide: 1/4 comunicar · 2/4 trabajar · 1/4 IA.
    -- `center` es simétrico, así que las dos columnas de los lados tienen que medir
    -- lo mismo: 1/4 + 2/4 + 1/4 es el único reparto de tres que sale con estas fracciones.
    -- La columna derecha es exclusiva de los chats de IA: nada más va ahí, o dejan de
    -- estar visibles en cuanto pulsas otra tecla.
    workAppLayout = {
        -- Comunicar: se tapan entre sí a propósito, son vistazos
        { name = "Slack", position = "left", width = "1/4", vertical = "top", height = "3/3" },
        { name = "Microsoft Teams", position = "left", width = "1/4", vertical = "top", height = "3/3" },
        { name = "Microsoft Outlook", position = "left", width = "1/4", vertical = "top", height = "3/3" },
        { name = "Finder", position = "left", width = "1/4", vertical = "top", height = "3/3" },

        -- Trabajar: la superficie que más píxeles pide
        { name = "IntelliJ IDEA", position = "center", width = "2/4", vertical = "top", height = "3/3" },
        { name = "Visual Studio Code", position = "center", width = "2/4", vertical = "top", height = "3/3" },
        { name = "Ghostty", position = "center", width = "2/4", vertical = "top", height = "3/3" },
        { name = "Google Chrome", position = "center", width = "2/4", vertical = "top", height = "3/3" },
        { name = "DBeaver", position = "center", width = "2/4", vertical = "top", height = "3/3" },
        { name = "OpenLens", position = "center", width = "2/4", vertical = "top", height = "3/3" },
        { name = "Kiro", position = "center", width = "2/4", vertical = "top", height = "3/3" },

        -- IA: columna reservada, siempre presente
        { name = "Claude", position = "right", width = "1/4", vertical = "top", height = "3/3" },
        { name = "Microsoft 365 Copilot", position = "right", width = "1/4", vertical = "top", height = "3/3" },
        { name = "Chromium", position = "right", width = "1/4", vertical = "top", height = "3/3" },

        -- Pantalla pequeña: las dos a pantalla completa, alternas con F9 / Shift+F9
        { name = "Obsidian", screen = "secondary", position = "center", width = "4/4", vertical = "center", height = "4/4" },
        { name = "WebPomodoro", screen = "secondary", position = "center", width = "4/4", vertical = "center", height = "4/4" },

        -- Escape deliberado: pantalla completa para demos y pruebas
        { name = "Google Chrome Canary", position = "center", width = "4/4", vertical = "center", height = "4/4" }
    },

    -- Las dos únicas que no arrancan con el layout: pesan y no se usan a diario.
    -- Tienen sitio reservado para cuando las abres a mano con Shift+F7 / Shift+F8.
    onDemandAppLayout = {
        { name = "Docker", position = "center", width = "2/4", vertical = "top", height = "3/3" },
        { name = "Cyberduck", position = "left", width = "1/4", vertical = "top", height = "3/3" }
    },

    -- Misma geometría, otros inquilinos: en kaizen la IA es Chromium (Gemini y Claude web)
    kaizenAppLayout = {
        { name = "Google Chrome", position = "center", width = "2/4", vertical = "top", height = "3/3" },
        { name = "Visual Studio Code", position = "center", width = "2/4", vertical = "top", height = "3/3" },
        { name = "Ghostty", position = "center", width = "2/4", vertical = "top", height = "3/3" },
        { name = "Chromium", position = "right", width = "1/4", vertical = "top", height = "3/3" },
        { name = "Obsidian", screen = "secondary", position = "center", width = "4/4", vertical = "center", height = "4/4" },
        { name = "WebPomodoro", screen = "secondary", position = "center", width = "4/4", vertical = "center", height = "4/4" },
        { name = "Google Chrome Canary", position = "center", width = "4/4", vertical = "center", height = "4/4" }
    },

    foregroundApps = {
        work = { "Obsidian", "IntelliJ IDEA" },
        kaizen = { "Google Chrome", "Obsidian" }
    },

    -- Apps installed outside the standard /Applications folders need an explicit path
    -- so hs.application.open() can find them (launchOrFocus only searches standard locations).
    appPaths = {
        ["WebPomodoro"] = "/Volumes/SecondBrain/Applications/WebPomodoro.app"
    },

    -- Apps que corren con un nombre distinto al de su .app: sin su bundle ID
    -- hs.application.get() no las encuentra y nunca se colocan.
    appIds = {
        ["Visual Studio Code"] = "com.microsoft.VSCode"
    }

}
