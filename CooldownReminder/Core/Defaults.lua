local _, NPR = ...

local function CopyColor(color)
    return {
        r = color.r,
        g = color.g,
        b = color.b,
        a = color.a,
    }
end

NPR.defaults = {
    version = NPR.version,
    ui = {
        window = {
            point = "CENTER",
            relativePoint = "CENTER",
            x = 0,
            y = 0,
            width = 1140,
            height = 360,
        },
        editor = {
            point = "CENTER",
            relativePoint = "CENTER",
            x = 0,
            y = 0,
            width = 560,
            height = 448,
        },
        runtimeAnchor = {
            point = "CENTER",
            relativePoint = "CENTER",
            x = 0,
            y = 180,
        },
        minimap = {
            hide = false,
            angle = 210,
        },
    },
    timeline = {
        selectedDungeonKey = "nexus_point_xenas",
        selectedEncounterKey = "kasreth",
        selectedEncounterByDungeon = {
            nexus_point_xenas = "kasreth",
        },
        zoom = 0.18,
        scroll = 0,
        showRelevantOnly = false,
        showDisabled = true,
        showDiagnostics = false,
        trackVisibility = {},
    },
    reminders = {},
    runtime = {
        soundChannel = "Master",
        activeEncounterKey = nil,
        selectedRole = "ALL",
    },
    debug = {
        enabled = false,
        armedBossKey = nil,
        observations = {},
        logs = {},
    },
}

NPR.soundOptions = {
    { key = "NONE", label = "None", soundKit = nil },
    { key = "RAID_WARNING", label = "Raid Warning", soundKit = SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959 },
    { key = "READY_CHECK", label = "Ready Check", soundKit = SOUNDKIT and SOUNDKIT.READY_CHECK or 8960 },
    { key = "LEVEL_UP", label = "Level Up", soundKit = SOUNDKIT and SOUNDKIT.UI_70_ARTIFACT_FORGE_TRAIT_FIRST_TRAIT or 5414 },
    { key = "MAP_PING", label = "Map Ping", soundKit = SOUNDKIT and SOUNDKIT.UI_MAP_WAYPOINT_CHAT_SHARE or 3175 },
}

NPR.importanceOptions = {
    LOW = {
        label = "Low",
        color = CopyColor({ r = 116 / 255, g = 180 / 255, b = 255 / 255, a = 1 }),
    },
    MEDIUM = {
        label = "Medium",
        color = CopyColor({ r = 0 / 255, g = 214 / 255, b = 143 / 255, a = 1 }),
    },
    HIGH = {
        label = "High",
        color = CopyColor({ r = 255 / 255, g = 91 / 255, b = 106 / 255, a = 1 }),
    },
}

NPR.roleOptions = {
    { key = "ALL", label = "All" },
    { key = "HEALER", label = "Healer" },
    { key = "TANK", label = "Tank" },
    { key = "DAMAGER", label = "DPS" },
}

function NPR:CreateDefaultReminder(encounterKey, eventKey, occurrence, offsetSeconds)
    return {
        id = self:GenerateID(),
        encounterKey = encounterKey,
        eventKey = eventKey,
        occurrence = occurrence or 1,
        offsetSeconds = offsetSeconds or 0,
        enabled = true,
        text = "",
        iconSpellID = nil,
        soundKey = "NONE",
        importance = "MEDIUM",
        durationSeconds = 6,
        roleScope = "ALL",
        updatedAt = time(),
    }
end
