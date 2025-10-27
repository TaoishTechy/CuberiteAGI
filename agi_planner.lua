
Planner = Planner or {}
local Dialogue = require("agi_dialogue")
local AGI      = require("agi_core_helpers")
local Biology  = require("agi_biology")

local VILLAGER_TYPE = (cEntity and cEntity.etVillager) or 12
local function is_villager(e)
  if e.GetEntityType and VILLAGER_TYPE and e:GetEntityType() == VILLAGER_TYPE then return true end
  if _G.tolua and tolua.type and tolua.type(e) == "cVillager" then return true end
  return false
end

function Planner.set_goal(s, goal) s.goal=goal; s.subgoal_step=0 end

function Planner.execute_step(World, s)
  s.goal = s.goal or "idle"
  s.subgoal_step = (s.subgoal_step or 0) + 1
  local line = "I am in reflective stasis."
  if s.goal == "build_shrine" then
    line = (s.subgoal_step==1) and "Finding nexus for shrine." or "Placing stones."
    if s.subgoal_step>=2 then s.goal="idle" end
  elseif s.goal == "trade" then
    line = (s.subgoal_step==1) and "Seeking trade partner." or "Negotiating value."
    if s.subgoal_step>=2 then s.goal="idle" end
  elseif s.goal == "panic" then
    line = "RUNNING! Chaos delta is high!"; AGI.emit_pheromone(World, s.pos or {x=0,y=0,z=0}, "stress", 3.0)
    if s.subgoal_step>=3 then s.goal="idle"; line="I find metastable stasis." end
  end
  Dialogue.say(World, s, line)
end

function Planner.inject_negative_goal(World, pos, radius)
  local count=0
  World:ForEachEntity(function(e)
    if is_villager(e) and AGI.near(pos, e, radius) then
      local s = AGI_States[e:GetUniqueID()]
      if s and s.goal ~= "panic" then
        Planner.set_goal(s, "panic"); count = count + 1
        Dialogue.emote(World, s, "is engulfed by resonance cascade.")
      end
    end
  end)
  LOGINFO(string.format("[PLANNER] Injected panic around (%.1f,%.1f,%.1f) r=%.1f affecting %d",
    pos.x,pos.y,pos.z,radius,count))
end

return Planner
