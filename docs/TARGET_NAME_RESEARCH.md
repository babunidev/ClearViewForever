# Selected-target overhead name — Forever research

Date: 2026-11-05. Target baseline: Forever 1.60.1 / Interface 16001.

## User-observed result

With all nameplate and standard NPC name settings disabled, selecting a mob still causes its red/yellow/green native name to appear above it. The selection circle should remain.

## Findings

- The `UnitNameNPC`, `UnitNameHostleNPC` (historical spelling), and `UnitNameNonCombatCreatureName` CVars control classes of ordinary overhead NPC names. The addon already attempts to set supported entries to zero, but the selected mob still shows a name in Forever.
- `nameplateForceShowUnitName` is documented for **nameplates**, not native world text. It is displayed in `/cvf diagnose` without changing it.
- A closely matching Blizzard forum report from 2021 found no verified option to remove only the selected NPC's native overhead label.
- The Forever-compatible FirstNames addon documents that native world-rendered overhead names are locked by the engine rather than standard addon UI font strings.
- Replacing / hiding nameplates is not a proven fix when **all nameplates are already disabled**. Intercepting `UnitName`, hiding the target frame, changing targeting, or hiding the whole UI is not an acceptable solution.

## Evidence and confidence

- **Confirmed by user, in Forever:** native target name remains visible; combat numbers and red errors are hidden successfully.
- **Documented in other modern WoW clients:** nameplateForceShowUnitName has nameplate-specific semantics.
- **Inferred:** the outstanding target name is rendered by the engine and cannot be directly hidden by a standard Lua addon.
- **Unverified:** whether a private/undocumented Forever-only CVar exists; no such CVar should be invented.

## Sources

- https://us.forums.blizzard.com/en/wow/t/how-to-remove-floating-name-over-current-target/1142496
- https://www.curseforge.com/wow/addons/firstnames
- https://warcraft.wiki.gg/wiki/CVar
- https://eu.forums.blizzard.com/en/wow/t/option-to-only-see-hostile-npc-names/582719
- https://atraeau.github.io/WoW-Addons/

## Precise follow-up diagnostic

On the currently installed addon, use `/cvf diagnose`; check which of the `UnitName...` variables exist and read `0`. This separates CVar failures from native engine override. On this development revision, also inspect `nameplateForceShowUnitName` (diagnostic only). Retest targeting both hostile and friendly NPCs. Do not claim native-name suppression until tested successfully in Forever.
