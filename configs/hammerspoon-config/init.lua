hs.console.clearConsole()
local config = require("app_config")

local function debugPrint(message)
    if config.debugMode then hs.alert.show(message) end
end

-- Localiza una app ya abierta. El nombre con el que se lanza (el del .app) no siempre
-- es el que macOS devuelve al buscarla: "Visual Studio Code.app" corre como "Code".
-- Para esos casos el profile declara su bundle ID en `appIds`.
local function getApp(appName)
    local id = config.appIds and config.appIds[appName]
    return (id and hs.application.get(id)) or hs.application.get(appName)
end

-- Launch/focus an app, using its configured path if it lives outside /Applications
local function launchOrFocusApp(appName)
    local path = config.appPaths and config.appPaths[appName]
    if path then
        -- Rutas externas (discos montados) pueden no estar disponibles: avisar en vez de fallar en silencio
        if not hs.fs.attributes(path) then
            hs.alert.show("❌ " .. appName .. " no encontrada en " .. path)
            return
        end
        hs.application.open(path)
    else
        hs.application.launchOrFocus(appName)
    end
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

-- Pantalla destino de una entrada del layout: "primary" (default) o "secondary".
-- Si no hay segunda pantalla cae a la primaria, para que al desconectar el monitor
-- la app no acabe en las coordenadas de una pantalla que ya no existe.
local function resolveScreen(which)
    local primary = hs.screen.primaryScreen()
    if which == "secondary" then
        for _, s in ipairs(hs.screen.allScreens()) do
            if s:id() ~= primary:id() then return s end
        end
    end
    return primary
end

-- ¿Hay ancho de sobra para repartir ventanas? Se decide por geometría y no por el
-- nombre de la pantalla, que varía entre modelos ("Built-in Liquid Retina XDR Display").
-- Pantalla estrecha = estás solo con el portátil = todo a pantalla completa.
local function shouldTile()
    local screen = hs.screen.primaryScreen()
    return screen ~= nil and screen:frame().w >= (config.minWidthForTiling or 2000)
end

local function moveWindow(appName, layoutTable)
    local app = getApp(appName)
    if app then
        local win = app:mainWindow()
        if win then
            local appConfig = nil

            for _, cfg in ipairs(layoutTable) do
                if cfg.name == appName then
                    appConfig = cfg
                    break
                end
            end

            if appConfig then
                local pos, vert = appConfig.position, appConfig.vertical
                local w, h = appConfig.width, appConfig.height
                -- Sin sitio para repartir: pantalla completa. En locales, nunca
                -- escribiendo en la tabla del profile (se perdería al reconectar).
                if not shouldTile() then
                    pos, vert, w, h = "center", "center", "3/3", "3/3"
                end

                local screen = resolveScreen(appConfig.screen):frame()
                local width = getSizeFraction(screen.w, w)
                local height = getSizeFraction(screen.h, h)
                local x, y = calculatePosition(screen, width, height, pos, vert)
                win:setFrame(hs.geometry.rect(x, y, width, height))
            end
        end
    end
end

-- Layout del modo activo. Lo actualizan workMode() y kaizenMode() para que
-- recolocar devuelva las ventanas al sitio del modo en el que estás.
local currentLayout = config.workAppLayout

-- Coloca una app al pulsar su tecla, buscando su sitio en el layout del modo activo
-- y, si no está ahí, en el de apps que solo se abren a mano.
local function positionApp(appName)
    for _, layoutTable in ipairs({ currentLayout, config.onDemandAppLayout or {} }) do
        for _, cfg in ipairs(layoutTable) do
            if cfg.name == appName then
                moveWindow(appName, layoutTable)
                return
            end
        end
    end
end

-- Devuelve a su posición inicial todas las ventanas abiertas ahora mismo.
-- No lanza nada: lo que esté cerrado sigue cerrado.
local function resetLayout()
    local moved = 0
    for _, layoutTable in ipairs({ currentLayout, config.onDemandAppLayout or {} }) do
        for _, cfg in ipairs(layoutTable) do
            local app = getApp(cfg.name)
            if app and app:mainWindow() then
                moveWindow(cfg.name, layoutTable)
                moved = moved + 1
            end
        end
    end
    hs.alert.show("🧹 " .. moved .. " ventanas recolocadas")
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

-- Solo avisa del modo en el que se va a colocar. Quien decide es shouldTile(),
-- en cada moveWindow, para que desconectar el monitor no exija recargar.
local function announceScreenMode()
    if shouldTile() then
        hs.alert.show("🖥️ External screen → multi-window layout")
    else
        hs.alert.show("💻 Laptop screen → fullscreen layout")
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
        launchOrFocusApp(appCfg.name)
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
        local app = getApp(name)
        if app and app:mainWindow() then
            app:activate()
        end
    end
end

-- Work mode
local function workMode()
    debugPrint("🧑🏾‍💻 Entering Work Mode...")
    hs.alert.show("🧑🏾‍💻 Entering Work Mode...")

    currentLayout = config.workAppLayout
    announceScreenMode()
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

    currentLayout = config.kaizenAppLayout
    announceScreenMode()
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
        elseif action == "WORK_MODE" then
            hs.hotkey.bind(modifiers, key, function()
                debugPrint("Activating Work Mode...")
                workMode()
            end)
        elseif action == "RESET_LAYOUT" then
            hs.hotkey.bind(modifiers, key, function()
                debugPrint("Recolocando ventanas abiertas...")
                resetLayout()
            end)
        elseif action == "EMOJI" then
            debugPrint("Activating Emoji Mode...")
            hs.hotkey.bind(modifiers, key, function()
                hs.eventtap.keyStroke({"ctrl", "cmd"}, "space")                
            end)
        elseif action then
            hs.hotkey.bind(modifiers, key, function()
                -- Solo colocar la ventana al abrir la app por primera vez. Si ya estaba
                -- corriendo la tecla es puro focus: el tamaño que le hayas dado se respeta.
                local wasRunning = getApp(action) ~= nil
                launchOrFocusApp(action)
                if not wasRunning then
                    hs.timer.doAfter(config.appLaunchDelay, function() positionApp(action) end)
                end
            end)
        end
    end
end

-- Start
configureFunctionKeys()
workMode()
