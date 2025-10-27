
AGI = AGI or {}
AGI_States = AGI_States or {}

-- Simple random name generator (fantasy-ish)
local SYL1 = {"A", "Be", "Ca", "Da", "El", "Fa", "Ga", "Ha", "Io", "Ja", "Ka", "La", "Ma", "Na", "O", "Pa", "Qua", "Ra", "Sa", "Ta", "Ul", "Va", "Wa", "Xa", "Ya", "Za"}
local SYL2 = {"bar", "cor", "dan", "eth", "fin", "gor", "hal", "ion", "jor", "kas", "lin", "mor", "nas", "or", "per", "quil", "rin", "sil", "tor", "us", "var", "wen", "xis", "yor", "zen"}

function AGI.rand_name(seed)
  local a = SYL1[math.random(#SYL1)]
  local b = SYL2[math.random(#SYL2)]
  return a .. b
end

-- Pheromones & geometry (kept minimal)
local function chunk_key(pos) return string.format("%d:%d:%d", math.floor(pos.x/16), math.floor(pos.y/16), math.floor(pos.z/16)) end
AGI.PHER = AGI.PHER or {}
function AGI.emit_pheromone(World, pos, kind, amount)
  if type(amount) ~= "number" then amount = 0 end
  local key = chunk_key(pos or {x=0,y=0,z=0})
  local cell = AGI.PHER[key] or {oxytocin=0, stress=0}
  cell[kind] = math.max(0, (cell[kind] or 0) * 0.95 + amount)
  AGI.PHER[key] = cell
end
function AGI.sample_pheromone(World, pos)
  local cell = AGI.PHER[chunk_key(pos or {x=0,y=0,z=0})] or {oxytocin=0, stress=0}
  return cell.oxytocin or 0, cell.stress or 0
end
function AGI.pos(e) local p=e:GetPosition(); return {x=p.x,y=p.y,z=p.z} end
function AGI.near(pos, entity, r)
  local p = entity:GetPosition(); local dx=pos.x-p.x; local dy=pos.y-p.y; local dz=pos.z-p.z
  return (dx*dx+dy*dy+dz*dz) <= (r*r)
end

-- Find villager utils
local function is_villager_entity(e)
  local m = tolua.cast(e, "cMonster")
  if not m then return false end
  local V = cMonster:StringToMobType("villager")
  return (m:GetMobType() == V)
end

function AGI.find_villager_by_id(world, uid)
  local found = nil
  world:DoWithEntityByID(uid, function(e) if is_villager_entity(e) then found = e end return true end)
  return found
end

function AGI.find_villager_by_name(world, name)
  local found = nil
  world:ForEachEntity(function(e)
    local m = tolua.cast(e, "cMonster")
    if m and is_villager_entity(e) then
      if (m:GetCustomName() or ""):lower() == tostring(name or ""):lower() then
        found = e
      end
    end
  end)
  return found
end

return AGI
