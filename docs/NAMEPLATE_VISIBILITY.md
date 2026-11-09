# Blizzard nameplate visibility

**Target:** World of Warcraft Forever 1.60.1 / Interface 16001  
**Status:** Both controls are implemented in development. General visual transparency has partial user confirmation; combat-only per-frame transparency still requires in-game verification.

## General visual transparency

**Setting:** `nameplates`  
**Command:** `/cvf nameplates on|off`

The setting makes the Blizzard visual `plate.UnitFrame` transparent with `SetAlpha(0)`. It does not hide or disable the nameplate base frame, turn off nameplate CVars, or unregister nameplate events.

The addon:
- Applies the setting to currently visible plates returned by `C_NamePlate.GetNamePlates()`.
- Applies it to newly added plates through `NAME_PLATE_UNIT_ADDED` and `C_NamePlate.GetNamePlateForUnit(unitToken)`, with one deferred recheck for frame/unit initialization.
- Handles `NAME_PLATE_UNIT_REMOVED` so combat-only transparency is released when a nameplate frame is reused for another unit.
- Rechecks visible plates on `PLAYER_ENTERING_WORLD`.
- Shares one per-frame alpha state with the combat-only option. The original alpha is saved once, the frame remains at zero while either hiding reason is active, and the original value is restored when both reasons are removed. An alpha change made by another addon while transparency is active is preserved for restoration.

Babuni reports that the general visual option hides most visible plates. Some combat-state plates have still appeared intermittently. In some tests, the selected creature's native overhead name also disappeared, but that effect was not consistent and is not treated as a solved native-name feature.

## Combat-only hostile nameplate transparency

**Setting:** `combatNameplates`  
**Command:** `/cvf combatplates on|off`

This is a separate control from general visual transparency, but it uses the same per-frame method. During combat, ClearViewForever identifies hostile nameplate units with `UnitCanAttack("player", unitToken)` and sets their Blizzard `UnitFrame` alpha to `0`. It does not change `nameplateShowEnemies` or any other nameplate CVar.

Behavior:
- Applies to currently visible hostile plates when `PLAYER_REGEN_DISABLED` fires.
- Applies to newly added hostile plates while combat is active.
- A short deferred recheck handles the possibility that Forever announces a new plate before its unit data is fully populated.
- Makes hostile NPC and hostile player UnitFrames transparent. Friendly plates are not affected by this combat-only reason.
- Leaves nameplate frames, unit tokens, mouse interaction and nameplate events active.
- If enabled during combat, applies immediately to currently visible hostile plates.
- If disabled during combat, removes only the combat transparency immediately.
- Restores each frame's previous alpha after combat, unless the general nameplate option is still active.
- If both options are enabled, a shared per-frame alpha state tracks both reasons. Disabling one option cannot reveal a frame while the other option still requires it to be transparent.
- If another addon changes a hidden frame's alpha, ClearViewForever records the new value before reapplying transparency, then restores that value after both hiding reasons are removed.

Older development builds used `nameplateShowEnemies`. If that build left a saved `combatNameplatesOriginal` value, the updated addon makes a one-time attempt to restore that legacy CVar override outside combat. The current combat transparency feature does not write the CVar.

## Compatibility boundaries

- General alpha zero does not disable nameplate frames, unit tokens, or events.
- Addon-created visuals parented beneath Blizzard's `UnitFrame` inherit its alpha and also become invisible.
- Alpha zero does not disable mouse interaction. An invisible nameplate may still receive mouse or hover interaction.
- Combat-only transparency affects hostile player plates as well as hostile creature plates.
- Both features are separate from the existing `/cvf names` controls. Neither guarantees suppression of engine-rendered native 3D overhead names or corpse labels.

## Forever API evidence

- `C_NamePlate.GetNamePlates()` is documented as returning currently visible nameplates and lists Forever 1.60.1 as a supported game type: https://warcraft.wiki.gg/wiki/API:C_NamePlate.GetNamePlates
- `C_NamePlate.GetNamePlateForUnit(unitToken)` is documented for Forever 1.60.1: https://warcraft.wiki.gg/wiki/API:C_NamePlate.GetNamePlateForUnit
- `NAME_PLATE_UNIT_ADDED` is documented as a Forever nameplate event: https://warcraft.wiki.gg/wiki/NAME_PLATE_UNIT_ADDED
- `NamePlateFrame.unitToken` identifies the unit represented by a visible plate: https://warcraft.wiki.gg/wiki/API:C_NamePlate.GetNamePlates
- `UnitCanAttack("player", unitToken)` is documented for Forever 1.60.1 and can distinguish hostile units: https://warcraft.wiki.gg/wiki/API:UnitCanAttack
- `NAME_PLATE_UNIT_ADDED` and `NAME_PLATE_UNIT_REMOVED` are documented Forever events: https://warcraft.wiki.gg/wiki/NAME_PLATE_UNIT_ADDED and https://warcraft.wiki.gg/wiki/NAME_PLATE_UNIT_REMOVED
- `C_Timer.After` is listed in current Forever addon API guidance; the delayed check is event-driven and does not poll continuously: https://wowforeverguides.com/addons/api-cheatsheet

These references support the API approach. They do not replace live testing on the installed Forever build.

## Verification still required

In-game, verify:
1. General transparency still hides existing and newly added friendly and hostile plates.
2. Combat transparency hides existing hostile creature and player plates as soon as combat begins.
3. Friendly nameplates remain visible when only the combat option is enabled.
4. The `nameplateShowEnemies` CVar remains unchanged when combat begins and ends.
5. Newly appearing hostile plates become transparent during combat, including plates whose unit data is populated after the add event.
6. Enabling the combat option during combat applies immediately; disabling it during combat removes only the combat transparency.
7. When both options are enabled, disabling either one leaves the plate transparent until the other option is also disabled.
8. Original frame alpha is restored after combat and after zoning/reloading.

The combat-only transparency has not yet been tested in-game. No live success is claimed.
