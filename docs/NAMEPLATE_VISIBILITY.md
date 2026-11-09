# Blizzard nameplate visibility

**Target:** World of Warcraft Forever 1.60.1 / Interface 16001  
**Status:** Both controls are implemented in development. General visual transparency has partial user confirmation; combat-only CVar suppression still requires in-game verification.

## General visual transparency

**Setting:** `nameplates`  
**Command:** `/cvf nameplates on|off`

The setting makes the Blizzard visual `plate.UnitFrame` transparent with `SetAlpha(0)`. It does not hide or disable the nameplate base frame, turn off nameplate CVars, or unregister nameplate events.

The addon:
- Applies the setting to currently visible plates returned by `C_NamePlate.GetNamePlates()`.
- Applies it to newly added plates through `NAME_PLATE_UNIT_ADDED` and `C_NamePlate.GetNamePlateForUnit(unitToken)`.
- Rechecks visible plates on `PLAYER_ENTERING_WORLD`.
- Saves each UnitFrame's previous alpha and restores it when disabled, but only if the alpha is still zero. This avoids overwriting a different alpha value another addon may have applied in the meantime.

Babuni reports that the general visual option hides most visible plates. Some combat-state plates have still appeared intermittently. In some tests, the selected creature's native overhead name also disappeared, but that effect was not consistent and is not treated as a solved native-name feature.

## Combat-only hostile nameplate suppression

**Setting:** `combatNameplates`  
**Command:** `/cvf combatplates on|off`

This is a separate control from general visual transparency. When enabled, it temporarily sets the Forever enemy-nameplate CVar `nameplateShowEnemies` to `0` as combat begins. The value that was active immediately before the change is saved in SavedVariables and restored after combat.

Behavior:
- Applies at `PLAYER_REGEN_DISABLED`, before combat lockdown, following the pattern used by a current Forever addon.
- Restores the saved CVar at `PLAYER_REGEN_ENABLED`.
- Does not modify `nameplateShowAll` or friendly-nameplate CVars.
- Suppresses hostile NPC and hostile player nameplates. It does not suppress friendly player or friendly NPC plates.
- Leaves out-of-combat enemy-nameplate visibility under the game's existing settings.
- If enabled after combat has already begun, it takes effect on the next combat because the CVar may no longer be writable during lockdown.
- If disabled during combat, restoration waits until combat ends.
- Restores the original value only while the CVar is still `0`. If another addon or the player has changed it to a different value, ClearViewForever leaves that external value untouched.

The option changes whether hostile nameplates are shown; it does not make an additional frame transparent. It is useful alongside the general alpha option: the general option handles visible plates broadly, while this control suppresses hostile enemy plates during combat at the CVar level.

## Compatibility boundaries

- General alpha zero does not disable nameplate frames, unit tokens, or events.
- Addon-created visuals parented beneath Blizzard's `UnitFrame` inherit its alpha and also become invisible.
- Alpha zero does not disable mouse interaction. An invisible nameplate may still receive mouse or hover interaction.
- Combat-only suppression affects hostile player plates as well as hostile creature plates.
- Both features are separate from the existing `/cvf names` controls. Neither guarantees suppression of engine-rendered native 3D overhead names or corpse labels.

## Forever API evidence

- `C_NamePlate.GetNamePlates()` is documented as returning currently visible nameplates and lists Forever 1.60.1 as a supported game type: https://warcraft.wiki.gg/wiki/API:C_NamePlate.GetNamePlates
- `C_NamePlate.GetNamePlateForUnit(unitToken)` is documented for Forever 1.60.1: https://warcraft.wiki.gg/wiki/API:C_NamePlate.GetNamePlateForUnit
- `NAME_PLATE_UNIT_ADDED` is documented as a Forever nameplate event: https://warcraft.wiki.gg/wiki/NAME_PLATE_UNIT_ADDED
- A current Forever addon uses `nameplateShowEnemies` to drive hostile nameplate visibility and documents that `PLAYER_REGEN_DISABLED` fires before combat lockdown: https://github.com/sorrow8/forever-combat-plates/blob/main/ForeverCombatPlates/Core.lua
- A Forever forum report confirms that setting `nameplateShowEnemies` to `0` hides enemy nameplates, while `1` makes them visible: https://eu.forums.blizzard.com/en/wow/t/enemy-nameplates-always-visible-even-when-not-in-combat-%E2%80%93-wow-forever/639688

These references support the API and CVar approach. They do not replace live testing on the installed Forever build.

## Verification still required

In-game, verify:
1. General transparency still hides existing and newly added friendly and hostile plates.
2. Combat suppression hides hostile creature plates as soon as combat begins.
3. The previous `nameplateShowEnemies` value returns after combat.
4. Friendly plates remain unaffected by the combat-only option.
5. Toggling the combat-only option on during combat takes effect on the next fight; toggling it off during combat restores after combat.
6. The two nameplate controls work independently and together.
7. Behavior remains correct after zoning and relogging, including recovery of a saved CVar if the client closes during combat.

The combat-only control has not yet been tested in-game. No live success is claimed.
