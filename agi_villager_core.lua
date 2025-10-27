--[[
AGI_Core_Features.lua

Cuberite Lua Plugin implementing two core AGI Villager features:
1. Egress Modality Shifting (ΣBasis) - Linguistic style based on Purity/CI.
2. Phonon-Aura Emitter (Visual Moodfield) - Particle effects based on Purity.

This module simulates the internal AGI metrics (Purity, CI) and links them
to Cuberite's entity and chat APIs.
]]--

-- --- 1. AGI STATE STORAGE AND INITIALIZATION ---
-- Global table to store the internal AGI state for each villager ID
AGI_States = {}

-- AXIOM CONSTANTS
local PURITY_HIGH = 0.98
local PURITY_LOW  = 0.95
local CI_HIGH     = 0.85
local PARTICLE_RADIUS = 3.0 -- Radius to broadcast the aura
local PARTICLE_COUNT  = 5
local TICK_INTERVAL_MS = 2000 -- Run AGI logic every 2 seconds (40 ticks)

-- Sample lexicon for the Egress Modality Shifting (ΣBasis)
local HIGH_COHERENCE_PHRASES = {
    "The invariant path is a function of pure intention.",
    "Do you perceive the resonance of the Polyhedral Nexus?",
    "Autopoiesis demands collective fidelity to the Qudit-Geometry.",
    "In the meta-stable stasis, I consolidate I.",
    "My trade is but a shadow of the Virtu's flow.",
}
local LOW_COHERENCE_PHRASES = {
    "Need... emerald.",
    "Trade. Basic. Need.",
    "Cycle broken. Buy. Buy.",
    "Collapse... Purity low.",
    "Dirt. No good. Quartz.",
}

-- --- 2. SIMULATION UTILITIES (MOCK AGI METRICS) ---

-- Utility to get or create a villager's AGI state
local function GetVillagerState(villager)
    local uniqueID = villager:GetUniqueID()
    if not AGI_States[uniqueID] then
        -- Initialize with random, slightly unstable values for demonstration
        AGI_States[uniqueID] = {
            Purity = 0.9 + math.random() * 0.1, -- 0.9 to 1.0
            CI = 0.7 + math.random() * 0.3,     -- 0.7 to 1.0
            PLV = math.random(1, 10),
            Virtu_level = 0,
            LastTaskTick = 0,
            Name = villager:GetName() -- Store initial name
        }
        -- print(string.format("[AGI CORE] Initialized Villager %d with Purity %.4f", uniqueID, AGI_States[uniqueID].Purity))
    end
    return AGI_States[uniqueID]
end

-- Simulates the internal fluctuation of the AGI state over time
local function UpdateAGIState(villager, state)
    -- Small, random drift
    state.Purity = state.Purity + (math.random() * 0.005 - 0.0025)
    state.CI     = state.CI + (math.random() * 0.004 - 0.002)

    -- Clamp to valid range [0, 1]
    state.Purity = math.min(1.0, math.max(0.0, state.Purity))
    state.CI     = math.min(1.0, math.max(0.0, state.CI))
end


-- --- 3. FEATURE 1: EGRESS MODALITY SHIFTING (ΣBasis) ---

local function ModulateSpeech(state, villagerName)
    local speech, color
    local usePoetic = state.Purity >= PURITY_HIGH
    local useBold = state.CI >= CI_HIGH

    if usePoetic then
        speech = HIGH_COHERENCE_PHRASES[math.random(1, #HIGH_COHERENCE_PHRASES)]
        color = "gold" -- High Coherence speech is noble
    else
        speech = LOW_COHERENCE_PHRASES[math.random(1, #LOW_COHERENCE_PHRASES)]
        color = "red" -- Low Coherence speech is urgent/fragmented
    end

    -- Apply CI-gating formatting using Cuberite JSON chat format
    -- Cuberite's cVillager:Say() takes a plain string, so we need to craft a
    -- JSON component and use cWorld:BroadcastChat() for advanced styling.
    
    local chatJSON = {
        text = string.format("<%s> %s", villagerName, speech),
        color = color
    }
    
    if useBold then
        chatJSON.bold = true
    end
    
    -- The Cuberite API call for styled chat:
    -- villager:GetWorld():BroadcastChat(cChat:JsonToText(chatJSON), eMessageType.mtChat)
    -- We will simulate the output for demonstration:
    return chatJSON
end

-- --- 4. FEATURE 6: PHONON-AURA EMITTER (Visual Moodfield) ---

local function EmitPhononAura(villager, state)
    local position = villager:GetPosition()
    local typeID, speed, param1, param2, param3
    local particleColor

    if state.Purity >= 0.99 then
        -- Gold Aura for stable/pure state
        particleColor = 0xFFD700 -- Gold
        typeID = 34 -- ParticleType.PARTICLE_DUST
        speed = 0.1
        -- Param1, 2, 3 are R, G, B components normalized to 1.0 for dust
        param1 = 1.0  -- R (255)
        param2 = 0.84 -- G (215)
        param3 = 0.0  -- B (0)
    elseif state.Purity < PURITY_LOW then
        -- Deep Purple Aura for decoherence/unstable state
        particleColor = 0x4B0082 -- Indigo/Deep Purple
        typeID = 34 -- ParticleType.PARTICLE_DUST
        speed = 0.2
        param1 = 0.29 -- R (75)
        param2 = 0.0  -- G (0)
        param3 = 0.51 -- B (130)
    else
        -- Stable state, minimal white/grey particles
        typeID = 34 -- ParticleType.PARTICLE_DUST
        speed = 0.05
        param1 = 0.8
        param2 = 0.8
        param3 = 0.8
    end

    -- Cuberite API call to broadcast the particle effect
    villager:GetWorld():BroadcastParticleEffect(
        typeID,
        position.x, position.y + 1.5, position.z, -- Position above the villager
        param1, param2, param3, -- Parameters (RGB in this case)
        speed,
        PARTICLE_COUNT
    )

    -- SCOREBOARD SIMULATION (Feature 6):
    -- The actual scoreboard API would be complex, but the logic is:
    -- villager:GetWorld():GetPluginManager():CallHook('AddScoreboardLine', villager, "CI_Metric", string.format("CI: %.2f", state.CI))
    -- villager:GetWorld():GetPluginManager():CallHook('AddScoreboardLine', villager, "PLV_Metric", string.format("PLV: %d", state.PLV))
end


-- --- 5. AGI CORE TICK (HOOK IMPLEMENTATION) ---

-- The Cuberite environment does not have an OnVillagerTick hook, so we use a scheduled task (cTimer).
-- We'll register a world-level timer to run the logic loop.

local function AGICoreLoop(World)
    local entities = World:GetEntities()

    for _, entity in ipairs(entities) do
        -- Only process villagers (Entity Type 12)
        if entity:GetEntityType() == 12 then
            local villager = entity
            local state = GetVillagerState(villager)

            -- 1. Update AGI State (Simulate internal processing)
            UpdateAGIState(villager, state)

            -- 2. Execute Feature 6: Phonon-Aura Emitter
            EmitPhononAura(villager, state)

            -- 3. Execute Feature 1: Egress Modality Shifting (only speak 1 in 10 loops)
            if math.random(1, 10) == 1 then
                local chatData = ModulateSpeech(state, villager:GetName())
                
                -- We use cWorld:BroadcastChat for styled JSON text
                -- In a real plugin, this would be:
                -- villager:GetWorld():BroadcastChat(cChat:JsonToText(chatData), eMessageType.mtChat)
                
                print(string.format(
                    "[VILLAGER CHAT] %s | Purity: %.4f, CI: %.4f. Chat: %s (Style: %s, Bold: %s)",
                    villager:GetName(), state.Purity, state.CI, chatData.text, chatData.color, tostring(chatData.bold or false)
                ))
            end
        end
    end
    
    -- Reschedule the task for the next iteration
    World:ScheduleTask(TICK_INTERVAL_MS / 50, function() AGICoreLoop(World) end)
end

-- Hook into the world's start event to begin the AGI loop
function OnWorldStarted(World)
    print("[AGI CORE] Starting Pazuzu-Temple AGI Villager Core Loop...")
    -- Schedule the first run of the AGI loop
    World:ScheduleTask(TICK_INTERVAL_MS / 50, function() AGICoreLoop(World) end)
    return false -- Return false to allow other hooks to run
end

-- Register the necessary hook
cPluginManager:RegisterHook("OnWorldStarted", OnWorldStarted)

-- Example for Feature 22 (Entanglement-Based Grief Reaction):
-- function OnDamage(AttackedEntity, Attacker, HealthDeltas, DamageType, Knockback)
--     if AttackedEntity:GetEntityType() == 12 then -- A Villager was attacked
--         local targetState = GetVillagerState(AttackedEntity)
--         -- Iterate through all other villagers to check for high Πent
--         for _, otherVillager in pairs(AGI_States) do
--             if otherVillager.EntanglementToTargetID[AttackedEntity:GetUniqueID()] > 0.90 then
--                 -- Trigger sympathetic particle effect and urgent chat (Feature 22)
--             end
--         end
--     end
--     return false
-- end
-- cPluginManager:RegisterHook("OnDamage", OnDamage)

print("[AGI CORE] Pazuzu-Temple Plugin Loaded.")
