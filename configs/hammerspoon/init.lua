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
    local script = "tell application \"" .. appName .. "\"\nactivate\ndelay 1\ntell window 1\n"
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

-- Pantalla portátil
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

-- Función para cerrar todas las apps excepto Hammerspoon
local function closeAllWindows()
    for _, app in ipairs(hs.application.runningApplications()) do
        if app:kind() == 1 and app:name() ~= "Hammerspoon" then
            app:kill()
        end
    end
end

-- Funciones principales
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

local function bringAppsToFront(appNames)
    for _, name in ipairs(appNames) do
        local app = hs.application.get(name)
        if app and app:mainWindow() then
            app:activate()
        end
    end
end

local function workMode()
    debugPrint("🧑🏾‍💻 Entering Work mode ...")
    adaptLayoutForCurrentScreen(config.workAppLayout)
    closeAllWindows()
    openAndArrange(config.workAppLayout)
    hs.timer.doAfter(config.appLaunchDelay + 1, function()
        handleChrome()
        handleChromium()
        bringAppsToFront(config.foregroundApps.work)
    end)
end

local function kaizenMode()
    debugPrint("Starting Kaizen Mode...")
    hs.alert.show("⛩️ Entering Kaizen Mode...")
    adaptLayoutForCurrentScreen(config.kaizenAppLayout)
    closeAllWindows()
    hs.timer.doAfter(2, function()
        openAndArrange(config.kaizenAppLayout)
        hs.timer.doAfter(config.appLaunchDelay + 1, function()
            handleKaizenChrome()
            handleKaizenChromium()
            bringAppsToFront(config.foregroundApps.kaizen)

        end)
    end)
end

-- Teclas de función
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
        elseif action then
            hs.hotkey.bind(modifiers, key, function()
                hs.application.launchOrFocus(action)
            end)
        end
    end
end

-- Ejecutar
configureFunctionKeys()
workMode()