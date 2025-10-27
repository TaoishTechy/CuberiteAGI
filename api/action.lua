
-- api/action.lua — action scheduler & primitives (self-resolving paths)

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
local U = dofile(BASE .. "/utils.lua")

local Action = {}

local function mk_task(name)
  return { name = name or "task", subs = {}, created = U.now_ms() }
end

function Action.CreateTask(name) return mk_task(name) end
function Action.AddSubTask(task, step) table.insert(task.subs, step) end

local function exec_step(World, step, Player)
  local t = step.type
  if t == "BROADCAST_MESSAGE" then
    local msg = step.message or "[AGI] ..."
    if World and World.BroadcastChat then World:BroadcastChat(msg) end
  elseif t == "SET_WEATHER" then
    if World and World.SetWeather then World:SetWeather(step.weather or 0, step.duration or 200) end
  elseif t == "SPAWN_ENTITY" then
    if World and World.SpawnMob and step.pos then
      World:SpawnMob(step.pos.x, step.pos.y, step.pos.z, eMonsterType.llLightning)
    end
  elseif t == "SET_BLOCK" then
    if World and step.pos and step.id then
      World:SetBlock(step.pos.x, step.pos.y, step.pos.z, step.id, step.meta or 0)
    end
  end
end

function Action.ScheduleTask(World, task, priority)
  if not (World and task) then return false end
  local delay = 20
  if type(priority) == "number" then delay = math.max(1, 40 - math.floor(priority)) end
  U.after_ticks(World, delay, function()
    for _, step in ipairs(task.subs or {}) do
      local ok = pcall(exec_step, World, step, nil)
      if not ok then
        LOGWARNING("[AGIAPI] Step failed in task '"..(task.name or "?").."'")
      end
    end
  end)
  return true
end

function Action.ComposeStructure(schematic, origin, World)
  if not (World and schematic and origin) then return end
  for _, b in ipairs(schematic) do
    World:SetBlock(origin.x + b.dx, origin.y + b.dy, origin.z + b.dz, b.id, b.meta or 0)
  end
end

return Action
