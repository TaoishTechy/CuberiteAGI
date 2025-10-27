--[[
  Main entry point for the PazuzuTemple plugin.
  Initializes global state and schedules the main AGI tick loop.
--]]

-- Define global tables expected by the modules if they don't exist
AGI = AGI or {}
AGI_States = AGI_States or {} -- Holds the shadow state for all villagers

-- Load all core modules
local Evolution = require("PazuzuTemple/agi_evolution")
local Biology = require("PazuzuTemple/agi_biology")
local Persist = require("PazuzuTemple/agi_persistance") -- FIX: Corrected filename from agi_persist to agi_persistance
local Planner = require("PazuzuTemple/agi_planner")
local CoreHelpers = require("PazuzuTemple/agi_core_helpers")
local VillagerCore = require("PazuzuTemple/agi_villager_core")
local Dialogue = require("PazuzuTemple/agi_dialogue")

-- Global constants (assumed available in the Cuberite environment)
local TICK_RATE = 20 -- Ticks per second
local TICK_DT = 2.0  -- Simulating a 2-second time step for AGI processing

-- AGI_MainTick runs the core loops for all villagers
function AGI_MainTick(World)
  local entities = World:GetEntities()
  local pop_ids = {} -- Collect IDs for the online_epoch

  for _, e in ipairs(entities) do
    if e:GetEntityType() == 120 then -- 120 is the Cuberite Villager entity type
      local uid = e:GetUniqueID()
      -- Initialize state if it doesn't exist, including entity reference for helpers
      AGI_States[uid] = AGI_States[uid] or {id=uid, world_obj=e} 
      
      -- Shadow state initialization (s)
      local s = AGI_States[uid]
      
      -- F6: Load persistent state (if new or if state is incomplete)
      if not s.goal then Persist.load(s) end
      
      -- F1: Homeostasis Tick + E3: Epigenetic Update (Per villager)
      Biology.tick_homeostasis(World, s, TICK_DT)
      if (os.time() % 10) == 0 then Evolution.epigenetic_update(World, s) end
      
      -- E3/E11: Mutation + Reflective Guard (Every ~45s)
      if (os.time() % 45) == 0 then
        -- F7: Journal before mutation (for rollback)
        Persist.journal(s, "pre_mut")
        local before = { PLV=s.metrics.PLV or 0.85, purity=s.metrics.purity or 0.97, trust=(s.metrics.trust or 0.2) }
        
        Evolution.mutate(s)
        local ok, msg = Evolution.reflective_guard(World, s, before)
        
        -- E6: Dream -> Code Synthesis
        if ok and s.dream_log_buffer then Evolution.codegen_from_dream(s) end
        
        -- F5: Save state
        Persist.save(s)
      end

      -- F14: Sleep/Dream Cycle Check
      Planner.sleep_and_dream(World, s)
      
      -- F5: Periodic Save (in addition to the mutation save)
      if (os.time() % 30)==0 then Persist.save(s) end

      table.insert(pop_ids, uid)
    end
  end

  -- E10: Online Evolution Epoch (Every ~90s)
  if (os.time() % 90) == 0 then Evolution.online_epoch(World, pop_ids) end

  -- Reschedule the tick
  World:ScheduleTask(TICK_DT * TICK_RATE, function() AGI_MainTick(World) end)
end

-- Entry point called by Cuberite on plugin load
function Initialize(World)
  print("[PazuzuTemple] Initializing AGI Core...")
  
  -- Start the main AGI logic loop
  World:ScheduleTask(TICK_DT * TICK_RATE, function() AGI_MainTick(World) end)
  
  return true -- Successfully initialized
end
