hs.console.clearConsole()
local config = require("app_config")

local function debugPrint(message)
    if config.debugMode then hs.alert.show(message) end
end

-- Helpers
local function getSizeFraction(screenSize, fraction)
    local fractions = {
        ["1/3"] = screenSize / 3, ["2/3"] = (screenSize / 3) * 2, ["3/3"] = screenSize,
        ["1/4"] = screenSize / 4, ["2/4"] = (screenSize / 4) * 2, ["3/4"] = (screenSize / 4) * 3, ["4/4"] = screenSize,
        ["2/2"] = screenSize
    }
    return fractions[fraction] or screenSize
end

local function calculatePosition(screen, width, height, horizontalPos, verticalPos)
    local xPositions = { left = screen.x, center = screen.x + (screen.w - width) / 2, right = screen.x + screen.w - width }
    local yPositions = { top = screen.y, center = screen.y + (screen.h - height) / 2, bottom = screen.y + screen.h - height }
    return xPositions[horizontalPos] or screen.x, yPositions[verticalPos] or screen.y
end

local function moveWindow(appName, layoutTable)
    local app = hs.application.get(appName)
    if app then
        local win = app:mainWindow()
        if win then
            local screen = hs.screen.primaryScreen():frame()
            local appConfig = nil

            for _, cfg in ipairs(layoutTable) do
                if cfg.name == appName then
                    appConfig = cfg
                    break
                end
            end

            if appConfig then
                local width = getSizeFraction(screen.w, appConfig.width)
                local height = getSizeFraction(screen.h, appConfig.height)
                local x, y = calculatePosition(screen, width, height, appConfig.position, appConfig.vertical)
                win:setFrame(hs.geometry.rect(x, y, width, height))
            end
        end
    end
end

-- Browser opener
local function openBrowserWithUrls(appName, urls)
    local script = "tell application \"" .. appName .. "\"\nactivate\ndelay 3\ntell window 1\n"
    for _, url in ipairs(urls) do
        script = script .. "make new tab with properties {URL: \"" .. url .. "\"}\n"
    end
    script = script .. "end tell\nend tell"
    hs.osascript.applescript(script)
end

local function handleChrome() openBrowserWithUrls("Google Chrome", config.workChromeConfig.urls) end
local function handleChromium() openBrowserWithUrls("Chromium", config.workChromiumConfig.urls) end
local function handleKaizenChrome() openBrowserWithUrls("Google Chrome", config.kaizenChromeConfig.urls) end
local function handleKaizenChromium() openBrowserWithUrls("Chromium", config.kaizenChromiumConfig.urls) end

-- Laptop screen detection
local function isUsingLaptopScreen()
    local screen = hs.screen.primaryScreen()
    if not screen then return false end
    local screenName = screen:name() or ""
    return screenName:lower():find("built%-in retina display") ~= nil
end

local function adaptLayoutForCurrentScreen(layoutTable)
    if isUsingLaptopScreen() then
        for _, appCfg in ipairs(layoutTable) do
            appCfg.position = "center"
            appCfg.width = "3/3"
            appCfg.height = "3/3"
            appCfg.vertical = "center"
        end
        hs.alert.show("💻 Laptop screen → fullscreen layout")
    else
        hs.alert.show("🖥️ External screen → multi-window layout")
    end
end

-- Close all apps except Hammerspoon
local function closeAllWindows()
    for _, app in ipairs(hs.application.runningApplications()) do
        if app:kind() == 1 and app:name() ~= "Hammerspoon" then
            app:kill()
        end
    end
end

-- Launch and arrange apps
local function openAndArrange(layoutTable)
    for _, appCfg in ipairs(layoutTable) do
        hs.application.launchOrFocus(appCfg.name)
    end

    hs.timer.doAfter(config.appLaunchDelay, function()
        for _, appCfg in ipairs(layoutTable) do
            for i = 0, 2 do
                hs.timer.doAfter(i * 2, function()
                    moveWindow(appCfg.name, layoutTable)
                end)
            end
        end
    end)
end

-- Bring apps to front
local function bringAppsToFront(appNames)
    for _, name in ipairs(appNames) do
        local app = hs.application.get(name)
        if app and app:mainWindow() then
            app:activate()
        end
    end
end

-- Work mode
local function workMode()
    debugPrint("🧑🏾‍💻 Entering Work Mode...")
    hs.alert.show("🧑🏾‍💻 Entering Work Mode...")

    adaptLayoutForCurrentScreen(config.workAppLayout)
    closeAllWindows()

    hs.timer.doAfter(2, function()
        debugPrint("🚀 Launching apps (openAndArrange) [Work]")
        local ok, err = pcall(function()
            openAndArrange(config.workAppLayout)
        end)
        if not ok then
            hs.alert.show("❌ Error in openAndArrange (Work): " .. tostring(err))
            debugPrint("❌ Error in openAndArrange (Work): " .. tostring(err))
        else
            hs.alert.show("✅ Work apps launched")
            debugPrint("✅ Work apps launched")
        end
    end)

    hs.timer.doAfter(config.appLaunchDelay + 6, function()
        hs.alert.show("🌐 Opening Chrome and Chromium...")
        debugPrint("🌐 Opening Chrome and Chromium...")

        local ok1, err1 = pcall(handleChrome)
        if not ok1 then debugPrint("❌ Error in handleChrome: " .. tostring(err1)) end

        local ok2, err2 = pcall(handleChromium)
        if not ok2 then debugPrint("❌ Error in handleChromium: " .. tostring(err2)) end

        local ok3, err3 = pcall(function()
            bringAppsToFront(config.foregroundApps.work)
        end)
        if not ok3 then debugPrint("❌ Error bringing apps to front (Work): " .. tostring(err3)) end

        hs.alert.show("🧑🏾‍💻 Work Mode ready")
        debugPrint("🧑🏾‍💻 Work Mode ready")
    end)
end

-- Kaizen mode
local function kaizenMode()
    debugPrint("⛩️ Starting Kaizen Mode...")
    hs.alert.show("⛩️ Entering Kaizen Mode...")

    adaptLayoutForCurrentScreen(config.kaizenAppLayout)
    closeAllWindows()

    hs.timer.doAfter(2, function()
        debugPrint("🚀 Launching apps (openAndArrange) [Kaizen]")
        local ok, err = pcall(function()
            openAndArrange(config.kaizenAppLayout)
        end)
        if not ok then
            hs.alert.show("❌ Error in openAndArrange (Kaizen): " .. tostring(err))
            debugPrint("❌ Error in openAndArrange (Kaizen): " .. tostring(err))
        else
            hs.alert.show("✅ Kaizen apps launched")
            debugPrint("✅ Kaizen apps launched")
        end
    end)

    hs.timer.doAfter(config.appLaunchDelay + 6, function()
        hs.alert.show("🌐 Opening Kaizen Chrome and Chromium...")
        debugPrint("🌐 Opening Kaizen Chrome and Chromium...")

        local ok1, err1 = pcall(handleKaizenChrome)
        if not ok1 then debugPrint("❌ Error in handleKaizenChrome: " .. tostring(err1)) end

        local ok2, err2 = pcall(handleKaizenChromium)
        if not ok2 then debugPrint("❌ Error in handleKaizenChromium: " .. tostring(err2)) end

        local ok3, err3 = pcall(function()
            bringAppsToFront(config.foregroundApps.kaizen)
        end)
        if not ok3 then debugPrint("❌ Error bringing apps to front (Kaizen): " .. tostring(err3)) end

        hs.alert.show("⛩️ Kaizen Mode ready")
        debugPrint("⛩️ Kaizen Mode ready")
    end)
end

-- Function keys
local function configureFunctionKeys()
    for _, mapping in ipairs(config.functionKeys) do
        local key = mapping.key
        local modifiers = mapping.modifiers or {}
        local action = mapping.action
        if action == "RELOAD_HAMMERSPOON" then
            hs.hotkey.bind(modifiers, key, function()
                debugPrint("Reloading config")
                hs.reload()
            end)
        elseif action == "KAIZEN_MODE" then
            hs.hotkey.bind(modifiers, key, function()
                debugPrint("Activating Kaizen Mode...")
                kaizenMode()
            end)
        elseif action == "EMOJI" then
            debugPrint("Activating Emoji Mode...")
            hs.hotkey.bind(modifiers, key, function()
                hs.eventtap.keyStroke({"ctrl", "cmd"}, "space")                
            end)
        elseif action then
            hs.hotkey.bind(modifiers, key, function()
                hs.application.launchOrFocus(action)
            end)
        end
    end
end

-- Start
configureFunctionKeys()
workMode()
