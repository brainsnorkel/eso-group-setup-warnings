# Changelog

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
