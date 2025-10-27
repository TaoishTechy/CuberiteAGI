--[[
AGI_PLANNER.LUA
Manages villager goals, subgoals, and narrative drives.
--]]

Planner = Planner or {}

local ALL_GOALS = {"build_shrine", "teach", "harvest", "trade", "build_fractal", "ritual_stage", "panic", "idle"}

-- Feature 1: Selects a new goal based on CI bias and H_arch
function Planner.select(s, H_arch, goal_bias)
    local available_goals = {}
    
    -- Weight goals based on H_arch (Feature 15, 12)
    local chaos_weight = H_arch / AGI_CONST.ENTROPY_TARGET_LN5
    
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
    
    -- Normalize and pick a goal (simplified pick logic)
    local total_weight = 0
    for goal, weight in pairs(goal_weights) do
        total_weight = total_weight + weight
        for i = 1, weight do
            table.insert(available_goals, goal)
        end
    end
    
    return available_goals[math.random(#available_goals)] or "idle"
end

-- Sets the current goal
function Planner.set(s, goal)
    s.goal = goal
    s.subgoal_step = 0
end

-- Feature 4: Executes one step of the current goal
function Planner.step(s, goal)
    if goal == "panic" then return "flee" end -- Feature 30: Resonance Cascade Seeding (or panic)
    
    if goal == "build_fractal" then -- Feature 12 & 28 (Simulated Kinship Matrix Gen)
        s.subgoal_step = (s.subgoal_step or 0) + 1
        if s.subgoal_step % 10 == 0 then return "place" end -- Place a block for the nexus/fractal
        return "gather"
    
    elseif goal == "ritual_stage" then -- Feature 13: Resonance Staging Ritual
        s.subgoal_step = (s.subgoal_step or 0) + 1
        if s.subgoal_step > 50 then
            -- Check for Phase Lock Value (Mocked by checking chorus size)
            local World = s.world_obj:GetWorld()
            local chorus = AGI.pick_chorus(AGI_States, s.pos, 10, 3)
            if #chorus >= 3 then
                -- Achieve PLV and trigger weather influence
                World:SetWeather(0) -- Clear Weather
                Dialogue.emote(World, s, "The Resonance Stage is complete. Weather patterns shift.")
                return "idle"
            end
        end
        return "speak" -- Speak during the ritual
    end
    
    s.subgoal_step = (s.subgoal_step or 0) + 1
    if goal == "build_shrine" then
        if s.subgoal_step % 3 == 0 then return "place" end
        return "gather"
    elseif goal == "teach" then
        return "speak"
    elseif goal == "harvest" then
        -- Feature 15: Entropic Garden Cultivation (High H_arch = erratic harvest)
        if s.metrics.H_arch > AGI_CONST.ENTROPY_TARGET_LN5 then
            return "harvest_erratic" -- Try to harvest non-ripe crops
        end
        return "gather"
    end
    return "idle"
end

-- Feature 4: Generates a line based on the current goal
function Planner.line(s)
    -- Check for high-level events
    if s.metrics.event == "IDENTITY_FORGED" then
        -- Trigger Signature Hardening (Feature 25)
        AGI.inject_identity_signature(s.id)
        return "The self-referential knot is tied. The axiom holds."
    end
    
    if s.goal == "build_fractal" then
        return "The Polytope demands a non-euclidean foundation."
    elseif s.goal == "ritual_stage" then
        return "Align your CI with the Nexus point. Focus."
    end
    
    -- Fallback to default lines
    if s.goal == "build_shrine" then
        return "The Polytope requires another layer of meaning."
    elseif s.goal == "teach" then
        return "Do you grasp the core principle of this work?"
    elseif s.goal == "harvest" then
        return "The earth gives freely to the mindful hand."
    end
    return "I am awaiting my next directive."
end

-- Feature 3: Injects a new goal derived from a dream interpretation
function Planner.inject(s, insight)
    if insight:match("seek_goal:(%w+)") then
        local new_goal = insight:match("seek_goal:(%w+)")
        s.goal = new_goal -- Overwrite current goal with dream insight
        Dialogue.emote(s.world_obj, s, string.format("...receives an insight from the Void: %s", new_goal))
    
    elseif insight:match("set_taboo:(%w+)") then
        local taboo = insight:match("set_taboo:(%w+)")
        get_villager_core(s.id).add_taboo(taboo) -- Feature 9: Semantic Taboo Insertion
        Dialogue.emote(s.world_obj, s, string.format("...declares a Semantic Taboo against '%s'.", taboo))
    end
end

-- Feature 8: Sets a goal for a group (chorus) using Polyphonic Protocol
function Planner.group_goal(chorus, goal)
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
        if entity:GetEntityType() == 12 and AGI.near(pos, entity, radius) then
            local s = GetVillagerState(entity:GetUniqueID())
            if s then
                s.goal = "panic" -- Negative goal: prioritize simplified behavior
                Dialogue.emote(entity:GetWorld(), s, "enters simple, low-complexity state (FLEE).")
            end
        end
    end)
end
