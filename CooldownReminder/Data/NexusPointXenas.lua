local _, NPR = ...

local function BuildEntries(firstSeenSec, cdSeriesSec, defaultDuration)
    local entries = {}
    if not firstSeenSec then
        return entries
    end

    local current = firstSeenSec
    entries[#entries + 1] = { time = current, duration = defaultDuration }

    if type(cdSeriesSec) == "table" then
        for _, delta in ipairs(cdSeriesSec) do
            current = current + delta
            entries[#entries + 1] = { time = current, duration = defaultDuration }
        end
    end

    return entries
end

local dungeon = NPR.Data and NPR.Data.dungeons and NPR.Data.dungeons.nexus_point_xenas
if dungeon then
    dungeon.encounterOrder = { "kasreth", "nysarra", "lothraxion" }
    dungeon.mappedBossCount = #dungeon.encounterOrder
    dungeon.source = {
        {
            name = "Method Ability Tracker",
            updated = "2026-04-11",
            url = "https://www.method.gg/guides/dungeons/nexus-point-xenas/ability-tracker",
        },
        {
            name = "wow.gg Guide",
            updated = "2026-04-11",
            url = "https://wow.gg/guides/nexuspointxenas",
        },
        {
            name = "Icy Veins Guide",
            updated = "2026-02-23",
            url = "https://www.icy-veins.com/wow/nexus-point-xenas-dungeon-guide",
        },
        {
            name = "EXBoss-v26.4.7.1900",
            updated = "local addon snapshot",
            url = "local:/Users/julienduhamel/Documents/HealerReminder/addon_examples/EXBoss-v26.4.7.1900/EXBossData/EncounterData.lua",
        },
    }
    dungeon.timerLimit = 30 * 60
end

local encounterData = {
        kasreth = {
            key = "kasreth",
            name = "Chief Corewright Kasreth",
            encounterID = 3328,
            confidence = "high",
            source = "Encounter ID cross-checked in EXBoss encounter data and Exwind encounter DB.",
            duration = 176,
            referenceSpellIDs = { 1250553, 1251626, 1251767, 1251772, 1257509, 1257512, 1257524, 1264040, 1264042, 1264048, 1265894, 1276485, 1282915 },
            referenceOnlySpells = {
                {
                    label = "Arcane Zap",
                    spellIDs = { 1250553, 1251626 },
                    note = "Current public guides consistently describe this as an interruptible Kasreth cast rather than a tank buster, but exact cadence and combat-log mapping still need live verification.",
                },
                {
                    label = "Unmapped Kasreth aliases",
                    spellIDs = { 1265894, 1276485, 1282915 },
                    note = "Present in Exwind local boss spell tables only. Kept as reference coverage until a live pull or log ties them to specific events.",
                },
            },
            events = {
                {
                    key = "reflux_charge",
                    spellID = 1251772,
                    eventSpellID = 1251767,
                    combatLogEvent = "SPELL_CAST_START",
                    combatLogSpellIDs = { 1251767 },
                    spellIDs = { 1251772, 1251767, 1257836 },
                    label = "Reflux Charge",
                    icon = "Interface\\Icons\\Ability_Mage_NetherWindPresence",
                    color = { r = 113 / 255, g = 228 / 255, b = 233 / 255, a = 1 },
                    defaultDuration = 8,
                    dangerPercent = 66,
                    source = "Method tracker + EXBoss encounter data + EXBoss private aura data.",
                    confidence = "high",
                    summary = "Targeted debuff that bends power lines and applies sustained damage until resolved.",
                    entries = BuildEntries(5.7, { 12.1, 12.1, 25.8 }, 8),
                },
                {
                    key = "corespark_detonation",
                    spellID = 1257509,
                    eventSpellID = 1257512,
                    combatLogEvent = "SPELL_CAST_START",
                    combatLogSpellIDs = { 1257512 },
                    spellIDs = { 1257509, 1257512, 1257524 },
                    label = "Corespark Detonation",
                    icon = "Interface\\Icons\\Ability_Monk_ForceSphere",
                    color = { r = 254 / 255, g = 56 / 255, b = 104 / 255, a = 1 },
                    defaultDuration = 5,
                    dangerPercent = 100,
                    source = "Method tracker + EXBoss encounter data.",
                    confidence = "high",
                    summary = "Primary burst event. Large-radius detonation with knockback.",
                    entries = BuildEntries(46.6, { 52.1, 53.3 }, 5),
                },
                {
                    key = "flux_collapse",
                    spellID = 1264048,
                    eventSpellID = 1264048,
                    combatLogEvent = "SPELL_CAST_SUCCESS",
                    spellIDs = { 1264048, 1264040, 1264042 },
                    label = "Flux Collapse",
                    icon = "Interface\\Icons\\Spell_Arcane_MindMastery",
                    color = { r = 123 / 255, g = 116 / 255, b = 255 / 255, a = 1 },
                    defaultDuration = 3,
                    dangerPercent = 74,
                    source = "Method tracker + EXBoss encounter data.",
                    confidence = "high",
                    summary = "Avoidable collapse zones that quickly choke remaining space.",
                    entries = BuildEntries(10.5, { 13.3, 29.5, 13.3, 15.8, 26.7, 14.6, 13.3, 26.7, 14.6, 15.7 }, 3),
                },
                {
                    key = "leyline_array",
                    spellID = 1251183,
                    eventSpellID = 1251183,
                    spellIDs = { 1251183 },
                    label = "Leyline Array",
                    icon = "Interface\\Icons\\Spell_Arcane_Arcane01",
                    color = { r = 255 / 255, g = 205 / 255, b = 77 / 255, a = 1 },
                    defaultDuration = 165,
                    dangerPercent = 42,
                    source = "Method tracker + EXBoss encounter data.",
                    confidence = "high",
                    summary = "Persistent arena beams that reshape movement for the rest of the pull.",
                    entries = {
                        { time = 1.0, duration = 165 },
                    },
                },
            },
        },
        nysarra = {
            key = "nysarra",
            name = "Corewarden Nysarra",
            encounterID = 3332,
            confidence = "high",
            source = "Encounter ID cross-checked in EXBoss encounter data and Exwind encounter DB.",
            duration = 168,
            referenceSpellIDs = { 1247937, 1248007, 1249014, 1249027, 1252875, 1252883, 1254096, 1259359, 1271433 },
            referenceOnlySpells = {
                {
                    label = "Unmapped Nysarra aliases",
                    spellIDs = { 1254096, 1259359, 1271433 },
                    note = "Present in Exwind local boss spell tables but not isolated as separate timeline anchors by EXBoss or current public guides.",
                },
            },
            events = {
                {
                    key = "eclipsing_step",
                    spellID = 1249027,
                    eventSpellID = 1249014,
                    combatLogEvent = "SPELL_CAST_START",
                    combatLogSpellIDs = { 1249014 },
                    spellIDs = { 1249027, 1249014, 1249020 },
                    label = "Eclipsing Step",
                    icon = "Interface\\Icons\\Ability_Rogue_ShadowDance",
                    color = { r = 92 / 255, g = 219 / 255, b = 229 / 255, a = 1 },
                    defaultDuration = 8,
                    dangerPercent = 80,
                    source = "Method tracker + wow.gg guide + EXBoss encounter data + EXBoss private aura data.",
                    confidence = "high",
                    summary = "Leap to the marked player. Splash damage plus follow-up DoT for nearby allies.",
                    entries = BuildEntries(10.7, { 19.0, 37.6, 18.6, 43.7, 18.2 }, 8),
                },
                {
                    key = "null_vanguard",
                    spellID = 1252703,
                    eventSpellID = 1252703,
                    spellIDs = { 1252703, 1252875 },
                    label = "Null Vanguard",
                    icon = "Interface\\Icons\\Spell_Shadow_ShadowWordDominate",
                    color = { r = 240 / 255, g = 75 / 255, b = 201 / 255, a = 1 },
                    defaultDuration = 16,
                    dangerPercent = 62,
                    source = "Method tracker + EXBoss encounter data + Exwind spell data.",
                    confidence = "high",
                    summary = "Add wave. Group damage rises until the summons are controlled and killed.",
                    entries = {
                        { time = 26, duration = 16 },
                        { time = 72, duration = 16 },
                        { time = 118, duration = 16 },
                    },
                },
                {
                    key = "umbral_lash",
                    spellID = 1247937,
                    eventSpellID = 1247937,
                    combatLogEvent = "SPELL_CAST_START",
                    spellIDs = { 1247937, 1248007 },
                    label = "Umbral Lash",
                    icon = "Interface\\Icons\\Spell_Shadow_DemonBreath",
                    color = { r = 255 / 255, g = 203 / 255, b = 80 / 255, a = 1 },
                    defaultDuration = 9,
                    dangerPercent = 56,
                    source = "Method tracker + wow.gg guide + EXBoss encounter data.",
                    confidence = "high",
                    summary = "Tank buster with knockback and a 9 second curse DoT.",
                    entries = BuildEntries(3.8, { 17.8, 38.8, 18.6, 17.8, 25.9, 17.0 }, 9),
                },
                {
                    key = "lightscar_flare",
                    spellID = 1264429,
                    eventSpellID = 1264439,
                    combatLogEvent = "SPELL_CAST_SUCCESS",
                    combatLogSpellIDs = { 1264439 },
                    spellIDs = { 1264429, 1264439 },
                    label = "Lightscar Flare",
                    icon = "Interface\\Icons\\Ability_Priest_Cascade",
                    color = { r = 255 / 255, g = 60 / 255, b = 88 / 255, a = 1 },
                    defaultDuration = 18,
                    dangerPercent = 100,
                    source = "Method tracker + wow.gg guide + EXBoss encounter data.",
                    confidence = "high",
                    summary = "Major group damage window and phase-defining beam / vulnerability interaction.",
                    entries = BuildEntries(36.8, { 62.1 }, 18),
                },
                {
                    key = "devour_the_unworthy",
                    spellID = 1252883,
                    eventSpellID = 1271684,
                    combatLogEvent = "SPELL_CAST_START",
                    combatLogSpellIDs = { 1271684 },
                    spellIDs = { 1252883, 1271684 },
                    label = "Devour the Unworthy",
                    icon = "Interface\\Icons\\Spell_Shadow_DevouringPlague",
                    color = { r = 209 / 255, g = 96 / 255, b = 236 / 255, a = 1 },
                    defaultDuration = 6,
                    dangerPercent = 84,
                    source = "Method tracker + EXBoss encounter data.",
                    confidence = "medium",
                    summary = "Late-fight pressure spike tied to the final add sequence.",
                    entries = {
                        { time = 164.2, duration = 6 },
                    },
                },
            },
        },
        lothraxion = {
            key = "lothraxion",
            name = "Lothraxion",
            encounterID = 3333,
            confidence = "high",
            source = "Encounter ID cross-checked in EXBoss encounter data and Exwind encounter DB.",
            duration = 190,
            referenceSpellIDs = { 1253855, 1253950, 1255208, 1255310, 1255335, 1255503, 1257595, 1257613, 1271511, 1282791 },
            referenceOnlySpells = {
                {
                    label = "Unmapped Lothraxion aliases",
                    spellIDs = { 1255208, 1255310, 1255335, 1257595, 1271511, 1282791 },
                    note = "Seen in Exwind local spell tables and likely tied to mirror-phase variants. Held as reference-only until live combat-log mapping is confirmed.",
                },
            },
            events = {
                {
                    key = "brilliant_dispersion",
                    spellID = 1253855,
                    eventSpellID = 1253848,
                    combatLogEvent = "SPELL_CAST_START",
                    combatLogSpellIDs = { 1253848 },
                    spellIDs = { 1253855, 1253848 },
                    label = "Brilliant Dispersion",
                    icon = "Interface\\Icons\\Ability_Priest_Cascade",
                    color = { r = 255 / 255, g = 63 / 255, b = 112 / 255, a = 1 },
                    defaultDuration = 7,
                    dangerPercent = 82,
                    source = "Method tracker + EXBoss encounter data.",
                    confidence = "high",
                    summary = "Heavy avoidable party damage with mirrored follow-up hazards.",
                    entries = BuildEntries(11.1, { 25.1, 39.1, 2.2, 23.3, 2.2, 37.6, 16.3, 9.2, 16.3 }, 7),
                },
                {
                    key = "divine_guile",
                    spellID = 1257601,
                    eventSpellID = 1257567,
                    combatLogEvent = "SPELL_CAST_START",
                    combatLogSpellIDs = { 1257567 },
                    spellIDs = { 1257601, 1257567, 1257613 },
                    label = "Divine Guile",
                    icon = "Interface\\Icons\\Spell_Holy_PrayerOfHealing",
                    color = { r = 126 / 255, g = 96 / 255, b = 255 / 255, a = 1 },
                    defaultDuration = 15,
                    dangerPercent = 100,
                    source = "Method tracker + EXBoss encounter data.",
                    confidence = "high",
                    summary = "Large phase event with interrupt and party-damage implications. Includes Core Exposure.",
                    entries = BuildEntries(60.5, { 64.3, 3.9, 60.3 }, 15),
                },
                {
                    key = "searing_rend",
                    spellID = 1253950,
                    eventSpellID = 1253950,
                    combatLogEvent = "SPELL_CAST_START",
                    spellIDs = { 1253950 },
                    label = "Searing Rend",
                    icon = "Interface\\Icons\\Ability_Warrior_SavageBlow",
                    color = { r = 255 / 255, g = 199 / 255, b = 78 / 255, a = 1 },
                    defaultDuration = 5,
                    dangerPercent = 58,
                    source = "Method tracker + wow.gg guide + EXBoss encounter data.",
                    confidence = "high",
                    summary = "Frequent tank buster that also creates damaging ground scars.",
                    entries = BuildEntries(2.2, { 26.9, 38.9, 3.9, 22.8, 3.9, 33.5, 16.3, 10.5, 16.3 }, 5),
                },
                {
                    key = "flicker",
                    spellID = 1269222,
                    eventSpellID = 1255531,
                    combatLogEvent = "SPELL_CAST_SUCCESS",
                    combatLogSpellIDs = { 1255531 },
                    spellIDs = { 1269222, 1255531, 1255503 },
                    label = "Flicker",
                    icon = "Interface\\Icons\\Spell_Holy_BorrowedTime",
                    color = { r = 95 / 255, g = 193 / 255, b = 255 / 255, a = 1 },
                    defaultDuration = 4,
                    dangerPercent = 48,
                    source = "Method tracker + EXBoss encounter data + Exwind spell data.",
                    confidence = "high",
                    summary = "Short reposition / frontal threat that spikes inside the mirror phase.",
                    entries = BuildEntries(29.3, { 10.7, 10.4, 43.3, 3.9, 7.0, 3.9, 6.9, 4.0, 38.4, 10.9, 6.6, 4.3 }, 4),
                },
            },
        },
}

for encounterKey, encounter in pairs(encounterData) do
    encounter.dungeonKey = "nexus_point_xenas"
    NPR.Data.encounters[encounterKey] = encounter
end

function NPR:BuildStaticData()
    wipe(self.state.eventsByEncounter)

    for encounterKey, encounter in pairs(self.Data.encounters) do
        self.state.eventsByEncounter[encounterKey] = {}
        encounter.maxTime = 60
        encounter.pullAnchor = {
            key = "pull_anchor",
            spellID = nil,
            label = "Pull",
            icon = "Interface\\Icons\\Ability_Rogue_Sprint",
            color = { r = 1, g = 1, b = 1, a = 1 },
            defaultDuration = 0,
            source = "Synthetic anchor for free reminders.",
            confidence = "high",
            hidden = true,
            entries = {
                { time = 0, duration = 0, occurrence = 1 },
            },
        }
        self.state.eventsByEncounter[encounterKey].pull_anchor = encounter.pullAnchor

        for _, event in ipairs(encounter.events) do
            event.dangerPercent = self:Clamp(event.dangerPercent or 0, 0, 100)
            self.state.eventsByEncounter[encounterKey][event.key] = event
            for index, entry in ipairs(event.entries) do
                entry.occurrence = index
                encounter.maxTime = max(encounter.maxTime, entry.time + (entry.duration or event.defaultDuration or 0))
            end
        end

        table.sort(encounter.events, function(left, right)
            local leftTime = left.entries[1] and left.entries[1].time or 0
            local rightTime = right.entries[1] and right.entries[1].time or 0
            return leftTime < rightTime
        end)
    end
end
