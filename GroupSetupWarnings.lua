-- Group Setup Warnings
-- Detects duplicate Champion Points and healing sets in trials

GroupSetupWarnings = {}
local GSW = GroupSetupWarnings

-- Addon name is the folder name in ESO
local ADDON_NAME = "GroupSetupWarnings"

-- Mapping from settingKey to corresponding missing buff warning key (if any)
local MISSING_BUFF_SETTINGS = {
    majorCourage = "warnMissingCourage",
    enlivening = "warnMissingEnlivening",
    frostCloak = "warnMissingFrostCloak",
}

-- Ability IDs to track
-- All abilities track the SOURCE (who applied/cast the buff)
-- sourceType 1 = player, we filter to only count player sources
local TRACKED_ABILITIES = {
    [156008] = { name = "Enlivening Overflow", type = "CP", settingKey = "enlivening" },
    [156012] = { name = "Enlivening Overflow", type = "CP", settingKey = "enlivening" },  -- Alternate ID
    [66902]  = { name = "Major Courage", type = "Buff", settingKey = "majorCourage" },
    [109966] = { name = "Major Courage", type = "Buff", settingKey = "majorCourage" },  -- Alternate ID (Olorime/etc)
    [88758]  = { name = "Major Resolve (Frost Cloak)", type = "Skill", settingKey = "frostCloak" },
    [117110] = { name = "Symphony of Blades", type = "Set", settingKey = "symphonyOfBlades" },
    [117111] = { name = "Symphony of Blades", type = "Set", settingKey = "symphonyOfBlades" },  -- Meridia's Favor buff
    [188456] = { name = "Ozezan's Inferno", type = "Set", settingKey = "ozezanInferno" },
    [61771]  = { name = "Powerful Assault", type = "Set", settingKey = "powerfulAssault" },
    [61763]  = { name = "Powerful Assault", type = "Set", settingKey = "powerfulAssault" },  -- Alternate ID
}

-- Addon version (keep in sync with manifest)
GSW.version = "1.7.1"

-- Default settings
local DEFAULT_SETTINGS = {
    enabled = true,
    showInitMessage = true,  -- Show initialization message on load
    debugMode = false,       -- Show individual detections
    -- Results window settings
    showResultsWindow = true,  -- Show results window after combat
    resultsWindowX = nil,
    resultsWindowY = nil,
    resultsWindowWidth = 400,
    resultsWindowHeight = 300,
    -- Missing buff warnings: Small (2-4) and Large (5+) toggles
    -- If both are off, warning is disabled for that buff
    warnMissingCourageSmall = false,
    warnMissingCourageLarge = true,
    warnMissingEnliveningSmall = false,
    warnMissingEnliveningLarge = true,
    warnMissingFrostCloakSmall = false,
    warnMissingFrostCloakLarge = true,
    -- Duplicate detection: Small (2-4) and Large (5+) toggles
    -- If both are off, detection is disabled for that ability
    enliveningSmall = true,
    enliveningLarge = true,
    majorCourageSmall = true,
    majorCourageLarge = true,
    frostCloakSmall = false,  -- Off for small groups by default
    frostCloakLarge = true,
    symphonyOfBladesSmall = true,
    symphonyOfBladesLarge = true,
    ozezanInfernoSmall = true,
    ozezanInfernoLarge = true,
    powerfulAssaultSmall = true,
    powerfulAssaultLarge = true,
}

-- State
local savedVars = nil
local isInTrial = false
local isInCombat = false
local isPaused = false  -- Temporary pause (resets on zone change)
local fightDetections = {} -- { abilityId = { playerName = true, ... }, ... }
local warnedThisFight = {} -- { abilityId = true, ... }
local combatStartTime = 0  -- When combat started (for minimum fight duration check)

-- UI Elements
local resultsWindow = nil
local resultsContentLabel = nil

-- Results tracking (for displaying in window)
local combatResults = {
    duplicates = {},  -- { {name="...", type="...", players={...}}, ... }
    missing = {},     -- { "Missing Major Courage", "Missing Enlivening Overflow", ... }
}


--------------------------------------------------------------------------------
-- Utility Functions
--------------------------------------------------------------------------------

-- Returns current group size category: "none", "small" (2-4), or "large" (5+)
local function GetGroupSizeCategory()
    if not GetGroupSize then return "none" end

    local groupSize = GetGroupSize()
    if groupSize >= 5 then
        return "large"
    elseif groupSize >= 2 then
        return "small"
    else
        return "none"
    end
end

-- Expose for external use
GSW.GetGroupSizeCategory = GetGroupSizeCategory

local function IsInGroup()
    return GetGroupSizeCategory() ~= "none"
end

-- Check if a detection rule is enabled for the current group size
-- settingKey: base setting name (e.g., "enlivening", "majorCourage")
local function IsDetectionEnabledForGroupSize(settingKey)
    if not savedVars then return false end

    local category = GetGroupSizeCategory()
    if category == "none" then return false end

    -- Check group-size-specific setting
    if category == "small" then
        local smallKey = settingKey .. "Small"
        return savedVars[smallKey] == true
    else  -- large
        local largeKey = settingKey .. "Large"
        return savedVars[largeKey] == true
    end
end

local function GetPlayerDisplayName(unitId)
    -- Returns "CharacterName (@Handle)" format
    if unitId and unitId > 0 and GetUnitTagByUnitId then
        local unitTag = GetUnitTagByUnitId(unitId)
        if unitTag and unitTag ~= "" then
            local charName = GetUnitName(unitTag)
            local displayName = GetUnitDisplayName(unitTag)
            -- Strip gender markers (^Fx, ^Mx) from character name
            charName = zo_strformat("<<1>>", charName)
            if displayName and displayName ~= "" then
                return string.format("%s (%s)", charName, displayName)
            end
            return charName
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
end

-- Expose for Settings.lua to call when group size requirement changes
GSW.CheckTrialStatus = CheckTrialStatus

--------------------------------------------------------------------------------
-- Detection Logic
--------------------------------------------------------------------------------

local function ResetFightTracking()
    fightDetections = {}
    warnedThisFight = {}
    combatResults.duplicates = {}
    combatResults.missing = {}
end

local function CheckForDuplicates(abilityId)
    local abilityInfo = TRACKED_ABILITIES[abilityId]
    if not abilityInfo then return end

    -- Use settingKey to track warnings (so multiple IDs for same ability share warning state)
    local settingKey = abilityInfo.settingKey
    if warnedThisFight[settingKey] then return end

    -- Only warn about duplicates if duplicate detection is enabled
    -- (Recording may have happened for missing buff warning purposes)
    if not IsDetectionEnabledForGroupSize(settingKey) then return end

    -- Count unique players across ALL ability IDs with the same settingKey
    local players = {}
    local seenPlayers = {}
    for id, info in pairs(TRACKED_ABILITIES) do
        if info.settingKey == settingKey and fightDetections[id] then
            for playerName in pairs(fightDetections[id]) do
                if not seenPlayers[playerName] then
                    seenPlayers[playerName] = true
                    table.insert(players, playerName)
                end
            end
        end
    end

    if #players >= 2 then
        warnedThisFight[settingKey] = true
        local playerList = table.concat(players, ", ")
        OutputWarning(string.format("Duplicate %s (%s) detected: %s",
            abilityInfo.name, abilityInfo.type, playerList))

        -- Store for results window
        table.insert(combatResults.duplicates, {
            name = abilityInfo.name,
            type = abilityInfo.type,
            players = players
        })
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
    if not savedVars or not savedVars.enabled or isPaused or not isInTrial then return end

    -- Only warn if fight lasted at least MIN_FIGHT_DURATION seconds
    local fightDuration = GetGameTimeSeconds() - combatStartTime
    if fightDuration < MIN_FIGHT_DURATION then
        OutputDebug(string.format("Fight too short (%.1fs) - skipping missing buff check", fightDuration))
        return
    end

    -- Check for missing Major Courage
    if IsDetectionEnabledForGroupSize("warnMissingCourage") then
        if not HasDetectionForSettingKey("majorCourage") and not warnedThisFight["missingCourage"] then
            warnedThisFight["missingCourage"] = true
            local msg = "No Major Courage detected this fight!"
            OutputWarning(msg)
            table.insert(combatResults.missing, "Major Courage")
        end
    end

    -- Check for missing Enlivening Overflow
    if IsDetectionEnabledForGroupSize("warnMissingEnlivening") then
        if not HasDetectionForSettingKey("enlivening") and not warnedThisFight["missingEnlivening"] then
            warnedThisFight["missingEnlivening"] = true
            local msg = "No Enlivening Overflow detected this fight!"
            OutputWarning(msg)
            table.insert(combatResults.missing, "Enlivening Overflow")
        end
    end

    -- Check for missing Frost Cloak (Major Resolve)
    if IsDetectionEnabledForGroupSize("warnMissingFrostCloak") then
        if not HasDetectionForSettingKey("frostCloak") and not warnedThisFight["missingFrostCloak"] then
            warnedThisFight["missingFrostCloak"] = true
            local msg = "No Frost Cloak (Major Resolve) detected this fight!"
            OutputWarning(msg)
            table.insert(combatResults.missing, "Frost Cloak (Major Resolve)")
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

    -- Only process if enabled, not paused, and in group
    if not savedVars.enabled or isPaused or not isInTrial then return end

    -- Check if either duplicate detection OR missing buff warning is enabled
    -- (We need to record detections for missing buff warnings even if duplicate detection is off)
    local isDetectionEnabled = IsDetectionEnabledForGroupSize(abilityInfo.settingKey)
    local missingBuffKey = MISSING_BUFF_SETTINGS[abilityInfo.settingKey]
    local isMissingWarningEnabled = missingBuffKey and IsDetectionEnabledForGroupSize(missingBuffKey)
    if not isDetectionEnabled and not isMissingWarningEnabled then return end

    -- Debug: always log the sourceType to help diagnose
    OutputDebug(string.format("%s: sourceType=%d, source=%s, targetType=%d, target=%s",
        abilityName, sourceType, tostring(sourceName), targetType, tostring(targetName)))

    -- Get source player name (who applied/cast the buff)
    local playerName = GetPlayerDisplayName(sourceUnitId)
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
        -- Leaving combat - check for missing buffs and show results
        CheckForMissingBuffs()

        -- Show results window if there were any issues
        if savedVars and savedVars.enabled and not isPaused and isInTrial then
            GSW.ShowResultsWindow()
        end
    end
end

local function OnPlayerActivated()
    -- Reset pause state on zone change (as per user request)
    if isPaused then
        isPaused = false
        OutputInfo("Pause reset (zone change)")
    end
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

-- Results Window Functions
function GSW.ShowResultsWindow()
    if not resultsWindow or not savedVars then return end
    if not savedVars.showResultsWindow then return end

    -- Build results text
    local lines = {}

    if #combatResults.duplicates > 0 then
        table.insert(lines, "|cFF6600DUPLICATE DETECTIONS:|r")
        for _, dup in ipairs(combatResults.duplicates) do
            local playerList = table.concat(dup.players, ", ")
            table.insert(lines, string.format("  • %s (%s): %s", dup.name, dup.type, playerList))
        end
    end

    if #combatResults.missing > 0 then
        if #lines > 0 then
            table.insert(lines, "")  -- Blank line separator
        end
        table.insert(lines, "|cFF6600MISSING BUFFS:|r")
        for _, missing in ipairs(combatResults.missing) do
            table.insert(lines, string.format("  • %s", missing))
        end
    end

    if #lines == 0 then
        -- No issues detected - don't show window
        return
    end

    local resultsText = table.concat(lines, "\n")
    resultsContentLabel:SetText(resultsText)

    resultsWindow:SetHidden(false)
end

function GSW.ShowResultsWindowForPositioning()
    if not resultsWindow or not resultsContentLabel or not savedVars then return end

    -- Build status text
    local lines = {}

    -- Addon status
    local statusColor = savedVars.enabled and "|c00FF00" or "|cFF0000"
    local statusText = savedVars.enabled and "ENABLED" or "DISABLED"
    table.insert(lines, string.format("Addon Status: %s%s|r", statusColor, statusText))
    table.insert(lines, "")

    -- Group status
    local groupCategory = GetGroupSizeCategory()
    if groupCategory == "none" then
        table.insert(lines, "|c888888Not in a group|r")
    elseif groupCategory == "small" then
        table.insert(lines, "|c00CCFFIn small group (2-4 players)|r")
    else
        table.insert(lines, "|c00CCFFIn large group (5+ players)|r")
    end
    table.insert(lines, "")

    -- Pause status
    if isPaused then
        table.insert(lines, "|cFF6600Detection PAUSED (until zone change)|r")
        table.insert(lines, "")
    end

    -- Instructions
    table.insert(lines, "|cFFFFFFYou can now:|r")
    table.insert(lines, "  • Drag the title bar to move this window")
    table.insert(lines, "  • Drag the bottom-right corner to resize")
    table.insert(lines, "  • Close when done positioning")
    table.insert(lines, "")
    table.insert(lines, "|c888888This window will appear after combat")
    table.insert(lines, "when duplicates or missing buffs are detected.|r")

    local positioningText = table.concat(lines, "\n")
    resultsContentLabel:SetText(positioningText)

    resultsWindow:SetHidden(false)
end

function GSW.HideResultsWindow()
    if resultsWindow then
        resultsWindow:SetHidden(true)
    end
end

function GSW.OnResultsWindowMoveStop()
    if not resultsWindow or not savedVars then return end

    local left = resultsWindow:GetLeft()
    local top = resultsWindow:GetTop()
    savedVars.resultsWindowX = left
    savedVars.resultsWindowY = top
end

function GSW.OnResultsWindowResizeStop()
    if not resultsWindow or not savedVars then return end

    local width = resultsWindow:GetWidth()
    local height = resultsWindow:GetHeight()
    savedVars.resultsWindowWidth = width
    savedVars.resultsWindowHeight = height
end

local function RestoreResultsWindowPosition()
    if not resultsWindow or not savedVars then return end

    if savedVars.resultsWindowX and savedVars.resultsWindowY then
        resultsWindow:ClearAnchors()
        resultsWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, savedVars.resultsWindowX, savedVars.resultsWindowY)
    end

    if savedVars.resultsWindowWidth and savedVars.resultsWindowHeight then
        resultsWindow:SetDimensions(savedVars.resultsWindowWidth, savedVars.resultsWindowHeight)
    end
end

local function InitializeUI()
    resultsWindow = GroupSetupWarningsResultsWindow
    if resultsWindow then
        resultsContentLabel = resultsWindow:GetNamedChild("ContentLabel")
        RestoreResultsWindowPosition()
    end
end

--------------------------------------------------------------------------------
-- Pause Toggle
--------------------------------------------------------------------------------

function GSW.TogglePause()
    isPaused = not isPaused
    local status = isPaused and "paused" or "resumed"
    OutputInfo("Detection " .. status .. (isPaused and " (until zone change)" or ""))
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

    elseif command == "on" then
        savedVars.enabled = true
        OutputInfo("Warnings enabled")

    elseif command == "off" then
        savedVars.enabled = false
        OutputInfo("Warnings disabled")

    elseif command == "status" then
        GSW.ShowResultsWindowForPositioning()

    elseif command == "pause" then
        GSW.TogglePause()

    elseif command == "debug" then
        savedVars.debugMode = not savedVars.debugMode
        local status = savedVars.debugMode and "enabled" or "disabled"
        OutputInfo("Debug mode " .. status)

    else
        OutputInfo("Commands: /gsw [on|off|status|pause|debug]")
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
    CHAT_ROUTER:AddSystemMessage("|cFF6600[GSW]|r Duplicate Major Courage (Buff) detected: Player1, Player2")
    CHAT_ROUTER:AddSystemMessage("|cFF6600[GSW]|r Duplicate Symphony of Blades (Set) detected: Player1, Player2")
    CHAT_ROUTER:AddSystemMessage("|cFF6600[GSW]|r Duplicate Ozezan's Inferno (Set) detected: Player1, Player2")
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
