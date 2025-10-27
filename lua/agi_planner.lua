--[[
AGI_PLANNER.LUA
Manages villager goals, subgoals, and narrative drives.
--]]

Planner = Planner or {}

local Dialogue = require("PazuzuTemple/agi_dialogue") -- Ensure Dialogue is available

local ALL_GOALS = {"build_shrine", "teach", "harvest", "trade", "build_fractal", "ritual_stage", "panic", "idle"}

-- Feature 1: Selects a new goal based on CI bias and H_arch
function Planner.select(s, H_arch, goal_bias)
    local available_goals = {}
    
    -- Weight goals based on H_arch (Feature 15, 12)
    -- FIX: AGI_CONST is not defined in this snippet, using a placeholder for ENTROPY_TARGET_LN5
    local ENTROPY_TARGET_LN5 = math.log(5) 
    local chaos_weight = H_arch / ENTROPY_TARGET_LN5
    
    -- Base goal list and weights
    local goal_weights = {
        build_shrine = 10,
        teach = 8,
        trade = 15,
        harvest = 10,
        build_fractal = math.floor(chaos_weight * 20), -- High chaos -> Fractal Synthesis
        ritual_stage = 5,
        idle = 5,
    }
    
    -- Feature 1: Apply Chiral Decision Drift bias
    if goal_bias == "spatial" then
        goal_weights.build_shrine = goal_weights.build_shrine + 10
        goal_weights.build_fractal = goal_weights.build_fractal + 10
    elseif goal_bias == "social" then
        goal_weights.teach = goal_weights.teach + 10
        goal_weights.trade = goal_weights.trade + 10
    end
    
    -- Simple selection for now
    local max_weight = 0
    local selected_goal = "idle"
    for goal, weight in pairs(goal_weights) do
        if weight > max_weight then
            max_weight = weight
            selected_goal = goal
        end
    end
    
    return selected_goal
end

-- Feature 14: Sleep/Dream Cycle Check
function Planner.sleep_and_dream(World, s)
    -- Stub for sleep/dream logic
    local b = s.bio or {}
    if b.fatigue and b.fatigue > 0.8 and not s.is_sleeping then
        s.is_sleeping = true
        -- Assuming Dialogue.emote is available
        Dialogue.emote(s.world_obj, s, "begins the Sleep Protocol.")
    elseif s.is_sleeping and b.fatigue and b.fatigue < 0.2 then
        s.is_sleeping = false
        Dialogue.emote(s.world_obj, s, "wakes up with a strange insight.")
        -- FIX: Now passing 'World' to the processing function
        Planner.process_dream_insight(World, s, "set_goal:build_fractal")
    end
end

-- Feature 7: Processes insight from the sleep/dream cycle
function Planner.process_dream_insight(World, s, insight) -- FIX: Added World parameter to resolve scope issue
    if insight:match("set_goal:(%w+)") then
        local new_goal = insight:match("set_goal:(%w+)")
        s.goal = new_goal -- Overwrite current goal with dream insight
        Dialogue.emote(s.world_obj, s, string.format("...receives an insight from the Void: %s", new_goal))
    
    elseif insight:match("set_taboo:(%w+)") then
        local taboo = insight:match("set_taboo:(%w+)")
        -- FIX: Directly manipulate the state table 's' instead of calling a broken helper
        s.linguistics = s.linguistics or {}
        s.linguistics.taboo = s.linguistics.taboo or {}
        s.linguistics.taboo[taboo] = os.time() -- Directly record the taboo in state
        Dialogue.emote(s.world_obj, s, string.format("...declares a Semantic Taboo against '%s'.", taboo))
    end
end

-- Feature 8: Sets a goal for a group (chorus) using Polyphonic Protocol
function Planner.group_goal(World, chorus, goal) -- FIX: Added World parameter
    for _, s in ipairs(chorus) do
        s.goal = goal
        s.subgoal_step = 0
        -- Feature 8: Send the specialized, invisible group command
        Dialogue.send_chorus_command(s.world_obj:GetWorld(), s, goal) 
    end
    print(string.format("[PLANNER] Set group goal to '%s' for %d villagers.", goal, #chorus))
end

-- Feature 30: Resonance Cascade Seeding (World Entropy Management)
function Planner.inject_negative_goal(World, pos, radius)
    World:ForEachEntity(function(entity)
        -- Cuberite Entity type for villager is 120, not 12
        if entity:GetEntityType() == 120 and AGI.near(pos, entity, radius) then
            local s = AGI_States[entity:GetUniqueID()] -- Assuming AGI_States is populated
            if s then
                s.goal = "panic"
                s.metrics = s.metrics or {purity=0.97, CI=0.80}
                s.metrics.purity = 0.01 -- Force low purity
                Dialogue.emote(entity, s, "is affected by a wave of primal dread.")
            end
        end
    end)
end
