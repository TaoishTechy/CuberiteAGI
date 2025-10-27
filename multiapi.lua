
-- multiapi.lua (included with AGIAPI hotfix) — trimmed header; full content from previous bundle expected.
-- If you already have multiapi.lua in the plugin folder, this file is identical in interface.
local MultiAPI = {}
local PI = math.pi
local function clamp(x,a,b) if x~=x then return a end if x<a then return a elseif x>b then return b else return x end end
local function now() return os.time() end
local function try(fn, ...) local ok, r = pcall(fn, ...) if ok then return true, r else return false, r end end

function MultiAPI.sense_time(W)
  if not W or not W.GetTimeOfDay then return {ok=false, err="no world"} end
  local tod = W:GetTimeOfDay(); local age = W:GetWorldAge() or 0
  return {ok=true, time_of_day=tod, world_age=age, circadian=(tod%24000)/24000.0}
end
function MultiAPI.portal_transfer(Player, TargetWorld, pos)
  if not (Player and TargetWorld and TargetWorld.GetName) then return false end
  local ok = try(function() Player:MoveToWorld(TargetWorld:GetName(), true, {x=pos.x, y=pos.y, z=pos.z}) end)
  return ok and true or false
end
function MultiAPI.mood_estimate(s)
  local d=(s.bio and s.bio.dopamine) or 0.5; local c=(s.bio and s.bio.cortisol) or 0.5; local a=(s.bio and s.bio.arousal) or 0.5
  local val = d - 0.5*c + 0.2*a; local label="neutral"
  if val>0.25 then label="joyful" elseif val<-0.25 then label="anxious" end
  return {score=val,label=label,color=(label=="joyful" and "gold") or (label=="anxious" and "crimson") or "lightgray"}
end
function MultiAPI.holographic_project(s)
  return { id=s.id, name=s.name, goal=s.goal, metrics=s.metrics or {}, bio=s.bio or {}, ts=now(), mood=MultiAPI.mood_estimate(s) }
end
return MultiAPI
