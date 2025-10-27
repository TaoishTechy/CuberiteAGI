-- agi_core_helpers.lua
-- Core utilities including pheromone fields and chorus scheduling (F15-F17).

AGI = AGI or {}
AGI_States = AGI_States or {}
-- local Dialogue = Dialogue or {} -- REMOVED: This was causing a critical bug by overriding the real Dialogue table.
local Biology = require("PazuzuTemple/agi_biology")

-- === STUBS for required external functions/logic ===
function AGI.pos(entity)
  -- Placeholder stub for getting entity position
  local p = entity:GetPosition() 
  return {x=p.x, y=p.y, z=p.z}
end
-- FIX: Removed the stub for Dialogue.say to ensure the real function from agi_dialogue.lua is used.
-- === END STUBS ===

-- (F15) Social pheromone field (lightweight cache in world tick)
AGI.PHER = AGI.PHER or {} -- map chunkKey -> {oxytocin=.., stress=..}
function AGI.emit_pheromone(World, pos, kind, amount)
  local key = string.format("%d:%d", math.floor(pos.x/16), math.floor(pos.z/16))
  AGI.PHER[key] = AGI.PHER[key] or {oxytocin=0, stress=0}
  
  -- Exponential decay (0.95) plus new amount
  AGI.PHER[key][kind] = math.max(0, (AGI.PHER[key][kind] or 0) * 0.95 + amount)
end

function AGI.sample_pheromone(World, pos)
  local key = string.format("%d:%d", math.floor(pos.x/16), math.floor(pos.z/16))
  local cell = AGI.PHER[key] or {oxytocin=0, stress=0}
  return cell.oxytocin or 0, cell.stress or 0
end

-- (F16) Chorus scheduler (time-sliced, not immediate print) building on your call/response
function AGI.schedule_chorus(World, chorus, lines)
  local delay = 0
  -- Dialogue is assumed to be a global table set by require() in main.lua
  for i,line in ipairs(lines) do
    local sp = chorus[(i-1)%#chorus+1] -- Cycle through speakers
    -- Schedule a task in the Cuberite world loop
    World:ScheduleTask(delay, function() 
      Dialogue.say(World, sp, line) -- Now correctly calls the function from agi_dialogue.lua
    end)
    delay = delay + 10 -- Add 10 ticks (0.5 seconds) delay between speakers
  end
end

-- (F17) Fast check for proximity
function AGI.near(pos1, entity2, radius)
  -- Assumes pos1 is {x,y,z} and entity2 has :GetPosition()
  local pos2 = entity2:GetPosition()
  local dx, dy, dz = pos1.x - pos2.x, pos1.y - pos2.y, pos1.z - pos2.z
  local dist_sq = dx*dx + dy*dy + dz*dz
  return dist_sq < radius*radius
end
