return {
    appLaunchDelay = 5,
    debugMode = false,

    functionKeys = {
        { key = "F1",  modifiers = {},        action = "Google Chrome" },
        { key = "F2",  modifiers = {},        action = "Visual Studio Code" },
        { key = "F3",  modifiers = {},        action = "IntelliJ IDEA" },
        { key = "F4",  modifiers = {},        action = "DBeaver" },
        { key = "F5",  modifiers = {},        action = "Slack" },
        { key = "F6",  modifiers = {},        action = "Chromium" },
        { key = "F7",  modifiers = {},        action = "Obsidian" },
        { key = "F8",  modifiers = {},        action = "Mural" },
        { key = "F9",  modifiers = {},        action = "OpenLens" },
        { key = "F10", modifiers = {},        action = "Ghostty" },
        { key = "F11", modifiers = {},        action = "Google Chrome Canary" },
        { key = "F12", modifiers = {},        action = nil },
        { key = "F12", modifiers = {"shift"}, action = "RELOAD_HAMMERSPOON" },
        { key = "F11", modifiers = {"shift"}, action = "KAIZEN_MODE" }
    },

    workChromeConfig = {
        urls = {
            "https://tracker.zooplus.de/secure/RapidBoard.jspa?rapidView=950&projectKey=ZOOB",
            "https://tracker.zooplus.de/secure/RapidBoard.jspa?rapidView=1511&projectKey=ZBHD",
            "https://src.private.zooplus.net/projects/DZB/repos/zoobrain/pull-requests/2268/builds",
            "https://dna-jenkins.cicdk8sp.int.aws.zooplus.io/job/Zoobrain/job/DZB/",
            "https://zpl.awsapps.com/start/#/?tab=accounts",
            "https://sonarqube.private.zooplus.net/dashboard?id=dzb%3Azoobrain%3Aui",
            "https://zoobrain.dnap.int.zooplus.io/ui/datamarts"
        }
    },

    workChromiumConfig = {
        urls = {
            "https://chatgpt.com/",
            "https://gemini.google.com/app?hl=es-ES",
            "https://notebooklm.google.com/",
            "https://chat.deepseek.com/",
            "https://developer.mozilla.org/en-US/"
        }
    },

    kaizenChromeConfig = {
        urls = {
            "https://mail.google.com/mail/u/0/#inbox",
            "https://calendar.google.com/calendar/u/0/r",
            "https://www.233academy.com/courses/take/Product%20Owner%20y%20Agile%20Product%20Manager%20con%20Inteligencia%20Artificial/lessons/54683546-el-product-owner-y-el-product-manager",
            "https://frontendmasters.com/login/?return=%2Fmy-account%2Flibrary%2F",
            "https://englishonline.britishcouncil.org/platform/nui/reactui/build/index.html?dd613#/login",
            "https://www.edclub.com/sportal/"
        }
    },

    kaizenChromiumConfig = {
        urls = {
            "https://chatgpt.com/",
            "https://gemini.google.com/app?hl=es-ES",
            "https://notebooklm.google.com/",
            "https://chat.deepseek.com/",
            "https://huggingface.co/datasets",
            "https://developer.mozilla.org/en-US/"
        }
    },

    workAppLayout = {
        { name = "Chromium", position = "left", width = "1/3", vertical = "top", height = "3/3" },
        { name = "Slack", position = "left", width = "1/3", vertical = "top", height = "3/3" },
        { name = "Ghostty", position = "right", width = "2/4", vertical = "top", height = "3/3" },
        { name = "Visual Studio Code", position = "right", width = "2/3", vertical = "top", height = "3/3" },
        { name = "IntelliJ IDEA", position = "right", width = "2/3", vertical = "top", height = "3/3" },
        { name = "DBeaver", position = "right", width = "2/3", vertical = "top", height = "3/3" },
        { name = "Obsidian", position = "left", width = "1/3", vertical = "top", height = "3/3" },
        { name = "Mural", position = "right", width = "2/3", vertical = "top", height = "3/3" },
        { name = "OpenLens", position = "right", width = "2/3", vertical = "top", height = "3/3" },
        { name = "Google Chrome", position = "right", width = "2/3", vertical = "top", height = "3/3" },
        { name = "Google Chrome Canary", position = "center", width = "4/4", vertical = "center", height = "4/4" }
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
