-- Group Setup Warnings - Settings Panel
-- Requires LibAddonMenu-2.0

local GSW = GroupSetupWarnings

local function GetPanelData()
    return {
        type = "panel",
        name = "Group Setup Warnings",
        displayName = "Group Setup Warnings",
        author = "brainsnorkel",
        version = GSW.version or "1.5.0",
        website = "https://github.com/brainsnorkel/GroupSetupWarnings",
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
            tooltip = "Enable or disable all detection. When disabled, no warnings are shown.",
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
            name = "Show Initialization Message",
            tooltip = "Show 'Group Setup Warnings loaded' message in chat when you log in or reload UI.",
            getFunc = function() return savedVars.showInitMessage end,
            setFunc = function(value) savedVars.showInitMessage = value end,
            width = "full",
            default = true,
        },
        {
            type = "checkbox",
            name = "Show Results Window",
            tooltip = "Display a results window after combat showing detected duplicates and missing buffs.",
            getFunc = function() return savedVars.showResultsWindow end,
            setFunc = function(value) savedVars.showResultsWindow = value end,
            width = "full",
            default = true,
        },
        {
            type = "button",
            name = "Show Window (for positioning)",
            tooltip = "Click to display the results window so you can move and resize it. " ..
                "The window will show your current addon status.",
            func = function()
                if GSW.ShowResultsWindowForPositioning then
                    GSW.ShowResultsWindowForPositioning()
                end
            end,
            width = "half",
        },

        -- Detection Rules Header
        {
            type = "header",
            name = "Duplicate Detection",
            width = "full",
        },
        {
            type = "description",
            text = "Warn when 2+ players trigger the same ability. " ..
                "Enable for Small (2-4) and/or Large (5+) groups.",
            width = "full",
        },

        -- Enlivening Overflow
        {
            type = "checkbox",
            name = "Enlivening Overflow (CP) - Small",
            tooltip = "Detect duplicate Enlivening Overflow in small groups (2-4 players).",
            getFunc = function() return savedVars.enliveningSmall end,
            setFunc = function(value) savedVars.enliveningSmall = value end,
            width = "half",
            default = true,
        },
        {
            type = "checkbox",
            name = "Enlivening Overflow (CP) - Large",
            tooltip = "Detect duplicate Enlivening Overflow in large groups (5+ players).",
            getFunc = function() return savedVars.enliveningLarge end,
            setFunc = function(value) savedVars.enliveningLarge = value end,
            width = "half",
            default = true,
        },

        -- Major Courage
        {
            type = "checkbox",
            name = "Major Courage (Buff) - Small",
            tooltip = "Detect duplicate Major Courage in small groups (2-4 players).",
            getFunc = function() return savedVars.majorCourageSmall end,
            setFunc = function(value) savedVars.majorCourageSmall = value end,
            width = "half",
            default = true,
        },
        {
            type = "checkbox",
            name = "Major Courage (Buff) - Large",
            tooltip = "Detect duplicate Major Courage in large groups (5+ players).",
            getFunc = function() return savedVars.majorCourageLarge end,
            setFunc = function(value) savedVars.majorCourageLarge = value end,
            width = "half",
            default = true,
        },

        -- Frost Cloak
        {
            type = "checkbox",
            name = "Frost Cloak (Skill) - Small",
            tooltip = "Detect duplicate Frost Cloak in small groups (2-4 players).",
            getFunc = function() return savedVars.frostCloakSmall end,
            setFunc = function(value) savedVars.frostCloakSmall = value end,
            width = "half",
            default = false,
        },
        {
            type = "checkbox",
            name = "Frost Cloak (Skill) - Large",
            tooltip = "Detect duplicate Frost Cloak in large groups (5+ players).",
            getFunc = function() return savedVars.frostCloakLarge end,
            setFunc = function(value) savedVars.frostCloakLarge = value end,
            width = "half",
            default = true,
        },

        -- Symphony of Blades
        {
            type = "checkbox",
            name = "Symphony of Blades (Set) - Small",
            tooltip = "Detect duplicate Symphony of Blades in small groups (2-4 players).",
            getFunc = function() return savedVars.symphonyOfBladesSmall end,
            setFunc = function(value) savedVars.symphonyOfBladesSmall = value end,
            width = "half",
            default = true,
        },
        {
            type = "checkbox",
            name = "Symphony of Blades (Set) - Large",
            tooltip = "Detect duplicate Symphony of Blades in large groups (5+ players).",
            getFunc = function() return savedVars.symphonyOfBladesLarge end,
            setFunc = function(value) savedVars.symphonyOfBladesLarge = value end,
            width = "half",
            default = true,
        },

        -- Ozezan's Inferno
        {
            type = "checkbox",
            name = "Ozezan's Inferno (Set) - Small",
            tooltip = "Detect duplicate Ozezan's Inferno in small groups (2-4 players).",
            getFunc = function() return savedVars.ozezanInfernoSmall end,
            setFunc = function(value) savedVars.ozezanInfernoSmall = value end,
            width = "half",
            default = true,
        },
        {
            type = "checkbox",
            name = "Ozezan's Inferno (Set) - Large",
            tooltip = "Detect duplicate Ozezan's Inferno in large groups (5+ players).",
            getFunc = function() return savedVars.ozezanInfernoLarge end,
            setFunc = function(value) savedVars.ozezanInfernoLarge = value end,
            width = "half",
            default = true,
        },

        -- Powerful Assault
        {
            type = "checkbox",
            name = "Powerful Assault (Set) - Small",
            tooltip = "Detect duplicate Powerful Assault in small groups (2-4 players).",
            getFunc = function() return savedVars.powerfulAssaultSmall end,
            setFunc = function(value) savedVars.powerfulAssaultSmall = value end,
            width = "half",
            default = true,
        },
        {
            type = "checkbox",
            name = "Powerful Assault (Set) - Large",
            tooltip = "Detect duplicate Powerful Assault in large groups (5+ players).",
            getFunc = function() return savedVars.powerfulAssaultLarge end,
            setFunc = function(value) savedVars.powerfulAssaultLarge = value end,
            width = "half",
            default = true,
        },

        -- Missing Buff Warnings Header
        {
            type = "header",
            name = "Missing Buff Warnings",
            width = "full",
        },
        {
            type = "description",
            text = "Warn at end of fights (10+ sec) if buffs not detected. " ..
                "Enable for Small (2-4) and/or Large (5+) groups.",
            width = "full",
        },

        -- Missing Major Courage
        {
            type = "checkbox",
            name = "Missing Major Courage - Small",
            tooltip = "Warn if Major Courage not detected in small groups (2-4 players).",
            getFunc = function() return savedVars.warnMissingCourageSmall end,
            setFunc = function(value) savedVars.warnMissingCourageSmall = value end,
            width = "half",
            default = false,
        },
        {
            type = "checkbox",
            name = "Missing Major Courage - Large",
            tooltip = "Warn if Major Courage not detected in large groups (5+ players).",
            getFunc = function() return savedVars.warnMissingCourageLarge end,
            setFunc = function(value) savedVars.warnMissingCourageLarge = value end,
            width = "half",
            default = true,
        },

        -- Missing Enlivening Overflow
        {
            type = "checkbox",
            name = "Missing Enlivening Overflow - Small",
            tooltip = "Warn if Enlivening Overflow not detected in small groups (2-4 players).",
            getFunc = function() return savedVars.warnMissingEnliveningSmall end,
            setFunc = function(value) savedVars.warnMissingEnliveningSmall = value end,
            width = "half",
            default = false,
        },
        {
            type = "checkbox",
            name = "Missing Enlivening Overflow - Large",
            tooltip = "Warn if Enlivening Overflow not detected in large groups (5+ players).",
            getFunc = function() return savedVars.warnMissingEnliveningLarge end,
            setFunc = function(value) savedVars.warnMissingEnliveningLarge = value end,
            width = "half",
            default = true,
        },

        -- Missing Frost Cloak
        {
            type = "checkbox",
            name = "Missing Frost Cloak - Small",
            tooltip = "Warn if Frost Cloak not detected in small groups (2-4 players).",
            getFunc = function() return savedVars.warnMissingFrostCloakSmall end,
            setFunc = function(value) savedVars.warnMissingFrostCloakSmall = value end,
            width = "half",
            default = false,
        },
        {
            type = "checkbox",
            name = "Missing Frost Cloak - Large",
            tooltip = "Warn if Frost Cloak not detected in large groups (5+ players).",
            getFunc = function() return savedVars.warnMissingFrostCloakLarge end,
            setFunc = function(value) savedVars.warnMissingFrostCloakLarge = value end,
            width = "half",
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
