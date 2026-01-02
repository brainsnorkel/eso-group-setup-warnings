# Group Setup Warnings

An ESO addon that alerts when Champion Points or healing sets are duplicated in your group.

## What It Detects

| Type | Name | Ability ID |
|------|------|------------|
| CP | Enlivening Overflow | 156008 |
| CP | From the Brink | 156019 |
| Buff | Major Courage | 66902 |
| Set | Roaring Opportunist | 135920 |
| Set | Symphony of Blades | 117110 |
| Set | Ozezan's Inferno | 188456 |

## How Detection Works

The addon monitors combat events to identify when multiple players are using the same buffs or set procs. Detection activates whenever you're in a group (2+ players).

### Detection Methods

**Combat Events** (primary): The addon registers for `EVENT_COMBAT_EVENT` filtered by each tracked ability ID. When a CP procs or a set triggers, the game fires a combat event containing the source player. This catches abilities like Enlivening Overflow, From the Brink, Symphony of Blades, and Ozezan's Inferno when they activate.

**Effect Events** (secondary): For buff applications, the addon also monitors `EVENT_EFFECT_CHANGED` to detect when buffs like Major Courage or Roaring Opportunist are applied.

### Per-Fight Tracking

1. When combat starts, the tracking tables reset
2. Each time a tracked ability fires, the source player is recorded
3. If 2+ different players trigger the same ability in the same fight, a warning appears in chat
4. Each ability only warns once per fight to avoid spam

### Limitations

- Can only detect abilities within render distance (~100m)
- Detection is reactive—abilities must proc/fire to be detected, not just equipped
- Effect events don't always identify who applied a buff, only who received it

## Slash Commands

| Command | Description |
|---------|-------------|
| `/gsw` | Toggle warnings on/off |
| `/gsw on` | Enable warnings |
| `/gsw off` | Disable warnings |
| `/gsw status` | Show current state |
| `/gsw unlock` | Unlock indicator for repositioning |
| `/gsw lock` | Lock indicator position |

## Dependencies

- **LibAddonMenu-2.0** (required) — Settings panel
