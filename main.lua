
-- AGIAPI/main.lua — core bootstrap without relying on global Plugin

local PluginName = "AGIAPI"

local function LOGI(msg) LOG(string.format("[%s] %s", PluginName, msg)) end
local function LOGW(msg) LOGWARNING(string.format("[%s] %s", PluginName, msg)) end

-- Resolve folder safely
local function get_folder(Plugin)
  if Plugin and Plugin.GetLocalFolder then return Plugin:GetLocalFolder() end
  if cPluginManager and cPluginManager.GetCurrentPlugin then
    local plug = cPluginManager:GetCurrentPlugin()
    if plug and plug.GetLocalFolder then return plug:GetLocalFolder() end
  end
  if debug and debug.getinfo then
    local src = debug.getinfo(1, "S").source or ""
    local p = src:match("^@(.+)$") or src
    local dir = p:match("^(.*)/[^/]+$")
    if dir then return dir end
  end
  return "."
end

-- Safe require that uses plugin-folder relative paths
local function require_local(folder, rel)
  local path = folder .. "/" .. rel
  local ok, mod_or_err = pcall(function() return dofile(path) end)
  if not ok then
    LOGW("Failed to load '" .. rel .. "': " .. tostring(mod_or_err))
    return nil
  end
  return mod_or_err
end

-- Namespace root (global for other plugins to use)
AGI = AGI or {}

-- WebAdmin helper that tries multiple signatures to avoid crashes across builds
local function add_web_tab_safe(Plugin, title, urlKey, handlerFn)
  if not (cWebAdmin and cWebAdmin.AddWebTab) then return false end
  local tries = {
    function() return cWebAdmin:AddWebTab(title, urlKey, handlerFn, Plugin) end, -- 4-arg
    function() return cWebAdmin:AddWebTab(title, Plugin, handlerFn) end,         -- 3-arg (title, plugin, handler)
    function() return cWebAdmin:AddWebTab(Plugin, title, handlerFn) end,         -- 3-arg (plugin, title, handler)
    function() return cWebAdmin:AddWebTab(title, urlKey, handlerFn) end,         -- 3-arg (title, url, handler)
    function() return cWebAdmin:AddWebTab(title, handlerFn) end,                 -- 2-arg (title, handler)
  }
  for i,fn in ipairs(tries) do
    local ok = pcall(fn)
    if ok then return true end
  end
  LOGW("WebAdmin present, but AddWebTab signatures failed; dashboards disabled for this build.")
  return false
end

-- Bound at Initialize scope
local PLUGIN_FOLDER = nil

-- /agi command
local function HandleAgi(Split, Player)
  local sub = tostring(Split[2] or "ping"):lower()
  if sub == "ping" then
    if Player then Player:SendMessageSuccess("[AGIAPI] pong") else LOG("[AGIAPI] pong") end
    return true
  elseif sub == "dump" then
    local N = 0
    if AGI and AGI.World and AGI.World.GetEntitiesInRadius then N = 1 end
    if Player then Player:SendMessageInfo("[AGIAPI] Namespaces online: " .. tostring(N > 0 and "World+Action+Harmony+Self" or "minimal")) end
    return true
  elseif sub == "task" then
    if Player then
      local W = Player:GetWorld()
      local pos = {x = math.floor(Player:GetPosX()), y = math.floor(Player:GetPosY()), z = math.floor(Player:GetPosZ())}
      local AGI_Action = AGI and AGI.Action
      if AGI_Action and AGI_Action.CreateTask then
        local t = AGI_Action.CreateTask("demo_bubble")
        AGI_Action.AddSubTask(t, {type="BROADCAST_MESSAGE", message="AGIAPI online at ("..pos.x..","..pos.y..","..pos.z..")"})
        AGI_Action.ScheduleTask(W, t, 10)
        Player:SendMessageSuccess("[AGIAPI] Scheduled demo task.")
      else
        Player:SendMessageFailure("[AGIAPI] Action module unavailable.")
      end
    else
      LOG("[AGIAPI] 'task' needs a player context")
    end
    return true
  end
  if Player then Player:SendMessageInfo("Usage: /agi ping | /agi dump | /agi task") end
  return true
end

function Initialize(Plugin)
  PLUGIN_FOLDER = get_folder(Plugin)

  -- Load utilities and modules
  local Utils = require_local(PLUGIN_FOLDER, "api/utils.lua") or {}
  local World = require_local(PLUGIN_FOLDER, "api/world.lua") or {}
  local Action = require_local(PLUGIN_FOLDER, "api/action.lua") or {}
  local Harmony = require_local(PLUGIN_FOLDER, "api/harmony.lua") or {}
  local SelfMod = require_local(PLUGIN_FOLDER, "api/self.lua") or {}
  local Crit = require_local(PLUGIN_FOLDER, "api/holographic_criticality.lua") or {}

  -- Wire namespaces
  AGI.World = World
  AGI.Action = Action
  AGI.Harmony = Harmony
  AGI.Self = SelfMod
  AGI.Criticality = Crit

  -- Bind command
  cPluginManager:BindCommand("/agi", "", HandleAgi, "AGIAPI control")

  -- WebAdmin dashboard (readonly intro + ping)
  local dash = require_local(PLUGIN_FOLDER, "web/dashboard.lua")
  if dash then add_web_tab_safe(Plugin, "AGI API", "AGIAPI", dash) end

  LOGI("Initialized. Namespaces: World/Action/Harmony/Self" .. (Crit and "/Criticality" or ""))
  return true
end

function OnDisable() LOGI("Disabled.") end
