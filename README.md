# Group Setup Warnings

An ESO addon that warns when Champion Points, buffs, or healing sets are duplicated in your group. It also alerts you when important buffs are missing from a fight.

## How to Use

1. **Install**: Copy the `GroupSetupWarnings` folder to your ESO AddOns directory
2. **Join a group**: Detection activates automatically when you're in a group of 2+ players
3. **Fight**: The addon monitors combat and warns in chat when duplicates are detected
4. **Check chat**: Orange warnings appear when duplicates or missing buffs are found

### Slash Commands

| Command | Description |
|---------|-------------|
| `/gsw` | Toggle warnings on/off |
| `/gsw on` | Enable warnings |
| `/gsw off` | Disable warnings |
| `/gsw status` | Show current state and group status |
| `/gsw unlock` | Unlock indicator for repositioning |
| `/gsw lock` | Lock indicator position |
| `/gsw pause` | Toggle pause (temporary, resets on zone change) |
| `/gsw debug` | Toggle debug mode (shows individual detections) |

### Settings Panel

Open the addon settings via `/gswsettings` or the ESO settings menu (requires LibAddonMenu-2.0).

## What Gets Detected

### Duplicate Detection

The addon warns when **2+ players trigger the same ability** in a single fight. This catches wasted resources where buffs don't stack:

| Type | Name | Why It Matters |
|------|------|----------------|
| CP | Enlivening Overflow | Only one player needs this slotted; duplicates waste CP allocation |
| Buff | Major Courage | Multiple sources (Olorime, SPC) don't stack |
| Skill | Frost Cloak | Multiple Wardens casting this is redundant |
| Set | Symphony of Blades | Resource restore doesn't stack effectively |
| Set | Ozezan's Inferno | Damage bonus doesn't stack from multiple sets |
| Set | Powerful Assault | Weapon/Spell Damage buff doesn't stack from multiple sets |

### Missing Buff Warnings

At the end of fights lasting **10+ seconds**, the addon warns if important buffs were never detected:

| Buff | What It Means |
|------|---------------|
| Major Courage | No healer applied this group damage buff |
| Enlivening Overflow | No one has this healing CP slotted |
| Frost Cloak | No Warden provided Major Resolve |

## How Detection Works

The addon uses ESO's combat event system to track abilities:

1. **Combat starts**: Tracking tables reset for a fresh fight
2. **Ability fires**: When a tracked ability procs, the source player is recorded
3. **Duplicate check**: If 2+ different players trigger the same ability, a chat warning appears
4. **Combat ends**: Missing buff warnings are checked (if fight lasted 10+ seconds)

### Technical Details

- Monitors `EVENT_COMBAT_EVENT` filtered by specific ability IDs
- Tracks the **source** player (who applied the buff), not the recipient
- Only detects abilities when they actually proc—not just when equipped
- Limited to ~100m render distance (standard ESO limitation)

### Ability IDs Tracked

| Ability | IDs |
|---------|-----|
| Enlivening Overflow | 156008, 156012 |
| Major Courage | 66902, 109966 |
| Frost Cloak (Major Resolve) | 88758 |
| Symphony of Blades | 117110, 117111 |
| Ozezan's Inferno | 188456 |
| Powerful Assault | 61771, 61763 |

## Dependencies

- **LibAddonMenu-2.0** (optional) — Enables the settings panel. The addon works without it, but you'll need slash commands to configure it.
- **LibDebugLogger** (optional) — Enhanced debug logging

## Links

- [GitHub Repository](https://github.com/brainsnorkel/GroupSetupWarnings)
- [Report Issues](https://github.com/brainsnorkel/GroupSetupWarnings/issues)
