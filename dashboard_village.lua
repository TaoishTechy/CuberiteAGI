
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
  local Persist = dofile(__AGI_PLUGIN_DIR .. "/agi_persistence.lua")
  local html = {}
  local function H(s) table.insert(html, s) end

  H("<style>body{font-family:sans-serif;background:#0b0f14;color:#e6edf3} .card{background:#0f172a;padding:16px;border-radius:12px;margin:12px 0} table{width:100%;border-collapse:collapse} th,td{padding:8px;border-bottom:1px solid #172036} .pill{display:inline-block;padding:4px 8px;border-radius:999px;background:#1f2937;color:#e5e7eb;margin-left:8px} button{background:#2563eb;color:#fff;border:none;padding:8px 12px;border-radius:8px;cursor:pointer} input,select{background:#0b1220;color:#e6edf3;border:1px solid #1f2937;border-radius:8px;padding:6px 8px}</style>")
  H("<h1>AGI Village Dashboard</h1>")

  local rows = {}
  cRoot:Get():ForEachWorld(function(W)
    local wname = W:GetName()
    local count, joy, anx = 0, 0, 0
    for id,s in pairs(AGI_States or {}) do
      if s.world_obj and s.world_obj:GetName() == wname then
        count = count + 1
        local mood = AGIAPI.mood_estimate(s)
        if mood.label == "joyful" then joy = joy + 1 elseif mood.label == "anxious" then anx = anx + 1 end
      end
    end
    table.insert(rows, {world=wname, villagers=count, joyful=joy, anxious=anx})
  end)

  H("<div class='card'><table><tr><th>World</th><th>Villagers</th><th>Joyful</th><th>Anxious</th><th>Actions</th></tr>")
  for _,r in ipairs(rows) do
    H("<tr><td>"..r.world.."</td><td>"..r.villagers.."</td><td>"..r.joyful.."</td><td>"..r.anxious.."</td>")
    H("<td><span class='pill'>Open</span></td></tr>")
  end
  H("</table></div>")

  -- Role assignment
  H("<div class='card'><h2>Assign Role</h2><form method='POST'>")
  H("Villager ID: <input name='id'> Role: <select name='role'><option>peasant</option><option>guard</option><option>merchant</option><option>priest</option><option>architect</option></select> ")
  H("<button name='action' value='role'>Set</button></form>")
  local p = a_Request.PostParams or {}
  if a_Request.Method=="POST" and p["action"]=="role" then
    local id = tonumber(p["id"] or "")
    local role = p["role"] or "peasant"
    if id and AGI_States[id] then
      AGI_States[id].role = role
      Persist.save(AGI_States[id])
      H("<p>Role set.</p>")
    else
      H("<p>Invalid ID.</p>")
    end
  end

  return table.concat(html)
end
