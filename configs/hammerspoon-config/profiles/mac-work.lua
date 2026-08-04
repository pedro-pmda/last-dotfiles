return {
    appLaunchDelay = 5,
    debugMode = false,

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
        { key = "F7",  modifiers = {},        action = "Ghostty" },
        { key = "F7",  modifiers = {"shift"}, action = "Cyberduck" },
        { key = "F8",  modifiers = {},        action = "OpenLens" },
        { key = "F8",  modifiers = {"shift"}, action = "Docker" },

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
        
    workAppLayout = {
        { name = "IntelliJ IDEA", position = "right", width = "2/3", vertical = "top", height = "3/3" },
        { name = "DBeaver", position = "right", width = "2/3", vertical = "top", height = "3/3" },       
        { name = "Slack", position = "left", width = "1/3", vertical = "top", height = "3/3" },
        { name = "Ghostty", position = "right", width = "3/4", vertical = "top", height = "3/3" },
        { name = "Visual Studio Code", position = "right", width = "2/3", vertical = "top", height = "3/3" },
        { name = "Obsidian", position = "left", width = "1/3", vertical = "top", height = "3/3" },
        { name = "OpenLens", position = "right", width = "2/3", vertical = "top", height = "3/3" },
        { name = "Chromium", position = "left", width = "1/3", vertical = "top", height = "3/3" },
        { name = "Google Chrome", position = "right", width = "2/3", vertical = "top", height = "3/3" },
        { name = "Google Chrome Canary", position = "center", width = "4/4", vertical = "center", height = "4/4" },
        { name = "Microsoft Outlook", position = "right", width = "2/3", vertical = "top", height = "3/3" },
        { name = "Microsoft Teams", position = "left", width = "1/3", vertical = "top", height = "3/3" },
        { name = "Microsoft 365 Copilot", position = "left", width = "1/3", vertical = "top", height = "3/3" },
        { name = "Claude", position = "left", width = "1/3", vertical = "top", height = "3/3" },
        { name = "WebPomodoro", position = "right", width = "2/4", vertical = "top", height = "4/4" }
    },

    -- Apps que no se lanzan en ningún modo pero sí tienen sitio cuando las abres a mano
    onDemandAppLayout = {
        { name = "Kiro", position = "right", width = "2/3", vertical = "top", height = "3/3" },
        { name = "Cyberduck", position = "left", width = "1/3", vertical = "top", height = "3/3" },
        { name = "Docker", position = "right", width = "2/3", vertical = "top", height = "3/3" }
    },

    kaizenAppLayout = {
        { name = "Chromium", position = "left", width = "1/3", vertical = "top", height = "3/3" },
        { name = "Google Chrome", position = "left", width = "2/4", vertical = "top", height = "4/4" },
        { name = "Google Chrome Canary", position = "center", width = "4/4", vertical = "center", height = "4/4" },
        { name = "Obsidian", position = "right", width = "2/4", vertical = "top", height = "4/4" },
        { name = "Visual Studio Code", position = "right", width = "2/4", vertical = "top", height = "4/4" },
        { name = "Ghostty", position = "right", width = "2/4", vertical = "top", height = "4/4" },
        { name = "WebPomodoro", position = "right", width = "2/4", vertical = "top", height = "4/4" }
    },

    foregroundApps = {
        work = { "Obsidian", "IntelliJ IDEA" },
        kaizen = { "Google Chrome", "Obsidian" }
    },

    -- Apps installed outside the standard /Applications folders need an explicit path
    -- so hs.application.open() can find them (launchOrFocus only searches standard locations).
    appPaths = {
        ["WebPomodoro"] = "/Volumes/SecondBrain/Applications/WebPomodoro.app"
    }

}
