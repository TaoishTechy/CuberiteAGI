
Dialogue = Dialogue or {}
local function safe_count(str, pat) local c=0; for _ in string.gmatch(str, "%"..pat) do c=c+1 end; return c end

-- Show text above head by temporarily augmenting the CustomName; revert after delay
local function talk_above_head(World, ent, baseName, text)
  local m = tolua.cast(ent, "cMonster")
  if not m then return end
  local orig = m:GetCustomName() or baseName or ""
  local label = string.format("%s » %s", baseName or orig, text)
  m:SetCustomName(label); m:SetCustomNameAlwaysVisible(true)
  World:ScheduleTask(2, function() m:SetCustomName(orig); m:SetCustomNameAlwaysVisible(true) end) -- revert after ~2 seconds
end

local function mood_particles(World, pos, mood)
  if mood == "happy" then
    World:BroadcastParticleEffect("villager_happy", pos.x,pos.y+1.8,pos.z, 0,0,0, 10)
  elseif mood == "angry" then
    World:BroadcastParticleEffect("villager_anger", pos.x,pos.y+1.8,pos.z, 0,0,0, 10)
  end
end

function Dialogue.say(World, s, message)
  local ent = AGI.find_villager_by_id(World, s.id)
  local pos = s.pos or {x=0,y=0,z=0}
  local ci = (s.metrics and s.metrics.CI) or 0.5
  local mood = (ci >= 0.5) and "happy" or "angry"
  if ent then talk_above_head(World, ent, s.name or ("Villager "..tostring(s.id)), message) end
  mood_particles(World, pos, mood)
end

function Dialogue.emote(World, s, message)
  local ent = AGI.find_villager_by_id(World, s.id)
  local pos = s.pos or {x=0,y=0,z=0}
  if ent then talk_above_head(World, ent, s.name or ("Villager "..tostring(s.id)), "*" .. message .. "*") end
  mood_particles(World, pos, "happy")
end

function Dialogue.OnChat(Player, Message)
  pcall(function()
    if type(Message)~="string" or #Message>512 then return end
    local dots = safe_count(Message, "."); local bangs = safe_count(Message, "!")
    local stress = (#Message)*(dots+bangs)/100.0
    if stress>1.0 then local World=Player:GetWorld(); local p=Player:GetPosition()
      World:BroadcastParticleEffect((stress<2.0) and "villager_happy" or "villager_anger", p.x,p.y,p.z, 1,1,1, 10) end
  end)
  return false
end

function Dialogue.OnPlayerCommand(Player, Command, Arguments) return false end
return Dialogue
