
Sandbox = Sandbox or {}
local DEFAULTS = { SandboxMaxStringRep = 2048, SandboxMaxBytes = 64 * 1024 }
local function create_safe_env(World, s, AGI_Config)
  AGI_Config = AGI_Config or DEFAULTS
  local safe = {
    print = function(...) LOGINFO("[AGI:Sandbox] "..table.concat({...}, " ")) end,
    math = math, table = table, tonumber = tonumber, tostring = tostring, type = type, pairs = pairs, ipairs = ipairs, select = select, pcall = pcall,
    LOGINFO = LOGINFO, LOGWARNING = LOGWARNING, World = World, s = s,
    string = setmetatable({}, { __index = function(_,k)
      if k == "rep" then
        return function(str, n) if n > (AGI_Config.SandboxMaxStringRep or DEFAULTS.SandboxMaxStringRep) then n = AGI_Config.SandboxMaxStringRep or DEFAULTS.SandboxMaxStringRep end
          return string.rep(str, n) end
      end
      return string[k]
    end }),
  }
  return safe
end
function Sandbox.safe_eval(code_str, s, AGI_Config)
  local World = s.world_obj; code_str = code_str:gsub("\27%[.-[mK]", "")
  if #code_str > (AGI_Config and AGI_Config.SandboxMaxBytes or DEFAULTS.SandboxMaxBytes) then return false, "Code exceeds maximum byte limit" end
  local env = create_safe_env(World, s, AGI_Config)
  local chunk, err = load(code_str, "=sandbox", "t", env); if not chunk then return false, "Compile error: "..tostring(err) end
  local ok, res = pcall(chunk); if not ok then return false, "Runtime error: "..tostring(res) end; return true, res
end
return Sandbox
