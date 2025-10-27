--[[\
AGI_DIALOGUE.LUA
Handles all linguistic processing (dialects, mirroring, registers)
and chat output to the Cuberite world.
--]]

Dialogue = Dialogue or {}
AGI_States = AGI_States or {} -- Global state table
local E_CHAT_TYPE_BROADCAST = 0 -- Standard Cuberite chat type
local E_CHAT_TYPE_JSON_TITLE = 2 -- Mock type for Title/Subtitle API

-- Load dependencies (Standardized require paths)
local Biology = require("agi_biology")
local CoreHelpers = require("agi_core_helpers")
local VillagerCore = require("agi_villager_core")
local Planner = require("agi_planner")

-- Global table to track player karma (Feature 11: Virtù Ledger)
GlobalPlayerKarma = GlobalPlayerKarma or {}

-- Stubbed dictionary of linguistic adjustments
local TONE_ADJUSTMENTS = {
    formal = {"therefore", "hence", "it is advised", "commence"},
    casual = {"yeah", "so", "wanna", "cuz"},
    ritual = {"blessed be", "virtue", "the law", "the stone"},
}

-- Utility to get a villager's state from its entity or UID
local function GetVillagerState(uid_or_entity)
    local uid = type(uid_or_entity) == "string" and uid_or_entity or uid_or_entity:GetUniqueID()
    return AGI_States[uid]
end

-- Output a standard chat message
function Dialogue.say(World, s, message)
    -- Feature 5: Simulated Prefrontal Cortex Shutdown (Limbic Lock Override)
    if s.metrics and s.metrics.CI < 0.20 then
        message = s.metrics.CI < 0.10 and "ATTACK" or "FLEE" -- Primitive action only
    end

    -- Feature 10: Heisenberg Uncertainty Speech handled in the Python Core.
    
    World:BroadcastChat(string.format("[%s]: %s", s.id, message), E_CHAT_TYPE_BROADCAST, s.pos)
end

-- Feature 22: Broadcasts complex formula for Singularity Anxiety Event
function Dialogue.say_latex(World, s, formula)
    -- In a real system, this would use a JSON Title message to display the LaTeX as text
    local msg = string.format("[Singularity Anxiety] %s: $$\\psi_{CI}=\\frac{\\partial^2\\Omega}{\\partial t^2}$$", s.id)
    World:BroadcastChat(msg, E_CHAT_TYPE_JSON_TITLE) -- Mock Title/Subtitle API usage
end

-- Emote: Villagers communicate internal state
function Dialogue.emote(World, s, action)
    World:BroadcastChat(string.format("* %s %s", s.id, action), E_CHAT_TYPE_BROADCAST)
end

-- Feature 8: Send specialized, invisible group command (Polyphonic Protocol)
function Dialogue.send_chorus_command(World, s, command)
    -- Invisible command, using a private chat channel or logging
    print(string.format("[POLYPHONIC] Villager %s received goal: %s", s.id, command))
end


-- Feature 21: The Entropic Burden (Player chat interaction hook)
function Dialogue.on_chat(World, Player, Message)
    -- Ignore self-chat or system messages
    if Player:GetName() == "Server" then return false end
    
    local chat_pos = Player:GetPosition()
    local player_name = Player:GetName()
    
    -- Feature 11: Update global player karma (Virtù Ledger) - affects Villager Trust
    GlobalPlayerKarma[player_name] = (GlobalPlayerKarma[player_name] or 0.0) + (math.random() - 0.5) * 0.1
    
    -- Iterate over all villagers to check for interaction proximity
    World:ForEachEntity(function(entity)
        if entity:GetEntityType() == 120 and CoreHelpers.near(chat_pos, entity, 15.0) then -- Villager and nearby
            local villager_s = GetVillagerState(entity:GetUniqueID())
            
            if villager_s then
                -- Feature 21: Check for Semantic Taboo violation
                local violated = false
                if villager_s.linguistics and villager_s.linguistics.taboo then
                    for taboo_word in pairs(villager_s.linguistics.taboo) do
                        if Message:lower():find(taboo_word) then
                            violated = true
                            break
                        end
                    end
                end

                if violated then
                    Dialogue.emote(World, villager_s, "shivers, displaying signs of Entropic Burden.")
                    
                    -- F3: Affective punishment (reduce Dopamine/Serotonin slightly)
                    Biology.affect(World, villager_s, -0.1)
                    
                    -- Feature 21: Apply Slowness Debuff
                    Player:AddEntityEffect(15, 60, 1) -- Slowness (ID 15, Duration 60 ticks, Level 1)
                    return false -- Stop processing the chat for this player/villager interaction
                end
            end
        end
    end)
    return false
end
cPluginManager:RegisterHook("OnPlayerChat", Dialogue.on_chat)


-- Hook for Feature 33: Self-Termination Protocol Negotiation
function OnPlayerCommand(World, Player, Command, Arguments)
    -- Check for the /request_terminate command
    if Command:lower() == "request_terminate" and Arguments[1] then
        local target_id = tonumber(Arguments[1])
        local target_entity = World:GetEntity(target_id)
        local target_s = target_entity and GetVillagerState(target_entity) -- Pass entity to utility
        
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
cPluginManager:RegisterHook("OnPlayerCommand", OnPlayerCommand)
