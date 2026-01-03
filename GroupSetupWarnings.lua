-- Group Setup Warnings
-- Detects duplicate Champion Points and healing sets in trials

GroupSetupWarnings = {}
local GSW = GroupSetupWarnings

-- Addon name is the folder name in ESO
local ADDON_NAME = "GroupSetupWarnings"

-- Ability IDs to track
-- All abilities track the SOURCE (who applied/cast the buff)
-- sourceType 1 = player, we filter to only count player sources
local TRACKED_ABILITIES = {
    [156008] = { name = "Enlivening Overflow", type = "CP", settingKey = "enlivening" },
    [156012] = { name = "Enlivening Overflow", type = "CP", settingKey = "enlivening" },  -- Alternate ID
    [156019] = { name = "From the Brink", type = "CP", settingKey = "fromTheBrink" },
    [156020] = { name = "From the Brink", type = "CP", settingKey = "fromTheBrink" },  -- Alternate ID
    [66902]  = { name = "Major Courage", type = "Buff", settingKey = "majorCourage" },
    [109966] = { name = "Major Courage", type = "Buff", settingKey = "majorCourage" },  -- Alternate ID (Olorime/etc)
    [135920] = { name = "Roaring Opportunist", type = "Set", settingKey = "roaringOpportunist" },
    [117110] = { name = "Symphony of Blades", type = "Set", settingKey = "symphonyOfBlades" },
    [117111] = { name = "Symphony of Blades", type = "Set", settingKey = "symphonyOfBlades" },  -- Meridia's Favor buff
    [188456] = { name = "Ozezan's Inferno", type = "Set", settingKey = "ozezanInferno" },
    [61743]  = { name = "Major Breach", type = "Debuff", settingKey = "majorBreach", targetHostile = true },
    [17906]  = { name = "Crusher", type = "Enchant", settingKey = "crusher", targetHostile = true },
}

-- Addon version (keep in sync with manifest)
GSW.version = "1.4.0"

-- Default settings
local DEFAULT_SETTINGS = {
    enabled = true,
    showIndicator = true,
    indicatorLocked = true,
    indicatorX = nil,
    indicatorY = nil,
    fontSize = 16,
    showAsIcon = false,
    showInitMessage = true,  -- Show initialization message on load
    debugMode = false,       -- Show individual detections
    warnMissingCourage = true,  -- Warn if no Major Courage in fight
    warnMissingEnlivening = true,  -- Warn if no Enlivening Overflow in fight
    warnMissingBreach = true,  -- Warn if no Major Breach in fight
    warnMissingCrusher = true,  -- Warn if no Crusher in fight
    -- Detection rules (duplicate detection)
    enlivening = true,
    fromTheBrink = true,
    majorCourage = true,
    roaringOpportunist = true,
    symphonyOfBlades = true,
    ozezanInferno = true,
    majorBreach = true,  -- Detect Major Breach applications
    crusher = true,      -- Detect Crusher applications
}

-- State
local savedVars = nil
local isInTrial = false
local isInCombat = false
local fightDetections = {} -- { abilityId = { playerName = true, ... }, ... }
local warnedThisFight = {} -- { abilityId = true, ... }
local combatStartTime = 0  -- When combat started (for minimum fight duration check)

-- UI Elements
local indicator = nil
local indicatorLabel = nil
local indicatorIcon = nil

-- UpdateIndicator function - defined on GSW table for access from Settings.lua
function GSW.UpdateIndicator()
    if not indicator or not savedVars then return end

    -- Show indicator if: (enabled AND in trial) OR (unlocked for repositioning)
    local isActive = savedVars.enabled and isInTrial
    local isUnlocked = not savedVars.indicatorLocked
    -- Always show when unlocked (for repositioning), otherwise only when active
    local shouldShow = isUnlocked or (savedVars.showIndicator and isActive)

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
            -- Show "Not in trial" when unlocked but not active
            if isUnlocked and not isActive then
                indicatorLabel:SetText("Not in trial")
                indicatorLabel:SetColor(0.5, 0.5, 0.5, 1) -- Gray
            else
                indicatorLabel:SetText("GSW")
                indicatorLabel:SetColor(0, 1, 0, 1) -- Green
            end
        end

        -- Update movability
        indicator:SetMovable(isUnlocked)
        indicator:SetMouseEnabled(isUnlocked)
    end
end

--------------------------------------------------------------------------------
-- Utility Functions
--------------------------------------------------------------------------------

local function IsInGroup()
    -- Any group (2+ players)
    if GetGroupSize then
        return GetGroupSize() >= 2
    end
    return false
end

local function GetPlayerNameFromUnitId(unitId)
    if unitId and unitId > 0 and GetUnitTagByUnitId then
        local unitTag = GetUnitTagByUnitId(unitId)
        if unitTag and unitTag ~= "" then
            local name = GetUnitName(unitTag)
            -- Strip gender markers (^Fx, ^Mx) from name
            return zo_strformat("<<1>>", name)
        end
    end
    return nil
end

-- Logger (optional LibDebugLogger support)
local logger = nil

local function OutputWarning(message)
    CHAT_ROUTER:AddSystemMessage("|cFF6600[GSW]|r " .. message)
    if logger then logger:Warn(message) end
end

local function OutputInfo(message)
    CHAT_ROUTER:AddSystemMessage("|c00CCFF[GSW]|r " .. message)
    if logger then logger:Info(message) end
end

local function OutputDebug(message)
    if savedVars and savedVars.debugMode then
        CHAT_ROUTER:AddSystemMessage("|c888888[GSW Debug]|r " .. message)
    end
    if logger then logger:Debug(message) end
end

local function CheckTrialStatus()
    local wasInTrial = isInTrial
    isInTrial = IsInGroup()

    if savedVars and savedVars.enabled then
        -- Show activation message when entering group
        if isInTrial and not wasInTrial then
            OutputInfo("Duplicate detection active")
        -- Show deactivation message when leaving group
        elseif wasInTrial and not isInTrial then
            OutputInfo("Duplicate detection inactive")
        end
    end

    GSW.UpdateIndicator()
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

-- Helper to check if any ability with given settingKey was detected
local function HasDetectionForSettingKey(settingKey)
    for abilityId, info in pairs(TRACKED_ABILITIES) do
        if info.settingKey == settingKey and fightDetections[abilityId] then
            -- Check if there's at least one player recorded
            if next(fightDetections[abilityId]) then
                return true
            end
        end
    end
    return false
end

-- Minimum fight duration (in seconds) before warning about missing buffs
local MIN_FIGHT_DURATION = 10

local function CheckForMissingBuffs()
    if not savedVars or not savedVars.enabled or not isInTrial then return end

    -- Only warn if fight lasted at least MIN_FIGHT_DURATION seconds
    local fightDuration = GetGameTimeSeconds() - combatStartTime
    if fightDuration < MIN_FIGHT_DURATION then
        OutputDebug(string.format("Fight too short (%.1fs) - skipping missing buff check", fightDuration))
        return
    end

    -- Check for missing Major Courage
    if savedVars.warnMissingCourage then
        if not HasDetectionForSettingKey("majorCourage") and not warnedThisFight["missingCourage"] then
            warnedThisFight["missingCourage"] = true
            OutputWarning("No Major Courage detected this fight!")
        end
    end

    -- Check for missing Enlivening Overflow
    if savedVars.warnMissingEnlivening then
        if not HasDetectionForSettingKey("enlivening") and not warnedThisFight["missingEnlivening"] then
            warnedThisFight["missingEnlivening"] = true
            OutputWarning("No Enlivening Overflow detected this fight!")
        end
    end

    -- Check for missing Major Breach
    if savedVars.warnMissingBreach then
        if not HasDetectionForSettingKey("majorBreach") and not warnedThisFight["missingBreach"] then
            warnedThisFight["missingBreach"] = true
            OutputWarning("No Major Breach detected this fight!")
        end
    end

    -- Check for missing Crusher
    if savedVars.warnMissingCrusher then
        if not HasDetectionForSettingKey("crusher") and not warnedThisFight["missingCrusher"] then
            warnedThisFight["missingCrusher"] = true
            OutputWarning("No Crusher detected this fight!")
        end
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
        local abilityInfo = TRACKED_ABILITIES[abilityId]
        OutputDebug(string.format("%s detected: %s", abilityInfo.name, playerName))
        CheckForDuplicates(abilityId)
    end
end

--------------------------------------------------------------------------------
-- Event Handlers
--------------------------------------------------------------------------------

-- Combat unit type constant (use ESO's global constant)

local function OnCombatEvent(eventCode, result, isError, abilityName, abilityGraphic,
    abilityActionSlotType, sourceName, sourceType, targetName, targetType,
    hitValue, powerType, damageType, log, sourceUnitId, targetUnitId, abilityId)

    -- Check if this ability is tracked
    local abilityInfo = TRACKED_ABILITIES[abilityId]
    if not abilityInfo then return end

    -- Only process if enabled and in group
    if not savedVars.enabled or not isInTrial then return end

    -- Check if this specific rule is enabled
    if not savedVars[abilityInfo.settingKey] then return end

    -- For debuffs that target hostiles, verify target is a monster (not player)
    if abilityInfo.targetHostile then
        -- Skip if debuff hit a player (we want hostile targets only)
        if targetType == COMBAT_UNIT_TYPE_PLAYER then
            return
        end
    end

    -- Debug: always log the sourceType to help diagnose
    OutputDebug(string.format("%s: sourceType=%d, source=%s, targetType=%d, target=%s",
        abilityName, sourceType, tostring(sourceName), targetType, tostring(targetName)))

    -- Get source player name (who applied/cast the buff)
    local playerName = GetPlayerNameFromUnitId(sourceUnitId)
    if not playerName then
        playerName = zo_strformat("<<1>>", sourceName)
    end

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
        combatStartTime = GetGameTimeSeconds()
    elseif wasInCombat and not inCombat then
        -- Leaving combat - check for missing buffs
        CheckForMissingBuffs()
    end
end

local function OnPlayerActivated()
    -- Check if we're in a trial zone or large group
    CheckTrialStatus()
end

local function OnRaidMemberJoined()
    -- Recheck trial status when group changes
    CheckTrialStatus()
end

local function OnRaidMemberLeft()
    -- Recheck trial status when group changes
    CheckTrialStatus()
end

local function OnGroupMemberLeft()
    -- Recheck status when regular group member leaves (including self)
    CheckTrialStatus()
end

--------------------------------------------------------------------------------
-- UI Functions
--------------------------------------------------------------------------------

function GSW.OnIndicatorMoveStop()
    if not indicator or not savedVars then return end

    -- Save the top-left position relative to screen
    local left = indicator:GetLeft()
    local top = indicator:GetTop()
    savedVars.indicatorX = left
    savedVars.indicatorY = top
end

local function RestoreIndicatorPosition()
    if not indicator or not savedVars then return end

    if savedVars.indicatorX and savedVars.indicatorY then
        indicator:ClearAnchors()
        indicator:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, savedVars.indicatorX, savedVars.indicatorY)
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

    elseif command == "debug" then
        savedVars.debugMode = not savedVars.debugMode
        local status = savedVars.debugMode and "enabled" or "disabled"
        OutputInfo("Debug mode " .. status)

    else
        OutputInfo("Commands: /gsw [on|off|status|unlock|lock|debug]")
    end
end

local function HandleTestCommand()
    CHAT_ROUTER:AddSystemMessage("|c00CCFF[GSW]|r === GSW Message Test ===")
    CHAT_ROUTER:AddSystemMessage("|c00CCFF[GSW]|r Group Setup Warnings loaded. Use /gsw for commands.")
    CHAT_ROUTER:AddSystemMessage("|c00CCFF[GSW]|r Duplicate detection active")
    CHAT_ROUTER:AddSystemMessage("|c00CCFF[GSW]|r Warnings enabled")
    CHAT_ROUTER:AddSystemMessage("|c00CCFF[GSW]|r Warnings disabled")
    CHAT_ROUTER:AddSystemMessage("|c00CCFF[GSW]|r Warnings: enabled | in trial")
    CHAT_ROUTER:AddSystemMessage("|c00CCFF[GSW]|r Warnings: disabled | not in trial")
    CHAT_ROUTER:AddSystemMessage("|c00CCFF[GSW]|r Indicator unlocked - drag to reposition")
    CHAT_ROUTER:AddSystemMessage("|c00CCFF[GSW]|r Indicator locked")
    CHAT_ROUTER:AddSystemMessage("|c00CCFF[GSW]|r Commands: /gsw [on|off|status|unlock|lock]")
    CHAT_ROUTER:AddSystemMessage("|cFF6600[GSW]|r Duplicate Enlivening Overflow (CP) detected: Player1, Player2")
    CHAT_ROUTER:AddSystemMessage("|cFF6600[GSW]|r Duplicate From the Brink (CP) detected: Player1, Player2")
    CHAT_ROUTER:AddSystemMessage("|cFF6600[GSW]|r Duplicate Major Courage (Buff) detected: Player1, Player2")
    CHAT_ROUTER:AddSystemMessage("|cFF6600[GSW]|r Duplicate Roaring Opportunist (Set) detected: Player1, Player2")
    CHAT_ROUTER:AddSystemMessage("|cFF6600[GSW]|r Duplicate Symphony of Blades (Set) detected: Player1, Player2")
    CHAT_ROUTER:AddSystemMessage("|cFF6600[GSW]|r Duplicate Ozezan's Inferno (Set) detected: Player1, Player2")
    CHAT_ROUTER:AddSystemMessage("|cFF6600[GSW]|r No Major Breach detected this fight!")
    CHAT_ROUTER:AddSystemMessage("|cFF6600[GSW]|r No Crusher detected this fight!")
    CHAT_ROUTER:AddSystemMessage("|c00CCFF[GSW]|r === End Test ===")
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

    -- NOTE: EVENT_EFFECT_CHANGED is disabled because it only tells us who
    -- RECEIVED the buff, not who applied it. This causes false positives
    -- (e.g., companions being detected as wearing Symphony of Blades).
    -- EVENT_COMBAT_EVENT correctly identifies the source player.

    -- Combat state tracking
    em:RegisterForEvent(ADDON_NAME, EVENT_PLAYER_COMBAT_STATE, OnCombatStateChanged)

    -- Zone/trial detection
    em:RegisterForEvent(ADDON_NAME, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
    em:RegisterForEvent(ADDON_NAME, EVENT_RAID_MEMBER_JOINED, OnRaidMemberJoined)
    em:RegisterForEvent(ADDON_NAME .. "_RaidLeft", EVENT_RAID_MEMBER_LEFT, OnRaidMemberLeft)
    em:RegisterForEvent(ADDON_NAME .. "_GroupLeft", EVENT_GROUP_MEMBER_LEFT, OnGroupMemberLeft)
end

--------------------------------------------------------------------------------
-- Initialization
--------------------------------------------------------------------------------

local function OnAddonLoaded(eventCode, addonName)
    if addonName ~= ADDON_NAME then return end

    EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED)

    -- Initialize logger if LibDebugLogger is available
    if LibDebugLogger then
        logger = LibDebugLogger(ADDON_NAME)
    end

    -- Initialize saved variables
    savedVars = ZO_SavedVars:NewAccountWide("GroupSetupWarningsSV", 1, nil, DEFAULT_SETTINGS)
    GSW.savedVars = savedVars

    -- Show initialization message if enabled
    if savedVars.showInitMessage then
        OutputInfo("Group Setup Warnings loaded. Use /gsw for commands.")
    end

    -- Initialize UI
    InitializeUI()

    -- Register events
    RegisterEvents()

    -- Register slash commands
    SLASH_COMMANDS["/gsw"] = HandleSlashCommand
    SLASH_COMMANDS["/gswtest"] = HandleTestCommand

    -- Initial trial state will be set on EVENT_PLAYER_ACTIVATED
    -- (IsUnitInRaid is not available at addon load time)
end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddonLoaded)
