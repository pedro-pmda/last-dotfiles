-- Perfil sintético: linux-personal no ejercita todos los layouts a la vez,
-- así que para probar el dispatcher (KAIZEN_MODE / RESET_LAYOUT despachados
-- como acciones y no como nombres de app) hace falta un perfil dedicado.
return {
  debugMode = false,
  appLaunchDelay = 0,
  minWidthForTiling = 2000,
  kaizenAppLayout = {
    { name = "Google Chrome", position = "right", width = "1/2", vertical = "top", height = "3/3" },
  },
  onDemandAppLayout = {
    { name = "Slack", position = "center", width = "2/3", vertical = "center", height = "2/3" },
  },
  foregroundApps = { kaizen = {} },
  functionKeys = {
    { key = "F11", modifiers = {"shift"}, action = "KAIZEN_MODE" },
    { key = "F12", modifiers = {},        action = "RESET_LAYOUT" },
  },
}
