# ESO Group Setup Warnings

Addon that alerts when Champion Points or healing sets are unusual in ESO dungeons and trials.

## Addon Goals

Detect duplicate buffs/sets in **trials** during combat and warn the player. Specifically:

| Type | Name | Ability/Buff ID | Detection Method |
|------|------|-----------------|------------------|
| CP | Enlivening Overflow | 156008 | Combat event when CP procs |
| CP | From the Brink | 156019 | Combat event when heal triggers |
| Buff | Major Courage | 66902 | Effect applied event |
| Set | Roaring Opportunist | 135920 | Effect applied event |
| Set | Symphony of Blades | 117110 | Combat event when proc triggers |
| Set | Ozezan's Inferno | 188456 | Combat event when proc triggers |

When 2+ players trigger the same ability/buff in the same fight, display a chat warning listing who has duplicates.

### Trial-Only Activation

The addon only activates detection when `IsUnitInRaid("player")` returns true (player is in a trial).

### On-Screen Status Indicator

A movable UI element that:
- **Shows**: Icon or text (e.g., "GSW" or eye icon) when addon is enabled AND player is in a trial
- **Hidden**: Invisible when disabled OR outside a trial

### Slash Commands

| Command | Description |
|---------|-------------|
| `/gsw` | Toggle all warnings on/off |
| `/gsw on` | Enable all warnings |
| `/gsw off` | Disable all warnings |
| `/gsw status` | Show current warning state |
| `/gsw unlock` | Unlock indicator for repositioning |
| `/gsw lock` | Lock indicator position |

## Settings Panel (LibAddonMenu-2.0)

### General Settings
| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| Enable Addon | Checkbox | On | Master on/off toggle |
| Show Status Indicator | Checkbox | On | Show/hide on-screen indicator |
| Indicator Locked | Checkbox | On | Lock indicator position |

### Indicator Appearance
| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| Font Size | Slider | 16 | Text size (12-24) |
| Show As Icon | Checkbox | Off | Use icon instead of text |

### Detection Rules (Individual Toggles)
| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| Enlivening Overflow | Checkbox | On | Detect duplicate CP |
| From the Brink | Checkbox | On | Detect duplicate CP |
| Major Courage | Checkbox | On | Detect duplicate buff |
| Roaring Opportunist | Checkbox | On | Detect duplicate set |
| Symphony of Blades | Checkbox | On | Detect duplicate set |
| Ozezan's Inferno | Checkbox | On | Detect duplicate set |

## Feasibility Analysis

### What ESO APIs Allow

**Can detect (via combat log):**
- `EVENT_COMBAT_EVENT` — Fires for damage, healing, and buff applications. Provides `sourceUnitId`, `abilityId`, etc.
- `EVENT_EFFECT_CHANGED` — Fires when buffs are applied/removed. Provides `unitTag`, `effectSlot`, `abilityId`, etc.
- `GetUnitName(unitTag)` — Get player name from unit tag
- `IsUnitInRaid("player")` — Check if in trial/raid
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

### Implementation Strategy

1. **Trial Detection**: Use `IsUnitInRaid("player")` or check zone IDs for trial zones
2. **Combat Tracking**: Register for `EVENT_PLAYER_COMBAT_STATE` to track fight boundaries
3. **Ability Detection**:
   - Hook `EVENT_COMBAT_EVENT` with filter for target ability IDs
   - Hook `EVENT_EFFECT_CHANGED` for buff applications
4. **Duplicate Tracking**: Maintain per-fight table of `{abilityId = {playerName1, playerName2, ...}}`
5. **Warning Output**: Use `d()` or `CHAT_SYSTEM:AddMessage()` for warnings
6. **Fight Reset**: Clear tracking tables when combat ends
7. **Status Indicator UI**:
   - Define in XML with TopLevelControl, label, and optional icon texture
   - Register `OnMoveStop` handler to save position to SavedVariables
   - Update visibility on zone change (`EVENT_PLAYER_ACTIVATED`)
   - Refresh text when rules are toggled in settings

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
# Lint
luacheck . --config .luacheckrc

# Create release ZIP (excludes dev files)
zip -r GroupSetupWarnings.zip GroupSetupWarnings -x "*.git*" -x "*.md" -x ".luacheckrc"
```

## ESO Addon Conventions

### Manifest Format
```
## Title: Group Setup Warnings
## Description: Alerts when CPs and healing sets are unusual in dungeons/trials
## Author: brainsnorkel
## Version: 1.0.0
## APIVersion: 101048
## SavedVariables: GroupSetupWarningsSV
## DependsOn: LibAddonMenu-2.0
## OptionalDependsOn: LibDebugLogger
```

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

- **LibAddonMenu-2.0** — Settings menu (external dependency)
- **LibDebugLogger** — Debug logging (optional)
- **LibAsync** — Deferred actions

## CI/CD

### GitHub Secrets Required
| Secret | Source |
|--------|--------|
| `ESOUI_API_KEY` | https://www.esoui.com/downloads/filecpl.php?action=apitokens |
| `ESOUI_ADDON_ID` | From ESOUI URL after first manual upload |

### Release Workflow
Create `.github/workflows/release.yml` for automated ESOUI publishing on tagged releases using `m00nyONE/esoui-upload@v2`.

## Luacheck

Use `.luacheckrc` in repo root with:
- `std = "lua51"`
- ESO globals: `EVENT_MANAGER`, `ZO_SavedVars`, `GetGroupSize`, etc.
- Exclude `libs/*`

## Best Practices

- Semantic versioning (sync manifest with git tags)
- Throttle group scan events (use zo_callLater)
- Cache zone checks to avoid repeated API calls
- Use savedvars for user thresholds (min CP, required sets)
