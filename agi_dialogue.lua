
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

Dialogue = Dialogue or {}
local AGIAPI = dofile(__AGI_PLUGIN_DIR .. "/AGIAPI.lua")

local function talk(World, ent, label, text, secs)
  local m = tolua.cast(ent, "cMonster"); if not m then return end
  local orig = m:GetCustomName() or label or ""
  local new  = string.format("%s » %s", label or orig, text)
  m:SetCustomName(new); m:SetCustomNameAlwaysVisible(true)
  World:ScheduleTask((secs or 2), function() m:SetCustomName(orig); m:SetCustomNameAlwaysVisible(true) end)
end

function Dialogue.say(World, s, message)
  local ent = nil
  if World and s and s.id then World:DoWithEntityByID(s.id, function(e) ent = e; return true end) end
  local pos = (ent and ent:GetPosition()) or {x=0,y=0,z=0}
  local mood = AGIAPI.mood_estimate(s)
  if ent then talk(World, ent, (s.name or ("Villager "..tostring(s.id))), message, 2) end
  if mood.label == "joyful" then World:BroadcastParticleEffect("villager_happy", pos.x,pos.y+1.8,pos.z, 0,0,0, 10)
  elseif mood.label == "anxious" then World:BroadcastParticleEffect("villager_anger", pos.x,pos.y+1.8,pos.z, 0,0,0, 10) end
end

function Dialogue.OnChat(Player, Message) return false end
return Dialogue
