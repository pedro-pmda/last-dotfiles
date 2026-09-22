local config = require("app_config")

-- Sin esto el CLI `hs` no tiene puerto al que hablar: el binario existe dentro de
-- Hammerspoon.app pero contesta "can't access Hammerspoon message port". El puerto se
-- crea como efecto del require, y es lo que permite inspeccionar el estado en vivo.
pcall(require, "hs.ipc")

-- Requisito, no estética: con animación (0.2 s por defecto) win:frame() devuelve el
-- frame de DESTINO y no el real, así que toda comprobación de dónde está una ventana
-- miente durante ese rato. Este layout decide cosas midiendo, así que tiene que ser 0.
hs.window.animationDuration = 0

-- La consola es el único log que queda. Borrarla al arrancar deja sin rastro justo el
-- arranque que falla, así que solo se limpia cuando estás depurando a propósito.
if config.debugMode then hs.console.clearConsole() end

local function log(message)
    print(os.date("%H:%M:%S") .. " · " .. tostring(message))
end

local function debugPrint(message)
    if config.debugMode then hs.alert.show(message) end
end

local function listHas(list, value)
    for _, v in ipairs(list or {}) do if v == value then return true end end
    return false
end

--------------------------------------------------------------------------------
-- Apps
--------------------------------------------------------------------------------

-- Localiza una app ya abierta. El nombre con el que se lanza (el del .app) no siempre
-- es el que macOS devuelve al buscarla: "Visual Studio Code.app" corre como "Code".
-- Y hs.application.get hace match por SUBCADENA, así que "Google Chrome" encuentra
-- también a "Google Chrome Canary". Para esos casos el profile declara su bundle ID.
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

--------------------------------------------------------------------------------
-- Geometría
--------------------------------------------------------------------------------

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

-- Coloca una ventana según una geometría concreta. La decisión de repartir o no se
-- toma aquí, en locales, nunca escribiendo en la tabla del profile: así desconectar
-- el monitor no exige recargar.
local function applyGeometry(appName, geo)
    local app = getApp(appName)
    if not app then return false end
    local win = app:mainWindow()
    if not win then return false end

    local pos, vert = geo.position, geo.vertical
    local w, h = geo.width, geo.height
    if not shouldTile() then
        pos, vert, w, h = "center", "center", "3/3", "3/3"
    end

    local screen = resolveScreen(geo.screen):frame()
    local width  = getSizeFraction(screen.w, w)
    local height = getSizeFraction(screen.h, h)
    local x, y = calculatePosition(screen, width, height, pos, vert)
    win:setFrame(hs.geometry.rect(x, y, width, height))
    return true
end

local function moveWindow(appName, layoutTable)
    for _, cfg in ipairs(layoutTable or {}) do
        if cfg.name == appName then return applyGeometry(appName, cfg) end
    end
    return false
end

--------------------------------------------------------------------------------
-- El mapa de lados
--------------------------------------------------------------------------------
-- El perfil declara solo el lado; la geometría del 50% se deriva aquí. Por eso
-- mac-work.lua son dos listas de nombres en vez de treinta entradas de coordenadas.

local SIDE_GEOMETRY = {
    left  = { position = "left",  width = "2/4", vertical = "top", height = "3/3" },
    right = { position = "right", width = "2/4", vertical = "top", height = "3/3" }
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
                vertical = geo.vertical, height = geo.height
            })
        end
    end
    return out
end

-- Perfil nuevo (mac-work): un solo mapa de lados para los dos modos.
-- Perfil antiguo (mac-personal): cada modo trae su propia tabla de layout.
local sideLayout = buildSideLayout()
local currentLayout = sideLayout or config.workAppLayout
local currentMode = "work"

-- Coloca una app en su sitio, buscándola en el layout del modo activo y, si no está
-- ahí, en el de apps que solo se abren a mano (esquema antiguo).
local function positionApp(appName)
    for _, layoutTable in ipairs({ currentLayout or {}, config.onDemandAppLayout or {} }) do
        if moveWindow(appName, layoutTable) then return true end
    end
    return false
end

--------------------------------------------------------------------------------
-- Expandir y colapsar
--------------------------------------------------------------------------------
-- El doble toque lleva la ventana al centro a 2/3 y, si ya está ahí, la devuelve a su
-- lado al 50%. Lo único que se recuerda es el nombre de la app expandida, y antes de
-- usarlo se comprueba midiendo: así sobrevive a que muevas ventanas a mano o con
-- Rectangle, y un recuerdo obsoleto no rompe nada.

local expandedApp = nil

local function expandGeometryFor(name)
    return listHas(config.expandFull, name) and EXPANDED_FULL or EXPANDED
end

local function expandedWidthFor(name)
    local screen = hs.screen.primaryScreen():frame()
    if not shouldTile() then return screen.w end
    return getSizeFraction(screen.w, expandGeometryFor(name).width)
end

-- Tolerancia generosa a propósito: Ghostty redondea a celdas de carácter enteras y
-- nunca va a medir exactamente los 2293 px que le pides.
local function isExpanded(name)
    local app = getApp(name)
    local win = app and app:mainWindow()
    if not win then return false end
    return math.abs(win:frame().w - expandedWidthFor(name)) <= 40
end

-- Al irte a otra app, la que estuviera expandida vuelve sola a su mitad. Así nunca
-- quedan dos ventanas solapadas a medias esperando a que las ordenes tú.
local function collapseExpanded(except)
    if not expandedApp or expandedApp == except then return end
    local name = expandedApp
    expandedApp = nil
    if isExpanded(name) then positionApp(name) end
end

-- Devuelve a su posición todas las ventanas abiertas ahora mismo. El salvoconducto:
-- no lanza nada, lo que esté cerrado sigue cerrado.
local function resetLayout()
    expandedApp = nil
    local moved = 0
    for _, layoutTable in ipairs({ currentLayout or {}, config.onDemandAppLayout or {} }) do
        for _, cfg in ipairs(layoutTable) do
            local app = getApp(cfg.name)
            if app and app:mainWindow() then
                applyGeometry(cfg.name, cfg)
                moved = moved + 1
            end
        end
    end
    hs.alert.show("🧹 " .. moved .. " ventanas recolocadas")
end

--------------------------------------------------------------------------------
-- La tecla de una app
--------------------------------------------------------------------------------

local lastPressAt = {}

local function onAppKey(name)
    -- Expandir solo existe en el esquema de lados. Un perfil antiguo (mac-personal)
    -- conserva exactamente el comportamiento de siempre: la tecla es puro focus.
    if not sideLayout then
        local wasRunning = getApp(name) ~= nil
        launchOrFocusApp(name)
        if not wasRunning then
            hs.timer.doAfter(config.appLaunchDelay, function() positionApp(name) end)
        end
        return
    end

    local now = hs.timer.absoluteTime()           -- nanosegundos
    local previous = lastPressAt[name]
    local double = previous ~= nil
                   and (now - previous) < ((config.doubleTapMs or 400) * 1000000)
    -- Consumir la marca al detectar el doble, para que una tercera pulsación cuente
    -- como un simple nuevo y no se lea como otro doble encadenado.
    -- (Nada de `double and nil or now`: en Lua ese idiom devuelve `now` cuando
    -- `double` es cierto, porque `nil` es falso y el `or` se lo lleva.)
    if double then lastPressAt[name] = nil else lastPressAt[name] = now end

    log((double and "doble " or "simple ") .. name ..
        " · expandida=" .. tostring(expandedApp))

    if not double then
        collapseExpanded(name)
        -- Solo colocar al abrir la app por primera vez. Si ya estaba corriendo la
        -- tecla es puro focus: el tamaño que le hayas dado a mano se respeta.
        local wasRunning = getApp(name) ~= nil
        launchOrFocusApp(name)
        if not wasRunning then
            hs.timer.doAfter(config.appLaunchDelay, function() positionApp(name) end)
        end
        return
    end

    if isExpanded(name) then
        expandedApp = nil
        launchOrFocusApp(name)
        positionApp(name)
        return
    end

    collapseExpanded(name)
    local wasRunning = getApp(name) ~= nil
    launchOrFocusApp(name)
    local function expand()
        if applyGeometry(name, expandGeometryFor(name)) then expandedApp = name end
    end
    if wasRunning then expand() else hs.timer.doAfter(config.appLaunchDelay, expand) end
end

--------------------------------------------------------------------------------
-- Modos
--------------------------------------------------------------------------------

local function openBrowserWithUrls(appName, urls)
    local script = "tell application \"" .. appName .. "\"\nactivate\ndelay 3\ntell window 1\n"
    for _, url in ipairs(urls) do
        script = script .. "make new tab with properties {URL: \"" .. url .. "\"}\n"
    end
    script = script .. "end tell\nend tell"
    hs.osascript.applescript(script)
end

local function openBrowserSet(appName, cfg)
    if cfg and cfg.urls then openBrowserWithUrls(appName, cfg.urls) end
end

-- Solo avisa del modo en el que se va a colocar. Quien decide es shouldTile(),
-- en cada colocación, para que desconectar el monitor no exija recargar.
local function announceScreenMode()
    if shouldTile() then
        hs.alert.show("🖥️ Pantalla externa → reparto al 50%")
    else
        hs.alert.show("💻 Pantalla del portátil → todo a pantalla completa")
    end
end

local function closeAllWindows()
    for _, app in ipairs(hs.application.runningApplications()) do
        if app:kind() == 1 and app:name() ~= "Hammerspoon" then
            app:kill()
        end
    end
end

local function bringAppsToFront(appNames)
    for _, name in ipairs(appNames or {}) do
        local app = getApp(name)
        if app and app:mainWindow() then
            app:activate()
        end
    end
end

-- Normaliza los dos esquemas de perfil a una sola forma. El nuevo separa "dónde va
-- cada app" de "qué lanza este modo"; el antiguo usaba una única tabla para las dos
-- cosas, y por eso en Kaizen las apps que no lanzaba tampoco se colocaban.
local function modeSpec(name)
    local mode = config.modes and config.modes[name]
    if mode then
        return {
            layout = sideLayout, launch = mode.launch, chrome = mode.chrome,
            chromium = mode.chromium, foreground = mode.foreground, comms = mode.comms
        }
    end

    local layout = (name == "work") and config.workAppLayout or config.kaizenAppLayout
    if not layout then return nil end
    local launch = {}
    for _, cfg in ipairs(layout) do table.insert(launch, cfg.name) end
    return {
        layout = layout, launch = launch,
        chrome   = (name == "work") and config.workChromeConfig   or config.kaizenChromeConfig,
        chromium = (name == "work") and config.workChromiumConfig or config.kaizenChromiumConfig,
        foreground = config.foregroundApps and config.foregroundApps[name]
    }
end

local MODE_BANNER = { work = "🧑🏾‍💻 Work Mode", kaizen = "⛩️ Kaizen Mode" }

local function enterMode(name)
    local spec = modeSpec(name)
    if not spec then hs.alert.show("⚠️ Este perfil no tiene modo " .. name); return end

    currentMode = name
    currentLayout = spec.layout
    expandedApp = nil
    hs.alert.show(MODE_BANNER[name] .. "…")
    announceScreenMode()
    closeAllWindows()

    hs.timer.doAfter(2, function()
        for _, appName in ipairs(spec.launch or {}) do launchOrFocusApp(appName) end
        hs.timer.doAfter(config.appLaunchDelay, function()
            -- Tres pasadas: algunas apps tardan en tener ventana y la primera no las pilla.
            for i = 0, 2 do
                hs.timer.doAfter(i * 2, function()
                    for _, appName in ipairs(spec.launch or {}) do
                        moveWindow(appName, spec.layout)
                    end
                end)
            end
        end)
    end)

    hs.timer.doAfter((config.appLaunchDelay or 5) + 6, function()
        pcall(function() openBrowserSet("Google Chrome", spec.chrome) end)
        pcall(function() openBrowserSet("Chromium", spec.chromium) end)
        pcall(function() bringAppsToFront(spec.foreground) end)
        hs.alert.show(MODE_BANNER[name] .. " listo")
    end)
end

--------------------------------------------------------------------------------
-- Ventanas de comunicación
--------------------------------------------------------------------------------
-- Lo único que interrumpe es el reloj. Salen dos apps a mitades durante unos minutos
-- y al vencer se recoloca todo con el mismo resetLayout() del salvoconducto: no hay
-- que recordar qué había antes, se vuelve a calcular.

-- Ocultar o mover ventanas encima de una pantalla compartida es un desastre para
-- quien te está viendo, así que mientras haya cámara o micro en uso no se irrumpe.
local function inCall()
    local ok, result = pcall(function()
        if hs.camera then
            for _, cam in ipairs(hs.camera.allCameras() or {}) do
                if cam.isInUse and cam:isInUse() then return true end
            end
        end
        local mic = hs.audiodevice and hs.audiodevice.defaultInputDevice()
        if mic and mic.inUse and mic:inUse() then return true end
        return false
    end)
    return (ok and result) == true
end

local function runCommsWindow(window, comms)
    hs.alert.show("📬 Tiempo de Comunicación")
    log("ventana de comunicación " .. window.time .. ": " .. window.left .. " | " .. window.right)

    collapseExpanded(nil)
    launchOrFocusApp(window.left)
    launchOrFocusApp(window.right)

    hs.timer.doAfter(config.appLaunchDelay or 5, function()
        applyGeometry(window.left,  SIDE_GEOMETRY.left)
        applyGeometry(window.right, SIDE_GEOMETRY.right)
        launchOrFocusApp(window.left)
    end)

    local minutes = comms.durationMinutes or 10
    hs.timer.doAfter(minutes * 60, function()
        hs.alert.show("🔕 Fin del tiempo de comunicación")
        resetLayout()
    end)
end

local function isWeekday()
    local day = os.date("*t").wday      -- 1 = domingo, 7 = sábado
    return day >= 2 and day <= 6
end

local function scheduleCommsWindows()
    local comms = config.modes and config.modes.work and config.modes.work.comms
    if not comms then return end

    for _, window in ipairs(comms.windows or {}) do
        hs.timer.doAt(window.time, "1d", function()
            if currentMode ~= "work" then return end
            if comms.weekdaysOnly ~= false and not isWeekday() then return end

            local attempts = 0
            local function attempt()
                if inCall() then
                    attempts = attempts + 1
                    if attempts <= (comms.maxPostpones or 12) then
                        hs.timer.doAfter((comms.postponeMinutes or 2) * 60, attempt)
                    else
                        -- Visible a propósito: si la ventana se cae, hay que enterarse.
                        hs.alert.show("📭 Comunicación de las " .. window.time .. " descartada")
                    end
                    return
                end
                runCommsWindow(window, comms)
            end
            attempt()
        end)
    end
end

--------------------------------------------------------------------------------
-- Teclas
--------------------------------------------------------------------------------

local ACTIONS = {
    RELOAD_HAMMERSPOON = function() hs.reload() end,
    WORK_MODE   = function() enterMode("work") end,
    KAIZEN_MODE = function() enterMode("kaizen") end,
    RESET_LAYOUT = resetLayout,
    EMOJI = function() hs.eventtap.keyStroke({ "ctrl", "cmd" }, "space") end
}

-- macOS solo admite un dueño por atajo global: si otro proceso ya tiene registrado el
-- mismo, RegisterEventHotKey contesta -9878 y hs.hotkey.bind devuelve nil. Fallaba en
-- silencio, y por eso F11 (Work Mode) no hacía nada mientras ⇧F11 iba perfecto —la
-- tecla ni siquiera aparecía en hs.hotkey.getHotkeys(). El repuesto es un eventtap:
-- ve la pulsación en el tap de sesión, antes del despacho de atajos, así que no hay
-- que averiguar quién es el dueño ni convencerle de que la suelte.
local MODIFIER_ALIASES = {
    cmd = "cmd", command = "cmd",
    alt = "alt", option = "alt", opt = "alt",
    shift = "shift",
    ctrl = "ctrl", control = "ctrl"
}
local REAL_MODIFIERS = { "cmd", "alt", "shift", "ctrl" }

local function normalizeMods(mods)
    local set = {}
    for _, m in ipairs(mods or {}) do
        local name = tostring(m):lower()
        set[MODIFIER_ALIASES[name] or name] = true
    end
    return set
end

-- `fn` se deja fuera de la comparación a propósito: en un portátil la fila F llega con
-- fn puesto o no según cómo esté configurado el teclado, y eso no es parte del atajo.
local function flagsMatch(flags, wanted)
    for _, name in ipairs(REAL_MODIFIERS) do
        if (flags[name] and true or false) ~= (wanted[name] or false) then return false end
    end
    return true
end

local fallbackKeys = {}

local function bindKey(mapping, handler)
    if hs.hotkey.bind(mapping.modifiers or {}, mapping.key, handler) then return end

    local code = hs.keycodes.map[tostring(mapping.key):lower()]
    if not code then
        hs.alert.show("⚠️ Tecla desconocida: " .. tostring(mapping.key))
        return
    end
    log("atajo " .. mapping.key .. " ocupado por otro proceso → va por eventtap")
    table.insert(fallbackKeys, {
        code = code, mods = normalizeMods(mapping.modifiers), fn = handler
    })
end

-- El tap se guarda en una global aposta: si solo vive en un local del chunk, el
-- recolector se lo lleva al rato y las teclas de repuesto dejan de responder sin avisar.
local function startFallbackTap()
    if #fallbackKeys == 0 then return end
    _G.hotkeyFallbackTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
        local code, flags = event:getKeyCode(), event:getFlags()
        for _, key in ipairs(fallbackKeys) do
            if key.code == code and flagsMatch(flags, key.mods) then
                key.fn()
                return true    -- consumida: que no le llegue también al dueño del atajo
            end
        end
        return false
    end)
    _G.hotkeyFallbackTap:start()
end

local function configureFunctionKeys()
    for _, mapping in ipairs(config.functionKeys) do
        local action = mapping.action
        local handler = ACTIONS[action]
        if handler then
            bindKey(mapping, handler)
        elseif action then
            bindKey(mapping, function() onAppKey(action) end)
        end
    end
    startFallbackTap()
end

--------------------------------------------------------------------------------
-- Inspección en vivo
--------------------------------------------------------------------------------
-- `hs -c "wm.estado()"` desde la terminal. El handler de IPC evalúa en el entorno
-- global y hace tostring() del resultado, así que esto tiene que ser global y
-- devolver cadenas, no tablas.

_G.wm = {
    estado = function()
        local front = hs.application.frontmostApplication()
        return hs.inspect({
            modo      = currentMode,
            expandida = expandedApp,
            delante   = front and front:name() or nil,
            reparte   = shouldTile(),
            repuestos = #fallbackKeys,
            pantalla  = hs.screen.primaryScreen():frame().string
        })
    end,
    ventanas = function()
        local out = {}
        for _, cfg in ipairs(currentLayout or {}) do
            local app = getApp(cfg.name)
            local win = app and app:mainWindow()
            out[cfg.name] = {
                lado  = cfg.side,
                marco = win and win:frame().string or nil
            }
        end
        return hs.inspect(out)
    end
}

--------------------------------------------------------------------------------
-- Start
--------------------------------------------------------------------------------

configureFunctionKeys()
scheduleCommsWindows()
enterMode("work")
