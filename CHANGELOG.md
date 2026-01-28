# Changelog

## [1.8.0] - 2026-01-28
### Changed
- Replace status indicator with results window UI
- Window displays duplicates and missing buffs after combat ends
- Window shows addon status (enabled/paused/group size)
- Add settings button to show window for positioning
- Update `/gsw status` to show results window instead of chat output
- Simplify slash commands (remove `/gsw unlock` and `/gsw lock`)

### Fixed
- Missing buff warnings now work correctly even when duplicate detection is disabled

## [1.7.1] - 2026-01-04
### Fixed
- Fix duplicate warnings firing multiple times for abilities with multiple IDs (e.g., Major Courage, Powerful Assault)

## [1.7.0] - 2026-01-04
### Added
- Powerful Assault set duplicate detection (ability IDs 61771, 61763)

## [1.6.0] - 2026-01-04
### Changed
- Simplified settings: removed master toggles for each detection
- Detection is now controlled by just Small Group (2-4) and Large Group (5+) checkboxes
- If both group size checkboxes are off, detection is disabled for that ability

## [1.5.0] - 2026-01-04
### Added
- Frost Cloak (Major Resolve) tracking - detects duplicates and warns if missing
- Player names now show both character name and @handle format

### Changed
- Removed From the Brink, Roaring Opportunist detection (unreliable)
- Removed Major Breach/Crusher detection (ESO API limitation - can't see other players' debuffs)
- Removed "Show As Icon" setting

## [1.4.0] - 2026-01-04
### Changed
- Use ESO's `COMBAT_UNIT_TYPE_PLAYER` constant instead of hardcoded value
- Add shared version constant (`GSW.version`) for sync between files
- Consolidate duplicate event registrations in Settings.lua
- Replace inefficient loop with `next()` for empty table checks

### Fixed
- Add missing `majorBreach` and `crusher` detection setting defaults

## [1.3.0] - 2026-01-04
### Added
- Missing debuff warnings for fights lasting 10+ seconds:
  - Major Breach (ID 61743) - warns if no player applied this debuff to enemies
  - Crusher enchant (ID 17906) - warns if no player applied this debuff to enemies
- New settings section "Missing Debuff Warnings" with toggles for each debuff
- `targetHostile` flag for abilities that should only be tracked when applied to enemies

## [1.2.0] - 2026-01-03
### Added
- Debug mode (`/gsw debug`) to show individual buff detections
- Warn when Major Courage is missing from a fight (10+ seconds)
- Warn when Enlivening Overflow is missing from a fight (10+ seconds)
- LibDebugLogger support for logging
- Alternate ability IDs for better detection:
  - Enlivening Overflow: 156012
  - From the Brink: 156020
  - Major Courage: 109966 (Olorime/etc)
  - Symphony of Blades: 117111 (Meridia's Favor)

### Fixed
- Fix GetUnitTagById -> GetUnitTagByUnitId (correct ESO API)
- Strip gender markers (^Fx, ^Mx) from player names
- Fix group leave detection (now listens to EVENT_GROUP_MEMBER_LEFT)
- Remove EVENT_EFFECT_CHANGED to prevent false positives with companions

### Changed
- Show "inactive" message when leaving group

## [1.1.0] - 2026-01-02
### Changed
- Enable duplicate detection for all group sizes (2+ players), not just trials
- Improved README with detailed detection logic documentation

### Added
- GitHub Actions release workflow for automated builds

## [1.0.0] - Initial Release
### Added
- Duplicate detection for Champion Points (Enlivening Overflow, From the Brink)
- Duplicate detection for buffs (Major Courage)
- Duplicate detection for sets (Roaring Opportunist, Symphony of Blades, Ozezan's Inferno)
- On-screen status indicator (movable, lockable)
- Settings panel via LibAddonMenu-2.0
- Slash commands (/gsw, /gsw on, /gsw off, /gsw status, /gsw unlock, /gsw lock)
