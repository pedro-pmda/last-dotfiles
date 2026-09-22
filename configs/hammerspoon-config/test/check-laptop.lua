-- Portátil solo (1512 px): no hay ancho que repartir, así que no se reparte.

local H = dofile((os.getenv("TEST_DIR") or ".") .. "/harness.lua")

H.load()
H.flush()

print("D1 · nadie se queda a media pantalla")
H.expectRect("IntelliJ a pantalla completa", "IntelliJ IDEA", 0, 0, 1512, 982)
H.expectRect("Ghostty a pantalla completa",  "Ghostty",       0, 0, 1512, 982)

print("D2 · y el doble toque no inventa un 2/3 que no cabe")
H.doublePress("F5")
H.flush()
H.expectRect("IntelliJ sigue a pantalla completa", "IntelliJ IDEA", 0, 0, 1512, 982)

print("D3 · se anuncia el modo correcto")
H.check("avisa de que no reparte", H.alertsMatch("portátil"))

H.done()
