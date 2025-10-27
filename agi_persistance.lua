-- agi_persist.lua
-- Persistence with journaling + rollbacks (F5-F7).
-- This module requires Cuberite's cJson and cFile APIs.

Persist = Persist or {}

-- Utility to determine the save path for the villager ID
local function path_for(id) return string.format("world/agi/%s.json", tostring(id)) end
-- Attempt to create the folder (assuming Cuberite API access)
if cFile and cFile.CreateFolder then cFile:CreateFolder("world/agi") end

-- (F5) Save villager brain (genome, state, bio, goals, linguistics)
function Persist.save(s)
  local data = {
    id=s.id, goal=s.goal, subgoal_step=s.subgoal_step or 0,
    bio=s.bio, linguistics=s.linguistics, trust=s.trust_map,
    dream_log=s.dream_log_buffer, genome=s.genome, ts=os.time()
  }
  
  if cJson and cFile then
    local json = cJson:Serialize(data)
    cFile:WriteWholeFile(path_for(s.id), json)
    return true
  else
    -- LOG("Persist.save: Cuberite API (cJson/cFile) not available.")
    return false
  end
end

-- (F6) Load (if exists), else noop
function Persist.load(s)
  if not cJson or not cFile then return false end
  local p = path_for(s.id)
  
  if not cFile:IsFile(p) then return false end
  
  local ok, data = pcall(function() return cJson:Parse(cFile:ReadWholeFile(p)) end)
  
  if ok and data then
    s.goal, s.subgoal_step = data.goal, data.subgoal_step
    s.bio = data.bio; 
    s.linguistics = data.linguistics or {}; 
    s.trust_map = data.trust or {};
    s.genome = data.genome or {}; -- Load the full genome state
    s.dream_log_buffer = data.dream_log or {}
    return true
  end
  return false
end

-- (F7) Journal + soft rollback (keep last N snapshots per villager)
function Persist.journal(s, tag)
  if not cJson or not cFile then return false end

  local stamp = os.time()
  local jpath = string.format("world/agi/journal/%s_%d_%s.json", s.id, stamp, tag or "snap")
  if cFile.CreateFolder then cFile:CreateFolder("world/agi/journal") end

  -- Serialize a copy of the shadow state 's'
  if cFile and cJson then
    local ok, json = pcall(function() return cJson:Serialize(s) end)
    if ok then
      cFile:WriteWholeFile(jpath, json)
      return true
    end
  end
  return false
end
