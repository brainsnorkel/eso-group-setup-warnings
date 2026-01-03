# ESO Group Setup Warnings

Addon that alerts when Champion Points, buffs, or healing sets are duplicated in ESO group content.

## Addon Goals

Detect duplicate buffs/sets in **groups** (2+ players) during combat and warn the player. Specifically:

| Type | Name | Ability IDs | Detection Method |
|------|------|-------------|------------------|
| CP | Enlivening Overflow | 156008, 156012 | Combat event when CP procs |
| Buff | Major Courage | 66902, 109966 | Combat event when buff applied |
| Skill | Major Resolve (Frost Cloak) | 88758 | Combat event when skill cast |
| Set | Symphony of Blades | 117110, 117111 | Combat event when proc triggers |
| Set | Ozezan's Inferno | 188456 | Combat event when proc triggers |
| Set | Powerful Assault | 61771, 61763 | Combat event when proc triggers |

When 2+ players trigger the same ability/buff in the same fight, display a chat warning listing who has duplicates.

### Missing Buff Warnings

For fights lasting 10+ seconds, warn if these buffs were NOT detected:
- **Major Courage** - Group damage buff (from Olorime, Spell Power Cure, etc.)
- **Enlivening Overflow** - Champion Point healing star
- **Frost Cloak** - Major Resolve buff from Warden skill

### Group Activation

The addon activates when in any group (2+ players). Each detection rule has separate toggles for:
- **Small Group (2-4 players)**: Duos and small groups
- **Large Group (5+ players)**: Dungeons, trials, and arenas

This allows fine-grained control, e.g., disable Frost Cloak warnings in small groups where it's less relevant.

### On-Screen Status Indicator

A movable, clickable UI element that:
- **Shows "GSW" (green)**: When addon is enabled AND player is in a group
- **Shows "GSW (Paused)" (orange)**: When detection is temporarily paused
- **Shows "GSW not active" (gray)**: When indicator is unlocked for repositioning but detection is inactive
- **Hidden**: When disabled OR (outside a group AND indicator is locked)
- **Click to toggle pause**: Left-click the indicator to pause/resume detection (when locked)

### Slash Commands

| Command | Description |
|---------|-------------|
| `/gsw` | Toggle all warnings on/off |
| `/gsw on` | Enable all warnings |
| `/gsw off` | Disable all warnings |
| `/gsw status` | Show current warning state and group status |
| `/gsw unlock` | Unlock indicator for repositioning |
| `/gsw lock` | Lock indicator position |
| `/gsw pause` | Toggle pause (temporary, resets on zone change) |
| `/gsw debug` | Toggle debug mode (shows individual detections) |
| `/gswtest` | Display all message types for testing |

## Settings Panel (LibAddonMenu-2.0)

### General Settings
| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| Enable Addon | Checkbox | On | Master on/off toggle |
| Show Status Indicator | Checkbox | On | Show/hide on-screen indicator |
| Lock Indicator Position | Checkbox | On | Lock indicator position |
| Show Initialization Message | Checkbox | On | Show chat message on addon load |

### Indicator Appearance
| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| Font Size | Slider | 16 | Text size (12-24) |

### Detection Rules (Duplicate Detection)

Each detection has Small Group (2-4) and Large Group (5+) checkboxes. If both are off, detection is disabled for that ability.

| Detection | Small Default | Large Default |
|-----------|---------------|---------------|
| Enlivening Overflow (CP) | On | On |
| Major Courage (Buff) | On | On |
| Frost Cloak (Skill) | Off | On |
| Symphony of Blades (Set) | On | On |
| Ozezan's Inferno (Set) | On | On |
| Powerful Assault (Set) | On | On |

### Missing Buff Warnings

Each warning has Small Group (2-4) and Large Group (5+) checkboxes. If both are off, warning is disabled for that buff.

| Warning | Small Default | Large Default |
|---------|---------------|---------------|
| Missing Major Courage | Off | On |
| Missing Enlivening Overflow | Off | On |
| Missing Frost Cloak | Off | On |

## Feasibility Analysis

### What ESO APIs Allow

**Can detect (via combat log):**
- `EVENT_COMBAT_EVENT` — Fires for damage, healing, and buff applications. Provides `sourceUnitId`, `abilityId`, etc.
- `GetUnitName(unitTag)` — Get player name from unit tag
- `GetGroupSize()` — Check if in a group (2+ players)
- `IsUnitInCombat("player")` — Check combat state

**UI APIs (for status indicator):**
- `WINDOW_MANAGER:CreateTopLevelWindow()` — Create movable window
- `CreateControlFromVirtual()` — Create controls from XML templates
- `SetMovable(true/false)` — Enable/disable dragging
- `SetMouseEnabled(true/false)` — Enable mouse interaction
- `SetFont("ZoFontGame")` — Set text font/size
- `SetHidden(true/false)` — Show/hide control

**Limitations:**
- Can only see combat events for players within render distance (~100m)
- Cannot directly query what CP abilities other players have slotted (must wait for proc)
- Detection is reactive (see ability when it fires, not when equipped)
- UI position must be saved in SavedVariables to persist across sessions
- `EVENT_EFFECT_CHANGED` only identifies buff recipient, not who applied it (causes false positives)

### Implementation Strategy

1. **Group Detection**: Use `GetGroupSize()` to categorize: small (2-4) or large (5+) groups
2. **Combat Tracking**: Register for `EVENT_PLAYER_COMBAT_STATE` to track fight boundaries
3. **Ability Detection**:
   - Hook `EVENT_COMBAT_EVENT` with filter for target ability IDs
   - NOTE: `EVENT_EFFECT_CHANGED` is disabled due to false positives (detects recipient, not source)
4. **Duplicate Tracking**: Maintain per-fight table of `{abilityId = {playerName1, playerName2, ...}}`
5. **Warning Output**: Use `CHAT_ROUTER:AddSystemMessage()` for warnings
6. **Fight Reset**: Clear tracking tables when combat ends
7. **Missing Buff Check**: At end of combat (if fight >= 10s), warn if expected buffs weren't detected
8. **Status Indicator UI**:
   - Define in XML with TopLevelControl and label
   - Register `OnMoveStop` handler to save position to SavedVariables
   - Update visibility on group change events
   - Show gray "GSW not active" text when unlocked for repositioning

### Key Combat Event Filter

```lua
EVENT_MANAGER:RegisterForEvent(addon, EVENT_COMBAT_EVENT, OnCombatEvent)
EVENT_MANAGER:AddFilterForEvent(addon, EVENT_COMBAT_EVENT,
    REGISTER_FILTER_ABILITY_ID, abilityId)
```

Multiple filters can be registered with unique namespaces for each ability ID.

## Project Structure

```
GroupSetupWarnings/
├── GroupSetupWarnings.txt    # Manifest (required)
├── GroupSetupWarnings.lua    # Main addon code
├── GroupSetupWarnings.xml    # UI definitions (indicator)
└── Settings.lua              # LAM settings panel
```

## Commands

```bash
# Lint (luacheck is installed at C:\Users\Nebula PC\Tools\luacheck.exe)
luacheck.exe --config .luacheckrc GroupSetupWarnings.lua Settings.lua

# Or from any directory (if PATH is set):
luacheck --config .luacheckrc GroupSetupWarnings.lua Settings.lua

# Create release ZIP (excludes dev files)
zip -r GroupSetupWarnings.zip GroupSetupWarnings -x "*.git*" -x "*.md" -x ".luacheckrc"
```

## ESO Addon Conventions

### Manifest Format
```
## Title: Group Setup Warnings
## Description: Alerts when Champion Points and healing sets are duplicated in trials
## Author: brainsnorkel
## Version: 1.6.0
## APIVersion: 101044
## SavedVariables: GroupSetupWarningsSV
## OptionalDependsOn: LibAddonMenu-2.0 LibDebugLogger
```

Note: LibAddonMenu-2.0 is optional. The addon works without it but won't have a settings panel.

### Event Registration
```lua
EVENT_MANAGER:RegisterForEvent(addonName, EVENT_NAME, callback)
EVENT_MANAGER:UnregisterForEvent(addonName, EVENT_NAME)
```

### Saved Variables
```lua
ZO_SavedVars:NewAccountWide("GroupSetupWarningsSV", 1, nil, defaults)
```

## Key ESO APIs for This Addon

- `EVENT_GROUP_MEMBER_JOINED` / `EVENT_GROUP_MEMBER_LEFT` — Group roster changes
- `EVENT_PLAYER_ACTIVATED` — Zone load complete
- `GetGroupSize()` — Current group size (1-24)
- `GetGroupMemberIndexByCharacterName(name)` — Get member index
- `GetUnitChampionPoints("group" .. i)` — Get CP of group member
- `GetItemSetInfo(setId)` — Set bonus info
- `GetCurrentZoneId()` — Current zone
- `IsUnitInDungeon("player")` — Check if in dungeon
- `GetActivityManagerActivityType()` — Check activity type

## Common Libraries

- **LibAddonMenu-2.0** — Settings menu (optional, addon works without it)
- **LibDebugLogger** — Debug logging (optional)

## Reference Documentation

- **ESOUI Wiki** — https://wiki.esoui.com/ — Primary reference for ESO addon API and Lua documentation

## CI/CD

### GitHub Secrets Required
| Secret | Source |
|--------|--------|
| `ESOUI_API_KEY` | https://www.esoui.com/downloads/filecpl.php?action=apitokens |
| `ESOUI_ADDON_ID` | From ESOUI URL after first manual upload |

### Release Workflow
Create `.github/workflows/release.yml` for automated ESOUI publishing on tagged releases using `m00nyONE/esoui-upload@v2`.

## Luacheck

### Installation Location
- **Path**: `C:\Users\Nebula PC\Tools\luacheck.exe`
- **Version**: 0.23.0
- **Status**: Installed and added to user PATH
- **Usage**: `luacheck.exe --config .luacheckrc GroupSetupWarnings.lua Settings.lua`

### Configuration
Use `.luacheckrc` in repo root with:
- `std = "lua51"`
- ESO globals: `EVENT_MANAGER`, `ZO_SavedVars`, `GetGroupSize`, etc.
- `unused_args = false` (ESO event handlers have many unused parameters)
- Exclude `libs/*`

## Best Practices

### Code Organization
- Use `local` for all variables to avoid polluting the global `_G` table
- Create ONE global table per addon (e.g., `GSW = {}`) rather than multiple globals
- Use `GSW = GSW or {}` pattern when splitting code across multiple files
- Hook class functions rather than object instances for better addon compatibility
- Variables must be defined before use in their scope

### Performance
- Semantic versioning (sync manifest with git tags)
- Throttle group scan events (use `zo_callLater`)
- Cache zone checks to avoid repeated API calls
- Use savedvars for user thresholds (min CP, required sets)
- Avoid unnecessary global variable creation
- Review ZOS library utilities before creating custom solutions

### Event Handling
- `EVENT_ADD_ON_LOADED` fires for EACH enabled addon - always check the `addonName` parameter
- Unregister events after handling if not needed for other addons
- Chat output via `d()` only displays after `EVENT_PLAYER_ACTIVATED`
- Use LibDebugLogger + DebugLogViewer for logging before chat is available

### Common Mistakes to Avoid
- **Texture issues**: Delete `shader_cache.cooked` after adding/modifying .dds files
- **SavedVariables timing**: Changes made while logged in won't take effect until UI reload or loading screen
- **Manifest files**: Folder and manifest filename must match exactly; logout before changing dependencies

### Testing & Development
- Use `/script` commands in chat for inline testing
- Reload UI via `/reloadui` (or create shortcut `/rl`)
- Install debug addons: merTorchbug, sidTools, or Liliths Command History
- Always disable other addons during testing to prevent interference
- Check current API version: `/script d(GetAPIVersion())`

### API Restrictions (What Addons Cannot Do)
- Cannot access pre-game content or character selection screens
- Cannot detect non-grouped player positions or enemy locations
- Cannot modify character/NPC visuals, textures, or effects
- Cannot play custom sounds or include external 3D objects
- Cannot load files outside AddOns folder or deeper than 3 subfolder levels
- Cannot automate "botting related" features (against TOS)
- Do NOT use LibGroupSocket or LibDataShare for group data sharing
- Cannot use map pings as a data sharing workaround

### Pre-Release Checklist
- Test on both keyboard and gamepad interfaces if supporting consoles
- Verify SavedVariables persist correctly across sessions
- Review addon upload guidelines before publishing

## Changelog

Maintain a changelog in CHANGELOG.md for each release. Format:

```markdown
## [1.1.0] - YYYY-MM-DD
### Added
- New feature description

### Changed
- Modified behavior description

### Fixed
- Bug fix description
```

Update the changelog before creating a release tag. The GitHub Actions workflow will auto-generate release notes, but CHANGELOG.md provides a human-curated history.
