return {
    appLaunchDelay = 5,
    debugMode = false,

    -- Por debajo de este ancho en la pantalla principal todo va a pantalla completa
    minWidthForTiling = 2000,

    functionKeys = {
        { key = "F1",  modifiers = {},        action = "Google Chrome" },
        { key = "F1",  modifiers = {"shift"}, action = "Google Chrome Canary" },
        { key = "F2",  modifiers = {},        action = "Visual Studio Code" },
        { key = "F3",  modifiers = {},        action = "IntelliJ IDEA" },
        { key = "F4",  modifiers = {},        action = "Microsoft Teams" },
        { key = "F5",  modifiers = {},        action = "Slack" },
        { key = "F6",  modifiers = {},        action = "Chromium" },
        { key = "F7",  modifiers = {},        action = "Obsidian" },
        { key = "F8",  modifiers = {},        action = "Mural" },
        { key = "F9",  modifiers = {},        action = "OpenLens" },
        { key = "F10", modifiers = {},        action = "Ghostty" },
        { key = "F11", modifiers = {},        action = "WORK_MODE" },
        { key = "F12", modifiers = {},        action = "RESET_LAYOUT" },
        { key = "F6",  modifiers = {"shift"}, action = "EMOJI" },
        { key = "F11", modifiers = {"shift"}, action = "KAIZEN_MODE" },
        { key = "F12", modifiers = {"shift"}, action = "RELOAD_HAMMERSPOON" }
    },

    workChromeConfig = {
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

    workChromiumConfig = {
        urls = {
            "https://m365.cloud.microsoft/chat/",
            "https://claude.ai/new",
            "https://gemini.google.com/app?hl=es-ES"
        }
    },

    kaizenChromeConfig = {
        urls = {
            "https://mail.google.com/mail/u/0/#inbox",
            "https://calendar.google.com/calendar/u/0/r",
            "https://frontendmasters.com/login/?return=%2Fmy-account%2Flibrary%2F",
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
        { name = "Mural", position = "right", width = "2/3", vertical = "top", height = "3/3" },
        { name = "OpenLens", position = "right", width = "2/3", vertical = "top", height = "3/3" },
        { name = "Chromium", position = "left", width = "1/3", vertical = "top", height = "3/3" },
        { name = "Google Chrome", position = "right", width = "2/3", vertical = "top", height = "3/3" },
        { name = "Google Chrome Canary", position = "center", width = "4/4", vertical = "center", height = "4/4" },
        { name = "Microsoft Outlook", position = "right", width = "2/3", vertical = "top", height = "3/3" },
        { name = "Microsoft Teams", position = "left", width = "1/3", vertical = "top", height = "3/3" }
    },

    kaizenAppLayout = {
        { name = "Chromium", position = "left", width = "1/3", vertical = "top", height = "3/3" },
        { name = "Google Chrome", position = "left", width = "2/4", vertical = "top", height = "4/4" },
        { name = "Google Chrome Canary", position = "center", width = "4/4", vertical = "center", height = "4/4" },
        { name = "Obsidian", position = "right", width = "2/4", vertical = "top", height = "4/4" },
        { name = "Visual Studio Code", position = "right", width = "2/4", vertical = "top", height = "4/4" },
        { name = "Ghostty", position = "right", width = "2/4", vertical = "top", height = "4/4" }
    },

    foregroundApps = {
        work = { "Obsidian", "IntelliJ IDEA" },
        kaizen = { "Google Chrome", "Obsidian" }
    }
    
}
