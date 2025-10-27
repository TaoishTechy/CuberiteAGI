
AGI_Core = AGI_Core or {}
AGI_States = AGI_States or {}

local AGI       = require("agi_core_helpers")
local Biology   = require("agi_biology")
local Persist   = require("agi_persistence")
local Planner   = require("agi_planner")
local Evolution = require("agi_evolution")
local Dialogue  = require("agi_dialogue")

local VILLAGER_TYPE = (cEntity and cEntity.etVillager) or 12
AGI_Core.WorldState = AGI_Core.WorldState or {}
AGI_Core.WorldLock  = AGI_Core.WorldLock  or {}

local function now() return os.time() end
local function is_villager(e)
  if e.GetEntityType and VILLAGER_TYPE and e:GetEntityType() == VILLAGER_TYPE then return true end
  if _G.tolua and tolua.type and tolua.type(e) == "cVillager" then return true end
  return false
end
local function schedule_next(World, ms) World:ScheduleTask((ms or 2000) / 1000, function() AGI_Core.AGI_MainTick(World) end) end

function AGI_Core.AGI_MainTick(World)
  local cfg = AGI_CONFIG or { TICK_INTERVAL_MS=2000, SAVE_PERIOD_SECONDS=30, IDLE_THROTTLE_RATE=5, MUTATION_PERIOD=45, EPOCH_PERIOD=90 }
  local wname = World:GetName()
  if AGI_Core.WorldLock[wname] then schedule_next(World, cfg.TICK_INTERVAL_MS); return end
  AGI_Core.WorldLock[wname] = true

  local dt   = (cfg.TICK_INTERVAL_MS or 2000) / 1000
  local pop  = {}
  local tnow = now()

  World:ForEachEntity(function(e)
    if is_villager(e) then
      local id = e:GetUniqueID()
      local s = AGI_States[id] or { id=id, world_obj=World, pos=AGI.pos(e), metrics={CI=0.5, PLV=0.85, purity=0.97, trust=0.2}, genome={} }
      AGI_States[id] = s
      s.pos = AGI.pos(e)
      Persist.load(s)

      if s.is_asleep then
        if math.random(1, (cfg.IDLE_THROTTLE_RATE or 5)) == 1 then Biology.tick_homeostasis(World, s, dt*(cfg.IDLE_THROTTLE_RATE or 5)) end
      else
        Biology.tick_homeostasis(World, s, dt)
        Planner.execute_step(World, s)
        local oxy, stress = AGI.sample_pheromone(World, s.pos)
        Biology.affect(World, s, {calm = oxy * 0.1, stress = stress * 0.1})
      end

      local mut_period = cfg.MUTATION_PERIOD or 45
      s._last_mut_ts = s._last_mut_ts or 0
      if tnow - s._last_mut_ts >= mut_period then
        Persist.journal(s, "pre_mut")
        local before = { PLV = s.metrics.PLV or 0.85, purity = s.metrics.purity or 0.97 }
        Evolution.mutate(s)
        Evolution.reflective_guard(World, s, before)
        Persist.save(s)
        s._last_mut_ts = tnow
      end

      local save_period = cfg.SAVE_PERIOD_SECONDS or 30
      s._last_save_ts = s._last_save_ts or 0
      if tnow - s._last_save_ts >= save_period then Persist.save(s); s._last_save_ts = tnow end
      table.insert(pop, id)
    end
  end)

  local ws = AGI_Core.WorldState[wname] or { last_epoch_ts = 0 }
  local epoch_period = cfg.EPOCH_PERIOD or 90
  if tnow - (ws.last_epoch_ts or 0) >= epoch_period then
    ws.last_epoch_ts = tnow
    AGI_Core.WorldState[wname] = ws
    Evolution.online_epoch(World, pop)
  else
    AGI_Core.WorldState[wname] = ws
  end

  AGI_Core.WorldLock[wname] = false
  schedule_next(World, cfg.TICK_INTERVAL_MS)
end

function AGI_Core.HandleAdminCommand(Player, Command, Args)
  if not Player:HasPermission("pazuzu.admin") then return false end
  local id = tonumber(Args[1] or "")
  if not id then return false end
  local s = AGI_States[id]
  if not s then Player:SendMessage("No AGI state for ID."); return true end
  local action = (Args[2] or ""):lower()
  if action == "inspect" then
    Player:SendMessage(("AGI %d  goal=%s  asleep=%s"):format(id, tostring(s.goal), tostring(s.is_asleep))); return true
  elseif action=="sleep" then s.is_asleep=true; Player:SendMessage("Sleeping."); return true
  elseif action=="wake" then s.is_asleep=false; Player:SendMessage("Woken."); return true
  elseif action=="reset" then AGI_States[id]=nil; require("agi_persistence").delete(id); Player:SendMessage("Reset done."); return true
  end
  return false
end

return AGI_Core
