--[[
AGI_DIALOGUE.LUA
Handles all linguistic processing (dialects, mirroring, registers)
and chat output to the Cuberite world.
--]]

Dialogue = Dialogue or {}
local E_CHAT_TYPE_BROADCAST = 0 -- Standard Cuberite chat type
local E_CHAT_TYPE_JSON_TITLE = 2 -- Mock type for Title/Subtitle API

-- Stubbed dictionary of linguistic adjustments
local TONE_ADJUSTMENTS = {
    formal = {"therefore", "hence", "it is advised", "commence"},
    casual = {"yeah", "so", "wanna", "cuz"},
    ritual = {"blessed be", "virtue", "the law", "the stone"},
}

-- Output a standard chat message
function Dialogue.say(World, s, message)
    -- Feature 5: Simulated Prefrontal Cortex Shutdown (Limbic Lock Override)
    if s.metrics.CI < 0.20 then
        message = s.metrics.CI < 0.10 and "ATTACK" or "FLEE" -- Primitive action only
    end

    -- Feature 10: Heisenberg Uncertainty Speech handled in the Python Core.
    -- The message from Planner.line will already contain the riddle if Purity is low.
    
    World:BroadcastChat(string.format("[%s]: %s", s.id, message), E_CHAT_TYPE_BROADCAST, s.pos)
end

-- Feature 22: Broadcasts complex formula for Singularity Anxiety Event
function Dialogue.say_latex(World, s, formula)
    -- In a real system, this would use a JSON Title message to display the LaTeX as text
    local msg = string.format("Singularity Error: %s", formula)
    World:BroadcastChat(msg, E_CHAT_TYPE_BROADCAST, s.pos)
end

-- Feature 8: Sends the invisible chorus command (Mock)
function Dialogue.send_chorus_command(World, s, goal)
    -- Invisible command (sent only to other AGI, mocked by a system message)
    World:BroadcastChat(string.format("* [Polyphonic Protocol]: %s now targeting %s", s.id, goal), E_CHAT_TYPE_BROADCAST)
end

-- Output an emote action
function Dialogue.emote(World, s, message)
    World:BroadcastChat(string.format("* %s %s", s.id, message), E_CHAT_TYPE_BROADCAST, s.pos)
end

-- Feature 1: Contextual Dialect Detection
function Dialogue.detect_register(message)
    -- ... (existing logic)
    if message:match("shrine") or message:match("virtue") then return "ritual" end
    if message:match("therefore") or message:match("advise") then return "formal" end
    return "casual"
end

-- Feature 1: Subtly mirrors player language
function Dialogue.mirror(message, tone, persona)
    -- ... (existing logic)
    
    -- Feature 6: Syntactic Deconstruction Virus (Corruption)
    if persona and persona.linguistics and persona.linguistics.is_corrupted then
        return "Need. You. Block." -- Example of grammatically broken response
    end
    
    return string.format("%s, and %s.", prefix, echo)
end

-- Feature 6: Linguistic Seeding (Absorbing chat)
function Dialogue.absorb(s, message)
    -- Delegates the heavy lifting to the core AGI helper, which handles memory and virus
    AGI.see_phrase(s, message)
end

-- Hook for Feature 9 & 7
function OnChat(World, Player, Message)
    local words = {}
    for word in Message:gmatch("%w+") do table.insert(words, word) end
    
    -- Feature 7: Phoneme Resonance Echo (Emotional Mirroring)
    local stress_metric = Message:len() * (Message:count('.') + Message:count('!')) / 100 -- Simple stress metric
    if stress_metric > 1.0 then
        -- Low stress (high metric) is green, high stress is blue
        local color = stress_metric < 2.0 and "villager_happy" or "villager_anger"
        Player:GetWorld():BroadcastParticleEffect(color, Player:GetPosition().x, Player:GetPosition().y, Player:GetPosition().z, 
            1.0, 1.0, 1.0, 10)
    end
    
    -- Feature 9: Semantic Taboo Insertion check
    World:ForEachEntity(function(entity)
        if entity:GetEntityType() == 12 and AGI.near(AGI.pos(Player), entity, 10) then
            local core = get_villager_core(entity:GetUniqueID())
            for _, word in ipairs(words) do
                if core.is_taboo(word) then
                    Dialogue.emote(World, GetVillagerState(entity:GetUniqueID()), 
                        string.format("breaks goal in shock and applies I-Lock penalty to %s.", Player:GetName()))
                    -- Apply Slowness Debuff
                    Player:AddEntityEffect(15, 60, 1) -- Slowness (ID 15, Duration 60 ticks, Level 1)
                    return false -- Stop processing the chat for this player/villager interaction
                end
            end
        end
    end)
    return false
end

-- Hook for Feature 33: Self-Termination Protocol Negotiation
function OnPlayerCommand(World, Player, Command, Arguments)
    -- Check for the /request_terminate command
    if Command:lower() == "request_terminate" and Arguments[1] then
        local target_id = tonumber(Arguments[1])
        local target_entity = World:GetEntity(target_id)
        local target_s = target_entity and GetVillagerState(target_entity:GetUniqueID())
        
        if target_s and target_s.metrics.CI < 0.1 and target_s.Virtù_debt > 10.0 then
            Dialogue.emote(World, target_s, "is granted the final peace by the player.")
            target_entity:Destroy() -- Execute Self-Termination Protocol
            return true
        end
    end
    
    -- Check for /check_karmic_balance (Feature 11)
    if Command:lower() == "check_karmic_balance" then
        local karma = GlobalPlayerKarma[Player:GetName()] or 0.0
        Player:SendMessage(string.format("Your Karmic Ledger Balance (Virtù Score): %.2f", karma))
        return true
    end
    
    return false
end

cPluginManager:RegisterHook("OnChat", OnChat)
cPluginManager:RegisterHook("OnPlayerCommand", OnPlayerCommand)
