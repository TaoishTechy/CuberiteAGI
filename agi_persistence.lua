
Persist = Persist or {}
local function world_root(World) if World and World.GetDataPath then return World:GetDataPath() end return "world" end
local function path_for(World, id) return string.format("%s/agi/%s.json", world_root(World), tostring(id)) end
local function journal_dir(World) return string.format("%s/agi/journal", world_root(World)) end
local function ensure_dir(path)
  if cFile and cFile.CreateFolder then
    local parts = {}; for s in string.gmatch(path, "[^/]+") do table.insert(parts, s) end
    local acc=""; for i=1,#parts do acc = acc .. (i>1 and "/" or "") .. parts[i]; cFile:CreateFolder(acc) end
  end
end
local function atomic_write(path, data) local tmp=path..".tmp"; cFile:WriteWholeFile(tmp,data); cFile:DeleteFile(path); cFile:RenameFile(tmp,path) end
function Persist.save(s)
  if not cJson or not cFile then return false end
  local data = { id=s.id, goal=s.goal, subgoal_step=s.subgoal_step or 0, bio=s.bio, linguistics=s.linguistics,
                 trust=s.trust_map, dream_log=s.dream_log_buffer, genome=s.genome, metrics=s.metrics, ts=os.time() }
  local p = path_for(s.world_obj, s.id); ensure_dir(p:match("(.+)/[^/]+$") or "world/agi"); atomic_write(p, cJson:Serialize(data)); return true
end
function Persist.load(s)
  if not cJson or not cFile then return false end
  local p = path_for(s.world_obj, s.id); if not cFile:IsFile(p) then return false end
  local ok, data = pcall(function() return cJson:Parse(cFile:ReadWholeFile(p)) end); if not ok or not data then return false end
  s.goal, s.subgoal_step, s.bio, s.metrics = data.goal, data.subgoal_step, data.bio, (data.metrics or s.metrics or {})
  s.linguistics, s.trust_map, s.genome, s.dream_log_buffer = data.linguistics or {}, data.trust or {}, data.genome or {}, data.dream_log or {}
  if s.bio then for k,v in pairs(s.bio) do if type(v)=="number" then if v~=v then s.bio[k]=0 else s.bio[k]=math.max(0, math.min(1, v)) end end end end
  return true
end
function Persist.journal(s, tag)
  if not cJson or not cFile then return false end
  local dir=journal_dir(s.world_obj); ensure_dir(dir)
  local data = { id=s.id, goal=s.goal, subgoal_step=s.subgoal_step or 0, bio=s.bio, linguistics=s.linguistics, trust=s.trust_map,
                 dream_log=s.dream_log_buffer, genome=s.genome, metrics=s.metrics, ts=os.time(), tag=tag }
  atomic_write(string.format("%s/%s_%s_%d.json", dir, tostring(s.id), tostring(tag or "snap"), data.ts), cJson:Serialize(data)); return true
end
function Persist.rollback(s, expected_tag)
  local dir=journal_dir(s.world_obj); if not cFile or not cFile.IsFolder or not cFile:IsFolder(dir) then return false end
  local files=cFile:GetFilesInFolder(dir); local latest,ts=nil,-1
  for _,f in ipairs(files) do local id,tag,t=string.match(f,"^(%d+)_(%w+)_(%d+)%.json$"); t=tonumber(t or "-1")
    if id==tostring(s.id) and (not expected_tag or tag==expected_tag) and t>ts then latest,ts=f,t end end
  if not latest then return false end
  local ok,data=pcall(function() return cJson:Parse(cFile:ReadWholeFile(dir.."/"..latest)) end); if not ok or not data then return false end
  s.goal,s.subgoal_step,s.bio,s.metrics=data.goal,data.subgoal_step,data.bio,(data.metrics or s.metrics or {})
  s.linguistics,s.trust_map,s.genome,s.dream_log_buffer=data.linguistics or {},data.trust or {},data.genome or {},data.dream_log or {}
  return true
end
function Persist.delete(id) return true end
return Persist
