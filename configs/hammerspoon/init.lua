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
    hs.timer.doAfter(2, function()
        local win = hs.window.find(appName)
        if win then
            local screen = hs.screen.primaryScreen():frame()
            local appConfig = nil

            for _, config in ipairs(config.appLayout) do
                if config.name == appName then
                    appConfig = config
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
    end)
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
    local screen = hs.screen.primaryScreen():frame()
    for _, appConfig in ipairs(config.appLayout) do
        local app = hs.application.get(appConfig.name)
        if app then
            moveWindow(appConfig.name)
        end
    end
end

-- **Work Mode Execution**
local function workMode()
    debugPrint("Starting work mode...")
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
