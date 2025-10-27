
-- AGIAPI.lua — robust loader for multiapi.lua in the same plugin folder
-- Avoids relative './multiapi.lua' by resolving the plugin directory via:
-- 1) cPluginManager:GetCurrentPlugin():GetLocalFolder()
-- 2) debug.getinfo() fallback to this file's directory

local function get_plugin_folder()
  if (cPluginManager and cPluginManager.GetCurrentPlugin) then
    local plug = cPluginManager:GetCurrentPlugin()
    if plug and plug.GetLocalFolder then
      return plug:GetLocalFolder()
    end
  end
  -- Fallback: use this file path (requires debug library enabled in build)
  if debug and debug.getinfo then
    local src = debug.getinfo(1, "S").source or ""
    local path = src:match("^@(.+)$") or src
    local dir = path:match("^(.*)/[^/]+$")
    if dir and dir ~= "" then return dir end
  end
  return "."  -- last resort
end

local folder = get_plugin_folder()
local ok, mod = pcall(function() return dofile(folder .. "/multiapi.lua") end)
if not ok then
  LOGWARNING("[AGIAPI] Failed to load multiapi.lua from: " .. tostring(folder) .. " (" .. tostring(mod) .. ")")
  error("AGIAPI cannot continue without multiapi.lua")
end
return mod
