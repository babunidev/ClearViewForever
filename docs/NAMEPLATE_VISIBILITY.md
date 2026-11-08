# Transparent Blizzard nameplates

**Target:** World of Warcraft Forever 1.60.1 / Interface 16001  
**Status:** Implemented in the development branch; in-game verification pending.

## Behavior

The optional `nameplates` setting makes the Blizzard visual `plate.UnitFrame` transparent with `SetAlpha(0)`. It does not hide or disable the nameplate base frame, turn off nameplate CVars, or unregister nameplate events.

The addon:
- Applies the setting to currently visible plates returned by `C_NamePlate.GetNamePlates()`.
- Applies it to newly added plates through `NAME_PLATE_UNIT_ADDED` and `C_NamePlate.GetNamePlateForUnit(unitToken)`.
- Rechecks visible plates on `PLAYER_ENTERING_WORLD`.
- Saves each UnitFrame's previous alpha and restores it when disabled, but only if the alpha is still zero. This avoids overwriting a different alpha value another addon may have applied in the meantime.

## Compatibility boundaries

- Nameplate frames, unit tokens and nameplate events remain available while the Blizzard visual UnitFrame is transparent.
- Addons that read unit tokens, listen for nameplate events, or draw overlays in independent frames can continue to use the nameplate system.
- Addon-created visuals parented beneath Blizzard's `UnitFrame` inherit its alpha and will also become invisible. This is an unavoidable consequence of making that parent frame transparent.
- Alpha zero does not disable mouse interaction. An invisible nameplate may still receive mouse or hover interaction.
- This feature is separate from the existing `/cvf names` CVar controls. It does not guarantee suppression of engine-rendered native 3D overhead names, including the selected-target name that remains unresolved in `TARGET_NAME_RESEARCH.md`.

## Forever API evidence

- `C_NamePlate.GetNamePlates()` is documented as returning currently visible nameplates and lists Forever 1.60.1 as a supported game type: https://warcraft.wiki.gg/wiki/API:C_NamePlate.GetNamePlates
- `C_NamePlate.GetNamePlateForUnit(unitToken)` is documented for Forever 1.60.1: https://warcraft.wiki.gg/wiki/API:C_NamePlate.GetNamePlateForUnit
- `NAME_PLATE_UNIT_ADDED` is documented as a Forever nameplate event: https://warcraft.wiki.gg/wiki/NAME_PLATE_UNIT_ADDED
- `SetAlpha(0)` makes a frame fully transparent; alpha propagates to descendants, while zero alpha does not itself remove interaction: https://warcraft.wiki.gg/wiki/API:Region_SetAlpha

These references support API availability and the expected frame behavior. They do not replace live testing on the installed Forever build.

## Verification still required

In-game, enable and disable `/cvf nameplates on|off` while checking:
1. Existing hostile and friendly nameplates become invisible and return when disabled.
2. Nameplates appearing after the toggle are also hidden.
3. Unit tokens and nameplate events remain available to another addon.
4. Addon visuals parented beneath Blizzard's UnitFrame are hidden, while independent overlays remain visible.
5. The feature behaves correctly after `/reload`, zoning, and combat transitions.

No in-game success is claimed yet.
