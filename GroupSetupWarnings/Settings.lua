-- Group Setup Warnings - Settings Panel
-- Requires LibAddonMenu-2.0

local GSW = GroupSetupWarnings
local LAM = LibAddonMenu2

-- Only initialize if LAM is available
if not LAM then return end

local panelData = {
    type = "panel",
    name = "Group Setup Warnings",
    displayName = "Group Setup Warnings",
    author = "brainsnorkel",
    version = "1.0.0",
    slashCommand = "/gswsettings",
    registerForRefresh = true,
    registerForDefaults = true,
}

local function CreateOptionsTable()
    local savedVars = GSW.savedVars

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
                GSW.UpdateIndicator()
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
                GSW.UpdateIndicator()
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
                GSW.UpdateIndicator()
            end,
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
                GSW.UpdateIndicator()
            end,
            width = "full",
            default = 16,
        },
        {
            type = "checkbox",
            name = "Show As Icon",
            tooltip = "Display an icon instead of text",
            getFunc = function() return savedVars.showAsIcon end,
            setFunc = function(value)
                savedVars.showAsIcon = value
                GSW.UpdateIndicator()
            end,
            width = "full",
            default = false,
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
            name = "From the Brink (CP)",
            tooltip = "Detect when multiple players are providing From the Brink healing",
            getFunc = function() return savedVars.fromTheBrink end,
            setFunc = function(value) savedVars.fromTheBrink = value end,
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
            name = "Roaring Opportunist (Set)",
            tooltip = "Detect when multiple players have Roaring Opportunist equipped",
            getFunc = function() return savedVars.roaringOpportunist end,
            setFunc = function(value) savedVars.roaringOpportunist = value end,
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

local function InitializeSettings()
    local panel = LAM:RegisterAddonPanel("GroupSetupWarningsOptions", panelData)
    LAM:RegisterOptionControls("GroupSetupWarningsOptions", CreateOptionsTable())
end

-- Wait for addon to fully load before initializing settings
local function OnPlayerActivated()
    EVENT_MANAGER:UnregisterForEvent("GSW_Settings", EVENT_PLAYER_ACTIVATED)
    -- Small delay to ensure savedVars is ready
    zo_callLater(InitializeSettings, 500)
end

EVENT_MANAGER:RegisterForEvent("GSW_Settings", EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
