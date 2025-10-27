
Biology = Biology or {}
local function clamp(x) if x ~= x then return 0 end return math.min(1, math.max(0, x or 0)) end
function Biology.init_state(s)
  s.metrics = s.metrics or { CI=0.5, PLV=0.85, purity=0.97, trust=0.2 }
  s.bio = s.bio or { dopamine=0.55, serotonin=0.55, oxytocin=0.50, cortisol=0.45,
                     arousal=0.50, fatigue=0.20, hunger=0.20, last_sleep=os.time(), attach="anxious" }
end
function Biology.tick_homeostasis(World, s, dt)
  Biology.init_state(s)
  local b = s.bio
  local function n() return (math.random() * 0.06 - 0.03) end
  b.dopamine  = clamp(b.dopamine  + 0.02*n())
  b.serotonin = clamp(b.serotonin + 0.02*n())
  b.oxytocin  = clamp(b.oxytocin  + 0.02*n())
  b.cortisol  = clamp(b.cortisol  + 0.03*n() + 0.005*(b.hunger or 0))
  b.hunger    = clamp(b.hunger + 0.002*(dt or 1))
  b.fatigue   = clamp(b.fatigue + 0.0015*(dt or 1))
  b.arousal   = clamp(0.6*(b.dopamine or 0) + 0.5*(b.cortisol or 0) - 0.4*(b.serotonin or 0) + 0.2*n())
end
function Biology.affect(World, s, d)
  Biology.init_state(s); local b=s.bio
  local function c(x) return math.min(1, math.max(0, x or 0)) end
  b.dopamine  = c(b.dopamine  + (d.rew or 0))
  b.serotonin = c(b.serotonin + (d.calm or 0))
  b.oxytocin  = c(b.oxytocin  + (d.bond or 0))
  b.cortisol  = c(b.cortisol  + (d.stress or 0))
  b.arousal   = c(0.6*(b.dopamine or 0) + 0.5*(b.cortisol or 0) - 0.4*(b.serotonin or 0))
end
function Biology.need_sleep(s) Biology.init_state(s); local b=s.bio; return (b.fatigue or 0)>0.75 or (b.hunger or 0)>0.80 end
return Biology
