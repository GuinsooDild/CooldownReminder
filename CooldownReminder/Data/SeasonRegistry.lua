local _, NPR = ...

local dungeonOrder = {
    "magisters_terrace",
    "maisara_caverns",
    "nexus_point_xenas",
    "windrunner_spire",
    "algethar_academy",
    "pit_of_saron",
    "seat_of_the_triumvirate",
    "skyreach",
}

local function BuildEncounterSeed(encounterKey, displayName, journalEncounterID, encounterID)
    return {
        encounterKey = encounterKey,
        displayName = displayName,
        journalEncounterID = journalEncounterID,
        encounterID = encounterID,
    }
end

local function BuildDungeon(key, displayName, selectorOrder, journalInstanceID, mapID, challengeMapID, challengeMapIDPosture, totalBossCount, incompleteNote, encounterRegistry, proofEncounterOrder)
    return {
        key = key,
        dungeonKey = key,
        name = displayName,
        displayName = displayName,
        selectorOrder = selectorOrder,
        journalInstanceID = journalInstanceID,
        mapID = mapID,
        challengeMapID = challengeMapID,
        challengeMapIDPosture = challengeMapIDPosture,
        totalBossCount = totalBossCount,
        mappedBossCount = 0,
        encounterOrder = {},
        encounterRegistry = encounterRegistry or {},
        proofEncounterOrder = proofEncounterOrder or {},
        incompleteNote = incompleteNote,
        source = "Season 1 registry seed cross-checked from Blizzard roster and local reference addons.",
    }
end

NPR.Data = NPR.Data or {}
NPR.Data.season = {
    key = "midnight_season_1",
    name = "Midnight Season 1",
    dungeonOrder = dungeonOrder,
}

NPR.Data.dungeons = {
    magisters_terrace = BuildDungeon(
        "magisters_terrace",
        "Magisters' Terrace",
        1,
        2811,
        2811,
        558,
        "provisional",
        4,
        "Boss timelines are not wired yet for this Season 1 dungeon."
    ),
    maisara_caverns = BuildDungeon(
        "maisara_caverns",
        "Maisara Caverns",
        2,
        2874,
        2874,
        560,
        "provisional",
        3,
        "Boss timelines are not wired yet for this Season 1 dungeon."
    ),
    nexus_point_xenas = BuildDungeon(
        "nexus_point_xenas",
        "Nexus-Point Xenas",
        3,
        2915,
        2915,
        559,
        "provisional",
        3,
        nil
    ),
    windrunner_spire = BuildDungeon(
        "windrunner_spire",
        "Windrunner Spire",
        4,
        2805,
        2805,
        557,
        "provisional",
        4,
        "Boss timelines are not wired yet for this Season 1 dungeon."
    ),
    algethar_academy = BuildDungeon(
        "algethar_academy",
        "Algeth'ar Academy",
        5,
        2526,
        2526,
        402,
        "provisional",
        4,
        "Boss timelines are not wired yet for this Season 1 dungeon.",
        nil,
        {
            -- Imported local bossOrder drift is known here, so keep one proof roster
            -- in normalized selector order before broader non-Nexus rollout.
            BuildEncounterSeed("overgrown_ancient", "Overgrown Ancient", 2563, 2563),
            BuildEncounterSeed("crawth", "Crawth", 2564, 2564),
            BuildEncounterSeed("vexamus", "Vexamus", 2562, 2562),
            BuildEncounterSeed("echo_of_doragosa", "Echo of Doragosa", 2565, 2565),
        }
    ),
    pit_of_saron = BuildDungeon(
        "pit_of_saron",
        "Pit of Saron",
        6,
        658,
        658,
        556,
        "provisional",
        3,
        "Boss timelines are not wired yet for this Season 1 dungeon."
    ),
    seat_of_the_triumvirate = BuildDungeon(
        "seat_of_the_triumvirate",
        "Seat of the Triumvirate",
        7,
        1753,
        1753,
        239,
        "provisional",
        4,
        "Boss timelines are not wired yet for this Season 1 dungeon.",
        {
            zuraal_the_ascended = BuildEncounterSeed("zuraal_the_ascended", "Zuraal the Ascended", 1979, 2065),
            saprish = BuildEncounterSeed("saprish", "Saprish", 1980, 2066),
            viceroy_nezhar = BuildEncounterSeed("viceroy_nezhar", "Viceroy Nezhar", 1981, 2067),
            lura = BuildEncounterSeed("lura", "L'ura", 1982, 2068),
        }
    ),
    skyreach = BuildDungeon(
        "skyreach",
        "Skyreach",
        8,
        1209,
        1209,
        161,
        "provisional",
        4,
        "Boss timelines are not wired yet for this Season 1 dungeon.",
        {
            ranjit = BuildEncounterSeed("ranjit", "Ranjit", 965, 1698),
            araknath = BuildEncounterSeed("araknath", "Araknath", 966, 1699),
            rukhran = BuildEncounterSeed("rukhran", "Rukhran", 967, 1700),
            high_sage_viryx = BuildEncounterSeed("high_sage_viryx", "High Sage Viryx", 968, 1701),
        }
    ),
}

NPR.Data.encounters = NPR.Data.encounters or {}
