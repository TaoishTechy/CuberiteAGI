
g_PluginInfo =
{
  Name = "AGIAPI",
  Version = "1.0.0",
  Date = "2025-10-27",
  Description = "Recursive Agent API: World sensing, action scheduler, harmony oracle, self-model; optional holographic criticality tools.",
  AdditionalInfo =
  {
    {
      Title = "Repository",
      Contents = "https://github.com/TaoishTechy/CuberiteAGI"
    },
  },
  Commands =
  {
    agi =
    {
      Permission = "",
      HelpString = "AGIAPI control: /agi ping | /agi dump | /agi task",
      Handler = nil, -- bound from main.lua
    },
  },
}
