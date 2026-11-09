# Roadmap

## Current
- [x] Implement opt-in transparent Blizzard nameplate visuals without disabling the nameplate system.
- [x] Implement separate combat-only hostile nameplate suppression through `nameplateShowEnemies`, preserving the previous CVar value.
- [ ] Test combat suppression and CVar restoration in Forever, including enabling/disabling during combat and interaction with general nameplate transparency.
- [ ] Test new and reused nameplates, friendly and hostile units, reloads, and addons that attach visuals beneath Blizzard's UnitFrame.
- [x] Implement optional target-portrait damage display using Forever UNIT_COMBAT (not yet tested in-game).
- [x] Confirm target-portrait damage feedback in Forever — Babuni reports it working.
- [ ] Test larger portrait font and 30% critical-hit emphasis in Forever.
- [x] Implement best-effort white physical / yellow ability-style portrait colors, using damage school and recent player casts.
- [ ] In-game test color rules across auto attacks, physical abilities, magical spells, pets and group combat.
- [ ] Investigate accurate attribution of player damage; UNIT_COMBAT has no attacker identity.
- [x] Hide central red error text — confirmed in-game by Babuni, 2026-11-05.
- [x] Hide floating combat numbers — confirmed in-game by Babuni, 2026-11-05.
- [ ] Investigate selected creature's native overhead name; current CVar approach does not hide it.
- [x] Add an optional, reversible **experimental** global world-text-scale workaround for XP popups (off by default).
- [x] Confirm XP popup hiding in Forever — Babuni reports success after cycling the control, 2026-11-05.
- [ ] Test the impact on other world text and restore behavior.
- [x] Implement minimal persisted options window.
- [ ] Test options window in Forever, including toggles and reload persistence.
- [ ] Find an XP-only method that does not affect unrelated text.
- [ ] Verify latest Forever build and API/CVar support after client updates.
- [ ] Test updated diagnostic behavior in-game.
- [ ] Restore original CVar values on disabling features, without overriding unrelated settings.

## Release gate
- `v0.1.0-alpha` is the initial tag-triggered alpha distribution.
- Development commits are not public releases; only an explicitly approved version tag should trigger CurseForge packaging.
- Every later public version requires explicit approval for that exact version.
