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
        -- Sin este filtro, un .desktop oculto (NoDisplay=true, ej. helpers de
        -- csd) con el mismo Name= que una app real pisa su entrada si se
        -- enumera después: "Files" acababa apuntando a csd-automount en vez
        -- de a Nemo. should_show() no vale: también mira OnlyShowIn, y
        -- gnome-terminal.desktop trae "OnlyShowIn=GNOME;Unity;" — en Cinnamon
        -- eso lo habría descartado sin estar oculto de verdad.
        if not info:get_boolean("NoDisplay") then
            local cls = info:get_startup_wm_class()
            if not cls or cls == "" then
                -- Fallback: strip .desktop suffix from the app id
                cls = (info:get_id() or ""):gsub("%.desktop$", "")
            end
            -- get_name() devuelve el Name= TRADUCIDO al idioma de la sesión, y
            -- get_string("Name") el original. El daemon corre con LANG=es_ES, así
            -- que "Chromium Web Browser" llegaba como "Navegador web Chromium" y
            -- "Files" como "Archivos": el perfil (que usa el Name= tal cual) no
            -- los encontraba y Kaizen nunca los colocaba. Desde un terminal en
            -- inglés no se reproducía. Se indexan los dos.
            for _, name in ipairs({ info:get_string("Name"), info:get_name() }) do
                if name and name ~= "" then
                    appInfoIndex[name] = info
                    wmClassIndex[name] = cls:lower()
                end
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

local function listHas(list, value)
    for _, v in ipairs(list or {}) do
        if v == value then return true end
    end
    return false
end

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

-- Aplica una geometría { position, width, vertical, height } a la ventana de la
-- app. Devuelve true si había ventana que mover.
local function applyGeometry(appName, geo)
    local win = findWindowByName(appName)
    if not win then return false end
    local screen = getScreenFrame()
    local pos, vert = geo.position, geo.vertical
    local w, h = geo.width, geo.height
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
    return true
end

local function moveWindow(appName, layoutTable)
    for _, cfg in ipairs(layoutTable or {}) do
        if cfg.name == appName then
            return applyGeometry(appName, cfg)
        end
    end
    return false
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

-- ─── El mapa de lados ───────────────────────────────────────────────────────
-- Mismo esquema que Hammerspoon: el perfil declara solo el lado (leftApps /
-- rightApps) y la geometría del 50% se deriva aquí. Un perfil que no los
-- declare sigue con la rejilla de siempre (kaizenAppLayout).

local SIDE_GEOMETRY = {
    left  = { position = "left",  width = "2/4", vertical = "top", height = "3/3" },
    right = { position = "right", width = "2/4", vertical = "top", height = "3/3" },
}

local EXPANDED      = { position = "center", width = "2/3", vertical = "top", height = "3/3" }
local EXPANDED_FULL = { position = "center", width = "3/3", vertical = "top", height = "3/3" }

local function buildSideLayout()
    if not config.leftApps and not config.rightApps then return nil end
    local out = {}
    for _, side in ipairs({ "left", "right" }) do
        local geo = SIDE_GEOMETRY[side]
        for _, name in ipairs(config[side .. "Apps"] or {}) do
            table.insert(out, {
                name = name, side = side,
                position = geo.position, width = geo.width,
                vertical = geo.vertical, height = geo.height,
            })
        end
    end
    return out
end

local sideLayout = buildSideLayout()

-- Layout del modo activo. Con lados es uno solo para todo; con la rejilla lo
-- actualiza kaizenMode() para que recolocar devuelva las ventanas a su sitio.
local currentLayout = sideLayout or config.kaizenAppLayout

-- Coloca una app al pulsar su tecla, buscando su sitio en el layout del modo
-- activo y, si no está ahí, en el de apps que solo se abren a mano.
local function positionApp(appName)
    for _, layoutTable in ipairs({ currentLayout or {}, config.onDemandAppLayout or {} }) do
        if moveWindow(appName, layoutTable) then return true end
    end
    return false
end

-- ─── Expandir y colapsar ────────────────────────────────────────────────────
-- El doble toque lleva la ventana al centro a 2/3 y, si ya está ahí, la
-- devuelve a su lado. Solo se recuerda el NOMBRE de la expandida, y antes de
-- usarlo se mide: así sobrevive a que muevas ventanas a mano.

local expandedApp = nil

local function expandGeometryFor(name)
    return listHas(config.expandFull, name) and EXPANDED_FULL or EXPANDED
end

local function expandedWidthFor(name)
    local screen = getScreenFrame()
    if not shouldTile() then return screen.w end
    return getSizeFraction(screen.w, expandGeometryFor(name).width)
end

-- Se mide el marco (get_geometry), no la ventana cliente: en Cinnamon las apps
-- con decoración propia (Obsidian, Chrome) declaran una cliente 32px más ancha
-- por la sombra, mientras que el marco cae donde se pidió. La tolerancia es
-- generosa porque el terminal redondea a celdas enteras (1274 por 1280).
local function isExpanded(name)
    local win = findWindowByName(name)
    if not win then return false end
    local _, _, w = win:get_geometry()
    return w ~= nil and math.abs(w - expandedWidthFor(name)) <= 40
end

-- Al irte a otra app, la que estuviera expandida vuelve sola a su mitad.
local function collapseExpanded(except)
    if not expandedApp or expandedApp == except then return end
    local name = expandedApp
    expandedApp = nil
    if isExpanded(name) then positionApp(name) end
end

-- Devuelve a su posición inicial todas las ventanas abiertas ahora mismo.
-- No lanza nada: lo que esté cerrado sigue cerrado.
local function resetLayout()
    expandedApp = nil
    local moved = 0
    for _, layoutTable in ipairs({ currentLayout or {}, config.onDemandAppLayout or {} }) do
        for _, cfg in ipairs(layoutTable) do
            if applyGeometry(cfg.name, cfg) then moved = moved + 1 end
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

local function bringAppsToFront(appNames)
    for _, name in ipairs(appNames or {}) do
        local win = findWindowByName(name)
        if win then win:activate(0) end
    end
end

-- ─── La tecla de una app ────────────────────────────────────────────────────

local lastPressAt = {}

local function placeOnFirstLaunch(name, wasRunning, fn)
    if wasRunning then fn() return end
    GLib.timeout_add(GLib.PRIORITY_DEFAULT, math.floor(config.appLaunchDelay * 1000),
        function() fn() return false end)
end

local function onAppKey(name)
    -- Sin lados (perfil de rejilla) la tecla es puro focus, como siempre.
    if not sideLayout then
        local wasRunning = findWindowByName(name) ~= nil
        launchOrFocusApp(name)
        if not wasRunning then placeOnFirstLaunch(name, false, function() positionApp(name) end) end
        return
    end

    local now = GLib.get_monotonic_time()          -- microsegundos
    local previous = lastPressAt[name]
    local double = previous ~= nil
                   and (now - previous) < ((config.doubleTapMs or 400) * 1000)
    -- Consumir la marca al detectar el doble, para que una tercera pulsación
    -- cuente como simple. (Nada de `double and nil or now`: en Lua devuelve
    -- `now` cuando double es cierto.)
    if double then lastPressAt[name] = nil else lastPressAt[name] = now end

    if not double then
        collapseExpanded(name)
        -- Solo colocar al abrir la app por primera vez. Si ya estaba corriendo
        -- la tecla es puro focus: el tamaño que le hayas dado se respeta.
        local wasRunning = findWindowByName(name) ~= nil
        launchOrFocusApp(name)
        if not wasRunning then placeOnFirstLaunch(name, false, function() positionApp(name) end) end
        return
    end

    if isExpanded(name) then
        expandedApp = nil
        launchOrFocusApp(name)
        positionApp(name)
        return
    end

    collapseExpanded(name)
    local wasRunning = findWindowByName(name) ~= nil
    launchOrFocusApp(name)
    placeOnFirstLaunch(name, wasRunning, function()
        if applyGeometry(name, expandGeometryFor(name)) then expandedApp = name end
    end)
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
    for _, url in ipairs(urls or {}) do
        -- io.popen deja el handle abierto; con una pestaña por URL se acumulan.
        local f = io.popen(binary .. flag .. shellQuote(url) .. " >/dev/null 2>&1 &")
        if f then f:close() end
    end
end

-- ─── Modes ───────────────────────────────────────────────────────────────────

-- Normaliza los dos esquemas de perfil. El de lados separa "dónde va cada app"
-- (leftApps/rightApps) de "qué lanza el modo" (modes.kaizen.launch); el de
-- rejilla usaba una sola tabla para las dos cosas, y por eso lo que Kaizen no
-- lanzaba tampoco se colocaba.
local function kaizenSpec()
    local mode = config.modes and config.modes.kaizen
    if mode then
        return { layout = sideLayout, launch = mode.launch, chrome = mode.chrome,
                 chromium = mode.chromium, foreground = mode.foreground }
    end
    local layout = config.kaizenAppLayout or {}
    local launch = {}
    for _, cfg in ipairs(layout) do table.insert(launch, cfg.name) end
    return { layout = layout, launch = launch,
             chrome = config.kaizenChromeConfig, chromium = config.kaizenChromiumConfig,
             foreground = config.foregroundApps and config.foregroundApps.kaizen }
end

local function kaizenMode()
    local spec = kaizenSpec()
    notify("⛩️ Entering Kaizen Mode...")
    currentLayout = spec.layout
    expandedApp = nil
    announceScreenMode()
    closeAllWindows()

    GLib.timeout_add(GLib.PRIORITY_DEFAULT, 2000, function()
        local ok, err = pcall(function()
            for _, name in ipairs(spec.launch or {}) do launchOrFocusApp(name) end
            GLib.timeout_add(GLib.PRIORITY_DEFAULT, math.floor(config.appLaunchDelay * 1000),
                function()
                    -- Tres pasadas: algunas apps tardan en tener ventana.
                    for i = 0, 2 do
                        GLib.timeout_add(GLib.PRIORITY_DEFAULT, i * 2000, function()
                            for _, name in ipairs(spec.launch or {}) do
                                moveWindow(name, spec.layout)
                            end
                            return false
                        end)
                    end
                    return false
                end)
        end)
        if not ok then io.stderr:write("lua-wm openAndArrange error: " .. tostring(err) .. "\n") end
        return false
    end)

    GLib.timeout_add(GLib.PRIORITY_DEFAULT, math.floor((config.appLaunchDelay + 6) * 1000),
        function()
            pcall(function() openBrowserWithUrls("Google Chrome", spec.chrome and spec.chrome.urls) end)
            pcall(function() openBrowserWithUrls("Chromium", spec.chromium and spec.chromium.urls) end)
            pcall(function() bringAppsToFront(spec.foreground) end)
            -- Dos pasadas tardías. Las tres de arriba acaban a los appLaunchDelay+4 s,
            -- y hay ventanas que nacen después: Chromium no tiene ventana hasta que
            -- --new-tab de justo aquí arriba lo arranca, y calibre tarda en abrir (y
            -- además saca su diálogo de actualización). Medido en el iMac: las dos
            -- se quedaban a 2560 sin colocar.
            for _, delay in ipairs({ 3000, 6000 }) do
                GLib.timeout_add(GLib.PRIORITY_DEFAULT, delay, function()
                    for _, name in ipairs(spec.launch or {}) do
                        moveWindow(name, spec.layout)
                    end
                    return false
                end)
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
            local bound = Keybinder.bind(accel, function()
                if action == "RELOAD_WM" or action == "RELOAD_HAMMERSPOON" then
                    -- Restart the service (which reloads config via symlinked profile)
                    os.execute("systemctl --user restart lua-wm.service &")
                elseif action == "KAIZEN_MODE" then
                    kaizenMode()
                elseif action == "RESET_LAYOUT" then
                    resetLayout()
                elseif action == "EMOJI" then
                    pcall(function() os.execute("ibus emoji >/dev/null 2>&1 &") end)
                else
                    onAppKey(action)
                end
            end)
            -- Si otro proceso ya tiene el atajo (X11 solo admite un dueño por
            -- tecla), bind devuelve false y la tecla se queda muerta sin más.
            -- En macOS pasó con F11; aquí al menos que se vea.
            if bound == false then
                io.stderr:write("lua-wm: no se pudo enlazar " .. accel .. "\n")
                notify("⚠️ " .. accel .. " está ocupada por otro programa")
            end
        end
    end
end

-- ─── Main ────────────────────────────────────────────────────────────────────

buildAppIndex()
configureFunctionKeys()
kaizenMode()

GLib.MainLoop.new(nil, false):run()
