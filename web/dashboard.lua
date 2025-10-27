
-- web/dashboard.lua — simple HTML dashboard for AGIAPI status
return function(a_Request)
  local html = {}
  local function H(s) table.insert(html, s) end
  H("<style>body{font-family:sans-serif;background:#0b0f14;color:#e6edf3} .card{background:#0b1220;padding:16px;border-radius:12px;margin:12px 0}</style>")
  H("<h1>AGI API</h1>")
  H("<div class='card'><b>Namespaces</b><ul>")
  local ns = {"World","Action","Harmony","Self","Criticality"}
  for _,k in ipairs(ns) do
    local ok = (_G.AGI and _G.AGI[k]) and "online" or "missing"
    H("<li>"..k.." — <b>"..ok.."</b></li>")
  end
  H("</ul></div>")
  H("<div class='card'><p>Use <code>/agi ping</code>, <code>/agi task</code> in-game to verify runtime.</p></div>")
  return table.concat(html)
end
