
Evolution = Evolution or {}
local Sandbox = require("agi_sandbox")
local Persist = Persist or {}
local Planner = Planner or {}
local Dialogue = Dialogue or {}

function Evolution.codegen_from_dream(s)
  if not (s.dream_log_buffer and s.dream_log_buffer.code) then return false end
  local code = s.dream_log_buffer.code
  local ok, res = Sandbox.safe_eval(code, s, { SandboxMaxBytes = 65536, SandboxMaxStringRep = 2048 })
  if not ok then return false, res end
  s.genome = s.genome or {}; s.genome.dream_gene = code; return true
end

function Evolution.reflective_guard(World, s, before)
  local after = s.metrics or {}
  local cfg = AGI_CONFIG or { GUARD_PLV_DECAY=0.95, GUARD_PURITY_DECAY=0.90, ETHICS_VIRTU_MIN=0.05, GUARD_VIRTU_DECAY=0.85 }
  local ok, msgs = true, {}
  local function decr(k, d) return (after[k] or 0) < (before[k] or 0) * (d or 1) end
  if decr("PLV", cfg.GUARD_PLV_DECAY) then ok=false; msgs[#msgs+1]="PLV drop" end
  if decr("purity", cfg.GUARD_PURITY_DECAY) then ok=false; msgs[#msgs+1]="Purity drop" end
  local vn = (after.purity or 0) - (after.PLV or 0); local vb = (before.purity or 0) - (before.PLV or 0)
  if vn < cfg.ETHICS_VIRTU_MIN or vn < vb * (cfg.GUARD_VIRTU_DECAY or 1) then ok=false; msgs[#msgs+1]="Virtu debt" end
  if not ok then Persist.rollback(s, "pre_mut"); if Dialogue and Dialogue.emote then Dialogue.emote(World, s, "reverts a harmful mutation.") end
    if Planner and Planner.set_goal then Planner.set_goal(s, "panic") end; return false, table.concat(msgs,", ") end
  return true, "OK"
end

function Evolution.mutate(s)
  s.genome=s.genome or {}; s.genome.mut=(s.genome.mut or 0)+(math.random()*0.02-0.01)
  s.metrics=s.metrics or {}; s.metrics.PLV=(s.metrics.PLV or 0.85)*(0.995+math.random()*0.01)
end

function Evolution.online_epoch(World, pop_ids)
  LOGINFO(string.format("[AGI] Online epoch over %d villagers", #pop_ids))
end

return Evolution
