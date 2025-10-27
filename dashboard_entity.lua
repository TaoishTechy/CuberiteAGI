
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
  local params = a_Request.PostParams or a_Request.Params or {}
  local id = tonumber(params["id"] or "")

  H("<style>body{font-family:sans-serif;background:#0b0f14;color:#e6edf3} .card{background:#111827;padding:16px;border-radius:12px;margin:12px 0} .grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:12px} h2{margin:0 0 8px} .bar{height:8px;background:#1f2937;border-radius:6px;overflow:hidden} .bar>i{display:block;height:100%} .row{display:flex;justify-content:space-between;align-items:center;margin:6px 0} button{background:#2563eb;color:#fff;border:none;padding:8px 12px;border-radius:8px;cursor:pointer} input,select{background:#0b1220;color:#e6edf3;border:1px solid #1f2937;border-radius:8px;padding:6px 8px} a{color:#93c5fd}</style>")
  H("<h1>AGI Entity Dashboard</h1>")
  H("<div class='card'><form method='GET'>ID: <input name='id' value='"..(id or "").."'><button>Open</button></form></div>")

  if not id then
    H("<p>Select an entity ID to view.</p>")
    return table.concat(html)
  end

  local W = cRoot:Get():GetDefaultWorld()
  local ent = nil
  W:DoWithEntityByID(id, function(e) ent = e; return true end)
  if not ent then
    H("<div class='card'>Entity not found.</div>")
    return table.concat(html)
  end

  local s = AGI_States and AGI_States[id] or {id=id, name="Unknown", bio={}, metrics={}, trust_map={}}
  local function meter(label, v, color)
    v = math.max(0, math.min(1, tonumber(v or 0)))
    H("<div class='row'><div>"..label.."</div><div style='width:60%'><div class='bar'><i style='width:"..math.floor(v*100).."%;background:"..(color or "#10b981").."'></i></div></div><div>"..math.floor(v*100).."%</div></div>")
  end

  H("<div class='card'><h2>Identity</h2>")
  H("<div class='grid'>")
  H("<div><b>ID</b><br>"..id.."</div>")
  H("<div><b>Name</b><br>"..(s.name or "Unnamed").."</div>")
  H("</div></div>")

  H("<div class='card'><h2>Mood & Bio</h2>")
  meter("CI", (s.metrics and s.metrics.CI) or 0.5, "#f59e0b")
  meter("PLV", (s.metrics and s.metrics.PLV) or 0.8, "#22c55e")
  meter("Purity", (s.metrics and s.metrics.purity) or 0.9, "#06b6d4")
  meter("Trust", (s.metrics and s.metrics.trust) or 0.2, "#a78bfa")
  meter("Dopamine", (s.bio and s.bio.dopamine) or 0.5, "#10b981")
  meter("Serotonin", (s.bio and s.bio.serotonin) or 0.5, "#38bdf8")
  meter("Oxytocin", (s.bio and s.bio.oxytocin) or 0.5, "#f472b6")
  meter("Cortisol", (s.bio and s.bio.cortisol) or 0.5, "#ef4444")
  H("</div>")

  H("<div class='card'><h2>Memory Crystals</h2>")
  local root = cRoot:Get():GetDefaultWorld():GetDataPath() .. "/agi/journal"
  if cFile:IsFolder(root) then
    local files = cFile:GetFilesInFolder(root)
    local shown=0
    H("<ul>")
    for _,f in ipairs(files) do
      local eid = f:match("^(%d+)_")
      if tostring(eid) == tostring(id) then
        H("<li>"..f.."</li>")
        shown = shown + 1
        if shown > 20 then break end
      end
    end
    H("</ul>")
  else
    H("<p>No journal directory.</p>")
  end
  H("</div>")

  -- Quick edit
  H("<div class='card'><h2>Edit State</h2>")
  H("<form method='POST'>")
  H("Name: <input name='new_name' value='"..(s.name or "").."'> ")
  H("CI: <input name='ci' value='"..((s.metrics and s.metrics.CI) or 0.5).."'> ")
  H("<button name='action' value='save'>Save</button>")
  H("</form>")
  if a_Request.Method == "POST" and params["action"] == "save" then
    s.name = params["new_name"] or s.name
    s.metrics = s.metrics or {}
    s.metrics.CI = tonumber(params["ci"] or s.metrics.CI or 0.5)
    Persist.save(s)
    H("<p>Saved.</p>")
  end
  H("</div>")

  return table.concat(html)
end
