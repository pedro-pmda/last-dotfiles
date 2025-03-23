return {
    appLaunchDelay = 5,
    debugMode = false,

    functionKeys = {
        F1  = "Google Chrome",
        F2  = "Visual Studio Code",
        F3  = "IntelliJ IDEA",
        F4  = "DBeaver",
        F5  = "Slack",
        F6  = "Chromium", 
        F7  = "Obsidian",
        F8  = "Mural",
        F9  = "OpenLens",
        F10 = "Warp",
        F11 = "Google Chrome Canary",
        F12 = "RELOAD_HAMMERSPOON"
    },

    chromeConfig = {
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

    chromiumConfig = {
        urls = {
            "https://chatgpt.com/",
            "https://gemini.google.com/app?hl=es-ES",
            "https://notebooklm.google.com/",
            "https://chat.deepseek.com/",
            "https://huggingface.co/datasets"
        }
    },

    appLayout = {
        { name = "Chromium", position = "left", width = "1/3", vertical = "top", height = "3/3" },  
        { name = "Slack", position = "left", width = "1/3", vertical = "top", height = "3/3" },
        { name = "Warp", position = "right", width = "2/4", vertical = "top", height = "3/3" },
        { name = "Visual Studio Code", position = "right", width = "2/3", vertical = "top", height = "3/3" },
        { name = "IntelliJ IDEA", position = "right", width = "2/3", vertical = "top", height = "3/3" },
        { name = "DBeaver", position = "right", width = "2/3", vertical = "top", height = "3/3" },
        { name = "Obsidian", position = "left", width = "1/3", vertical = "top", height = "3/3" },
        { name = "Mural", position = "right", width = "2/3", vertical = "top", height = "3/3" },
        { name = "OpenLens", position = "right", width = "2/3", vertical = "top", height = "3/3" },
        { name = "Google Chrome", position = "right", width = "2/3", vertical = "top", height = "3/3" },
        { name = "Google Chrome Canary", position = "center", width = "3/4", vertical = "center", height = "3/4" }
    },

    foregroundApps = { "Obsidian", "IntelliJ IDEA" }
}
