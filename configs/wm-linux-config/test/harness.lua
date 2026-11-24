-- Arnés de prueba para configs/wm-linux-config/init.lua.
-- Stubea lgi (GLib/Gtk/Gdk/Gio/Wnck/Keybinder/Notify) para poder ejecutar el
-- init.lua real fuera de Linux y comprobar su comportamiento, no solo su sintaxis.

local SCREEN_W = tonumber(os.getenv("SCREEN_W")) or 3440
local SCREEN_H = tonumber(os.getenv("SCREEN_H")) or 1440

-- Registro de lo que el init.lua le pide al sistema
_G.TESTCLOCK = 1000000000

local log = {
  geometry = {},   -- {app, x, y, w, h}
  notified = {},
  launched = {},
  closed   = 0,
  popen    = {},
  bindings = {},   -- accel -> callback
}
_G.TESTLOG = log

-- Ventanas "abiertas": wm_class -> nombre visible
local openWindows = {}
_G.TESTOPEN = openWindows

-- Geometría actual de cada ventana (marco), para que init.lua pueda medirla
-- como hace con Wnck: get_geometry devuelve lo último que se le aplicó.
local frames = {}
_G.TESTFRAMES = frames

local function makeWindow(cls)
  return {
    get_geometry = function()
      local f = frames[cls] or { x = 100, y = 100, w = 800, h = 600 }
      return f.x, f.y, f.w, f.h
    end,
    get_class_group_name = function() return cls end,
    get_window_type = function() return "NORMAL" end,
    activate = function() end,
    unmaximize = function() end,
    close = function() log.closed = log.closed + 1 end,
    set_geometry = function(_, _, _, x, y, w, h)
      table.insert(log.geometry, { cls = cls, x = x, y = y, w = w, h = h })
      frames[cls] = { x = x, y = y, w = w, h = h }
    end,
  }
end

local GLib = {
  PRIORITY_DEFAULT = 0,
  -- Ejecuta el callback en el acto: el test es síncrono
  timeout_add = function(_, _, fn) fn() end,
  -- Reloj de mentira en microsegundos: lo avanza H.press() para simular toques
  get_monotonic_time = function() return _G.TESTCLOCK end,
  MainLoop = { new = function() return { run = function() end } end },
}

local Gtk = { init = function() end }

local Gdk = {
  Screen = {
    get_default = function()
      return {
        get_primary_monitor = function() return 0 end,
        get_monitor_workarea = function()
          return { x = 0, y = 0, width = SCREEN_W, height = SCREEN_H }
        end,
        get_width = function() return SCREEN_W end,
        get_height = function() return SCREEN_H end,
      }
    end,
  },
  Display = {
    get_default = function()
      return { get_app_launch_context = function() return {} end }
    end,
  },
}

-- Índice de apps: se declara igual que un .desktop, con StartupWMClass
local DESKTOP_APPS = {
  { name = "Google Chrome",          cls = "google-chrome" },
  { name = "Google Chrome (unstable)", cls = "google-chrome-unstable" },
  -- Como en Mint con LANG=es_ES: get_name() da el Name[es]=, get_string("Name") el
  -- original. El perfil usa el original; sin indexarlo, Chromium no se encontraba.
  { name = "Chromium Web Browser",   cls = "chromium-browser", localized = "Navegador web Chromium" },
  { name = "Visual Studio Code",     cls = "code" },
  { name = "IntelliJ IDEA Ultimate", cls = "jetbrains-idea" },
  { name = "Slack",                  cls = "slack" },
  { name = "Obsidian",               cls = "obsidian" },
  { name = "Ghostty",                cls = "ghostty" },
  { name = "Terminal",               cls = "gnome-terminal-server" },
  { name = "Freelens",               cls = "freelens" },
  { name = "Claude",                 cls = "claude" },
  { name = "Ferdium",                cls = "ferdium" },
  { name = "Spotify",                cls = "spotify" },
  { name = "Kodi",                   cls = "kodi" },
  { name = "calibre",                cls = "calibre-gui" },
  { name = "Files",                  cls = "nemo",            localized = "Archivos" },
}

local Gio = {
  DesktopAppInfo = {
    get_all = function()
      local out = {}
      for _, a in ipairs(DESKTOP_APPS) do
        table.insert(out, {
          get_name = function() return a.localized or a.name end,
          get_string = function(_, key) if key == "Name" then return a.name end end,
          get_startup_wm_class = function() return a.cls end,
          get_id = function() return a.cls .. ".desktop" end,
          get_boolean = function(_, key) return key == "NoDisplay" and (a.noDisplay or false) end,
          -- Lanzar abre la ventana en el acto (los timeouts también son síncronos)
          launch = function()
            table.insert(log.launched, a.name)
            openWindows[a.cls] = true
          end,
        })
      end
      return out
    end,
  },
}

local Wnck = {
  ClientType = { PAGER = 2 },
  WindowType = { NORMAL = "NORMAL" },
  WindowGravity = { STATIC = 10 },
  set_client_type = function() end,
  Screen = {
    get_default = function()
      return {
        force_update = function() end,
        get_windows = function()
          local out = {}
          for cls in pairs(openWindows) do table.insert(out, makeWindow(cls)) end
          return out
        end,
      }
    end,
  },
}

local Keybinder = {
  init = function() end,
  -- BUSY_KEYS="F3,<Shift>F4" simula atajos que ya tiene otro proceso: X11 solo
  -- admite un dueño por tecla y Keybinder.bind devuelve false.
  bind = function(accel, fn)
    for busy in (os.getenv("BUSY_KEYS") or ""):gmatch("[^,]+") do
      if busy == accel then return false end
    end
    log.bindings[accel] = fn
    return true
  end,
}

local Notify = {
  init = function() end,
  Notification = {
    new = function(msg)
      table.insert(log.notified, msg)
      return { set_timeout = function() end, show = function() end }
    end,
  },
}

package.preload["lgi"] = function()
  return {
    require = function(name)
      local mods = { GLib = GLib, Gtk = Gtk, Gdk = Gdk, Gio = Gio,
                     Wnck = Wnck, Keybinder = Keybinder, Notify = Notify }
      return mods[name] or error("lgi stub: falta " .. name)
    end,
    GLib = GLib,
  }
end

-- io.popen: xrandr y los lanzamientos de navegador
local realPopen = io.popen
io.popen = function(cmd)
  table.insert(log.popen, cmd)
  if cmd:match("xrandr") then
    local n = os.getenv("XRANDR_COUNT") or "0"
    return { read = function() return n .. "\n" end, close = function() end }
  end
  return { read = function() return "" end, close = function() end }
end
