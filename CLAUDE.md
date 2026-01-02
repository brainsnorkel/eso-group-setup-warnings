# ESO Group Setup Warnings

Addon that alerts when Champion Points or healing sets are unusual in ESO dungeons and trials.

## Project Structure

```
GroupSetupWarnings/
├── GroupSetupWarnings.txt    # Manifest (required)
├── GroupSetupWarnings.lua    # Main addon code
├── Settings.lua              # LAM settings panel (optional)
└── libs/                     # Bundled libraries
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

- **LibAddonMenu-2.0** — Settings menu (include in libs/)
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
