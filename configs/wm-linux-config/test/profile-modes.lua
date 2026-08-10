-- Perfil sintético: linux-personal no usa WORK_MODE ni RESET_LAYOUT, así que
-- para probar el dispatcher hace falta un perfil que sí los use.
return {
  debugMode = false,
  appLaunchDelay = 0,
  minWidthForTiling = 2000,
  workAppLayout = {
    { name = "Visual Studio Code", position = "left",  width = "1/2", vertical = "top", height = "3/3" },
  },
  kaizenAppLayout = {
    { name = "Google Chrome", position = "right", width = "1/2", vertical = "top", height = "3/3" },
  },
  onDemandAppLayout = {
    { name = "Slack", position = "center", width = "2/3", vertical = "center", height = "2/3" },
  },
  foregroundApps = { work = {}, kaizen = {} },
  functionKeys = {
    { key = "F11", modifiers = {},        action = "WORK_MODE" },
    { key = "F11", modifiers = {"shift"}, action = "KAIZEN_MODE" },
    { key = "F12", modifiers = {},        action = "RESET_LAYOUT" },
  },
}
