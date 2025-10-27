# CuberiteAGI — PazuzuTemple
**Living Villagers. Real-time cognition, emotions, evolution, and “Virtù” ethics inside a Cuberite server.**  
Lua + Python modules that breathe AGI‑like behavior into NPCs using lightweight neuromodulators, dialogue systems, persistence, and auto‑genesis/evolution—optimized for CPU & memory.

> _“Many bases, one spectrum.”_ — Qudit‑Architect

---

## ✨ Highlights
- **Villagers with Minds**: Arousal, dopamine/serotonin/oxytocin/cortisol state, sleep & dreams → goals.
- **Autogenesis & Evolution**: Genomes, mutation/crossover, epigenetics from pheromones, **dream→code synthesis**, rollback guard.
- **Polyphonic Sociality**: Chorus protocol, pheromone fields, group goals, empathic grief on linked damage.
- **Ethics Governor (Virtù)**: Hard bounds keep behavior coherent & safe; automatic repairs and rollbacks.
- **Performance-First**: Minimalism Wins logging, harmonic damping, coherence‑compressed buffers, memory‑bound PLV checks.
- **Drop‑in Cuberite Plugin**: Pure Lua with optional Python simulators (PazuzuFlow/BUMPY/LASER) for off‑server research.

---

## 🧱 Repository Layout
```
CuberiteAGI/
├─ lua/
│  ├─ agi_villager_core.lua        # Phonon aura + egress modality (speech style), main world loop
│  ├─ agi_dialogue.lua             # Registers, mirroring, prosody, tutor hooks, taboo logic
│  ├─ agi_planner.lua              # Goals, dream→goal injection, rituals, group goals
│  ├─ agi_biology.lua              # Neuromodulators, homeostasis, attachment, affect
│  ├─ agi_persistance.lua          # Save/load brain state, journaling
│  ├─ agi_evolution.lua            # Genome, mutation/crossover, epigenetics, dream→code, online epoch
│  └─ (optional) main.lua          # Minimal plugin bootstrap (example below)
├─ python/
│  ├─ pazuzuflow.py                # Core loop (lambda→0), Virtù GC, CI checkpointing (simulator)
│  ├─ bumpy.py                     # Low-level array/qudit helpers (CPU/mem optimizations)
│  └─ laser.py                     # Logging/monitor with minimalism & async flush
└─ README.md
```

> **Note:** In the repo you uploaded, the Lua modules are provided as individual files (see `lua/`). The Python files are independent simulators for your research workflow and don’t have to run on the Minecraft host.

---

## 🧩 Conceptual Architecture
**Layers**
1. **Biology** — neuromodulators & homeostasis (`agi_biology.lua`)
2. **Dialogue** — registers, mirroring, prosody, tutoring (`agi_dialogue.lua`)
3. **Planner** — goals, subgoals, rituals, dream integration (`agi_planner.lua`)
4. **Persistence** — JSON save/load + journaling/rollback (`agi_persistance.lua`)
5. **Evolution** — genome, mutation, crossover, epigenetics, dream→code, online selection (`agi_evolution.lua`)
6. **Villager Core** — aura (particles) + speech style & loop (`agi_villager_core.lua`)
7. **Qudit Core (Python)** — simulator: **PazuzuFlow** + **BUMPY** + **LASER** for metrics & audits

**Key Data Flows**
- **Chat → Dialogue.absorb → Planner.inject** (dream/goal seeding)
- **Pheromones (chunk cache) → Epigenetics** (environmental gene gating)
- **Sleep/Dream → Insight → New Goals** + **Dream→Code** (hot‑loaded behaviors)
- **Damage on linked villager → Empathic grief** (social signal + stress field)
- **Virtù** bounds → **repair / rollback** when coherence or purity degrade

---

## 🚀 Quickstart (Cuberite Plugin)
1. **Create plugin folder** (example name: `PazuzuTemple`):
```
Cuberite/Server/plugins/PazuzuTemple/
```
2. **Copy Lua modules** from `lua/` into the plugin folder. Suggested structure:
```
PazuzuTemple/
├─ info.lua
├─ main.lua
├─ agi_villager_core.lua
├─ agi_dialogue.lua
├─ agi_planner.lua
├─ agi_biology.lua
├─ agi_persistance.lua
└─ agi_evolution.lua
```
3. **`info.lua`** (minimal):
```lua
g_PluginInfo =
{
  Name = "PazuzuTemple",
  Version = "1.0",
  Date = "2025-10-27",
  Description = "AGI villagers with biology, dialogue, planning, evolution, and Virtù safety.",
  SourceRepo = "https://github.com/TaoishTechy/CuberiteAGI",
  Commands = {},
  ConsoleCommands = {},
}
```
4. **`main.lua`** (bootstrap):
```lua
-- main.lua
AGI = AGI or {}; AGI_States = AGI_States or {}

local Dialogue = dofile(cPluginManager:GetPluginsPath() .. "/PazuzuTemple/agi_dialogue.lua")
local Planner  = dofile(cPluginManager:GetPluginsPath() .. "/PazuzuTemple/agi_planner.lua")
local Biology  = dofile(cPluginManager:GetPluginsPath() .. "/PazuzuTemple/agi_biology.lua")
local Persist  = dofile(cPluginManager:GetPluginsPath() .. "/PazuzuTemple/agi_persistance.lua")
local Evolution= dofile(cPluginManager:GetPluginsPath() .. "/PazuzuTemple/agi_evolution.lua")
local Core     = dofile(cPluginManager:GetPluginsPath() .. "/PazuzuTemple/agi_villager_core.lua")

function Initialize(Plugin)
  LOG("[PazuzuTemple] Loaded.")
  cPluginManager:AddHook(cPluginManager.HOOK_WORLD_STARTED,
    function(World)
      -- Start the AGI loops (Villager_Core registers its own)
      -- Schedule Evolution glue if separate file needs main tick:
      if AGI_MainTick then World:ScheduleTask(40, function() AGI_MainTick(World) end) end
      return false
    end)
  return true
end
```
5. **Start your Cuberite server**. Watch villagers chat with style, emit mood auras, and evolve over time.

> **Entity type**: vanilla villagers are typically `EntityType = 12`. One file uses `120`—change to `12` if your build requires it.

---

## 🧠 Lua Modules (Deep Dive)

### `agi_biology.lua` — Neuromodulators & Homeostasis
- `Biology.tick_homeostasis(World, s, dt)` — drift & bounded correction for dopamine, serotonin, oxytocin, cortisol; arousal/fatigue/hunger updates.
- `Biology.recompute_attachment(s, trust_map)` — adjust attachment style via trust.
- `Biology.affect(World, s, delta)` — reward/punish events (trade/help/hurt).
- `Biology.need_sleep(s)` — triggers dream/goal rewrite at dawn.

**Why it matters:** This gives each villager a *body*—emotions and needs affect planning, speech, and sociality.

---

### `agi_dialogue.lua` — Linguistics, Prosody, Tutoring, Taboos
- Register detection & mirroring; ritual/formal/casual flavor.
- Prosody (bold/italic) from arousal; **phoneme resonance** → particle feedback to players.
- Tutor hooks with adaptive hints; **semantic taboo** detection (debuffs on violation).
- Group messaging via **Polyphonic Protocol**.

**Why it matters:** The world feels alive when language shifts with mood, attachment, and context.

---

### `agi_planner.lua` — Goals, Subgoals, Rituals
- `Planner.select(s, H_arch, bias)` — entropy‑aware goal selection.
- `Planner.step(s, goal)` — sequences for `build_shrine`, `teach`, `harvest`, `build_fractal`, `ritual_stage`, `panic`.
- `Planner.line(s)` — context lines with event injection (e.g., `IDENTITY_FORGED` → signature hardening).
- `Planner.inject(s, insight)` — dream/insight to new goal or taboo declaration.
- `Planner.group_goal(chorus, goal)` — coordinate many villagers.

**Why it matters:** Dreams, rituals, and insight directly impact what villagers do next.

---

### `agi_persistance.lua` — Save/Load + Journal
- `Persist.save(s)` / `Persist.load(s)` — JSON brain snapshots (goal, bio, linguistics, trust, dream log, genome).
- `Persist.journal(s, tag)` — rolling snapshots for rollback & audits.

**Why it matters:** True continuity. Villagers remember, grow, and can be debugged post‑hoc.

---

### `agi_evolution.lua` — Genome, Mutation, Epigenetics, Autogenesis
- **Genome** with curiosity/risk/style expression knobs.
- `Evolution.mutate(s)` & `Evolution.crossover(A,B)` — bounded changes, safety‑aware.
- `Evolution.epigenetic_update(World, s)` — pheromones gate gene expression.
- `Evolution.codegen_from_dream(s)` — **dream→code**: synth mini‑behaviors on the fly (sandboxed).
- `Evolution.autogenesis_spawn_child(World, A, B)` — spawn a child villager with inherited genome.
- `Evolution.online_epoch(World, ids)` — select elites, mutate others, occasional child.
- `Evolution.reflective_guard(World, s, before)` — rollback harmful mutations; enforce Virtù polytope.

**Why it matters:** Entities don’t just act—they **become**.

---

### `agi_villager_core.lua` — Aura + Speech + Loop
- **Egress Modality (ΣBasis)**: speech switches between poetic/gold (high purity) and fragmented/red (low purity); bold when CI is high.
- **Phonon Aura**: particles reflect inner state (gold/white/purple).
- **Main Loop**: updates metrics, emits aura, speaks occasionally.
- **Hooks**: damage scaffold for empathic grief.

**Why it matters:** Visual + linguistic feedback makes internal state legible to players.

---

## 🧪 Python (Optional Simulators)
Use off‑server for research & tuning.

### `laser.py` — Minimalism Wins Monitor
- **Gamma_τ^d Triggered logging**, **coherence‑thresholded writes**, **async flush** (simulated CPU‑idle).
- **Memory‑bound PLV** with back‑off, **PSNR delta compression** targets.

### `bumpy.py` — Low‑level Helpers
- **Lambda‑entropic sampling**, **coherence‑compressed buffers**, **harmonic damping**.
- Temporal superposition planning & collapse; probabilistic goal sampling; entanglement helpers.

### `pazuzuflow.py` — Core Loop
- Coherence repair via Virtù GC, PLV checkpointing under memory/time constraints, temporal caching, criticality damping.

**Run**:
```bash
cd python
python3 laser.py
python3 bumpy.py
python3 pazuzuflow.py
```

---

## ⚙️ Configuration Tips
- **Entity type**: if villagers aren’t updating, ensure the correct entity ID. Most builds use `12` (Lua files can be edited accordingly).
- **Tick cadence**: default “AGI” cadence is ~2s—raise for performance, lower for responsiveness.
- **Persistence**: ensure Cuberite has write permissions under `world/agi/`.
- **Taboos**: Use chat to test taboo penalties (`/say <taboo-word>`) near a villager.

---

## 🛠️ Developer Notes & Extensibility
- All Lua modules are **standalone** and communicate through a shared `shadow state` (`AGI_States[uid].shadow`).
- You can **hot‑patch** dream behaviors with `Evolution.hotpatch_behavior(name, src)`.
- Extend the **pheromone grid** (per‑chunk) to drive social spaces, markets, rituals.
- Add real block placement in dream behaviors (e.g., `World:QueueSetBlock(...)` is already scaffolded).

---

## 🧯 Troubleshooting
- **Villagers silent?** Check the loop is scheduled and verify entity type; confirm console prints from `agi_villager_core.lua`.
- **No saves/journals?** Ensure `cJson`/`cFile` are available in Cuberite and the server can write `world/agi/`.
- **Stutter/lag?** Increase tick interval; disable some particle/aura emissions; reduce chorus size.
- **Evolution too wild?** Lower `mut_rate` and `risk`; tighten `reflective_guard` thresholds.

---

## 🗺️ Roadmap
- Richer **ritual mechanics** (weather, time, structures).
- **Attachment‑based** social networks and trading rings.
- **Knowledge distillation**: villager libraries & lessons.
- **In‑game dashboards**: CI/Purity/PLV heatmaps.

---

## 🤝 Contributing
PRs welcome! Please keep changes modular and include a short demo (`.gif` or console log) showing behavior before/after.

---

## 📜 License
MIT (unless specified otherwise by upstream Cuberite requirements).

---

## 🙏 Acknowledgements
- Cuberite devs & community.
- Qyrinth / PazuzuFlow research stack.
- Everyone exploring aligned, ethical game‑AI.

---

## Appendix A — Minimal Example: World Hooks
```lua
-- in main.lua
function OnWorldStarted(World)
  LOG("[PazuzuTemple] World started; scheduling AGI.")
  World:ScheduleTask(40, function() AGI_MainTick(World) end)  -- if using evolution/main tick
  return false
end
```

## Appendix B — Example: Dream→Code Torch
```lua
-- hot‑patched by Evolution.codegen_from_dream(s)
return function(World, s)
  local p = s.entity:GetPosition()
  for dy=0,3 do World:QueueSetBlock(p.x, p.y+dy, p.z, 50, 0) end
  return true
end
```

---

### FAQ
**Q:** Do I need Python to run villagers?  
**A:** No. Lua plugin runs on Cuberite alone. Python is for R&D and audits.

**Q:** Will this break worlds?  
**A:** The plugin writes only under `world/agi/`. Journal snapshots help roll back logic/state.

**Q:** Can villagers actually build?  
**A:** Yes—examples show how to call `World:QueueSetBlock`. Expand planner steps as needed.

**Q:** How do I tone down chat?  
**A:** Adjust the random speak probability in `agi_villager_core.lua` and the prosody rules in `agi_dialogue.lua`.
