-- agi_biology.lua
-- Contains the neurobiological state and homeostasis functions (F1-F4).

Biology = Biology or {}
AGI = AGI or {}

-- === STUBS for required external functions ===
-- This function is referenced in F2. Assumed to exist in agi_core_helpers.
function AGI.classify_attachment(trust_map)
  -- Placeholder stub: returns a style based on a simple check
  local trust_score = 0
  for _, score in pairs(trust_map) do trust_score = trust_score + score end
  if trust_score > 5 then return "secure"
  elseif trust_score > 0 then return "anxious"
  else return "avoidant"
  end
end
-- === END STUBS ===

-- Per-villager neurostate (dopamine/serotonin/oxytocin/cortisol), circadian, hunger
function Biology.init_state(s)
  s.bio = s.bio or {
    dopamine=0.55, serotonin=0.55, oxytocin=0.50, cortisol=0.45,
    arousal=0.50, fatigue=0.20, hunger=0.20, last_sleep=os.time(), attach="anxious"
  }
end

-- (F1) Homeostasis loop: drift + bounded correction toward setpoints
function Biology.tick_homeostasis(World, s, dt)
  Biology.init_state(s)
  local b = s.bio
  -- small noise generator
  local function n() return (math.random()*0.06-0.03) end
  
  -- Neuromodulator drift (bounded between 0 and 1)
  local function bound(x) return math.min(1, math.max(0, x)) end
  
  b.dopamine  = bound(b.dopamine  + 0.02*n())
  b.serotonin = bound(b.serotonin + 0.02*n())
  b.oxytocin  = bound(b.oxytocin  + 0.02*n())
  b.cortisol  = bound(b.cortisol  + 0.03*n() + 0.005*b.hunger) -- Hunger increases stress
  
  b.hunger    = bound(b.hunger + 0.002*dt)
  b.fatigue   = bound(b.fatigue + 0.0015*dt)

  -- arousal ~ dop+cor − ser
  b.arousal = bound(0.6*b.dopamine + 0.5*b.cortisol - 0.4*b.serotonin + 0.2*n())
end

-- (F2) Attachment plasticity: update attachment style from trust map (ties to AGI.classify_attachment)
function Biology.recompute_attachment(s, trust_map)
  local style = AGI.classify_attachment(trust_map or s.trust_map or {})
  Biology.init_state(s); s.bio.attach = style
  return style
end

-- (F3) Affective reward/punish (called on events: trade/help/hurt)
function Biology.affect(World, s, delta)
  Biology.init_state(s)
  local b = s.bio
  local function bound(x) return math.min(1, math.max(0, x)) end

  b.dopamine  = bound(b.dopamine  + (delta.rew or 0))
  b.serotonin = bound(b.serotonin + (delta.calm or 0))
  b.oxytocin  = bound(b.oxytocin  + (delta.bond or 0))
  b.cortisol  = bound(b.cortisol  + (delta.stress or 0))
  
  -- Recompute arousal immediately
  b.arousal = bound(0.6*b.dopamine + 0.5*b.cortisol - 0.4*b.serotonin)
end

-- (F4) Sleep pressure / dreamgate trigger
function Biology.need_sleep(s)
  Biology.init_state(s)
  return s.bio.fatigue > 0.75 or s.bio.hunger > 0.80
end
