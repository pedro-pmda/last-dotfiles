-- Linux personal profile for lua-wm
-- Mismo formato que mac-personal.lua — tabla Lua pura, sin código imperativo.
--
-- IMPORTANTE: Los nombres de las apps deben coincidir exactamente con el campo
-- "Name=" de su archivo .desktop. Para encontrar el nombre correcto:
--
--   grep -r "^Name=" /usr/share/applications/ | grep -i "nombre-app"
--   grep -r "^Name=" ~/.local/share/applications/
--   grep -r "^Name=" /var/lib/flatpak/exports/share/applications/   (apps Flatpak)
--
-- Para ver qué WM_CLASS reporta una ventana abierta:
--   xprop WM_CLASS  (y luego clic en la ventana)

return {
    appLaunchDelay = 5,
    debugMode = false,

    -- Mismos bloques que mac-work.lua (F1-F4 comunicar · F5-F8 construir ·
    -- F9-F12 personal/meta), nivelados a lo que hay instalado en este equipo.
    -- Shift+F1 y Shift+F2 siguen el mismo patrón que mac-work.lua (Canary y
    -- Chromium junto a Chrome/Claude), pero con los nombres reales que Mint
    -- les da a sus .desktop — no coinciden con los de macOS.
    -- Este perfil no arranca nada de golpe al pulsar teclas de app, solo
    -- coloca al vuelo lo que ya está abierto o lo que lanzas tecla a tecla.
    functionKeys = {
        -- Comunicar
        { key = "F1",  modifiers = {},        action = "Google Chrome" },
        -- "Canary" no existe en Linux; el canal Dev/unstable es el equivalente,
        -- y Mint lo registra literalmente como "Google Chrome (unstable)".
        { key = "F1",  modifiers = {"shift"}, action = "Google Chrome (unstable)" },
        { key = "F2",  modifiers = {},        action = "Claude" },
        -- Mint llama a Chromium "Chromium Web Browser" en su .desktop, no
        -- solo "Chromium" como en macOS.
        { key = "F2",  modifiers = {"shift"}, action = "Chromium Web Browser" },
        { key = "F3",  modifiers = {},        action = "Ferdium" },
        { key = "F4",  modifiers = {},        action = "Spotify" },
        { key = "F4",  modifiers = {"shift"}, action = "Kodi" },

        -- Construir
        { key = "F5",  modifiers = {},        action = "Visual Studio Code" },
        -- Name= es "calibre" en minúscula, tal cual lo trae su .desktop.
        { key = "F6",  modifiers = {},        action = "calibre" },
        { key = "F7",  modifiers = {},        action = "Freelens" },
        { key = "F8",  modifiers = {},        action = "Terminal" },

        -- Personal y meta
        { key = "F9",  modifiers = {},        action = "Obsidian" },
        { key = "F10", modifiers = {},        action = "Files" },
        { key = "F10", modifiers = {"shift"}, action = "EMOJI" },
        { key = "F11", modifiers = {"shift"}, action = "KAIZEN_MODE" },
        { key = "F12", modifiers = {},        action = "RESET_LAYOUT" },
        { key = "F12", modifiers = {"shift"}, action = "RELOAD_WM" },
    },

    kaizenChromeConfig = {
        urls = {
            "https://mail.google.com/mail/u/0/#inbox",
            "https://calendar.google.com/calendar/u/0/r",
        }
    },

    kaizenChromiumConfig = {
        urls = {
            "https://gemini.google.com/app?hl=es-ES",
            "https://claude.ai/new",
        }
    },

    -- Pantalla única 2560x1440: dos columnas al 50% ("2/4" en el esquema de
    -- fracciones de getSizeFraction), no el reparto 1/4·2/4·1/4 del
    -- ultrawide de mac-work.
    -- IA (Claude, Chromium dedicado a Gemini) y CLI (Terminal) van siempre a
    -- la derecha; el resto (notas, navegación normal, editor) a la izquierda.
    kaizenAppLayout = {
        { name = "Obsidian",           position = "left",  width = "2/4", vertical = "top", height = "3/3" },
        { name = "Google Chrome",      position = "left",  width = "2/4", vertical = "top", height = "3/3" },
        { name = "Visual Studio Code", position = "left",  width = "2/4", vertical = "top", height = "3/3" },

        { name = "Claude",             position = "right", width = "2/4", vertical = "top", height = "3/3" },
        { name = "Chromium Web Browser", position = "right", width = "2/4", vertical = "top", height = "3/3" },
        { name = "Terminal",           position = "right", width = "2/4", vertical = "top", height = "3/3" },

        -- Escape a pantalla completa: no forma parte de la rejilla de columnas
        { name = "Spotify",            position = "center", width = "4/4", vertical = "center", height = "4/4" },
        { name = "Google Chrome (unstable)", position = "center", width = "4/4", vertical = "center", height = "4/4" },
        { name = "calibre",            position = "center", width = "4/4", vertical = "center", height = "4/4" },
    },

    foregroundApps = {
        kaizen = { "Google Chrome", "Obsidian" },
    },
}
