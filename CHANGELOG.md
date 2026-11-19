# ClearViewForever changelog

## Unreleased — development

### Changed — human–AI collaboration record (2026-11-19)
- Added a rule to `AGENTS.md` and `docs/DOCUMENTATION.md`: `docs/AI_COLLABORATION.md` takes no dated entries; contributions are recorded in the journal and changelog. Claude Code (Claude Opus 5.5).
- Rewrote `docs/AI_COLLABORATION.md` to the shared text used in all of Babuni's repositories: how Babuni works with AI, who did what (the tools and recorded models named in this project's records) and where the details are. The earlier, longer version stays in the Git history. Claude Code (Claude Opus 5.5).

### Changed — documentation moved into `docs/` (2026-11-19)
- Moved `CONCEPT.md` and `ROADMAP.md` into `docs/`. The root keeps only `README.md`, `AGENTS.md`, `LICENSE` and `CHANGELOG.md`; links to the moved files and the documentation rules in `AGENTS.md` were updated. No code changed. Claude Code (Claude Opus 5.5).

- Replace combat-only enemy nameplate CVar suppression with per-frame `SetAlpha(0)` transparency, sharing alpha state with the general nameplate option. Hostile NPC and player UnitFrames remain active but invisible during combat; in-game verification is pending.
- Reapply nameplate transparency after zone/instance loading and guard accessible UnitFrames against later alpha resets. Friendly nameplates protected by the client inside dungeons and raids remain outside addon control.

## 0.1.0-alpha

Initial alpha package for **World of Warcraft Forever 1.60.1 / Interface 16001**.

- Hide central red error messages and supported floating combat numbers. Both have been confirmed in-game.
- Request suppression of ordinary NPC names through the game's CVars. The native 3D overhead name above the selected target may remain visible.
- Add optional transparent Blizzard nameplate visuals while keeping the nameplate system, unit tokens and events active. In-game verification is still pending.
- Add optional target-portrait damage feedback. The basic display has been confirmed in-game, but it reports all damage received by the selected target, including damage from other players and pets. Updated damage colors and critical-hit sizing are not yet verified.
- Add optional experimental XP popup suppression through global world-text scaling. It affects all native floating world text, not XP alone, and is disabled by default.
- Include a compact options window, slash commands and saved settings.

## 2026-11-13 — License and rights

- Established MIT for original addon software and updated repository documentation to explain the permission boundary.
- Preserved third-party authorship and external assets' separate terms. No gameplay or runtime verification is claimed.
