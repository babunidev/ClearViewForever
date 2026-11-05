# Roadmap

## Current
- [x] Implement optional target-portrait damage display using Forever UNIT_COMBAT (not yet tested in-game).
- [ ] Test target-portrait feedback and placement in Forever.
- [ ] Investigate accurate attribution of player damage; UNIT_COMBAT has no attacker identity.
- [x] Hide central red error text — confirmed in-game by Babuni, 2026-11-05.
- [x] Hide floating combat numbers — confirmed in-game by Babuni, 2026-11-05.
- [ ] Investigate selected creature's native overhead name; current CVar approach does not hide it.
- [x] Add an optional, reversible **experimental** global world-text-scale workaround for XP popups (off by default).
- [x] Confirm XP popup hiding in Forever — Babuni reports success after cycling the control, 2026-11-05.
- [ ] Test the impact on other world text and restore behavior.
- [x] Implement minimal persisted four-checkbox options window.
- [ ] Test options window in Forever, including toggles and reload persistence.
- [ ] Find an XP-only method that does not affect unrelated text.
- [ ] Verify latest Forever build and API/CVar support after client updates.
- [ ] Test updated diagnostic behavior in-game.
- [ ] Restore original CVar values on disabling features, without overriding unrelated settings.

## Release gate
No public version authorized. No tags or publication until review and explicit approval.
