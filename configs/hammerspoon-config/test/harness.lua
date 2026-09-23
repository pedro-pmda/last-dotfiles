-- Doble de `hs` para poder correr el init.lua real fuera de Hammerspoon.
--
-- Mismo truco que la suite de wm-linux: en vez de probar una copia del código se
-- carga el fichero de verdad con las dependencias del sistema sustituidas. Lo que se
-- comprueba aquí es lo que no se puede verificar leyendo: en qué píxeles acaba cada
-- ventana, el ciclo 50% → 2/3 → 50%, y las ventanas de comunicación por horario.
--
-- Env: SCREEN_W, SCREEN_H, SCREENS (1 o 2), HS_REPO, HS_PROFILE

local H = {}

local SCREEN_W = tonumber(os.getenv("SCREEN_W") or "3440")
local SCREEN_H = tonumber(os.getenv("SCREEN_H") or "1440")
local SCREENS  = tonumber(os.getenv("SCREENS") or "1")

H.alerts    = {}
-- Lo que queda en el Centro de Notificaciones y los sonidos: el globo se va solo, y un
-- aviso que no deja rastro es lo que hacía que las franjas pasaran sin enterarte.
H.notifications = {}
H.sounds        = {}
-- Valores débiles a propósito: Hammerspoon no retiene los temporizadores, así que uno cuya
-- única referencia sea esta tabla desaparece en cuanto pasa el recolector. H.collect()
-- simula ese paso — es lo que dejaba muertas las franjas de comunicación y sus reintentos.
H.timers          = setmetatable({}, { __mode = "v" })
H.scheduledTimers = setmetatable({}, { __mode = "v" })
H.scheduled = {}
H.bindings  = {}
H.apps      = {}
H.killed    = {}
H.clock     = 0        -- nanosegundos, como hs.timer.absoluteTime()
H.front     = nil
-- Cámara y micro por separado: el micro de un auricular USB se queda "en uso" todo el día
-- aunque no haya reunión, y eso tiene que poder probarse sin tocar la cámara.
H.cameraInUse = false
H.micInUse    = false

--------------------------------------------------------------------------------
-- Ventanas y apps
--------------------------------------------------------------------------------

local Win = {}
Win.__index = Win
function Win:setFrame(r) self._frame = r end
-- El init.lua mide con win:frame() para decidir si una ventana ya está expandida,
-- así que el doble tiene que devolver lo último que se le pidió colocar.
function Win:frame() return self._frame end

local App = {}
App.__index = App
function App:name() return self._name end
function App:pid() return self._pid end
function App:kind() return 1 end
function App:mainWindow() return self._win end
function App:hide() self.hidden = true; if H.front == self._name then H.front = nil end end
function App:unhide() self.hidden = false end
function App:activate() self.hidden = false; H.front = self._name; return true end
function App:kill() H.killed[self._name] = true; H.apps[self._name] = nil end

local nextPid = 100
-- register(nombre) = la app ya está corriendo. No registrarla ejercita la rama de
-- lanzamiento, que es la que espera appLaunchDelay antes de colocar.
function H.register(name, bundle)
    nextPid = nextPid + 1
    local app = setmetatable({
        _name = name, _pid = nextPid, _win = setmetatable({}, Win),
        hidden = false, bundle = bundle
    }, App)
    H.apps[name] = app
    return app
end

--------------------------------------------------------------------------------
-- hs
--------------------------------------------------------------------------------

_G.hs = {}

hs.console   = { clearConsole = function() end }
hs.alert     = { show = function(m) table.insert(H.alerts, tostring(m)) end }
hs.notify    = { new = function(attrs)
    return { send = function() table.insert(H.notifications, attrs.title) end }
end }
hs.sound     = { getByName = function(name)
    return { play = function() table.insert(H.sounds, name) end }
end }
hs.fs        = { attributes = function() return true end }
hs.geometry  = { rect = function(x, y, w, h) return { x = x, y = y, w = w, h = h } end }
hs.eventtap  = { keyStroke = function() end }
hs.osascript = { applescript = function() return true end }
hs.reload    = function() H.reloaded = true end
hs.window    = { animationDuration = 0 }
hs.inspect   = function(v) return tostring(v) end

hs.screen = {
    primaryScreen = function()
        return {
            id = function() return 1 end,
            frame = function() return { x = 0, y = 0, w = SCREEN_W, h = SCREEN_H } end
        }
    end,
    allScreens = function()
        local list = { hs.screen.primaryScreen() }
        if SCREENS > 1 then
            table.insert(list, {
                id = function() return 2 end,
                frame = function() return { x = SCREEN_W, y = 0, w = 1512, h = 982 } end
            })
        end
        return list
    end
}

hs.application = {}

-- Ojo: el real hace match por subcadena. Aquí es exacto a propósito, para que un test
-- no pase por accidente gracias a una coincidencia parcial.
function hs.application.get(key)
    for name, app in pairs(H.apps) do
        if name == key or app.bundle == key then return app end
    end
    return nil
end

function hs.application.frontmostApplication()
    return H.front and H.apps[H.front] or nil
end

function hs.application.launchOrFocus(name)
    local app = H.apps[name] or H.register(name)
    app.hidden = false
    H.front = name
    return true
end

function hs.application.open(path)
    local name = tostring(path):match("([^/]+)%.app$")
    if name then hs.application.launchOrFocus(name) end
end

function hs.application.runningApplications()
    local out = {}
    for _, app in pairs(H.apps) do table.insert(out, app) end
    return out
end

hs.camera = {
    allCameras = function() return { { isInUse = function() return H.cameraInUse end } } end
}

hs.audiodevice = {
    defaultInputDevice = function() return { inUse = function() return H.micInUse end } end
}

-- Atajos que macOS rechaza porque otro proceso ya los tiene: bind devuelve nil, igual
-- que el de verdad cuando RegisterEventHotKey falla con -9878. H.reject() los marca.
H.rejected = {}
function H.reject(combo) H.rejected[combo] = true end

local function comboName(mods, key)
    local prefix = table.concat(mods or {}, "+")
    return (prefix ~= "" and prefix .. "+" or "") .. key
end

hs.hotkey = {
    bind = function(mods, key, fn)
        local combo = comboName(mods, key)
        if H.rejected[combo] then return nil end
        H.bindings[combo] = fn
        return { combo = combo }
    end
}

hs.keycodes = {
    map = {
        f1 = 122, f2 = 120, f3 = 99,  f4 = 118, f5 = 96,  f6 = 97,
        f7 = 98,  f8 = 100, f9 = 101, f10 = 109, f11 = 103, f12 = 111
    }
}

-- Tap de teclado. Solo guarda el callback: H.press() le pasa un evento sintético
-- cuando la combinación no tiene binding, que es justo lo que hace el repuesto.
H.taps = {}
hs.eventtap.event = { types = { keyDown = 10 } }
function hs.eventtap.new(_, fn)
    local tap = { fn = fn, running = false }
    tap.start = function(self) self.running = true; return self end
    tap.stop  = function(self) self.running = false; return self end
    table.insert(H.taps, tap)
    return tap
end

hs.timer = {}

local nextTimerId = 0

function hs.timer.doAfter(seconds, fn)
    local t = { fn = fn, at = seconds, stopped = false }
    t.stop = function(self) self.stopped = true end
    nextTimerId = nextTimerId + 1
    H.timers[nextTimerId] = t
    return t
end

-- H.scheduled guarda la función (es como los tests disparan una franja a mano) y
-- H.scheduledTimers el objeto temporizador, que es lo que el recolector puede llevarse.
function hs.timer.doAt(time, _, fn)
    local t = { time = time, fn = fn, stop = function() end }
    H.scheduled[time] = fn
    H.scheduledTimers[time] = t
    return t
end

function hs.timer.absoluteTime() return H.clock end

-- El filtro de día laborable pregunta la fecha real: sin fijarla, la suite pasaría de
-- lunes a viernes y fallaría el sábado. H.wday la controla (3 = martes).
H.wday = 3
local realDate = os.date
os.date = function(fmt, t)
    if fmt == "*t" then
        local d = realDate("*t", t)
        d.wday = H.wday
        return d
    end
    return realDate(fmt, t)
end

--------------------------------------------------------------------------------
-- Control del tiempo
--------------------------------------------------------------------------------

-- Corre los temporizadores cortos (arranque y colocación). Los largos —los 10 min de
-- la ventana de comunicación— se quedan esperando a fireLong().
-- Saca de la tabla débil los que cumplan el filtro. `pairs`, no `ipairs`: tras un GC la
-- tabla tiene huecos justo donde estaban los temporizadores que nadie retenía.
local function takeTimers(keep)
    local taken = {}
    for id, t in pairs(H.timers) do
        if keep(t) then
            table.insert(taken, t)
            H.timers[id] = nil
        end
    end
    table.sort(taken, function(a, b) return a.at < b.at end)
    return taken
end

function H.flush(maxSeconds, rounds)
    maxSeconds = maxSeconds or 30
    for _ = 1, (rounds or 8) do
        local ready = takeTimers(function(t) return t.at <= maxSeconds end)
        if #ready == 0 then break end
        for _, t in ipairs(ready) do
            if not t.stopped then t.fn() end
        end
    end
end

function H.fireLong(minSeconds)
    for _, t in ipairs(takeTimers(function(t) return t.at >= minSeconds end)) do
        if not t.stopped then t.fn() end
    end
end

-- Pasa el recolector. Un temporizador que init.lua haya programado tirando la referencia
-- desaparece aquí, igual que en Hammerspoon.
function H.collect()
    collectgarbage("collect")
    collectgarbage("collect")
end

-- Pulsa una tecla. `gapMs` es lo que ha pasado desde la pulsación anterior: por
-- defecto mucho, para que no cuente como doble toque.
function H.press(combo, gapMs)
    H.clock = H.clock + ((gapMs or 5000) * 1000000)
    local fn = H.bindings[combo]
    if fn then fn(); return "hotkey" end
    if H.tap(combo) then return "eventtap" end
    error("tecla sin binding: " .. combo)
end

-- Entrega la pulsación a los taps activos. Devuelve true si alguno la consumió, que
-- es lo que impide que le llegue también al proceso dueño del atajo.
function H.tap(combo)
    local parts = {}
    for part in combo:gmatch("[^+]+") do table.insert(parts, part) end
    local key = table.remove(parts)
    local flags = {}
    for _, m in ipairs(parts) do flags[m] = true end

    local event = {
        getKeyCode = function() return hs.keycodes.map[key:lower()] end,
        getFlags   = function() return flags end
    }
    for _, tap in ipairs(H.taps) do
        if tap.running and tap.fn(event) then return true end
    end
    return false
end

-- Doble toque: dos pulsaciones dentro de la ventana de 400 ms.
function H.doublePress(combo)
    H.press(combo)
    H.press(combo, 100)
end

local function anyMatch(list, pattern)
    for _, a in ipairs(list) do
        if a:find(pattern, 1, true) then return true end
    end
    return false
end

function H.alertsMatch(pattern)        return anyMatch(H.alerts, pattern) end
function H.notificationsMatch(pattern) return anyMatch(H.notifications, pattern) end

--------------------------------------------------------------------------------
-- Carga y aserciones
--------------------------------------------------------------------------------

function H.load()
    local repo = os.getenv("HS_REPO") or "."
    local profile = assert(os.getenv("HS_PROFILE"), "falta HS_PROFILE")
    package.loaded["app_config"] = dofile(profile)
    H.config = package.loaded["app_config"]
    dofile(repo .. "/init.lua")
    return H.config
end

local failures = 0

function H.check(label, ok, detail)
    if ok then
        print("  ✅ " .. label)
    else
        print("  ❌ " .. label .. (detail and ("  → " .. detail) or ""))
        failures = failures + 1
    end
end

function H.rect(name)
    local app = H.apps[name]
    return app and app._win._frame or nil
end

local function near(a, b) return math.abs(a - b) <= 2 end

function H.expectRect(label, name, x, y, w, h)
    local r = H.rect(name)
    if not r then H.check(label, false, "la ventana nunca se colocó"); return end
    H.check(label,
        near(r.x, x) and near(r.y, y) and near(r.w, w) and near(r.h, h),
        string.format("x=%.0f y=%.0f w=%.0f h=%.0f · esperado x=%.0f y=%.0f w=%.0f h=%.0f",
                      r.x, r.y, r.w, r.h, x, y, w, h))
end

function H.done()
    if failures > 0 then
        print(string.format("  (%d fallo(s))", failures))
        os.exit(1)
    end
end

return H
