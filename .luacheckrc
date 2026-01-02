-- Luacheck configuration for ESO addon development
std = "lua51"

-- Exclude library directories
exclude_files = {
    "GroupSetupWarnings/libs/*",
    "libs/*",
}

-- ESO global functions and constants
globals = {
    -- Addon globals
    "GroupSetupWarnings",
    "GroupSetupWarningsIndicator",

    -- ESO Core
    "EVENT_MANAGER",
    "WINDOW_MANAGER",
    "CHAT_SYSTEM",
    "SLASH_COMMANDS",
    "GuiRoot",

    -- ESO SavedVars
    "ZO_SavedVars",

    -- ESO Events
    "EVENT_ADD_ON_LOADED",
    "EVENT_PLAYER_ACTIVATED",
    "EVENT_PLAYER_COMBAT_STATE",
    "EVENT_COMBAT_EVENT",
    "EVENT_EFFECT_CHANGED",
    "EVENT_RAID_MEMBER_JOINED",
    "EVENT_RAID_MEMBER_LEFT",

    -- ESO Combat/Effect constants
    "EFFECT_RESULT_GAINED",
    "REGISTER_FILTER_ABILITY_ID",
    "REGISTER_FILTER_IS_ERROR",
    "CENTER",

    -- ESO Functions
    "IsUnitInRaid",
    "GetUnitTagById",
    "GetUnitName",
    "GetCurrentZoneId",
    "zo_strformat",
    "zo_callLater",

    -- Libraries
    "LibAddonMenu2",
}

-- Read-only globals (don't warn about accessing these)
read_globals = {
    "string",
    "table",
    "pairs",
    "ipairs",
    "type",
    "tostring",
    "tonumber",
}

-- Max line length
max_line_length = 120

-- Ignore unused self parameter (common in ESO callbacks)
self = false

-- Ignore unused arguments (common in ESO event handlers)
unused_args = false