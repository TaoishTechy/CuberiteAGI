
-- api/harmony.lua — ethical & coherence governor

local H = {}
local directive = "max(player_engagement)"
local constraints = { "min(block_griefing)" }

function H.SetDirective(text) directive = text or directive end
function H.SetConstraint(c) table.insert(constraints, c) end

-- Naive scoring: discourage destructive opcodes, encourage comms & visual events
local destructive = { SET_BLOCK=false, SPAWN_ENTITY=true, BROADCAST_MESSAGE=true, SET_WEATHER=true }

function H.EvaluateAction(action)
  if not action then return 0, "no action" end
  local score = 0.0
  local reason = {}

  local t = action.type or action.name or "unknown"
  if destructive[t] == false then score = score - 0.4; table.insert(reason, "Avoid griefing.") end
  if t == "BROADCAST_MESSAGE" then score = score + 0.2; table.insert(reason, "Engages players.") end
  if t == "ORCHESTRATE_EVENT" then score = score + 0.1; table.insert(reason, "Curated experience.") end
  if t == "SET_WEATHER" then score = score + 0.05 end

  -- clamp to [-1, 1]
  if score > 1 then score = 1 end
  if score < -1 then score = -1 end

  return score, table.concat(reason, " ")
end

return H
