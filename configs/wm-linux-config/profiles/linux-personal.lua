-- Linux personal profile for lua-wm
-- Mismo esquema de lados que mac-personal.lua — tabla Lua pura, sin código imperativo.
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

    -- Por debajo de este ancho en la pantalla principal no se reparten ventanas:
    -- todo va a pantalla completa.
    minWidthForTiling = 2000,

    -- Dos pulsaciones de la misma tecla dentro de esta ventana cuentan como doble toque.
    doubleTapMs = 400,

    -- Mismos bloques y mismo vocabulario que los perfiles de Mac (F1-F4 comunicar ·
    -- F5-F8 construir · F9-F12 personal/meta): la memoria muscular no debería depender
    -- de en qué máquina estés. Por eso VS Code va en F6 como en mac-personal, y F5
    -- (IntelliJ allí) se queda libre. Los nombres son los que Mint les da a sus
    -- .desktop, que no coinciden con los de macOS.
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
        { key = "F6",  modifiers = {},        action = "Visual Studio Code" },
        { key = "F7",  modifiers = {},        action = "Freelens" },
        { key = "F8",  modifiers = {},        action = "Terminal" },

        -- Personal y meta
        { key = "F9",  modifiers = {},        action = "Obsidian" },
        -- calibre es lectura: va junto a las notas, en el hueco que en mac-personal
        -- ocupa Mural. Name= es "calibre" en minúscula, tal cual lo trae su .desktop.
        { key = "F9",  modifiers = {"shift"}, action = "calibre" },
        { key = "F10", modifiers = {},        action = "Files" },
        { key = "F10", modifiers = {"shift"}, action = "EMOJI" },
        { key = "F11", modifiers = {"shift"}, action = "KAIZEN_MODE" },
        { key = "F12", modifiers = {},        action = "RESET_LAYOUT" },
        { key = "F12", modifiers = {"shift"}, action = "RELOAD_WM" },
    },

    ---------------------------------------------------------------------------
    -- El mapa de lados
    ---------------------------------------------------------------------------
    -- Todo al 50%. El lado decide QUÉ SE VE A LA VEZ, porque dos apps del mismo lado
    -- se tapan siempre. Antes Obsidian y Chrome iban los dos a la izquierda y la
    -- pareja de Kaizen —notas y navegador— no se podía ver entera.

    -- Izquierda: donde escribes o lees. Son alternativas de verdad entre sí.
    leftApps = {
        "Visual Studio Code",
        "Obsidian",
        "calibre",
    },

    -- Derecha: lo que acompaña.
    rightApps = {
        "Terminal",
        "Google Chrome",
        "Google Chrome (unstable)",
        "Chromium Web Browser",
        "Claude",
        "Ferdium",
        "Freelens",
        "Files",
        "Spotify",
        "Kodi",
    },

    -- El doble toque expande al centro a 2/3. Estas van a pantalla completa en su
    -- lugar: antes vivían siempre así, y una prueba de navegador o un vídeo no
    -- caben en dos tercios.
    expandFull = { "Google Chrome (unstable)", "Spotify", "Kodi" },

    ---------------------------------------------------------------------------
    -- Modos
    ---------------------------------------------------------------------------
    -- Solo cambian qué se lanza y qué pestañas se abren. Los lados son los mismos,
    -- así que una app que Kaizen no lance se coloca igual al abrirla a mano.
    -- Linux no tiene modo work: es la máquina personal.
    modes = {
        kaizen = {
            launch = {
                "Obsidian", "Google Chrome", "Visual Studio Code",
                "Claude", "Chromium Web Browser", "Terminal",
                "Spotify", "Google Chrome (unstable)", "calibre",
            },
            foreground = { "Google Chrome", "Obsidian" },

            chrome = {
                urls = {
                    "https://mail.google.com/mail/u/0/#inbox",
                    "https://calendar.google.com/calendar/u/0/r",
                }
            },

            chromium = {
                urls = {
                    "https://gemini.google.com/app?hl=es-ES",
                    "https://claude.ai/new",
                }
            },
        },
    },
}
