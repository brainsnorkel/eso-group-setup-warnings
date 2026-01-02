-- Group Setup Warnings
-- Detects duplicate Champion Points and healing sets in trials

GroupSetupWarnings = {}
local GSW = GroupSetupWarnings

local ADDON_NAME = "GroupSetupWarnings"

-- Ability IDs to track
local TRACKED_ABILITIES = {
    [156008] = { name = "Enlivening Overflow", type = "CP", settingKey = "enlivening" },
    [156019] = { name = "From the Brink", type = "CP", settingKey = "fromTheBrink" },
    [66902]  = { name = "Major Courage", type = "Buff", settingKey = "majorCourage" },
    [135920] = { name = "Roaring Opportunist", type = "Set", settingKey = "roaringOpportunist" },
    [117110] = { name = "Symphony of Blades", type = "Set", settingKey = "symphonyOfBlades" },
    [188456] = { name = "Ozezan's Inferno", type = "Set", settingKey = "ozezanInferno" },
}

-- Default settings
local DEFAULT_SETTINGS = {
    enabled = true,
    showIndicator = true,
    indicatorLocked = true,
    indicatorX = nil,
    indicatorY = nil,
    fontSize = 16,
    showAsIcon = false,
    -- Detection rules
    enlivening = true,
    fromTheBrink = true,
    majorCourage = true,
    roaringOpportunist = true,
    symphonyOfBlades = true,
    ozezanInferno = true,
}

-- State
local savedVars = nil
local isInTrial = false
local isInCombat = false
local fightDetections = {} -- { abilityId = { playerName = true, ... }, ... }
local warnedThisFight = {} -- { abilityId = true, ... }

-- UI Elements
local indicator = nil
local indicatorLabel = nil
local indicatorIcon = nil

--------------------------------------------------------------------------------
-- Utility Functions
--------------------------------------------------------------------------------

local function GetPlayerNameFromUnitId(unitId)
    if unitId and unitId > 0 then
        local unitTag = GetUnitTagById(unitId)
        if unitTag and unitTag ~= "" then
            return GetUnitName(unitTag)
        end
    end
    return nil
end

local function OutputWarning(message)
    -- Use system channel for visibility
    CHAT_SYSTEM:AddMessage("|cFF6600[GSW]|r " .. message)
end

local function OutputInfo(message)
    CHAT_SYSTEM:AddMessage("|c00CCFF[GSW]|r " .. message)
end

--------------------------------------------------------------------------------
-- Detection Logic
--------------------------------------------------------------------------------

local function ResetFightTracking()
    fightDetections = {}
    warnedThisFight = {}
end

local function CheckForDuplicates(abilityId)
    local detection = fightDetections[abilityId]
    if not detection then return end

    -- Count unique players
    local players = {}
    for playerName in pairs(detection) do
        table.insert(players, playerName)
    end

    if #players >= 2 and not warnedThisFight[abilityId] then
        warnedThisFight[abilityId] = true
        local abilityInfo = TRACKED_ABILITIES[abilityId]
        local playerList = table.concat(players, ", ")
        OutputWarning(string.format("Duplicate %s (%s) detected: %s",
            abilityInfo.name, abilityInfo.type, playerList))
    end
end

local function RecordAbilityUse(abilityId, playerName)
    if not playerName or playerName == "" then return end

    -- Initialize tracking table for this ability if needed
    if not fightDetections[abilityId] then
        fightDetections[abilityId] = {}
    end

    -- Record this player using the ability (if not already recorded)
    if not fightDetections[abilityId][playerName] then
        fightDetections[abilityId][playerName] = true
        CheckForDuplicates(abilityId)
    end
end

--------------------------------------------------------------------------------
-- Event Handlers
--------------------------------------------------------------------------------

local function OnCombatEvent(eventCode, result, isError, abilityName, abilityGraphic,
    abilityActionSlotType, sourceName, sourceType, targetName, targetType,
    hitValue, powerType, damageType, log, sourceUnitId, targetUnitId, abilityId)

    -- Only process if enabled and in trial
    if not savedVars.enabled or not isInTrial then return end

    -- Check if this ability is tracked
    local abilityInfo = TRACKED_ABILITIES[abilityId]
    if not abilityInfo then return end

    -- Check if this specific rule is enabled
    if not savedVars[abilityInfo.settingKey] then return end

    -- Get player name from source
    local playerName = GetPlayerNameFromUnitId(sourceUnitId)
    if not playerName then
        -- Fallback to sourceName if available
        playerName = zo_strformat("<<1>>", sourceName)
    end

    if playerName and playerName ~= "" then
        RecordAbilityUse(abilityId, playerName)
    end
end

local function OnEffectChanged(eventCode, changeType, effectSlot, effectName,
    unitTag, beginTime, endTime, stackCount, iconName, buffType, effectType,
    abilityType, statusEffectType, unitName, unitId, abilityId, sourceType)

    -- Only process buff gains
    if changeType ~= EFFECT_RESULT_GAINED then return end

    -- Only process if enabled and in trial
    if not savedVars.enabled or not isInTrial then return end

    -- Check if this ability is tracked
    local abilityInfo = TRACKED_ABILITIES[abilityId]
    if not abilityInfo then return end

    -- Check if this specific rule is enabled
    if not savedVars[abilityInfo.settingKey] then return end

    -- For effect changed, we need to determine who applied the buff
    -- The unitTag is who received the buff, but we want who applied it
    -- Unfortunately, EVENT_EFFECT_CHANGED doesn't always give us the source
    -- We'll use this primarily as a backup detection method
    local playerName = zo_strformat("<<1>>", unitName)
    if playerName and playerName ~= "" then
        RecordAbilityUse(abilityId, playerName)
    end
end

local function OnCombatStateChanged(eventCode, inCombat)
    local wasInCombat = isInCombat
    isInCombat = inCombat

    if inCombat and not wasInCombat then
        -- Entering combat - reset tracking for new fight
        ResetFightTracking()
    end
end

local function OnPlayerActivated()
    -- Check if we're in a trial
    isInTrial = IsUnitInRaid("player")
    GSW.UpdateIndicator()
end

local function OnRaidMemberJoined()
    isInTrial = IsUnitInRaid("player")
    GSW.UpdateIndicator()
end

local function OnRaidMemberLeft()
    isInTrial = IsUnitInRaid("player")
    GSW.UpdateIndicator()
end

--------------------------------------------------------------------------------
-- UI Functions
--------------------------------------------------------------------------------

function GSW.UpdateIndicator()
    if not indicator then return end

    -- Show indicator only if enabled AND in a trial
    local shouldShow = savedVars.enabled and savedVars.showIndicator and isInTrial

    indicator:SetHidden(not shouldShow)

    if shouldShow then
        -- Update font size
        local fontString = string.format("$(MEDIUM_FONT)|%d|soft-shadow-thin", savedVars.fontSize)
        indicatorLabel:SetFont(fontString)

        -- Toggle between icon and text mode
        if savedVars.showAsIcon then
            indicatorLabel:SetHidden(true)
            indicatorIcon:SetHidden(false)
        else
            indicatorLabel:SetHidden(false)
            indicatorIcon:SetHidden(true)
        end

        -- Update movability
        indicator:SetMovable(not savedVars.indicatorLocked)
        indicator:SetMouseEnabled(not savedVars.indicatorLocked)
    end
end

function GSW.OnIndicatorMoveStop()
    if not indicator or not savedVars then return end

    local _, _, _, _, offsetX, offsetY = indicator:GetAnchor(0)
    savedVars.indicatorX = offsetX
    savedVars.indicatorY = offsetY
end

local function RestoreIndicatorPosition()
    if not indicator or not savedVars then return end

    if savedVars.indicatorX and savedVars.indicatorY then
        indicator:ClearAnchors()
        indicator:SetAnchor(CENTER, GuiRoot, CENTER, savedVars.indicatorX, savedVars.indicatorY)
    end
end

local function InitializeUI()
    indicator = GroupSetupWarningsIndicator
    if indicator then
        indicatorLabel = indicator:GetNamedChild("Label")
        indicatorIcon = indicator:GetNamedChild("Icon")
        RestoreIndicatorPosition()
        GSW.UpdateIndicator()
    end
end

--------------------------------------------------------------------------------
-- Slash Commands
--------------------------------------------------------------------------------

local function HandleSlashCommand(args)
    local command = string.lower(args or "")

    if command == "" then
        -- Toggle
        savedVars.enabled = not savedVars.enabled
        local status = savedVars.enabled and "enabled" or "disabled"
        OutputInfo("Warnings " .. status)
        GSW.UpdateIndicator()

    elseif command == "on" then
        savedVars.enabled = true
        OutputInfo("Warnings enabled")
        GSW.UpdateIndicator()

    elseif command == "off" then
        savedVars.enabled = false
        OutputInfo("Warnings disabled")
        GSW.UpdateIndicator()

    elseif command == "status" then
        local status = savedVars.enabled and "enabled" or "disabled"
        local trialStatus = isInTrial and "in trial" or "not in trial"
        OutputInfo(string.format("Warnings: %s | %s", status, trialStatus))

    elseif command == "unlock" then
        savedVars.indicatorLocked = false
        OutputInfo("Indicator unlocked - drag to reposition")
        GSW.UpdateIndicator()

    elseif command == "lock" then
        savedVars.indicatorLocked = true
        OutputInfo("Indicator locked")
        GSW.UpdateIndicator()

    else
        OutputInfo("Commands: /gsw [on|off|status|unlock|lock]")
    end
end

--------------------------------------------------------------------------------
-- Event Registration
--------------------------------------------------------------------------------

local function RegisterEvents()
    local em = EVENT_MANAGER

    -- Combat events for each tracked ability
    for abilityId in pairs(TRACKED_ABILITIES) do
        local eventName = ADDON_NAME .. "_Combat_" .. abilityId
        em:RegisterForEvent(eventName, EVENT_COMBAT_EVENT, OnCombatEvent)
        em:AddFilterForEvent(eventName, EVENT_COMBAT_EVENT,
            REGISTER_FILTER_ABILITY_ID, abilityId,
            REGISTER_FILTER_IS_ERROR, false)
    end

    -- Effect changed events for buff detection
    for abilityId in pairs(TRACKED_ABILITIES) do
        local eventName = ADDON_NAME .. "_Effect_" .. abilityId
        em:RegisterForEvent(eventName, EVENT_EFFECT_CHANGED, OnEffectChanged)
        em:AddFilterForEvent(eventName, EVENT_EFFECT_CHANGED,
            REGISTER_FILTER_ABILITY_ID, abilityId)
    end

    -- Combat state tracking
    em:RegisterForEvent(ADDON_NAME, EVENT_PLAYER_COMBAT_STATE, OnCombatStateChanged)

    -- Zone/trial detection
    em:RegisterForEvent(ADDON_NAME, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
    em:RegisterForEvent(ADDON_NAME, EVENT_RAID_MEMBER_JOINED, OnRaidMemberJoined)
    em:RegisterForEvent(ADDON_NAME .. "_Left", EVENT_RAID_MEMBER_LEFT, OnRaidMemberLeft)
end

--------------------------------------------------------------------------------
-- Initialization
--------------------------------------------------------------------------------

local function OnAddonLoaded(eventCode, addonName)
    if addonName ~= ADDON_NAME then return end

    EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED)

    -- Initialize saved variables
    savedVars = ZO_SavedVars:NewAccountWide("GroupSetupWarningsSV", 1, nil, DEFAULT_SETTINGS)
    GSW.savedVars = savedVars

    -- Initialize UI
    InitializeUI()

    -- Register events
    RegisterEvents()

    -- Register slash command
    SLASH_COMMANDS["/gsw"] = HandleSlashCommand

    -- Check initial trial state
    isInTrial = IsUnitInRaid("player")
    GSW.UpdateIndicator()
end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddonLoaded)
