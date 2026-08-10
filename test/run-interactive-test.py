#!/usr/bin/env python3
"""Prueba ./run -i conduciéndolo desde un pty real.

Hace falta un pty porque el menú exige terminal interactiva (`[[ -t 0 ]]`) y
porque `script -q` no transmite bien las pulsaciones. Se ejecuta siempre con
--dry, así que no instala nada.

    python3 test/run-interactive-test.py
"""
import os, pty, re, select, subprocess, sys, time

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

ANSI = re.compile(r'\x1b\[[0-9;?]*[A-Za-z]|\x1b\][^\x07]*\x07')

def run(keys, args=("-i", "--dry"), timeout=25):
    master, slave = pty.openpty()
    p = subprocess.Popen(
        ["/bin/bash", "./run", *args],
        stdin=slave, stdout=slave, stderr=slave,
        cwd=REPO, close_fds=True,
    )
    os.close(slave)
    out, deadline, pending = b"", time.time() + timeout, list(keys)
    last_send = 0.0
    while time.time() < deadline:
        r, _, _ = select.select([master], [], [], 0.4)
        if r:
            try:
                chunk = os.read(master, 65536)
            except OSError:
                break
            if not chunk:
                break
            out += chunk
            last_send = 0.0
        else:
            # Silencio: la UI está esperando entrada
            if pending and time.time() - last_send > 0.2:
                os.write(master, pending.pop(0).encode())
                last_send = time.time()
            elif p.poll() is not None:
                break
    try:
        p.wait(timeout=5)
    except subprocess.TimeoutExpired:
        p.kill()
    os.close(master)
    return ANSI.sub("", out.decode(errors="replace")).replace("\r", ""), p.returncode

def check(name, ok, detail=""):
    print(("  ✅ " if ok else "  ❌ ") + name + (f"  → {detail}" if detail and not ok else ""))
    return 0 if ok else 1

# Lo que se espera se deriva del repo, no se fija a mano: si no, añadir un script
# desplaza los números del menú y el test falla por motivos que no son un bug.
OS_KEY = "darwin" if os.uname().sysname == "Darwin" else "linux"

def script_os(path):
    for line in open(path, encoding="utf-8", errors="replace"):
        m = re.match(r"# run-os: (\S+)", line)
        if m:
            return m.group(1)
    return "any"

def applicable(folder):
    d = os.path.join(REPO, "runs", folder)
    out = []
    for name in sorted(os.listdir(d)):
        p = os.path.join(d, name)
        if os.path.isfile(p) and os.access(p, os.X_OK) and script_os(p) in ("any", OS_KEY):
            out.append(name)
    return out

def menu_index(out):
    """Mapa nº → nombre de script, leído del menú tal como se renderiza."""
    idx = {}
    for m in re.finditer(r"[○●]\s*(\d+)\)\s+(\S+)", out):
        idx[int(m.group(1))] = m.group(2)
    return idx

fails = 0
print("=== A. Seleccionar 2 y 4, luego ejecutar ===")
out, rc = run(["2 4\n", "\n"])
ran = [os.path.basename(x) for x in re.findall(r"running script: (\S+)", out)]
idx = menu_index(out)
expected = sorted(n for k, n in idx.items() if k in (2, 4))
fails += check("ejecuta exactamente los dos elegidos", len(ran) == 2, f"ejecutó {ran}")
fails += check(f"son los que el menú numeraba 2 y 4 ({', '.join(expected)})",
               sorted(ran) == expected, f"ran={sorted(ran)} esperado={expected}")
fails += check("install-wm-linux oculto en macOS", "install-wm-linux" not in
               out.split("Ocultos")[0], "aparecía en la lista")
fails += check("aparece en la nota de ocultos", "install-wm-linux" in out)
fails += check("exit 0", rc == 0, f"rc={rc}")

print("\n=== B. 'b' selecciona solo el bootstrap ===")
out, rc = run(["b\n", "\n"])
ran = [os.path.basename(x) for x in re.findall(r"running script: (\S+)", out)]
want = applicable("bootstrap")
fails += check("todos los ejecutados son de bootstrap",
               bool(ran) and all("/bootstrap/" in x for x in
                                 re.findall(r"running script: (\S+)", out)), str(ran))
fails += check(f"son los {len(want)} de bootstrap que aplican a este OS",
               sorted(ran) == want, f"ran={sorted(ran)} esperado={want}")
fails += check("install-home-brew va primero", ran and ran[0] == "install-home-brew",
               ran[0] if ran else "")

print("\n=== C. 'q' sale sin ejecutar nada ===")
out, rc = run(["q\n"])
fails += check("no ejecuta nada", "running script" not in out)
fails += check("exit 0", rc == 0, f"rc={rc}")

print("\n=== D. Enter sin selección avisa y no sale ===")
out, rc = run(["\n", "q\n"])
fails += check("avisa de que no hay nada elegido", "No has elegido nada" in out)
fails += check("no ejecuta nada", "running script" not in out)

print("\n=== E. Número fuera de rango ===")
out, rc = run(["99\n", "q\n"])
fails += check("avisa de fuera de rango", "Fuera de rango" in out)

print("\n=== F. Alternar dos veces deselecciona ===")
out, rc = run(["5\n", "5\n", "\n", "q\n"])
fails += check("tras alternar dos veces no queda nada seleccionado",
               "No has elegido nada" in out, "debería avisar al pulsar Enter")

print("\n=== G. -i sin tty falla con mensaje ===")
p = subprocess.run(["/bin/bash", "./run", "-i"], cwd=REPO,
                   capture_output=True, text=True, stdin=subprocess.DEVNULL)
fails += check("rechaza -i sin terminal", p.returncode == 1 and "necesita una terminal" in p.stdout,
               f"rc={p.returncode} out={p.stdout[:80]}")

print(f"\n{'✅ TODO OK' if fails == 0 else f'❌ {fails} fallos'}")
sys.exit(1 if fails else 0)
