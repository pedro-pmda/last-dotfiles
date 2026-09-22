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
H.timers    = {}
H.scheduled = {}
H.bindings  = {}
H.apps      = {}
H.killed    = {}
H.clock     = 0        -- nanosegundos, como hs.timer.absoluteTime()
H.front     = nil
H.inCall    = false

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
    allCameras = function() return { { isInUse = function() return H.inCall end } } end
}

hs.audiodevice = {
    defaultInputDevice = function() return { inUse = function() return H.inCall end } end
}

hs.hotkey = {
    bind = function(mods, key, fn)
        local prefix = table.concat(mods or {}, "+")
        H.bindings[(prefix ~= "" and prefix .. "+" or "") .. key] = fn
    end
}

hs.timer = {}

function hs.timer.doAfter(seconds, fn)
    local t = { fn = fn, at = seconds, stopped = false }
    t.stop = function(self) self.stopped = true end
    table.insert(H.timers, t)
    return t
end

function hs.timer.doAt(time, _, fn)
    H.scheduled[time] = fn
    return { stop = function() end }
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
function H.flush(maxSeconds, rounds)
    maxSeconds = maxSeconds or 30
    for _ = 1, (rounds or 8) do
        local ready, later = {}, {}
        for _, t in ipairs(H.timers) do
            if t.at <= maxSeconds then table.insert(ready, t) else table.insert(later, t) end
        end
        H.timers = later
        if #ready == 0 then break end
        table.sort(ready, function(a, b) return a.at < b.at end)
        for _, t in ipairs(ready) do
            if not t.stopped then t.fn() end
        end
    end
end

function H.fireLong(minSeconds)
    local ready, later = {}, {}
    for _, t in ipairs(H.timers) do
        if t.at >= minSeconds then table.insert(ready, t) else table.insert(later, t) end
    end
    H.timers = later
    for _, t in ipairs(ready) do
        if not t.stopped then t.fn() end
    end
end

-- Pulsa una tecla. `gapMs` es lo que ha pasado desde la pulsación anterior: por
-- defecto mucho, para que no cuente como doble toque.
function H.press(combo, gapMs)
    H.clock = H.clock + ((gapMs or 5000) * 1000000)
    local fn = H.bindings[combo]
    if not fn then error("tecla sin binding: " .. combo) end
    fn()
end

-- Doble toque: dos pulsaciones dentro de la ventana de 400 ms.
function H.doublePress(combo)
    H.press(combo)
    H.press(combo, 100)
end

function H.alertsMatch(pattern)
    for _, a in ipairs(H.alerts) do
        if a:find(pattern, 1, true) then return true end
    end
    return false
end

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
