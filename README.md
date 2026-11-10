# ClearViewForever

ClearViewForever lets you hide selected combat text, error messages and nameplate visuals in **World of Warcraft Forever**.

**Version:** `0.1.0-alpha` · **Target:** Forever 1.60.1 / Interface 16001.

## Display controls and test status

- **Central red error messages:** hides the default UIErrorsFrame messages. Confirmed by Babuni in-game on November 5, 2026.
- **Floating combat damage/healing numbers:** disables supported combat-text CVars. Confirmed by Babuni in-game on November 5, 2026.
- **Creature names:** requests that normal NPC name CVars be disabled. In recent testing, hiding Blizzard nameplate visuals also made the selected target's native overhead name disappear in some cases, but this was intermittent; native 3D name suppression is not considered solved.
- **Blizzard nameplates:** optional transparent rendering of each modifiable Blizzard nameplate `UnitFrame`. The addon reapplies transparency after zone/instance loading and guards against later alpha resets while keeping the nameplate system, unit tokens and events active. Friendly nameplates that the client protects inside dungeons and raids cannot be modified by addons and may remain visible. In-game verification of dungeon behavior is pending.
- **Combat enemy nameplates:** a separate optional control makes hostile Blizzard nameplate `UnitFrame`s fully transparent with `SetAlpha(0)` during combat. It uses the same per-frame alpha manager as the general nameplate option and does not change `nameplateShowEnemies` or disable the nameplate system. It affects hostile NPC and hostile player plates, not friendly plates. The original per-frame alpha is restored after combat unless the general option is still hiding the same frame. In-game testing is pending.
- **XP popups:** confirmed by Babuni in-game after toggling the feature off and on. It uses an optional **experimental** workaround via `/cvf xp on`. This changes **all native floating world text** using `WorldTextScale_v2` or `WorldTextScale`, not XP alone. It is disabled by default, has been confirmed to hide XP in Forever but may affect other world labels. `/cvf xp off` attempts to restore the saved original scale; it will not overwrite a scale changed by another addon.

The addon does not alter the target selection circle, target unit frame, combat log or combat mechanics. See [research](docs/TARGET_NAME_RESEARCH.md).

## Target portrait damage

An **optional** checkbox shows damage received by your selected target using the player portrait's large numeric font over its portrait, without restoring damage text in the world. It uses Forever's `UNIT_COMBAT` event for the `target` unit. It displays **all damage received by that target**, which can include other players or pets: the event does **not** identify the attacker. It does not display AoE damage on enemies you are not targeting. OFF by default. Enable with `/cvf portrait on`, or use the menu. Damage colors use a **best-effort** distinction: physical hits are white by default, magical hits are yellow, and physical abilities may be yellow if a successful player cast was observed in the previous 0.65 seconds. This is not reliable spell attribution: overlap, projectiles, pets, and other players may cause incorrect classifications. The updated colors and font sizing are **not yet tested in Forever**. Babuni confirmed the basic target portrait damage feedback in-game.

## Install

Put the repository files in `World of Warcraft/_forever_/Interface/AddOns/ClearViewForever/`, so that `ClearViewForever.toc` sits directly inside that directory. Enable the addon in the Forever client.

## In-game menu

Type **`/cvf`** or **`/cvf menu`** to open a compact window with seven checkboxes: XP popups, red error messages, combat numbers, creature names, nameplate visuals, combat enemy nameplates, and target portrait damage. The first six checkboxes mean **hide**; the seventh means **show**. Settings persist across sessions. The creature-name CVar option does not reliably suppress native 3D overhead names. The general nameplate option makes modifiable Blizzard nameplate `UnitFrame`s transparent without disabling the nameplate system. It performs delayed refreshes after zone/instance loading and maintains alpha zero if another system tries to change it. Friendly nameplates protected by the client inside dungeons and raids cannot be changed by addons. The combat option makes hostile nameplate `UnitFrame`s transparent only while fighting; nameplate frames, unit tokens and events remain active. The two options share alpha state, so disabling one does not reveal a plate still hidden by the other.

## Commands

- `/cvf` or `/cvf menu` — toggle the options window.
- `/cvf status` — show enabled controls and limitations.
- `/cvf diagnose` — print client build and relevant CVars.
- `/cvf apply` — reapply enabled controls.
- `/cvf names on|off` — request suppression of ordinary NPC names; cannot guarantee target overhead suppression.
- `/cvf nameplates on|off` — make Blizzard nameplate visuals transparent while keeping nameplate frames, unit tokens and events active.
- `/cvf combatplates on|off` — make hostile enemy nameplate `UnitFrame`s transparent during combat using `SetAlpha(0)`. Includes hostile players as well as NPCs; leaves the nameplate system and `nameplateShowEnemies` CVar unchanged.
- `/cvf numbers on|off` — control hiding floating combat numbers.
- `/cvf errors on|off` — control hiding red error messages.
- `/cvf portrait on|off` — toggle target-portrait damage feedback (all received target damage, not only yours).
- `/cvf xp on|off` — enable/disable experimental global world-text scaling. **Affects other world text and is OFF by default.**

Turning name/number management off does not restore original console values. Use in-game options to restore them.

## Verification

Confirmed in-game **by the user**: error text gone; combat text gone. XP workaround **confirmed by Babuni in-game**, after toggling once. Basic target-portrait damage feedback was **confirmed by Babuni in-game**. The new font sizing and critical emphasis remain **untested in-game**. The menu has no separately reported test outcome. The updated diagnostic command is **not yet tested in-game**. General nameplate transparency has partial user confirmation. Dungeon/instance refresh handling is implemented but not yet tested in-game; client-protected friendly plates may remain visible. The separate combat enemy-nameplate transparency option is implemented but **not yet tested in Forever**. Native target-name suppression remains intermittent and unconfirmed.

## CurseForge package

The CurseForge archive contains only `ClearViewForever.toc` and the three runtime Lua files, inside the `ClearViewForever/` addon folder. Development documentation remains in the GitHub repository and is excluded from the downloadable archive.

## Credits

Concept and creative direction: Babuni. Technical implementation and documentation: OpenAI. No borrowed source code or artwork.
