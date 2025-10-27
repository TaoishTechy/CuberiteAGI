
-- api/utils.lua
local M = {}

function M.clamp(x, a, b) if x~=x then return a end if x<a then return a elseif x>b then return b else return x end end
function M.now_ms() return math.floor((cRoot:Get():GetTime() or os.time()) * 1000) end

-- Safe world scheduling
function M.after_ticks(World, ticks, fn)
  if not (World and fn) then return end
  local d = math.max(1, math.floor(ticks))
  World:ScheduleTask(d, fn)
end

-- Safe DoWithEntityByID
function M.with_entity(World, id, fn)
  if not (World and id and fn) then return false end
  local ok = World:DoWithEntityByID(id, function(e) fn(e); return true end)
  return ok and true or false
end

-- Meter to 0..1
function M.norm(x, lo, hi)
  if not x then return 0 end
  if hi == lo then return 0 end
  return (x - lo) / (hi - lo)
end

return M
