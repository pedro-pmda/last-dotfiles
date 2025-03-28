hs.console.clearConsole()

local config = require("app_config")

local function debugPrint(message)
    if config.debugMode then hs.alert.show(message) end
end

-- **Helper Functions for Window Management**
local function getSizeFraction(screenSize, fraction)
    local fractions = {
        ["1/3"] = screenSize / 3, ["2/3"] = (screenSize / 3) * 2, ["3/3"] = screenSize,
        ["1/4"] = screenSize / 4, ["2/4"] = (screenSize / 4) * 2, ["3/4"] = (screenSize / 4) * 3, ["4/4"] = screenSize
    }
    return fractions[fraction] or screenSize
end

local function calculatePosition(screen, width, height, horizontalPos, verticalPos)
    local xPositions = { left = screen.x, center = screen.x + (screen.w - width) / 2, right = screen.x + screen.w - width }
    local yPositions = { top = screen.y, center = screen.y + (screen.h - height) / 2, bottom = screen.y + screen.h - height }
    return xPositions[horizontalPos] or screen.x, yPositions[verticalPos] or screen.y
end

local function moveWindow(appName)
    local app = hs.application.get(appName)
    if app then
        local win = app:mainWindow()
        if win then
            local screen = hs.screen.primaryScreen():frame()
            local appConfig = nil

            for _, cfg in ipairs(config.appLayout) do
                if cfg.name == appName then
                    appConfig = cfg
                    break
                end
            end

            if appConfig then
                local width = getSizeFraction(screen.w, appConfig.width)
                local height = getSizeFraction(screen.h, appConfig.height)
                local x, y = calculatePosition(screen, width, height, appConfig.position, appConfig.vertical)

                debugPrint("Moving " .. appName .. " to " .. appConfig.position)
                win:setFrame(hs.geometry.rect(x, y, width, height))
            end
        else
            debugPrint(appName .. " window not found, retrying...")
            hs.timer.doAfter(2, function() moveWindow(appName) end)
        end
    else
        debugPrint(appName .. " not running, retrying...")
        hs.timer.doAfter(2, function() moveWindow(appName) end)
    end
end

-- **Generic Browser Tab Handler**
local function openBrowserWithUrls(appName, urls)
    local script = "tell application \"" .. appName .. "\"\nactivate\ndelay 1\n"
    script = script .. "tell window 1\n"

    for _, url in ipairs(urls) do
        script = script .. "make new tab with properties {URL: \"" .. url .. "\"}\n"
    end

    script = script .. "end tell\nend tell"
    hs.osascript.applescript(script)
end

-- **Chrome Handling**
local function handleChrome()
    openBrowserWithUrls("Google Chrome", config.chromeConfig.urls)
end

-- **Chromium Handling**
local function handleChromium()
    openBrowserWithUrls("Chromium", config.chromiumConfig.urls)
end

-- **Configure Function Keys**
local function configureFunctionKeys()
    for key, appName in pairs(config.functionKeys) do
        if appName == "RELOAD_HAMMERSPOON" then
            hs.hotkey.bind({}, key, function()
                debugPrint("Reloading Hammerspoon configuration...")
                hs.reload()
            end)
        else
            hs.hotkey.bind({}, key, function()
                debugPrint("Launching " .. appName)
                hs.application.launchOrFocus(appName)
            end)
        end
    end
end

-- **Open and Arrange All Apps First**
local function openAllApps()
    for _, appConfig in ipairs(config.appLayout) do
        debugPrint("Launching " .. appConfig.name)
        hs.application.launchOrFocus(appConfig.name)
    end
end

local function configureScreens()
    for _, appConfig in ipairs(config.appLayout) do
        for i = 0, 2 do -- Reintento 3 veces con separación de 2s
            hs.timer.doAfter(i * 2, function()
                moveWindow(appConfig.name)
            end)
        end
    end
end

-- 🆕 Detectar si usamos pantalla del portátil
local function isUsingLaptopScreen()
    local screen = hs.screen.primaryScreen()
    if not screen then return false end

    local screenName = screen:name() or ""
    return screenName:lower():find("built%-in retina display") ~= nil
end

-- 🆕 Adaptar layout para pantalla del portátil con alerta visual
local function adaptAppLayoutForCurrentScreen()
    if isUsingLaptopScreen() then
        local msg = "💻 Laptop screen detected → Fullscreen layout"
        debugPrint(msg)
        hs.alert.show(msg)

        for _, appConfig in ipairs(config.appLayout) do
            appConfig.position = "center"
            appConfig.width = "3/3"
            appConfig.height = "3/3"
            appConfig.vertical = "center"
        end
    else
        local msg = "🖥️ External screen detected → Multi-window layout"
        debugPrint(msg)
        hs.alert.show(msg)
    end
end

-- **Work Mode Execution**
local function workMode()
    debugPrint("Starting work mode...")
    adaptAppLayoutForCurrentScreen()
    openAllApps()

    hs.timer.doAfter(config.appLaunchDelay, function()
        configureScreens()
        configureFunctionKeys()
        debugPrint("Opening browser tabs...")
        handleChrome()
        handleChromium()
    end)
end

workMode()
