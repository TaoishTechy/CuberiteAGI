--[[
AGI_PLANNER.LUA
Manages villager goals, subgoals, and narrative drives.
--]]

Planner = Planner or {}

local Dialogue = require("agi_dialogue") -- DEBUG FIX: Removed "PazuzuTemple/" prefix

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
        goal_weights.build_fractal = goal_weights.build_fractal + 10 -- Spatial is good for physical tasks
    elseif goal_bias == "temporal" then
        goal_weights.teach = goal_weights.teach + 10
        goal_weights.ritual_stage = goal_weights.ritual_stage + 10 -- Temporal is good for long-term/scheduled tasks
    end
    
    -- Feature 31: Add Panic goal if Cortisol is high (Stress response)
    if s.bio.cortisol > 0.8 then
        goal_weights.panic = goal_weights.panic + math.floor((s.bio.cortisol - 0.8) * 50)
    end
    
    -- Weighted random selection
    local total_weight = 0
    for _, goal in ipairs(ALL_GOALS) do
        local weight = goal_weights[goal] or 0
        if weight > 0 then
            table.insert(available_goals, {goal=goal, weight=weight})
            total_weight = total_weight + weight
        end
    end
    
    local target = math.random() * total_weight
    local cumulative = 0
    for _, item in ipairs(available_goals) do
        cumulative = cumulative + item.weight
        if target < cumulative then
            return item.goal
        end
    end
    
    return "idle" -- Fallback
end

-- Feature 4: Sub-goal execution logic (simple state machine)
function Planner.tick(World, s) -- FIX: Added World parameter
    s.id = s.id or s.world_obj:GetUniqueID() -- Ensure s.id is set
    
    -- Check if the current goal is finished
    if s.subgoal_step >= 5 then -- 5 steps completes a goal for simplicity
        s.goal = nil
        s.subgoal_step = 0
        -- Feature 1: Announce completion
        Dialogue.emote(World, s, string.format("...has completed the goal '%s'.", s.goal))
    end
    
    -- Select a new goal if none exists
    if not s.goal then
        -- Placeholder for H_arch and goal_bias, typically computed elsewhere
        local H_arch = 0.5 
        local goal_bias = "spatial" 
        s.goal = Planner.select(s, H_arch, goal_bias)
        Dialogue.emote(World, s, string.format("...adopts the new goal: '%s'.", s.goal))
        s.subgoal_step = 0
    end
    
    -- Execute the current step
    s.subgoal_step = s.subgoal_step + 1
    
    -- Feature 14: Sleep/Dream Check (Moved to main.lua tick loop for control)
    
    -- Feature 13: Semantic Taboo enforcement (prevents goal selection/chat if taboo)
    if s.linguistics and s.linguistics.taboo and s.linguistics.taboo[s.goal] then
        local taboo_time = s.linguistics.taboo[s.goal]
        if os.time() - taboo_time < 300 then -- 5-minute taboo
            s.goal = "idle" -- Enforce idle
            s.subgoal_step = 0
            Dialogue.emote(World, s, string.format("...is restricted by a Semantic Taboo on '%s'.", s.goal))
        else
            s.linguistics.taboo[s.goal] = nil -- Remove expired taboo
        end
    end

    -- F28: Execute the sub-goal action (This is where movement/block placement would happen)
    -- Placeholder:
    print(string.format("[PLANNER] Villager %s: Goal='%s', Step=%d", s.id, s.goal, s.subgoal_step))
    
    return s.goal, s.subgoal_step
end

-- Feature 14: Sleep/Dream Cycle Check
function Planner.sleep_and_dream(World, s)
    local hours_since_sleep = (os.time() - (s.bio.last_sleep or 0)) / 3600
    local fatigue_threshold = 0.8
    
    if s.bio.fatigue > fatigue_threshold and hours_since_sleep > 8 then
        s.goal = "sleep"
        s.subgoal_step = 0
        s.dream_log_buffer = s.dream_log_buffer or {}
        
        -- E6: Dream -> Log Buffer
        local dream = "A fractal spiral of pure logic. (Placeholder)" -- Replace with complex dream generation
        table.insert(s.dream_log_buffer, dream)
        
        Dialogue.emote(World, s, "...is initiated into the dream-state of the Polyhedral Nexus.")
        
        -- Reset sleep metrics after a 'cycle' of sleep
        s.bio.fatigue = 0.1 
        s.bio.last_sleep = os.time()
        s.bio.cortisol = 0.3 -- Reset stress
        s.goal = nil -- Immediately select new goal next tick
    end
end

-- Feature 13: Semantic Taboo injection
function Planner.taboo(s, taboo)
    if taboo and #taboo > 0 then
        s.world_obj = s.world_obj or s.world_obj -- Stubbed helper
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
                s.metrics = s.metrics or {purity=0.5} -- Low purity for panic
                s.metrics.purity = 0.5
                Dialogue.emote(World, s, "experiences a surge of global Entropic Anxiety.")
            end
        end
    end)
end
