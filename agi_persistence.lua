
-- agi_persistence.lua — Memory Crystal Persistence (v2.0)
-- High-integrity, write-optimized persistence with:
--   • Memory Crystal files (append-only frames with checksums)
--   • Atomic snapshot JSON (minified) for fast cold loads
--   • Per-entity locks + write-behind queue
--   • Delta journaling (only changed fields)
--   • Lightweight Fletcher-32 checksums (no external deps)
--   • Schema versioning + migration hooks
--   • Directory creation cache (no repeated syscalls)
-- Designed to be drop-in compatible with earlier Persist API:
--   Persist.save(s), Persist.load(s), Persist.journal(s, tag), Persist.rollback(s, tag)

Persist = Persist or {}

--////////////// Config ////////////////////////////////////////////////////////

local CFG = {
  SCHEMA_VERSION          = 2,        -- bump when structure changes
  SNAPSHOT_DIR_NAME       = "agi",    -- snapshots + indexes
  JOURNAL_DIR_NAME        = "agi/journal",
  CRYSTAL_DIR_NAME        = "agi/crystals",
  QUEUE_FLUSH_PERIOD_TICKS= 20,       -- (~1s @ 20 TPS); tune in config if needed
  MAX_QUEUE_BATCH         = 16,       -- max writes per flush
  ENABLE_CRYSTAL          = true,     -- append frames for forensic history
  ENABLE_MINIFY_JSON      = true,     -- strip whitespace from JSON
  ENABLE_DELTA_JOURNAL    = true,     -- write delta frames to journal
  MAX_LRU                 = 128,      -- keep up to N recent states in RAM
}

--////////////// Utilities /////////////////////////////////////////////////////

local function world_root(World)
  if World and World.GetDataPath then return World:GetDataPath() end
  return "world"
end

local function join(...)
  local parts, out = {...}, {}
  for _,p in ipairs(parts) do
    if p and p ~= "" then
      p = tostring(p)
      p = p:gsub("[/\\]+", "/")
      table.insert(out, p:gsub("^/+",""):gsub("/+$",""))
    end
  end
  return table.concat(out, "/")
end

local _dir_cache = {}
local function ensure_dir(path)
  if not cFile or not cFile.CreateFolder or not path or path == "" then return end
  if _dir_cache[path] then return end
  local acc = ""
  for seg in path:gmatch("[^/]+") do
    acc = (acc == "") and seg or (acc .. "/" .. seg)
    if not _dir_cache[acc] then cFile:CreateFolder(acc); _dir_cache[acc] = true end
  end
end

local function path_for(World, id)
  return join(world_root(World), CFG.SNAPSHOT_DIR_NAME, tostring(id) .. ".json")
end

local function journal_dir(World)
  return join(world_root(World), CFG.JOURNAL_DIR_NAME)
end

local function crystal_path(World, id)
  return join(world_root(World), CFG.CRYSTAL_DIR_NAME, tostring(id) .. ".crystal")
end

local function atomic_write(path, data)
  local tmp = path .. ".tmp"
  cFile:WriteWholeFile(tmp, data)
  cFile:DeleteFile(path)
  cFile:RenameFile(tmp, path)
end

-- Lightweight Fletcher-32 checksum (no external libs)
local function fletcher32(s)
  local sum1, sum2 = 0xffff, 0xffff
  local i, len = 1, #s
  while len > 0 do
    local tlen = math.min(len, 360)
    len = len - tlen
    for j = 0, tlen - 1 do
      sum1 = (sum1 + s:byte(i + j)) % 0xffff
      sum2 = (sum2 + sum1) % 0xffff
    end
    i = i + tlen
  end
  return string.format("%04x%04x", sum2, sum1)
end

local function minify_json_str(str)
  if not CFG.ENABLE_MINIFY_JSON then return str end
  -- remove insignificant whitespace after punctuation and around braces/brackets/colons/commas
  -- NOTE: keeps content inside quotes intact by a simple state machine
  local out, in_q, esc = {}, false, false
  for i = 1, #str do
    local ch = str:sub(i,i)
    if in_q then
      table.insert(out, ch)
      if esc then esc = false
      elseif ch == "\\" then esc = true
      elseif ch == "\"" then in_q = false end
    else
      if ch == '"' then in_q = true; table.insert(out, ch)
      elseif ch:match("%s") then
        local prev = out[#out] or ""
        local nxt = str:sub(i+1,i+1)
        -- keep a single space between two alphanumerics; otherwise drop
        if (prev:match("[%w_%]\}\"\']") and nxt:match("[%w_%[%{\"']")) then
          table.insert(out, " ")
        end
      else
        table.insert(out, ch)
      end
    end
  end
  return table.concat(out)
end

--////////////// LRU Cache /////////////////////////////////////////////////////

local _lru = { order = {}, map = {} }  -- id -> {json=..., ts=...}
local function lru_touch(id, entry)
  local m, o = _lru.map, _lru.order
  if m[id] then
    -- move to end
    for i, v in ipairs(o) do if v == id then table.remove(o, i) break end end
  end
  m[id] = entry
  table.insert(o, id)
  while #o > CFG.MAX_LRU do
    local ev = table.remove(o, 1)
    m[ev] = nil
  end
end

local function lru_get(id) return _lru.map[id] end

--////////////// Delta Computation /////////////////////////////////////////////

local function shallow_diff(old_tbl, new_tbl)
  local d = {}
  local changed = false
  local function copy_k(k, v) d[k] = v; changed = true end
  -- Added / changed
  for k, v in pairs(new_tbl or {}) do
    if type(v) ~= "table" then
      if not old_tbl or old_tbl[k] ~= v then copy_k(k, v) end
    end
  end
  -- Removed
  for k, _ in pairs(old_tbl or {}) do
    if (new_tbl or {})[k] == nil then d["__rm__:" .. k] = true; changed = true end
  end
  return changed and d or nil
end

--////////////// Frame Encoding (Memory Crystal) ///////////////////////////////

-- A "crystal" is an append-only log of frames:
--  [len]\t[type]\t[checksum]\t[timestamp]\t[payload]\n
-- Where:
--   type: "SNAP" (full snapshot) or "DELT" (delta) or "JTAG[tag]"
--   checksum: fletcher32(payload)
--   payload: JSON (minified), schema_version included
-- Consumers can rebuild current state by taking the last SNAP and applying following DELT frames.

local function write_crystal_frame(World, id, ftype, payload_tbl)
  if not CFG.ENABLE_CRYSTAL then return true end
  if not cFile then return false end
  local path = crystal_path(World, id)
  ensure_dir((path:match("(.+)/[^/]+$")) or "")
  payload_tbl.schema_version = CFG.SCHEMA_VERSION
  local json = cJson and cJson:Serialize(payload_tbl) or "{}"
  json = minify_json_str(json)
  local ck = fletcher32(json)
  local line = table.concat({ tostring(#json), ftype, ck, tostring(os.time()), json }, "\t") .. "\n"
  -- Append by read+concat+write (Cuberite lacks atomic append in Lua API). Efficient enough for small frames.
  local old = ""
  if cFile:IsFile(path) then old = cFile:ReadWholeFile(path) end
  atomic_write(path, old .. line)
  return true
end

--////////////// Locks + Write Queue ///////////////////////////////////////////

local _locks = {}          -- per-id lock flag
local _queue = {}          -- list of { op="save"|"journal", id=..., path=..., data=..., world=..., tag=... }

local function lock_id(id)
  if _locks[id] then return false end
  _locks[id] = true
  return true
end
local function unlock_id(id) _locks[id] = nil end

local function enqueue(op) _queue[#_queue + 1] = op end

local function flush_once()
  local n = 0
  for i = 1, math.min(#_queue, CFG.MAX_QUEUE_BATCH) do
    local job = table.remove(_queue, 1)
    if job then
      if job.op == "save" then
        atomic_write(job.path, job.data)
        n = n + 1
      elseif job.op == "journal" then
        atomic_write(job.path, job.data)
        n = n + 1
      end
    end
  end
  return n
end

-- starts a periodic flusher; safe to call multiple times
function Persist.start_flusher(Plugin)
  if Persist._flusher_started then return end
  Persist._flusher_started = true
  local ticks = CFG.QUEUE_FLUSH_PERIOD_TICKS
  cRoot:Get():GetDefaultWorld():ScheduleTask(ticks / 20, function()
    pcall(function() flush_once() end)
    Persist.start_flusher(Plugin) -- re-arm
  end)
end

--////////////// Schema + Migrations ///////////////////////////////////////////

local function normalize_bio(bio)
  if not bio then return nil end
  for k,v in pairs(bio) do
    if type(v) == "number" then
      if v ~= v then bio[k] = 0
      else bio[k] = math.max(0, math.min(1, v)) end
    end
  end
  return bio
end

local function make_snapshot_table(s)
  return {
    id = s.id,
    name = s.name,
    goal = s.goal,
    subgoal_step = s.subgoal_step or 0,
    bio = normalize_bio(s.bio),
    linguistics = s.linguistics,
    trust = s.trust_map,
    dream_log = s.dream_log_buffer,
    genome = s.genome,
    metrics = s.metrics,
    ts = os.time(),
    schema_version = CFG.SCHEMA_VERSION,
  }
end

local function migrate_if_needed(tbl)
  local v = tbl.schema_version or 1
  if v == CFG.SCHEMA_VERSION then return tbl end
  -- Example migration path; expand as schema evolves
  if v < 2 then
    tbl.schema_version = 2
    tbl.metrics = tbl.metrics or {}
    tbl.metrics.trust = tbl.metrics.trust or (tbl.trust and tbl.trust.mean) or 0.2
  end
  return tbl
end

--////////////// Public API /////////////////////////////////////////////////////

function Persist.save(s)
  if not cJson or not cFile then return false end
  local id, W = s.id, s.world_obj
  if not id or not W then return false end
  if not lock_id(id) then return false end
  local ok = true
  pcall(function()
    local snap = make_snapshot_table(s)
    local json = cJson:Serialize(snap)
    json = minify_json_str(json)
    local p = path_for(W, id)
    ensure_dir(p:match("(.+)/[^/]+$") or join(world_root(W), CFG.SNAPSHOT_DIR_NAME))
    -- LRU compare to avoid redundant writes
    local last = lru_get(id)
    if not last or last.json ~= json then
      enqueue({ op="save", id=id, path=p, data=json })
      lru_touch(id, { json=json, ts=snap.ts })
      -- write crystal frame (SNAP) for full state
      write_crystal_frame(W, id, "SNAP", snap)
    end
  end, function() ok = false end)
  unlock_id(id)
  return ok
end

function Persist.load(s)
  if not cJson or not cFile then return false end
  local id, W = s.id, s.world_obj
  if not id or not W then return false end
  local p = path_for(W, id)
  if not cFile:IsFile(p) then return false end
  local ok, data = pcall(function() return cJson:Parse(cFile:ReadWholeFile(p)) end)
  if not ok or not data then return false end
  data = migrate_if_needed(data)
  s.goal, s.subgoal_step, s.bio, s.metrics = data.goal, data.subgoal_step, normalize_bio(data.bio), (data.metrics or s.metrics or {})
  s.linguistics, s.trust_map, s.genome, s.dream_log_buffer = data.linguistics or {}, data.trust or {}, data.genome or {}, data.dream_log or {}
  lru_touch(id, { json = minify_json_str(cJson:Serialize(data)), ts = data.ts or os.time() })
  return true
end

function Persist.journal(s, tag)
  if not cJson or not cFile then return false end
  local id, W = s.id, s.world_obj
  if not id or not W then return false end
  local dir = journal_dir(W)
  ensure_dir(dir)

  local snap = make_snapshot_table(s)
  local payload = cJson:Serialize(snap)
  payload = minify_json_str(payload)

  -- Write delta frame if enabled and previous cached entry exists
  if CFG.ENABLE_DELTA_JOURNAL then
    local last = lru_get(id)
    local last_tbl = nil
    if last and last.json then
      local ok_prev, parsed_prev = pcall(function() return cJson:Parse(last.json) end)
      if ok_prev then last_tbl = parsed_prev end
    end
    local change = shallow_diff(last_tbl, snap)
    if change then
      local jpath = join(dir, string.format("%s_%s_%d.delta.json", tostring(id), tostring(tag or "snap"), snap.ts))
      enqueue({ op="journal", id=id, path=jpath, data=minify_json_str(cJson:Serialize({
        id = id, ts = snap.ts, tag = tag or "snap", delta = change, schema_version = CFG.SCHEMA_VERSION
      })) })
      write_crystal_frame(W, id, "DELT", { id=id, tag=tag or "snap", delta=change })
    end
  end

  -- Also write a tagged snapshot for guaranteed recovery
  local jpath_full = join(dir, string.format("%s_%s_%d.json", tostring(id), tostring(tag or "snap"), snap.ts))
  enqueue({ op="journal", id=id, path=jpath_full, data=payload })
  write_crystal_frame(W, id, "JTAG[" .. (tag or "snap") .. "]", snap)
  return true
end

function Persist.rollback(s, expected_tag)
  local W = s.world_obj
  local dir = journal_dir(W)
  if not cFile or not cFile.IsFolder or not cFile:IsFolder(dir) then return false end
  local files = cFile:GetFilesInFolder(dir)
  local latest, ts = nil, -1
  for _, f in ipairs(files) do
    local id, tag, t = string.match(f, "^(%d+)_(%w+)_(%d+)%.json$")
    t = tonumber(t or "-1")
    if id == tostring(s.id) and (not expected_tag or tag == expected_tag) and t > ts then
      latest, ts = f, t
    end
  end
  if not latest then return false end
  local ok, data = pcall(function() return cJson:Parse(cFile:ReadWholeFile(join(dir, latest))) end)
  if not ok or not data then return false end
  data = migrate_if_needed(data)
  s.goal, s.subgoal_step, s.bio, s.metrics = data.goal, data.subgoal_step, normalize_bio(data.bio), (data.metrics or s.metrics or {})
  s.linguistics, s.trust_map, s.genome, s.dream_log_buffer = data.linguistics or {}, data.trust or {}, data.genome or {}, data.dream_log or {}
  lru_touch(s.id, { json = minify_json_str(cJson:Serialize(data)), ts = data.ts or os.time() })
  return true
end

function Persist.delete(id) _locks[id] = nil; _lru.map[id] = nil; return true end

-- Optional: bind the flusher on plugin init
function Persist.bind_flusher_on_init(Plugin)
  Persist.start_flusher(Plugin)
end

return Persist
