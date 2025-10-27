
local PluginName = "CuberiteAGI-main"
AGI_States = AGI_States or {}

local function LogInfo(msg) LOG(string.format("[%s] %s", PluginName, msg)) end
local function clamp(v, a, b) if not v then return a end if v~=v then return a end if v<a then return a elseif v>b then return b else return v end end

-- Ensure helpers and dialogue are loaded (absolute dofile not used here since this is a drop-in patch)
-- If your plugin already loads these earlier in Initialize(), you can remove these requires.
local AGI = require("agi_core_helpers")
local Dialogue = require("agi_dialogue")

-- Pretty bar
local function bar(label, val)
  val = clamp(val, 0, 1)
  local filled = math.floor(val * 20)
  return string.format("%-10s [%s%s] %3d%%", label, string.rep("#", filled), string.rep("-", 20 - filled), math.floor(val*100))
end

-- /villager command (Split, Player)
local function HandleVillagerCommand(Split, Player)
  local sub = tostring(Split[2] or "help"):lower()
  local w = Player:GetWorld()
  local pos = Player:GetPosition()
  local VType = cMonster:StringToMobType("villager")

  if sub == "spawn" then
    local count = tonumber(Split[3] or "1") or 1
    if count < 1 then count = 1 end
    if count > 20 then count = 20 end
    local cx = math.floor(pos.x / 16)
    local cz = math.floor(pos.z / 16)
    w:ChunkStay({ { cx, cz } }, nil, function()
      local spawned = 0
      for i = 1, count do
        local ox, oz = math.random(-2, 2), math.random(-2, 2)
        local id = w:SpawnMob(pos.x + ox, pos.y, pos.z + oz, VType, false)
        if id ~= cEntity.INVALID_ID then
          spawned = spawned + 1
          local name = AGI.rand_name()
          AGI_States[id] = AGI_States[id] or {
            id = id,
            name = name,
            world_obj = w,
            pos = { x = pos.x, y = pos.y, z = pos.z },
            bio = { dopamine = 0.5, cortisol = 0.5, serotonin=0.5, oxytocin=0.5 },
            metrics = { CI = 0.5, PLV = 0.85, purity = 0.97, trust = 0.2 },
            genome = {},
            created_at = os.time()
          }
          w:DoWithEntityByID(id, function(ent)
            local m = tolua.cast(ent, "cMonster")
            if m then
              m:SetCustomName(name .. " [" .. tostring(id) .. "]")
              m:SetCustomNameAlwaysVisible(true)
            end
            return true
          end)
        end
      end
      Player:SendMessageSuccess(string.format("[AGI] Spawned %d villager(s).", spawned))
      LogInfo(string.format("Spawned %d villager(s) for %s at (%.1f, %.1f, %.1f)",
        spawned, Player:GetName(), pos.x, pos.y, pos.z))
    end)
    return true

  elseif sub == "inspect" then
    local key = Split[3]
    if not key or key == "" then
      Player:SendMessageInfo("Usage: /villager inspect <id|name>")
      return true
    end
    local ent = nil
    local uid = tonumber(key)
    if uid then
      ent = AGI.find_villager_by_id(w, uid)
    else
      -- Name may be quoted; join remaining pieces
      if key:sub(1,1) == '"' then
        local buf = {}
        for i=3,#Split do buf[#buf+1] = Split[i] end
        local joined = table.concat(buf, " ")
        key = joined:gsub('^"(.*)"$', "%1")
      end
      ent = AGI.find_villager_by_name(w, key)
    end
    if not ent then
      Player:SendMessageFailure("[AGI] Villager not found: " .. tostring(key))
      return true
    end
    local id = ent:GetUniqueID()
    local s = AGI_States[id]
    local m = tolua.cast(ent, "cMonster")
    local epos = ent:GetPosition()
    Player:SendMessageInfo(string.format("§a[AGI] Villager %s (ID %d) at (%.1f, %.1f, %.1f)",
      (s and (s.name or m:GetCustomName()) or m:GetCustomName() or "Unnamed"), id, epos.x, epos.y, epos.z))
    if s and s.metrics and s.bio then
      Player:SendMessageInfo(bar("CI", s.metrics.CI or 0))
      Player:SendMessageInfo(bar("PLV", s.metrics.PLV or 0))
      Player:SendMessageInfo(bar("Purity", s.metrics.purity or 0))
      Player:SendMessageInfo(bar("Trust", s.metrics.trust or 0))
      Player:SendMessageInfo(bar("Dopamine", s.bio.dopamine or 0))
      Player:SendMessageInfo(bar("Serotonin", s.bio.serotonin or 0))
      Player:SendMessageInfo(bar("Oxytocin", s.bio.oxytocin or 0))
      Player:SendMessageInfo(bar("Cortisol", s.bio.cortisol or 0))
    else
      Player:SendMessageInfo("No AGI state yet (will populate on next tick).")
    end
    return true

  elseif sub == "status" then
    -- Show a text "dashboard" like F3
    local count = 0
    for k,_ in pairs(AGI_States) do count = count + 1 end
    Player:SendMessageInfo("§b==== AGI STATUS (PazuzuTemple) ====")
    Player:SendMessageInfo(string.format("Villagers tracked: %d", count))
    local sample = 0
    for id,s in pairs(AGI_States) do
      if sample >= 6 then break end
      Player:SendMessageInfo(string.format("• %s [%d]  CI:%.2f PLV:%.2f Pur:%.2f",
        s.name or ("Villager "..tostring(id)), id,
        (s.metrics and s.metrics.CI or 0),
        (s.metrics and s.metrics.PLV or 0),
        (s.metrics and s.metrics.purity or 0)))
      sample = sample + 1
    end
    Player:SendMessageInfo("Use: /villager inspect <id|\"name\">")
    return true
  end

  Player:SendMessageInfo("Usage: /villager spawn [count] | /villager inspect <id|\"name\"> | /villager status")
  return true
end

function Initialize(Plugin)
  cPluginManager:BindCommand("/villager", "", HandleVillagerCommand,
    "AGI villager control: /villager spawn [count] | /villager inspect <id|\"name\"> | /villager status")
  LogInfo("[PazuzuTemple] Initialized. /villager ready.")
  return true
end

function OnDisable()
  LogInfo("Disabled.")
end
