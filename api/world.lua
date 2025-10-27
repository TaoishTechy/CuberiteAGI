
-- api/world.lua — semantic world model (self-resolving paths)

local function __base_dir()
  if debug and debug.getinfo then
    local src = debug.getinfo(1, "S").source or ""
    local p = src:match("^@(.+)$") or src
    local d = p:match("^(.*)/[^/]+$")
    if d then return d end
  end
  return "."
end

local BASE = __base_dir()
local Utils = dofile(BASE .. "/utils.lua")

local WorldAPI = {}

--- Get entities near a position with an optional filter
-- @param pos table {x,y,z}
-- @param radius number
-- @param filter fun(e:cEntity):boolean (optional)
function WorldAPI.GetEntitiesInRadius(pos, radius, filter)
  local out = {}
  cRoot:Get():ForEachWorld(function(W)
    local minx, maxx = pos.x - radius, pos.x + radius
    local miny, maxy = pos.y - radius, pos.y + radius
    local minz, maxz = pos.z - radius, pos.z + radius
    W:ForEachEntityInBox(minx, miny, minz, maxx, maxy, maxz,
      function(e)
        if (not filter) or filter(e) then table.insert(out, e:GetUniqueID()) end
      end)
  end)
  return out
end

--- Returns a minimal block state (ID/meta) at a position in the player's world
function WorldAPI.GetBlockState(World, x, y, z)
  if not World then return nil end
  local bid, meta = World:GetBlock(x, y, z)
  return { id = bid, meta = meta }
end

--- Player state wrapper (selected metrics)
function WorldAPI.GetPlayerState(Player)
  if not Player then return nil end
  return {
    name = Player:GetName(),
    uuid = Player:GetUUID(),
    pos = { x=Player:GetPosX(), y=Player:GetPosY(), z=Player:GetPosZ() },
    health = Player:GetHealth(),
    food = Player:GetFoodLevel(),
    saturation = Player:GetFoodSaturationLevel(),
  }
end

--- Subscribe to an event: thin wrapper around cPluginManager:AddHook
function WorldAPI.SubscribeToEvent(hookType, callback)
  if not (cPluginManager and cPluginManager.AddHook) then return false end
  return cPluginManager:AddHook(hookType, callback)
end

--- Sense time/environment of a world
function WorldAPI.SenseTime(World)
  if not World then return nil end
  local tod = World:GetTimeOfDay()
  local age = World:GetWorldAge()
  return { time_of_day = tod, world_age = age, circadian = (tod % 24000) / 24000.0 }
end

return WorldAPI
