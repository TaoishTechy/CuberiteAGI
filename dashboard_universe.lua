
-- Path helper: resolve this plugin's folder WITHOUT relying on a global `Plugin`
local function __agi_get_plugin_folder()
  if cPluginManager and cPluginManager.GetCurrentPlugin then
    local plug = cPluginManager:GetCurrentPlugin()
    if plug and plug.GetLocalFolder then return plug:GetLocalFolder() end
  end
  if debug and debug.getinfo then
    local src = debug.getinfo(1, "S").source or ""
    local path = src:match("^@(.+)$") or src
    local dir = path:match("^(.*)/[^/]+$")
    if dir and dir ~= "" then return dir end
  end
  return "."
end
local __AGI_PLUGIN_DIR = __agi_get_plugin_folder()

return function(a_Request)
  local AGIAPI = dofile(__AGI_PLUGIN_DIR .. "/AGIAPI.lua")
  local html = {}
  local function H(s) table.insert(html, s) end

  H("<style>body{font-family:sans-serif;background:#0b0f14;color:#e6edf3} .card{background:#0b1220;padding:16px;border-radius:12px;margin:12px 0} table{width:100%;border-collapse:collapse} th,td{padding:8px;border-bottom:1px solid #172036} button{background:#2563eb;color:#fff;border:none;padding:8px 12px;border-radius:8px;cursor:pointer} input,select{background:#0b1220;color:#e6edf3;border:1px solid #1f2937;border-radius:8px;padding:6px 8px}</style>")
  H("<h1>AGI Multiverse Dashboard</h1>")

  local worlds = {}
  cRoot:Get():ForEachWorld(function(W)
    local env = AGIAPI.sense_time(W)
    table.insert(worlds, {name=W:GetName(), tod=env.time_of_day or -1, age=env.world_age or -1, circ=env.circadian or 0})
  end)

  H("<div class='card'><table><tr><th>World</th><th>Time of Day</th><th>Age</th><th>Circadian</th></tr>")
  for _,w in ipairs(worlds) do
    H("<tr><td>"..w.name.."</td><td>"..w.tod.."</td><td>"..w.age.."</td><td>"..string.format('%.2f',w.circ).."</td></tr>")
  end
  H("</table></div>")

  return table.concat(html)
end
