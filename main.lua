--[[
  Main entry point for the PazuzuTemple plugin.
  Initializes global state and schedules the main AGI tick loop.
--]]

-- Define global tables expected by the modules if they don't exist
AGI = AGI or {}
AGI_States = AGI_States or {} -- Holds the shadow state for all villagers

-- Load all core modules
local Evolution = require("agi_evolution") -- DEBUG FIX: Removed "PazuzuTemple/" prefix
local Biology = require("agi_biology")     -- DEBUG FIX: Removed "PazuzuTemple/" prefix
local Persist = require("agi_persistance") -- DEBUG FIX: Removed "PazuzuTemple/" prefix, CORRECTED: agi_persist to agi_persistance
local Planner = require("agi_planner")     -- DEBUG FIX: Removed "PazuzuTemple/" prefix
local CoreHelpers = require("agi_core_helpers") -- DEBUG FIX: Removed "PazuzuTemple/" prefix
local VillagerCore = require("agi_villager_core") -- DEBUG FIX: Removed "PazuzuTemple/" prefix
local Dialogue = require("agi_dialogue")    -- DEBUG FIX: Removed "PazuzuTemple/" prefix

-- Global constants (assumed available in the Cuberite environment)
local TICK_RATE = 20 -- Ticks per second
local TICK_DT = 2.0  -- Simulating a 2-second time step for AGI processing

-- Evolution module functions
Evolution.AGI_States = AGI_States -- Give Evolution access to the state table

-- E1: The Mutagenic Drift (simple random value mutation)
function Evolution.mutate(s)
  s.genome = s.genome or {
    mutation_rate = 0.01,
    PLV_setpoint = 0.85, -- Psycho-Linguistic Valence setpoint
    trust_decay = 0.05,
    virtu_bias = 0.5, -- How much Virtù influences behavior
  }
  
  -- Mutate parameters by a small random factor
  local mutation_amount = s.genome.mutation_rate * (math.random() - 0.5) * 2
  s.genome.PLV_setpoint = math.min(1.0, math.max(0.0, s.genome.PLV_setpoint + mutation_amount * 0.1))
  s.genome.trust_decay = math.min(0.5, math.max(0.01, s.genome.trust_decay + mutation_amount * 0.05))
  s.genome.virtu_bias = math.min(1.0, math.max(0.0, s.genome.virtu_bias + mutation_amount * 0.1))
  
  print(string.format("[EVO] Villager %s mutated: PLV=%.2f, TrustDecay=%.2f", s.id, s.genome.PLV_setpoint, s.genome.trust_decay))
end

-- E2: Epigenetic Update (state-dependent change to genome)
function Evolution.epigenetic_update(World, s)
  s.genome = s.genome or {}
  
  -- High stress (Cortisol) increases PLV_setpoint (hyper-vigilance/anxiety)
  if s.bio.cortisol > 0.75 then
    s.genome.PLV_setpoint = math.min(1.0, s.genome.PLV_setpoint + 0.01)
  end
  
  -- High Virtù (Karma) decreases trust_decay (more persistent trust)
  if s.metrics and s.metrics.Virtù > 5.0 then
    s.genome.trust_decay = math.max(0.01, s.genome.trust_decay - 0.005)
  end
end

-- E11/E3: Reflective Guard (rollback if mutation leads to an unstable state)
function Evolution.reflective_guard(World, s, before_state)
  -- The core instability metric is CI (Coherence Index)
  if s.metrics.CI < 0.1 then 
    -- F7: Rollback to pre-mutation state if CI collapses
    Persist.rollback(s, "pre_mut")
    s.metrics.PLV = before_state.PLV
    s.metrics.purity = before_state.purity
    s.metrics.trust = before_state.trust
    Dialogue.emote(World, s, "...rejected the mutation; its syntax was deemed 'Unstable-Syntax' by the Guard.")
    return false, "Rollback: Unstable Syntax (CI too low)"
  end
  
  return true, "Mutation Accepted"
end

-- E6: Code Synthesis from Dream Log
function Evolution.codegen_from_dream(s)
  if #s.dream_log_buffer > 0 then
    local new_code_line = "local dream_insight = " .. s.dream_log_buffer[#s.dream_log_buffer]
    -- In a real scenario, this 'new_code_line' would be appended to a dynamic script/config
    print(string.format("[EVO] Villager %s synthesized code: %s", s.id, new_code_line))
    s.dream_log_buffer = {} -- Clear buffer after synthesis attempt
  end
end

-- E10: Online Evolution Epoch (Group-level selection)
function Evolution.online_epoch(World, pop_ids)
  print(string.format("[EVO] Starting Online Evolution Epoch for %d entities.", #pop_ids))
  -- For simplicity, select the fittest based on Purity and Trust, and copy their genome to the least fit.
  
  local best_s, best_score = nil, -math.huge
  local worst_s, worst_score = nil, math.huge
  
  for _, uid in ipairs(pop_ids) do
    local s = AGI_States[uid]
    if s and s.metrics then
      -- Score = Purity * Coherence + Virtù
      local score = (s.metrics.purity or 0) * (s.metrics.CI or 0) + (s.metrics.Virtù or 0)
      
      if score > best_score then
        best_score = score
        best_s = s
      end
      
      if score < worst_score then
        worst_score = score
        worst_s = s
      end
    end
  end
  
  if best_s and worst_s and best_s.id ~= worst_s.id then
    -- E4: Horizontal Gene Transfer (Fittest copies genome to weakest)
    worst_s.genome = table.copy(best_s.genome) -- Deep copy of the genome
    
    -- E5: Phenotype Drift (Apply immediate biological changes)
    -- The weakest is now slightly happier/less stressed
    worst_s.bio.dopamine = math.min(1.0, worst_s.bio.dopamine + 0.1)
    worst_s.bio.cortisol = math.max(0.0, worst_s.bio.cortisol - 0.1)
    
    Dialogue.emote(World, worst_s, string.format("...has received a Gene-Seed from Villager %s, initiating a local Virtù cascade.", best_s.id))
  end
end
