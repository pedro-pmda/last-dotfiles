-- lua-wm: Linux equivalent of Hammerspoon
-- Deps: lua5.3 lua-lgi gir1.2-keybinder-3.0 gir1.2-wnck-3.0 gir1.2-notify-0.7
-- Loads ~/.config/lua-wm/app_config.lua (symlink to the active profile)

local lgi       = require("lgi")
local GLib      = lgi.require("GLib")
local Gtk       = lgi.require("Gtk", "3.0")
local Gdk       = lgi.require("Gdk", "3.0")
local Gio       = lgi.require("Gio", "2.0")
local Wnck      = lgi.require("Wnck", "3.0")
local Keybinder = lgi.require("Keybinder", "3.0")
local Notify    = lgi.require("Notify", "0.7")

Gtk.init()
pcall(function() Keybinder.init() end)
Notify.init("lua-wm")
Wnck.set_client_type(Wnck.ClientType.PAGER)

local config = require("app_config")

-- ─── App discovery ──────────────────────────────────────────────────────────
-- Builds two indexes keyed by the display name used in profile app lists:
--   wmClassIndex[name] = wm_class string (what Wnck reports)
--   appInfoIndex[name] = GDesktopAppInfo (used to launch the app)

local wmClassIndex = {}
local appInfoIndex = {}

local function buildAppIndex()
    for _, info in ipairs(Gio.DesktopAppInfo.get_all()) do
        local name = info:get_name()
        if name then
            appInfoIndex[name] = info
            local cls = info:get_startup_wm_class()
            if cls and cls ~= "" then
                wmClassIndex[name] = cls:lower()
            else
                -- Fallback: strip .desktop suffix from the app id
                local id = info:get_id() or ""
                wmClassIndex[name] = id:gsub("%.desktop$", ""):lower()
            end
        end
    end
end

-- ─── Alerts / Notifications ──────────────────────────────────────────────────

local function alert(msg)
    if config.debugMode then
        local n = Notify.Notification.new(msg)
        n:set_timeout(2000)
        pcall(function() n:show() end)
    end
end

local function notify(msg)
    local n = Notify.Notification.new(msg)
    n:set_timeout(3000)
    pcall(function() n:show() end)
end

-- ─── Screen frame ────────────────────────────────────────────────────────────
-- Returns work area (excluding taskbar) of the primary monitor.

local function getScreenFrame()
    local screen = Gdk.Screen.get_default()
    if screen then
        local mon = screen:get_primary_monitor()
        local rect = screen:get_monitor_workarea(mon)
        if rect then
            return { x = rect.x or 0, y = rect.y or 0,
                     w = rect.width or 1920, h = rect.height or 1080 }
        end
        return { x = 0, y = 0, w = screen:get_width(), h = screen:get_height() }
    end
    -- Sin Gdk no hay geometría real: se marca para que shouldTile() no decida
    -- a partir de un 1920x1080 inventado.
    return { x = 0, y = 0, w = 1920, h = 1080, fallback = true }
end

-- eDP/LVDS are the X11 connector names for built-in laptop screens.
local function isUsingLaptopScreen()
    local f = io.popen("xrandr --listmonitors 2>/dev/null | grep -cE 'eDP|LVDS'")
    if not f then return false end
    local n = tonumber(f:read("*a")) or 0
    f:close()
    return n > 0
end

-- ¿Hay ancho de sobra para repartir ventanas? Igual que en Hammerspoon, se decide
-- por geometría y no por el conector: contar eDP/LVDS respondía a "¿hay panel
-- integrado?", que sigue siendo cierto con el portátil abierto y un monitor
-- externo conectado, así que forzaba pantalla completa cuando no tocaba.
-- xrandr queda solo como respaldo para cuando Gdk no sabe dar el workarea.
local function shouldTile()
    local screen = getScreenFrame()
    if screen.fallback then
        return not isUsingLaptopScreen()
    end
    return screen.w >= (config.minWidthForTiling or 2000)
end

-- ─── Window helpers ──────────────────────────────────────────────────────────

local function findWindowByName(appName)
    local wnckScreen = Wnck.Screen.get_default()
    wnckScreen:force_update()
    local wmClass = wmClassIndex[appName]
    if not wmClass then return nil end
    for _, win in ipairs(wnckScreen:get_windows()) do
        if win:get_class_group_name():lower() == wmClass then
            return win
        end
    end
    return nil
end

local function launchOrFocusApp(appName)
    local win = findWindowByName(appName)
    if win then
        win:activate(0)
        return
    end
    local info = appInfoIndex[appName]
    if info then
        local ctx = Gdk.Display.get_default():get_app_launch_context()
        pcall(function() info:launch(nil, ctx) end)
    end
end

-- ─── Geometry (identical logic to Hammerspoon init.lua) ─────────────────────

local function getSizeFraction(screenSize, fraction)
    local fractions = {
        ["1/3"] = screenSize / 3,       ["2/3"] = (screenSize / 3) * 2,
        ["3/3"] = screenSize,            ["1/4"] = screenSize / 4,
        ["2/4"] = (screenSize / 4) * 2, ["3/4"] = (screenSize / 4) * 3,
        ["4/4"] = screenSize,            ["2/2"] = screenSize,
    }
    return fractions[fraction] or screenSize
end

local function calculatePosition(screen, width, height, horizontalPos, verticalPos)
    local xPositions = {
        left   = screen.x,
        center = screen.x + (screen.w - width) / 2,
        right  = screen.x + screen.w - width,
    }
    local yPositions = {
        top    = screen.y,
        center = screen.y + (screen.h - height) / 2,
        bottom = screen.y + screen.h - height,
    }
    return xPositions[horizontalPos] or screen.x, yPositions[verticalPos] or screen.y
end

local function moveWindow(appName, layoutTable)
    local win = findWindowByName(appName)
    if not win then return end
    local screen = getScreenFrame()
    for _, cfg in ipairs(layoutTable) do
        if cfg.name == appName then
            local pos, vert = cfg.position, cfg.vertical
            local w, h = cfg.width, cfg.height
            -- Sin sitio para repartir: pantalla completa. En locales, nunca
            -- escribiendo en la tabla del profile. Antes esto lo hacía
            -- adaptLayoutForCurrentScreen mutando la tabla, así que en cuanto
            -- corría con el portátil solo, las fracciones originales se perdían
            -- para toda la vida del proceso y reconectar el monitor no las
            -- recuperaba sin reiniciar el servicio.
            if not shouldTile() then
                pos, vert, w, h = "center", "center", "3/3", "3/3"
            end
            local width  = getSizeFraction(screen.w, w)
            local height = getSizeFraction(screen.h, h)
            local x, y  = calculatePosition(screen, width, height, pos, vert)
            -- Muffin ignores set_geometry on maximized windows — always unmaximize first.
            win:unmaximize()
            -- STATIC gravity (10) = coordinates are screen-relative.
            -- Mask 15 = X(1)|Y(2)|WIDTH(4)|HEIGHT(8).
            win:set_geometry(Wnck.WindowGravity.STATIC, 15,
                math.floor(x), math.floor(y), math.floor(width), math.floor(height))
            return
        end
    end
end

-- Solo avisa del modo en el que se va a colocar. Quien decide es shouldTile(),
-- en cada moveWindow, para que desconectar el monitor no exija reiniciar.
local function announceScreenMode()
    if shouldTile() then
        notify("🖥️ External screen → multi-window layout")
    else
        notify("💻 Laptop screen → fullscreen layout")
    end
end

-- Layout del modo activo. Lo actualizan workMode() y kaizenMode() para que
-- recolocar devuelva las ventanas al sitio del modo en el que estás.
local currentLayout = config.workAppLayout

-- Coloca una app al pulsar su tecla, buscando su sitio en el layout del modo
-- activo y, si no está ahí, en el de apps que solo se abren a mano.
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
            if findWindowByName(cfg.name) then
                moveWindow(cfg.name, layoutTable)
                moved = moved + 1
            end
        end
    end
    notify("🧹 " .. moved .. " ventanas recolocadas")
end

local function closeAllWindows()
    local wnckScreen = Wnck.Screen.get_default()
    wnckScreen:force_update()
    for _, win in ipairs(wnckScreen:get_windows()) do
        if win:get_window_type() == Wnck.WindowType.NORMAL then
            win:close(0)
        end
    end
end

local function openAndArrange(layoutTable)
    for _, appCfg in ipairs(layoutTable) do
        launchOrFocusApp(appCfg.name)
    end
    GLib.timeout_add(GLib.PRIORITY_DEFAULT, math.floor(config.appLaunchDelay * 1000),
        function()
            for _, appCfg in ipairs(layoutTable) do
                for i = 0, 2 do
                    GLib.timeout_add(GLib.PRIORITY_DEFAULT, i * 2000, function()
                        moveWindow(appCfg.name, layoutTable)
                        return false
                    end)
                end
            end
            return false
        end)
end

local function bringAppsToFront(appNames)
    for _, name in ipairs(appNames) do
        local win = findWindowByName(name)
        if win then win:activate(0) end
    end
end

-- ─── Browser tab opening (replaces AppleScript) ─────────────────────────────

-- Debian empaqueta el binario como 'chromium' y Ubuntu como 'chromium-browser',
-- así que se prueban los candidatos y se usa el primero que exista.
local function firstAvailable(candidates)
    for _, bin in ipairs(candidates) do
        local f = io.popen("command -v " .. bin .. " 2>/dev/null")
        if f then
            local found = f:read("*a")
            f:close()
            if found and found:match("%S") then return bin end
        end
    end
    return nil
end

local browserBinary = {
    ["Google Chrome"] = firstAvailable({ "google-chrome", "google-chrome-stable" }),
    ["Chromium"]      = firstAvailable({ "chromium", "chromium-browser" }),
}

-- Las URLs vienen del profile, pero acaban en una línea de shell: sin citarlas,
-- cualquier & o ; en una query rompe el comando (o ejecuta otra cosa).
local function shellQuote(s)
    return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

local function openBrowserWithUrls(appName, urls)
    local binary = browserBinary[appName]
    -- xdg-open no entiende --new-tab, así que el fallback no puede llevarlo.
    local flag = binary and " --new-tab " or " "
    binary = binary or "xdg-open"
    for _, url in ipairs(urls) do
        -- io.popen deja el handle abierto; con una pestaña por URL se acumulan.
        local f = io.popen(binary .. flag .. shellQuote(url) .. " >/dev/null 2>&1 &")
        if f then f:close() end
    end
end

local function handleChrome()
    if config.workChromeConfig then
        openBrowserWithUrls("Google Chrome", config.workChromeConfig.urls)
    end
end

local function handleChromium()
    if config.workChromiumConfig then
        openBrowserWithUrls("Chromium", config.workChromiumConfig.urls)
    end
end

local function handleKaizenChrome()
    if config.kaizenChromeConfig then
        openBrowserWithUrls("Google Chrome", config.kaizenChromeConfig.urls)
    end
end

local function handleKaizenChromium()
    if config.kaizenChromiumConfig then
        openBrowserWithUrls("Chromium", config.kaizenChromiumConfig.urls)
    end
end

-- ─── Modes ───────────────────────────────────────────────────────────────────

local function workMode()
    notify("🧑🏾‍💻 Entering Work Mode...")
    currentLayout = config.workAppLayout
    announceScreenMode()
    closeAllWindows()

    GLib.timeout_add(GLib.PRIORITY_DEFAULT, 2000, function()
        local ok, err = pcall(openAndArrange, config.workAppLayout)
        if not ok then io.stderr:write("lua-wm openAndArrange error: " .. tostring(err) .. "\n") end
        return false
    end)

    GLib.timeout_add(GLib.PRIORITY_DEFAULT, math.floor((config.appLaunchDelay + 6) * 1000),
        function()
            pcall(handleChrome)
            pcall(handleChromium)
            if config.foregroundApps then
                bringAppsToFront(config.foregroundApps.work or {})
            end
            notify("🧑🏾‍💻 Work Mode ready")
            return false
        end)
end

local function kaizenMode()
    notify("⛩️ Entering Kaizen Mode...")
    currentLayout = config.kaizenAppLayout
    announceScreenMode()
    closeAllWindows()

    GLib.timeout_add(GLib.PRIORITY_DEFAULT, 2000, function()
        local ok, err = pcall(openAndArrange, config.kaizenAppLayout)
        if not ok then io.stderr:write("lua-wm openAndArrange error: " .. tostring(err) .. "\n") end
        return false
    end)

    GLib.timeout_add(GLib.PRIORITY_DEFAULT, math.floor((config.appLaunchDelay + 6) * 1000),
        function()
            pcall(handleKaizenChrome)
            pcall(handleKaizenChromium)
            if config.foregroundApps then
                bringAppsToFront(config.foregroundApps.kaizen or {})
            end
            notify("⛩️ Kaizen Mode ready")
            return false
        end)
end

-- ─── Hotkey binding ──────────────────────────────────────────────────────────
-- Converts the profile's modifiers array to GTK accelerator string format:
--   {} + "F1"        →  "F1"
--   {"shift"} + "F11" →  "<Shift>F11"

local modMap = {
    shift = "<Shift>",
    ctrl  = "<Control>",
    alt   = "<Alt>",
    super = "<Super>",
    cmd   = "<Super>",
}

local function toAccel(mods, key)
    local prefix = ""
    for _, m in ipairs(mods) do
        prefix = prefix .. (modMap[m:lower()] or "")
    end
    return prefix .. key
end

local function configureFunctionKeys()
    for _, mapping in ipairs(config.functionKeys) do
        local accel  = toAccel(mapping.modifiers or {}, mapping.key)
        local action = mapping.action
        if action then
            Keybinder.bind(accel, function()
                if action == "RELOAD_WM" or action == "RELOAD_HAMMERSPOON" then
                    -- Restart the service (which reloads config via symlinked profile)
                    os.execute("systemctl --user restart lua-wm.service &")
                elseif action == "KAIZEN_MODE" then
                    kaizenMode()
                elseif action == "WORK_MODE" then
                    workMode()
                elseif action == "RESET_LAYOUT" then
                    resetLayout()
                elseif action == "EMOJI" then
                    pcall(function() os.execute("ibus emoji >/dev/null 2>&1 &") end)
                else
                    -- Solo colocar la ventana al abrir la app por primera vez. Si ya
                    -- estaba corriendo la tecla es puro focus: el tamaño que le hayas
                    -- dado se respeta. Antes la tecla nunca colocaba nada en Linux.
                    local wasRunning = findWindowByName(action) ~= nil
                    launchOrFocusApp(action)
                    if not wasRunning then
                        GLib.timeout_add(GLib.PRIORITY_DEFAULT,
                            math.floor(config.appLaunchDelay * 1000), function()
                                positionApp(action)
                                return false
                            end)
                    end
                end
            end)
        end
    end
end

-- ─── Main ────────────────────────────────────────────────────────────────────

buildAppIndex()
configureFunctionKeys()
workMode()

GLib.MainLoop.new(nil, false):run()
