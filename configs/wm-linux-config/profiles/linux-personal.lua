-- Linux personal profile for lua-wm
-- Mismo formato que mac-personal.lua — tabla Lua pura, sin código imperativo.
--
-- IMPORTANTE: Los nombres de las apps deben coincidir exactamente con el campo
-- "Name=" de su archivo .desktop. Para encontrar el nombre correcto:
--
--   grep -r "^Name=" /usr/share/applications/ | grep -i "nombre-app"
--   grep -r "^Name=" ~/.local/share/applications/
--
-- Para ver qué WM_CLASS reporta una ventana abierta:
--   xprop WM_CLASS  (y luego clic en la ventana)

return {
    appLaunchDelay = 5,
    debugMode = false,

    functionKeys = {
        { key = "F1",  modifiers = {},          action = "Google Chrome" },
        { key = "F2",  modifiers = {},          action = "Visual Studio Code" },
        { key = "F3",  modifiers = {},          action = "IntelliJ IDEA Ultimate" },
        { key = "F5",  modifiers = {},          action = "Slack" },
        { key = "F6",  modifiers = {},          action = "Chromium" },
        { key = "F7",  modifiers = {},          action = "Obsidian" },
        { key = "F9",  modifiers = {},          action = "OpenLens" },
        { key = "F10", modifiers = {},          action = "Ghostty" },
        { key = "F12", modifiers = {},          action = nil },
        { key = "F11", modifiers = {"shift"},   action = "KAIZEN_MODE" },
        { key = "F12", modifiers = {"shift"},   action = "RELOAD_WM" },
    },

    workChromeConfig = {
        urls = {
            "https://mail.google.com",
            "https://calendar.google.com",
        }
    },

    workChromiumConfig = {
        urls = {
            "https://claude.ai/new",
        }
    },

    kaizenChromeConfig = {
        urls = {
            "https://mail.google.com/mail/u/0/#inbox",
            "https://calendar.google.com/calendar/u/0/r",
        }
    },

    kaizenChromiumConfig = {
        urls = {
            "https://claude.ai/new",
        }
    },

    workAppLayout = {
        { name = "Visual Studio Code",       position = "right", width = "2/3", vertical = "top", height = "3/3" },
        { name = "IntelliJ IDEA Ultimate",   position = "right", width = "2/3", vertical = "top", height = "3/3" },
        { name = "Slack",                    position = "left",  width = "1/3", vertical = "top", height = "3/3" },
        { name = "Ghostty",                  position = "right", width = "3/4", vertical = "top", height = "3/3" },
        { name = "Obsidian",                 position = "left",  width = "1/3", vertical = "top", height = "3/3" },
        { name = "OpenLens",                 position = "right", width = "2/3", vertical = "top", height = "3/3" },
        { name = "Chromium",                 position = "left",  width = "1/3", vertical = "top", height = "3/3" },
        { name = "Google Chrome",            position = "right", width = "2/3", vertical = "top", height = "3/3" },
    },

    kaizenAppLayout = {
        { name = "Chromium",      position = "left",  width = "1/3", vertical = "top", height = "3/3" },
        { name = "Google Chrome", position = "left",  width = "2/4", vertical = "top", height = "4/4" },
        { name = "Obsidian",      position = "right", width = "2/4", vertical = "top", height = "4/4" },
        { name = "Visual Studio Code", position = "right", width = "2/4", vertical = "top", height = "4/4" },
        { name = "Ghostty",       position = "right", width = "2/4", vertical = "top", height = "4/4" },
    },

    foregroundApps = {
        work   = { "Obsidian", "IntelliJ IDEA Ultimate" },
        kaizen = { "Google Chrome", "Obsidian" },
    },
}
