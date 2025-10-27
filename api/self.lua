
-- api/self.lua — recursive self model

local S = {}
local metrics = { actions=0, harmony_acc=0, last_score=0, last_reason="" }

function S.GetPerformanceMetrics()
  local avg = (metrics.actions > 0) and (metrics.harmony_acc / metrics.actions) or 0
  return { actions = metrics.actions, mean_harmony = avg, last_score = metrics.last_score, last_reason = metrics.last_reason }
end

function S.UpdateBehaviorModel(newParams)
  -- placeholder: store values for external use
  S._params = S._params or {}
  for k,v in pairs(newParams or {}) do S._params[k] = v end
  return true
end

function S.LogStateTransition(prev, action, nxt)
  metrics.actions = metrics.actions + 1
  if action and action._harmony_score then
    metrics.harmony_acc = metrics.harmony_acc + action._harmony_score
    metrics.last_score = action._harmony_score
    metrics.last_reason = action._harmony_reason or ""
  end
end

return S
