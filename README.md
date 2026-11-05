# ClearViewForever

A minimal screen-clutter addon for **World of Warcraft Forever only**.

**Development version:** `0.1.0-alpha` · **Target:** Forever 1.60.1 / Interface 16001. This is not a public release.

## What works

- **Central red error messages:** hides the default UIErrorsFrame messages. Confirmed by Babuni in-game on November 5, 2026.
- **Floating combat damage/healing numbers:** disables supported combat-text CVars. Confirmed by Babuni in-game on November 5, 2026.
- **Creature names:** requests that normal NPC name CVars be disabled, but the **selected target's native 3D overhead name remains visible**. Not solved.
- **XP popups:** no independently verified suppression yet; unchanged.

The addon does not alter the target selection circle, target unit frame, combat log or combat mechanics. See [research](docs/TARGET_NAME_RESEARCH.md).

## Install

Put the repository files in `World of Warcraft/_classic_beta_/Interface/AddOns/ClearViewForever/`, so that `ClearViewForever.toc` sits directly inside that directory. Enable the addon in the Forever client.

## Commands

- `/cvf status` — show enabled controls and limitations.
- `/cvf diagnose` — print client build, name-related CVars (including the nameplate-only diagnostic), and combat text CVars.
- `/cvf apply` — reapply enabled controls.
- `/cvf names on|off` — request suppression of ordinary NPC names; cannot guarantee target overhead suppression.
- `/cvf numbers on|off` — control hiding floating combat numbers.
- `/cvf errors on|off` — control hiding red error messages.

Turning name/number management off does not restore original console values. Use in-game options to restore them.

## Verification

Confirmed in-game **by the user**: error text gone; combat text gone. Target-name suppression **failed in user testing**. XP suppression unimplemented. The updated diagnostic command is **not yet tested in-game**.

No publishing tag, GitHub Release or CurseForge release has been authorized or created.

## Credits

Concept and creative direction: Babuni. Technical implementation and documentation: OpenAI. No borrowed source code or artwork.
