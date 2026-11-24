# Tests de lua-wm

El resto del repo no tiene tests a propósito. Estos existen por un motivo concreto:
`wm-linux-config/init.lua` solo corre en Linux, así que trabajando desde el Mac no hay
forma de comprobar que un cambio funciona salvo ejecutarlo de mentira.

`harness.lua` stubea `lgi` completo (GLib, Gtk, Gdk, Gio, Wnck, Keybinder, Notify) y
`xrandr`, de modo que el `init.lua` **real** se ejecuta con `luajit` (semántica de Lua
5.1, que es lo que usan los dos configs) y se registra todo lo que le pide al sistema:
geometrías aplicadas, notificaciones, apps lanzadas, hotkeys enlazadas y comandos de
shell.

```bash
./suite.sh                 # contra configs/wm-linux-config/
./suite.sh /otra/ruta      # contra otra copia (p.ej. una versión anterior)
```

Necesita `luajit` (`brew install luajit`) — no hace falta Lua 5.3 ni estar en Linux.

## Qué cubre

| Escenario | Qué comprueba |
|---|---|
| **A** — 3440px, sin eDP | Reparte ventanas; el perfil no se muta; avisa "External screen"; las URLs van citadas al shell |
| **B** — 1512px, con eDP | Todo a pantalla completa; **el perfil sigue sin mutarse** |
| **C** — perfil sintético | `KAIZEN_MODE` y `RESET_LAYOUT` se despachan como acciones y no como nombres de app |
| **D** — `linux-personal`, 2560px | Esquema de lados: izquierda/derecha al 50%, notas y navegador sin taparse, lo que Kaizen no lanza se coloca igual, doble toque a 2/3 y vuelta, colapso al cambiar de app, `expandFull` a pantalla completa, tres toques rápidos (D8), `F12` |
| **F** — `BUSY_KEYS=F3` | Un atajo que ya tiene otro proceso se avisa, y el resto de teclas sigue funcionando |

A y B corren contra `profile-grid.lua`, el `linux-personal.lua` de antes de los lados
congelado: ningún perfil usa ya la rejilla, pero `init.lua` la sigue entendiendo. Al
tocar `init.lua`, A, B y C deben pasar también contra la versión anterior; D y F, fallar.
El arnés lleva un reloj de mentira (`TESTCLOCK`, en µs) para los dobles toques, y cada
ventana recuerda la última geometría aplicada para que `isExpanded` pueda medirla.

El escenario B es el importante. `adaptLayoutForCurrentScreen` escribía
`position`/`width`/`height`/`vertical` **dentro de la tabla del perfil**, así que en
cuanto lua-wm corría una vez con el portátil solo, las fracciones originales se perdían
para toda la vida del proceso y reconectar el monitor no las recuperaba sin un
`systemctl --user restart lua-wm`. Hammerspoon evita eso decidiendo en locales, con un
comentario explicándolo; ahora Linux hace lo mismo.

Si tocas `init.lua`, la comprobación que de verdad vale es correr la suite también
contra la versión anterior y ver que **falla**:

```bash
git show HEAD:configs/wm-linux-config/init.lua > /tmp/old/init.lua
cp profiles/linux-personal.lua /tmp/old/profiles/
./suite.sh /tmp/old        # debe dar fallos
```

Un test que pasa con el bug delante no está probando nada.
