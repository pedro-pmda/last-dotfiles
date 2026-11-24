-- Un atajo que ya tiene otro proceso. X11 solo admite un dueño por tecla y
-- Keybinder.bind devuelve false sin más: la tecla queda muerta en silencio. En macOS
-- eso tuvo F11 inutilizada sin que nadie supiera por qué; aquí al menos que se avise.
local r = require("scenario")

print("F1 · la tecla ocupada se avisa con nombre")
r.check("notifica que F3 está ocupada", r.notifiedMatch("F3 está ocupada"))

print("F2 · y las demás siguen funcionando")
r.check("F6 enlazada", r.log.bindings["F6"] ~= nil)
r.doublePress("F6")
r.expectRect("VS Code expande igual", "code", 426, 0, 1706, 1440)

r.done()
