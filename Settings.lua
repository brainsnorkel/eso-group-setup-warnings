-- Group Setup Warnings - Settings Panel
-- Requires LibAddonMenu-2.0

local GSW = GroupSetupWarnings

local function GetPanelData()
    return {
        type = "panel",
        name = "Group Setup Warnings",
        displayName = "Group Setup Warnings",
        author = "brainsnorkel",
        version = GSW.version or "1.3.0",
        slashCommand = "/gswsettings",
        registerForRefresh = true,
        registerForDefaults = true,
    }
end

local function CreateOptionsTable()
    local savedVars = GSW.savedVars
    if not savedVars then
        return {}
    end

    local optionsTable = {
        -- General Settings Header
        {
            type = "header",
            name = "General Settings",
            width = "full",
        },
        {
            type = "checkbox",
            name = "Enable Addon",
            tooltip = "Master toggle for all duplicate detection warnings",
            getFunc = function() return savedVars.enabled end,
            setFunc = function(value)
                savedVars.enabled = value
                if GSW.UpdateIndicator then
                    GSW.UpdateIndicator()
                end
            end,
            width = "full",
            default = true,
        },
        {
            type = "checkbox",
            name = "Show Status Indicator",
            tooltip = "Show the on-screen indicator when in a trial",
            getFunc = function() return savedVars.showIndicator end,
            setFunc = function(value)
                savedVars.showIndicator = value
                if GSW.UpdateIndicator then
                    GSW.UpdateIndicator()
                end
            end,
            width = "full",
            default = true,
        },
        {
            type = "checkbox",
            name = "Lock Indicator Position",
            tooltip = "Lock the indicator so it cannot be moved",
            getFunc = function() return savedVars.indicatorLocked end,
            setFunc = function(value)
                savedVars.indicatorLocked = value
                if GSW.UpdateIndicator then
                    GSW.UpdateIndicator()
                end
            end,
            width = "full",
            default = true,
        },
        {
            type = "checkbox",
            name = "Show Initialization Message",
            tooltip = "Show a chat message when the addon loads",
            getFunc = function() return savedVars.showInitMessage end,
            setFunc = function(value) savedVars.showInitMessage = value end,
            width = "full",
            default = true,
        },

        -- Indicator Appearance Header
        {
            type = "header",
            name = "Indicator Appearance",
            width = "full",
        },
        {
            type = "slider",
            name = "Font Size",
            tooltip = "Size of the indicator text",
            min = 12,
            max = 24,
            step = 1,
            getFunc = function() return savedVars.fontSize end,
            setFunc = function(value)
                savedVars.fontSize = value
                if GSW.UpdateIndicator then
                    GSW.UpdateIndicator()
                end
            end,
            width = "full",
            default = 16,
        },

        -- Detection Rules Header
        {
            type = "header",
            name = "Detection Rules",
            width = "full",
        },
        {
            type = "description",
            text = "Enable or disable detection for specific abilities and sets.",
            width = "full",
        },
        {
            type = "checkbox",
            name = "Enlivening Overflow (CP)",
            tooltip = "Detect when multiple players have Enlivening Overflow slotted",
            getFunc = function() return savedVars.enlivening end,
            setFunc = function(value) savedVars.enlivening = value end,
            width = "full",
            default = true,
        },
        {
            type = "checkbox",
            name = "Major Courage (Buff)",
            tooltip = "Detect when multiple players are providing Major Courage",
            getFunc = function() return savedVars.majorCourage end,
            setFunc = function(value) savedVars.majorCourage = value end,
            width = "full",
            default = true,
        },
        {
            type = "checkbox",
            name = "Major Resolve - Frost Cloak (Skill)",
            tooltip = "Detect when multiple players are casting Frost Cloak for Major Resolve, and warn if missing",
            getFunc = function() return savedVars.frostCloak end,
            setFunc = function(value) savedVars.frostCloak = value end,
            width = "full",
            default = true,
        },
        {
            type = "checkbox",
            name = "Warn Missing Frost Cloak",
            tooltip = "Show warning if no Frost Cloak (Major Resolve) was cast during a fight",
            getFunc = function() return savedVars.warnMissingFrostCloak end,
            setFunc = function(value) savedVars.warnMissingFrostCloak = value end,
            width = "full",
            default = true,
        },
        {
            type = "checkbox",
            name = "Symphony of Blades (Set)",
            tooltip = "Detect when multiple players have Symphony of Blades equipped",
            getFunc = function() return savedVars.symphonyOfBlades end,
            setFunc = function(value) savedVars.symphonyOfBlades = value end,
            width = "full",
            default = true,
        },
        {
            type = "checkbox",
            name = "Ozezan's Inferno (Set)",
            tooltip = "Detect when multiple players have Ozezan's Inferno equipped",
            getFunc = function() return savedVars.ozezanInferno end,
            setFunc = function(value) savedVars.ozezanInferno = value end,
            width = "full",
            default = true,
        },
    }

    return optionsTable
end

local settingsInitialized = false

local function InitializeSettings()
    -- Prevent duplicate registration
    if settingsInitialized then
        return
    end

    local LAM = LibAddonMenu2
    if not LAM then
        return
    end

    if not GSW.savedVars then
        -- Wait a bit more for savedVars to be ready
        zo_callLater(InitializeSettings, 100)
        return
    end

    local panel = LAM:RegisterAddonPanel("GroupSetupWarningsOptions", GetPanelData())
    if panel then
        LAM:RegisterOptionControls("GroupSetupWarningsOptions", CreateOptionsTable())
        settingsInitialized = true
    end
end

-- Wait for addon to load and LibAddonMenu-2.0 to be available
local function TryInitializeSettings()
    -- Check if LibAddonMenu-2.0 is available
    if not LibAddonMenu2 then
        return false
    end

    -- Check if main addon is loaded and savedVars is initialized
    if not GSW or not GSW.savedVars then
        return false
    end

    InitializeSettings()
    return true
end

-- Initialize settings when either our addon or LibAddonMenu-2.0 loads
local function OnAddonLoaded(eventCode, addonName)
    -- Try to initialize when our addon or LAM loads
    if addonName == "GroupSetupWarnings" or addonName == "LibAddonMenu-2.0" then
        if TryInitializeSettings() then
            -- Successfully initialized, unregister
            EVENT_MANAGER:UnregisterForEvent("GSW_Settings", EVENT_ADD_ON_LOADED)
        elseif addonName == "GroupSetupWarnings" then
            -- Our addon loaded but LAM not ready yet, retry after delay
            zo_callLater(function()
                if TryInitializeSettings() then
                    EVENT_MANAGER:UnregisterForEvent("GSW_Settings", EVENT_ADD_ON_LOADED)
                end
            end, 100)
        end
    end
end

EVENT_MANAGER:RegisterForEvent("GSW_Settings", EVENT_ADD_ON_LOADED, OnAddonLoaded)
