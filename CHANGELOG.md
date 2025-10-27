
# CHANGELOG — v1.1.0 (The Architect Release)

- Fixed hook registration (modern AddHook signature, plus resilient fallback).
- Robust villager detection across builds (enum / numeric / class name).
- Reentrancy-safe tick loop per world; epoch runs once per period per world.
- Atomic JSON persistence with journal & rollback; schema sanity checks.
- Sandboxed dream codegen with byte/rep caps and ANSI stripping.
- Dialogue input validation + particle throttling.
- Python bridge secured with HMAC and imports corrected.
- Consolidator `makemd.py` to export repo into .md for auditing.
