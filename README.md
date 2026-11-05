# ClearViewForever

A minimal screen-clutter addon for **World of Warcraft Forever only**.

**Development version:** `0.1.0-alpha` · **Target:** Forever 1.60.1 / Interface 16001. This is not a public release.

## What works

- **Central red error messages:** hides the default UIErrorsFrame messages. Confirmed by Babuni in-game on November 5, 2026.
- **Floating combat damage/healing numbers:** disables supported combat-text CVars. Confirmed by Babuni in-game on November 5, 2026.
- **Creature names:** requests that normal NPC name CVars be disabled, but the **selected target's native 3D overhead name remains visible**. Not solved.
- **XP popups:** confirmed by Babuni in-game after toggling the feature off and on. It uses an optional **experimental** workaround via `/cvf xp on`. This changes **all native floating world text** using `WorldTextScale_v2` or `WorldTextScale`, not XP alone. It is disabled by default, has been confirmed to hide XP in Forever but may affect other world labels. `/cvf xp off` attempts to restore the saved original scale; it will not overwrite a scale changed by another addon.

The addon does not alter the target selection circle, target unit frame, combat log or combat mechanics. See [research](docs/TARGET_NAME_RESEARCH.md).

## Target portrait damage (confirmed in-game; sizing update untested)

An **optional** checkbox shows damage received by your selected target using the player portrait's large numeric font over its portrait, without restoring damage text in the world. It uses Forever's `UNIT_COMBAT` event for the `target` unit. It displays **all damage received by that target**, which can include other players or pets: the event does **not** identify the attacker. It does not display AoE damage on enemies you are not targeting. OFF by default. Enable with `/cvf portrait on`, or use the menu. Damage colors now use a **best-effort** distinction: physical hits are white by default, magical hits are yellow, and physical abilities may be yellow if a successful player cast was observed in the previous 0.65 seconds. This is not reliable spell attribution: overlap, projectiles, pets, and other players may cause incorrect classifications. The updated colors are **not yet tested in Forever**. Babuni confirmed target portrait damage feedback in-game. A subsequent font update uses `NumberFontNormalHuge` for regular hits and enlarges critical hits by 30%; this sizing change awaits in-game verification.

## Install

Put the repository files in `World of Warcraft/_forever_/Interface/AddOns/ClearViewForever/`, so that `ClearViewForever.toc` sits directly inside that directory. Enable the addon in the Forever client.

## In-game menu

Type **`/cvf`** or **`/cvf menu`** to open a compact window with five checkboxes: XP popups, red error messages, combat numbers, creature names, and target portrait damage. The first four checkboxes mean **hide**; the fifth means **show**. Settings persist across reloads. The creature-name option does **not** hide the native name above the selected target. The XP checkbox changes global world-text scaling, not XP alone.

## Commands

- `/cvf` or `/cvf menu` — toggle the options window.
- `/cvf status` — show enabled controls and limitations.
- `/cvf diagnose` — print client build, name-related CVars (including the nameplate-only diagnostic), and combat text CVars.
- `/cvf apply` — reapply enabled controls.
- `/cvf names on|off` — request suppression of ordinary NPC names; cannot guarantee target overhead suppression.
- `/cvf numbers on|off` — control hiding floating combat numbers.
- `/cvf errors on|off` — control hiding red error messages.
- `/cvf portrait on|off` — toggle target-portrait damage feedback (all received target damage, not only yours).
- `/cvf xp on|off` — enable/disable experimental global world-text scaling. **Affects other world text and is OFF by default.**

Turning name/number management off does not restore original console values. Use in-game options to restore them.

## Verification

Confirmed in-game **by the user**: error text gone; combat text gone. Target-name suppression **failed in user testing**. XP workaround **confirmed by Babuni in-game**, after toggling once. Target-portrait damage was **confirmed by Babuni in-game**. The new font sizing and critical emphasis remain **untested in-game**. The menu has no separately reported test outcome. The updated diagnostic command is **not yet tested in-game**.

No publishing tag, GitHub Release or CurseForge release has been authorized or created.

## Credits

Concept and creative direction: Babuni. Technical implementation and documentation: OpenAI. No borrowed source code or artwork.
