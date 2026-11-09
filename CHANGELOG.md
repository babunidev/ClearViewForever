# ClearViewForever changelog

## Unreleased — development

- Replace combat-only enemy nameplate CVar suppression with per-frame `SetAlpha(0)` transparency, sharing alpha state with the general nameplate option. Hostile NPC and player UnitFrames remain active but invisible during combat; in-game verification is pending.

## 0.1.0-alpha

Initial alpha package for **World of Warcraft Forever 1.60.1 / Interface 16001**.

- Hide central red error messages and supported floating combat numbers. Both have been confirmed in-game.
- Request suppression of ordinary NPC names through the game's CVars. The native 3D overhead name above the selected target may remain visible.
- Add optional transparent Blizzard nameplate visuals while keeping the nameplate system, unit tokens and events active. In-game verification is still pending.
- Add optional target-portrait damage feedback. The basic display has been confirmed in-game, but it reports all damage received by the selected target, including damage from other players and pets. Updated damage colors and critical-hit sizing are not yet verified.
- Add optional experimental XP popup suppression through global world-text scaling. It affects all native floating world text, not XP alone, and is disabled by default.
- Include a compact options window, slash commands and saved settings.
