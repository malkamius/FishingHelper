local addonName, addonTable = ...
local FH = addonTable[1]
FH.UI = FH.UI or {}

-------------------------------------------------------------------------------
-- Zone Fishing Skill Database
-- "neverMiss": Effective Fishing skill required to achieve 0% getaway rate
--              (never miss catching a fish) in the zone.
-- "minSkill":  Minimum skill required to cast a line.
-- "tier":      Standard progression bracket.
-- "notable":   Notable fish and rewards in this tier/zone.
-- "note":      Specific sub-zone or coastal exceptions.
-------------------------------------------------------------------------------
local ZONE_DATA = {
    -- ========================================================================
    -- KALIMDOR
    -- ========================================================================
    -- Tier 1: Starting Zones (25 Skill to Never Miss)
    [1411] = { name = "Durotar", neverMiss = 25, minSkill = 1, tier = "Tier 1 (Starting Zone)", notable = "Brilliant Smallfish, Longjaw Mud Snapper" },
    [1412] = { name = "Mulgore", neverMiss = 25, minSkill = 1, tier = "Tier 1 (Starting Zone)", notable = "Brilliant Smallfish, Longjaw Mud Snapper" },
    [1438] = { name = "Teldrassil", neverMiss = 25, minSkill = 1, tier = "Tier 1 (Starting Zone)", notable = "Brilliant Smallfish, Longjaw Mud Snapper" },

    -- Tier 2: Capital Cities & Lvl 10–20 Zones (75 Skill to Never Miss)
    [1413] = { name = "The Barrens", neverMiss = 75, minSkill = 1, tier = "Tier 2 (Lvl 10–20)", notable = "Deviate Fish (Oasis pools), Sagefish, Bristle Whisker Catfish" },
    [1426] = { name = "Darkshore", neverMiss = 75, minSkill = 1, tier = "Tier 2 (Lvl 10–20)", notable = "Sagefish, Oily Blackmouth (Coast)", note = "Coastal waters require 150 to never miss." },
    [1454] = { name = "Orgrimmar", neverMiss = 75, minSkill = 1, tier = "Tier 2 (Capital City)", notable = "Old Crafty (Achievement), Raw Longjaw Mud Snapper" },
    [1456] = { name = "Thunder Bluff", neverMiss = 75, minSkill = 1, tier = "Tier 2 (Capital City)", notable = "Raw Brilliant Smallfish, Longjaw Mud Snapper" },
    [1457] = { name = "Darnassus", neverMiss = 75, minSkill = 1, tier = "Tier 2 (Capital City)", notable = "Raw Brilliant Smallfish, Longjaw Mud Snapper" },

    -- Tier 3: Lvl 20–30 Zones (150 Skill to Never Miss)
    [1416] = { name = "Ashenvale", neverMiss = 150, minSkill = 55, tier = "Tier 3 (Lvl 20–30)", notable = "Bristle Whisker Catfish, Oily Blackmouth, Firefin Snapper" },
    [1418] = { name = "Stonetalon Mountains", neverMiss = 150, minSkill = 55, tier = "Tier 3 (Lvl 20–30)", notable = "Bristle Whisker Catfish, Raw Mithril Head Trout" },

    -- Tier 4: Lvl 30–40 Zones (225 Skill to Never Miss)
    [1417] = { name = "Thousand Needles", neverMiss = 225, minSkill = 130, tier = "Tier 4 (Lvl 30–40)", notable = "Firefin Snapper, Mithril Head Trout, Greater Sagefish" },
    [1419] = { name = "Desolace", neverMiss = 225, minSkill = 130, tier = "Tier 4 (Lvl 30–40)", notable = "Firefin Snapper, Mithril Head Trout, Big Iron Fishing Pole (Shellfish)" },
    [1421] = { name = "Dustwallow Marsh", neverMiss = 225, minSkill = 130, tier = "Tier 4 (Lvl 30–40)", notable = "Firefin Snapper, Mithril Head Trout, Nat Pagle (Artisan Quest)" },

    -- Tier 5: Lvl 40–50 Zones (300 Skill to Never Miss)
    [1420] = { name = "Feralas", neverMiss = 300, minSkill = 205, tier = "Tier 5 (Lvl 40–50)", notable = "Raw Glossy Mightfish, Stonescale Eel, Raw Redgill", note = "Jademir Lake requires 425 to never miss." },
    [1422] = { name = "Tanaris", neverMiss = 300, minSkill = 205, tier = "Tier 5 (Lvl 40–50)", notable = "Raw Glossy Mightfish, Stonescale Eel, Firefin Snapper" },
    [1424] = { name = "Felwood", neverMiss = 300, minSkill = 205, tier = "Tier 5 (Lvl 40–50)", notable = "Raw Nightfin Snapper, Raw Sunscale Salmon, Raw Redgill" },
    [1425] = { name = "Un'Goro Crater", neverMiss = 300, minSkill = 205, tier = "Tier 5 (Lvl 40–50)", notable = "Raw Nightfin Snapper, Raw Sunscale Salmon, Raw Redgill" },
    [1440] = { name = "Moonglade", neverMiss = 300, minSkill = 205, tier = "Tier 5 (Lvl 40–50)", notable = "Raw Nightfin Snapper, Raw Sunscale Salmon" },

    -- Tier 6: Lvl 50–60 Zones (330 to 425 Skill to Never Miss)
    [1423] = {
        name = "Azshara",
        neverMiss = 300,
        neverMissMax = 425,
        neverMissDisplay = "300 – 425",
        minSkill = 205,
        tier = "Tier 6 (Lvl 50–60)",
        notable = "Winter Squid, Large Raw Mightfish, Raw Glossy Mightfish, Stonescale Eel",
        note = "Inland waters: 300 to never miss. Bay of Storms / ocean coast: 425 to never miss (330 min to cast)."
    },
    [1427] = { name = "Silithus", neverMiss = 425, minSkill = 330, tier = "Tier 6 (Lvl 50–60)", notable = "Raw Whitescale Salmon, Raw Nightfin Snapper, Raw Sunscale Salmon" },
    [1428] = { name = "Winterspring", neverMiss = 425, minSkill = 330, tier = "Tier 6 (Lvl 50–60)", notable = "Winter Squid, Raw Whitescale Salmon, Raw Nightfin Snapper" },

    -- ========================================================================
    -- EASTERN KINGDOMS
    -- ========================================================================
    -- Tier 1: Starting Zones (25 Skill to Never Miss)
    [1429] = { name = "Elwynn Forest", neverMiss = 25, minSkill = 1, tier = "Tier 1 (Starting Zone)", notable = "Brilliant Smallfish, Longjaw Mud Snapper" },
    [1439] = { name = "Dun Morogh", neverMiss = 25, minSkill = 1, tier = "Tier 1 (Starting Zone)", notable = "Brilliant Smallfish, Longjaw Mud Snapper" },
    [1443] = { name = "Tirisfal Glades", neverMiss = 25, minSkill = 1, tier = "Tier 1 (Starting Zone)", notable = "Brilliant Smallfish, Longjaw Mud Snapper" },

    -- Tier 2: Capital Cities & Lvl 10–20 Zones (75 Skill to Never Miss)
    [1432] = { name = "Loch Modan", neverMiss = 75, minSkill = 1, tier = "Tier 2 (Lvl 10–20)", notable = "Loch Frenzy, Sagefish, Bristle Whisker Catfish" },
    [1436] = { name = "Westfall", neverMiss = 75, minSkill = 1, tier = "Tier 2 (Lvl 10–20)", notable = "Sagefish, Oily Blackmouth (Coast)", note = "Coastal waters require 150 to never miss." },
    [1444] = { name = "Silverpine Forest", neverMiss = 75, minSkill = 1, tier = "Tier 2 (Lvl 10–20)", notable = "Sagefish, Oily Blackmouth (Coast)", note = "Coastal waters require 150 to never miss." },
    [1453] = { name = "Stormwind City", neverMiss = 75, minSkill = 1, tier = "Tier 2 (Capital City)", notable = "Bristle Whisker Catfish, Longjaw Mud Snapper" },
    [1455] = { name = "Ironforge", neverMiss = 75, minSkill = 1, tier = "Tier 2 (Capital City)", notable = "Old Ironjaw (Achievement), Bristle Whisker Catfish" },
    [1458] = { name = "Undercity", neverMiss = 75, minSkill = 1, tier = "Tier 2 (Capital City)", notable = "Bristle Whisker Catfish, Longjaw Mud Snapper" },

    -- Tier 3: Lvl 20–30 Zones (150 Skill to Never Miss)
    [1431] = { name = "Duskwood", neverMiss = 150, minSkill = 55, tier = "Tier 3 (Lvl 20–30)", notable = "Bristle Whisker Catfish, Mithril Head Trout" },
    [1433] = { name = "Redridge Mountains", neverMiss = 150, minSkill = 55, tier = "Tier 3 (Lvl 20–30)", notable = "Bristle Whisker Catfish, Mithril Head Trout" },
    [1437] = { name = "Wetlands", neverMiss = 150, minSkill = 55, tier = "Tier 3 (Lvl 20–30)", notable = "Bristle Whisker Catfish, Oily Blackmouth, Firefin Snapper" },
    [1447] = { name = "Hillsbrad Foothills", neverMiss = 150, minSkill = 55, tier = "Tier 3 (Lvl 20–30)", notable = "Bristle Whisker Catfish, Oily Blackmouth, Firefin Snapper" },

    -- Tier 4: Lvl 30–40 Zones (225 Skill to Never Miss)
    [1434] = { name = "Stranglethorn Vale", neverMiss = 225, minSkill = 130, tier = "Tier 4 (Lvl 30–40)", notable = "Firefin Snapper, Oily Blackmouth, Speckled Tastyfish (Extravaganza)", note = "Jaguero Isle requires 300 to never miss." },
    [1435] = { name = "Swamp of Sorrows", neverMiss = 225, minSkill = 130, tier = "Tier 4 (Lvl 30–40)", notable = "Firefin Snapper, Mithril Head Trout" },
    [1440] = { name = "Arathi Highlands", neverMiss = 225, minSkill = 130, tier = "Tier 4 (Lvl 30–40)", notable = "Firefin Snapper, Mithril Head Trout" },
    [1441] = { name = "Badlands", neverMiss = 225, minSkill = 130, tier = "Tier 4 (Lvl 30–40)", notable = "Firefin Snapper, Mithril Head Trout" },
    [1451] = { name = "Alterac Mountains", neverMiss = 225, minSkill = 130, tier = "Tier 4 (Lvl 30–40)", notable = "Greater Sagefish, Mithril Head Trout" },

    -- Tier 5: Lvl 40–50 Zones (300 Skill to Never Miss)
    [1448] = { name = "The Hinterlands", neverMiss = 300, minSkill = 205, tier = "Tier 5 (Lvl 40–50)", notable = "Raw Glossy Mightfish, Stonescale Eel, Raw Redgill" },
    [1445] = {
        name = "Western Plaguelands",
        neverMiss = 300,
        neverMissMax = 425,
        neverMissDisplay = "300 – 425",
        minSkill = 205,
        tier = "Tier 6 (Lvl 50–60)",
        notable = "Nightfin Snapper, Plagueland Trout, Sunscale Salmon",
        note = "Inland waters: 300 to never miss. Scholomance: 425 to never miss."
    },

    -- Tier 6: Lvl 50–60 Zones (425 Skill to Never Miss, 330 min to cast)
    [1446] = { name = "Eastern Plaguelands", neverMiss = 425, minSkill = 330, tier = "Tier 6 (Lvl 50–60)", notable = "Raw Whitescale Salmon, Raw Nightfin Snapper, Plagueland Trout" },
    [1450] = { name = "Burning Steppes", neverMiss = 425, minSkill = 330, tier = "Tier 6 (Lvl 50–60)", notable = "Raw Whitescale Salmon, Raw Nightfin Snapper" },
    [1452] = { name = "Deadwind Pass", neverMiss = 425, minSkill = 330, tier = "Tier 6 (Lvl 50–60)", notable = "Raw Whitescale Salmon, Raw Nightfin Snapper" },

    -- ========================================================================
    -- THE BURNING CRUSADE (TBC) / STARTING AREAS
    -- ========================================================================
    [1941] = { name = "Eversong Woods", neverMiss = 25, minSkill = 1, tier = "Tier 1 (Starting Zone)", notable = "Brilliant Smallfish, Longjaw Mud Snapper" },
    [1942] = { name = "Ghostlands", neverMiss = 75, minSkill = 1, tier = "Tier 2 (Lvl 10–20)", notable = "Sagefish, Oily Blackmouth (Coast)", note = "Coastal waters require 150 to never miss." },
    [1943] = { name = "Silvermoon City", neverMiss = 75, minSkill = 1, tier = "Tier 2 (Capital City)", notable = "Bristle Whisker Catfish, Longjaw Mud Snapper" },
    [1954] = { name = "Azuremyst Isle", neverMiss = 25, minSkill = 1, tier = "Tier 1 (Starting Zone)", notable = "Brilliant Smallfish, Longjaw Mud Snapper" },
    [1955] = { name = "Bloodmyst Isle", neverMiss = 75, minSkill = 1, tier = "Tier 2 (Lvl 10–20)", notable = "Sagefish, Oily Blackmouth (Coast)", note = "Coastal waters require 150 to never miss." },
    [1956] = { name = "The Exodar", neverMiss = 75, minSkill = 1, tier = "Tier 2 (Capital City)", notable = "Bristle Whisker Catfish, Longjaw Mud Snapper" },
    [1949] = { name = "Hellfire Peninsula", neverMiss = 375, minSkill = 280, tier = "Outland (Tier 7)", notable = "Barbed Gill Trout, Zangar Trout" },
    [1950] = { name = "Zangarmarsh", neverMiss = 400, minSkill = 305, tier = "Outland (Tier 7)", notable = "Sporefish, Zangar Trout, Figスイーツ", note = "Western Zangarmarsh requires 450 to never miss." },
    [1946] = { name = "Terokkar Forest", neverMiss = 450, minSkill = 355, tier = "Outland (Tier 8)", notable = "Golden Darter, Mr. Pinchy (Highland)", note = "Highland Lakes require 500 to never miss." },
    [1947] = { name = "Nagrand", neverMiss = 375, minSkill = 280, tier = "Outland (Tier 7)", notable = "Icefin Bluefish, Figfish", note = "Mountain Lakes require 490 to never miss." },
    [1951] = { name = "Blade's Edge Mountains", neverMiss = 475, minSkill = 380, tier = "Outland (Tier 8)", notable = "Furious Crawdad, Golden Darter" },
    [1952] = { name = "Netherstorm", neverMiss = 475, minSkill = 380, tier = "Outland (Tier 8)", notable = "Netherfin, Furious Crawdad" },
    [1948] = { name = "Shadowmoon Valley", neverMiss = 375, minSkill = 280, tier = "Outland (Tier 7)", notable = "Barbed Gill Trout, Icefin Bluefish" },
    [1953] = { name = "Shattrath City", neverMiss = 450, minSkill = 355, tier = "Outland (Capital)", notable = "Golden Darter, Daily Fishing Quest" },
    [1957] = { name = "Isle of Quel'Danas", neverMiss = 500, minSkill = 405, tier = "Outland (Endgame)", notable = "Bloated Sunscale Salmon, Sunspring Carp" },

    -- ========================================================================
    -- WRATH OF THE LICH KING (WotLK)
    -- ========================================================================
    [114] = { name = "Borean Tundra", neverMiss = 475, minSkill = 380, tier = "Northrend (Tier 9)", notable = "Borean Man O' War, Musselback Sculpin" },
    [115] = { name = "Dragonblight", neverMiss = 475, minSkill = 380, tier = "Northrend (Tier 9)", notable = "Dragonfin Angelfish, Glassfin Snapper" },
    [116] = { name = "Grizzly Hills", neverMiss = 475, minSkill = 380, tier = "Northrend (Tier 9)", notable = "Dark Herring, Glacial Salmon" },
    [117] = { name = "Howling Fjord", neverMiss = 475, minSkill = 380, tier = "Northrend (Tier 9)", notable = "Dark Herring, Fangtooth Herring" },
    [119] = { name = "Sholazar Basin", neverMiss = 525, minSkill = 430, tier = "Northrend (Tier 10)", notable = "Nettlefish, Glacial Salmon" },
    [120] = { name = "The Storm Peaks", neverMiss = 525, minSkill = 430, tier = "Northrend (Tier 10)", notable = "Sewer Carp, Moonglow Cuttlefish" },
    [121] = { name = "Zul'Drak", neverMiss = 525, minSkill = 430, tier = "Northrend (Tier 10)", notable = "Musselback Sculpin, Nettlefish" },
    [123] = { name = "Wintergrasp", neverMiss = 525, minSkill = 430, tier = "Northrend (Tier 10)", notable = "Glacial Salmon, Deepsea Monsterbelly" },
    [125] = { name = "Dalaran", neverMiss = 525, minSkill = 430, tier = "Northrend (Capital)", notable = "Titanium Seal of Dalaran, Giant Sewer Rat" },
    [127] = { name = "Crystalsong Forest", neverMiss = 525, minSkill = 430, tier = "Northrend (Tier 10)", notable = "Glassfin Snapper" },
}

-- Normalized name lookup for fallbacks across client locales/sub-zones
local ZONE_DATA_BY_NAME = {}

local function NormalizeName(name)
    if not name then return "" end
    local clean = name:lower():gsub("[^%a%d]", "")
    return clean
end

-- Pre-populate ZONE_DATA_BY_NAME from ZONE_DATA
for _, data in pairs(ZONE_DATA) do
    if data.name then
        local key = NormalizeName(data.name)
        ZONE_DATA_BY_NAME[key] = data
    end
end

-- Additional name aliases, sub-zones, dungeons, and Forever custom zones
local ADDITIONAL_ALIASES = {
    -- Classic Dungeons & Battlegrounds
    ["wailingcaverns"]              = { name = "Wailing Caverns", neverMiss = 75, minSkill = 1, tier = "Tier 2 (Dungeon)", notable = "Deviate Fish" },
    ["thedeadmines"]                = { name = "The Deadmines", neverMiss = 75, minSkill = 1, tier = "Tier 2 (Dungeon)", notable = "Sagefish, Bristle Whisker Catfish" },
    ["deadmines"]                   = { name = "The Deadmines", neverMiss = 75, minSkill = 1, tier = "Tier 2 (Dungeon)", notable = "Sagefish, Bristle Whisker Catfish" },
    ["blackfathomdeeps"]            = { name = "Blackfathom Deeps", neverMiss = 75, minSkill = 1, tier = "Tier 2 (Dungeon)", notable = "Sagefish, Bristle Whisker Catfish" },
    ["scarletmonastery"]            = { name = "Scarlet Monastery", neverMiss = 225, minSkill = 130, tier = "Tier 4 (Dungeon)", notable = "Mithril Head Trout, Firefin Snapper" },
    ["maraudon"]                    = { name = "Maraudon", neverMiss = 300, minSkill = 205, tier = "Tier 5 (Dungeon)", notable = "Raw Redgill, Nightfin Snapper" },
    ["sunkentemple"]                = { name = "Sunken Temple", neverMiss = 300, minSkill = 205, tier = "Tier 5 (Dungeon)", notable = "Raw Redgill, Nightfin Snapper" },
    ["thetempleofatalhakkar"]       = { name = "The Temple of Atal'Hakkar", neverMiss = 300, minSkill = 205, tier = "Tier 5 (Dungeon)", notable = "Raw Redgill, Nightfin Snapper" },
    ["templeofatalhakkar"]          = { name = "The Temple of Atal'Hakkar", neverMiss = 300, minSkill = 205, tier = "Tier 5 (Dungeon)", notable = "Raw Redgill, Nightfin Snapper" },
    ["scholomance"]                 = { name = "Scholomance", neverMiss = 425, minSkill = 330, tier = "Tier 6 (Dungeon)", notable = "Plagueland Trout, 29 Pound Salmon" },
    ["stratholme"]                  = { name = "Stratholme", neverMiss = 425, minSkill = 330, tier = "Tier 6 (Dungeon)", notable = "Plagueland Trout, 29 Pound Salmon" },
    ["zulgurub"]                    = { name = "Zul'Gurub", neverMiss = 425, minSkill = 330, tier = "Tier 6 (Raid)", notable = "Gahz'ranka (Mudskunk Lure), Zulian Mudskunk" },
    ["alteracvalley"]               = { name = "Alterac Valley", neverMiss = 425, minSkill = 330, tier = "Tier 6 (Battleground)", notable = "Alterac Frenzy" },
    ["arathibasin"]                 = { name = "Arathi Basin", neverMiss = 225, minSkill = 130, tier = "Tier 4 (Battleground)", notable = "Mithril Head Trout" },
    ["blackmorass"]                 = { name = "The Black Morass", neverMiss = 425, minSkill = 330, tier = "Tier 6 (Dungeon)", notable = "Barbed Gill Trout" },
    ["theblackmorass"]              = { name = "The Black Morass", neverMiss = 425, minSkill = 330, tier = "Tier 6 (Dungeon)", notable = "Barbed Gill Trout" },
    ["oldhillsbradfoothills"]       = { name = "Old Hillsbrad Foothills", neverMiss = 225, minSkill = 130, tier = "Tier 4 (Dungeon)", notable = "Mithril Head Trout" },
    ["cavernsoftimeoldhillsbradfoothills"] = { name = "Old Hillsbrad Foothills", neverMiss = 225, minSkill = 130, tier = "Tier 4 (Dungeon)", notable = "Mithril Head Trout" },

    -- Forever / Custom zones
    ["zephrasisle"]                 = { name = "Zephras Isle", neverMiss = 25, minSkill = 1, tier = "Tier 1 (Starting Zone)", notable = "Brilliant Smallfish, Longjaw Mud Snapper" },
    ["riverglades"]                 = { name = "Riverglades", neverMiss = 225, minSkill = 130, tier = "Tier 4 (Mid-level Region)", notable = "Mithril Head Trout, Greater Sagefish" },

    -- Common variants & short forms
    ["barrens"]                     = ZONE_DATA[1413],
    ["hinterlands"]                 = ZONE_DATA[1448],
    ["ungoro"]                      = ZONE_DATA[1425],
    ["ungorocrater"]                = ZONE_DATA[1425],
    ["northernstranglethorn"]       = ZONE_DATA[1434],
    ["thecapeofstranglethorn"]      = ZONE_DATA[1434],
    ["capeofstranglethorn"]         = ZONE_DATA[1434],
    ["stranglethorn"]               = ZONE_DATA[1434],
    ["stormwind"]                   = ZONE_DATA[1453],
    ["exodar"]                      = ZONE_DATA[1956],
    ["silvermoon"]                  = ZONE_DATA[1943],
    ["thunderbluff"]                = ZONE_DATA[1456],
    ["ironforgecity"]               = ZONE_DATA[1455],
    ["cityofironforge"]             = ZONE_DATA[1455],
    ["orgrimmarcity"]               = ZONE_DATA[1454],
    ["bladesedge"]                  = ZONE_DATA[1951],
    ["bladesedgemountains"]         = ZONE_DATA[1951],
    ["hrothgarslanding"]            = { name = "Hrothgar's Landing", neverMiss = 525, minSkill = 430, tier = "Northrend (Tier 10)", notable = "Moonglow Cuttlefish" },
}

for k, v in pairs(ADDITIONAL_ALIASES) do
    if not ZONE_DATA_BY_NAME[k] then
        ZONE_DATA_BY_NAME[k] = v
    end
end

-------------------------------------------------------------------------------
-- Helper: Get Player Fishing Skill
-------------------------------------------------------------------------------
local function GetPlayerFishingSkill()
    -- Method 1: GetProfessions / GetProfessionInfo (Modern / Classic Forever)
    if GetProfessions and GetProfessionInfo then
        local ok, p1, p2, archaeology, fishing, cooking, firstAid = pcall(GetProfessions)
        if ok then
            local indexes = { fishing, p1, p2, cooking, firstAid, archaeology }
            for _, idx in pairs(indexes) do
                if type(idx) == "number" then
                    local cOK, name, _, rank, maxRank, _, _, _, modifier = pcall(GetProfessionInfo, idx)
                    if cOK and name and (name == "Fishing" or name:lower():find("fish")) then
                        local base = tonumber(rank) or 0
                        local mod = tonumber(modifier) or 0
                        return base + mod, base, mod, tonumber(maxRank) or 0
                    end
                end
            end
        end
    end

    -- Method 2: GetSkillLineInfo (Classic Era / Vanilla)
    if GetNumSkillLines and GetSkillLineInfo then
        for i = 1, GetNumSkillLines() do
            local name, header, _, rank, _, modifier, maxRank = GetSkillLineInfo(i)
            if not header and name and (name == "Fishing" or name:lower():find("fish")) then
                local base = tonumber(rank) or 0
                local mod = tonumber(modifier) or 0
                return base + mod, base, mod, tonumber(maxRank) or 0
            end
        end
    end

    return 0, 0, 0, 0
end

-------------------------------------------------------------------------------
-- Helper: Get Fishing Data for Current Map
-------------------------------------------------------------------------------
local function GetMapFishingData()
    if not WorldMapFrame then return nil, nil end

    local mapID = nil
    if WorldMapFrame.GetMapID then
        mapID = WorldMapFrame:GetMapID()
    end
    if not mapID and WorldMapFrame.mapID then
        mapID = WorldMapFrame.mapID
    end

    local mapInfo = nil
    if mapID and C_Map and C_Map.GetMapInfo then
        mapInfo = C_Map.GetMapInfo(mapID)
    end

    -- If map is a continent (type 2), world (type 1), or cosmic (type 0),
    -- do not display a single zone's fishing skill.
    if mapInfo and Enum and Enum.UIMapType then
        if mapInfo.mapType == Enum.UIMapType.Continent or
           mapInfo.mapType == Enum.UIMapType.World or
           mapInfo.mapType == Enum.UIMapType.Cosmic then
            return nil, mapInfo and mapInfo.name
        end
    end

    -- 1. Check by numeric mapID
    if mapID and ZONE_DATA[mapID] then
        return ZONE_DATA[mapID], mapInfo and mapInfo.name or ZONE_DATA[mapID].name
    end

    -- 2. Check by zone name from mapInfo
    if mapInfo and mapInfo.name then
        local cleanName = NormalizeName(mapInfo.name)
        if ZONE_DATA_BY_NAME[cleanName] then
            return ZONE_DATA_BY_NAME[cleanName], mapInfo.name
        end
    end

    -- 3. Check by parent map if this is a subzone
    if mapInfo and mapInfo.parentMapID and ZONE_DATA[mapInfo.parentMapID] then
        return ZONE_DATA[mapInfo.parentMapID], mapInfo.name
    end

    -- 4. Check active NavBar button text
    if WorldMapFrame.NavBar and WorldMapFrame.NavBar.navList then
        local navBar = WorldMapFrame.NavBar
        local lastBtn = navBar.navList[#navBar.navList]
        if lastBtn and lastBtn:IsShown() then
            local btnText = lastBtn:GetText() or (lastBtn.text and lastBtn.text:GetText())
            if btnText and btnText ~= "" then
                local cleanBtn = NormalizeName(btnText)
                if ZONE_DATA_BY_NAME[cleanBtn] then
                    return ZONE_DATA_BY_NAME[cleanBtn], btnText
                end
            end
        end
    end

    -- 5. Fallback for WorldMapZoneDropDown
    if WorldMapZoneDropDown and WorldMapZoneDropDown:IsShown() and UIDropDownMenu_GetText then
        local dropText = UIDropDownMenu_GetText(WorldMapZoneDropDown)
        if dropText and dropText ~= "" then
            local cleanDrop = NormalizeName(dropText)
            if ZONE_DATA_BY_NAME[cleanDrop] then
                return ZONE_DATA_BY_NAME[cleanDrop], dropText
            end
        end
    end

    return nil, mapInfo and mapInfo.name
end

-------------------------------------------------------------------------------
-- UI Frame: Fishing Level Indicator on World Map
-------------------------------------------------------------------------------
local indicator = nil

local function CreateWorldMapIndicator()
    if indicator then return indicator end
    if not WorldMapFrame then return nil end

    local parentFrame = (WorldMapFrame.NavBar) or (WorldMapFrame.BorderFrame) or WorldMapFrame

    indicator = CreateFrame("Button", "FishingHelperWorldMapIndicator", parentFrame)
    indicator:SetHeight(22)
    indicator:SetFrameStrata("HIGH")
    indicator:SetFrameLevel(parentFrame:GetFrameLevel() + 5)

    -- Fish icon
    local icon = indicator:CreateTexture(nil, "ARTWORK")
    icon:SetSize(16, 16)
    icon:SetPoint("LEFT", indicator, "LEFT", 0, 0)
    icon:SetTexture("Interface\\Icons\\Trade_Fishing")
    indicator.icon = icon

    -- Text
    local text = indicator:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    text:SetPoint("LEFT", icon, "RIGHT", 4, 0)
    text:SetJustifyH("LEFT")
    indicator.text = text

    -- Tooltip script
    indicator:SetScript("OnEnter", function(self)
        if not self.data then return end
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", 0, -2)
        GameTooltip:ClearLines()

        local zoneTitle = self.zoneName or (self.data and self.data.name) or "Current Zone"
        GameTooltip:AddLine(zoneTitle, 1, 0.82, 0)

        if self.data.tier then
            GameTooltip:AddLine(self.data.tier, 0.7, 0.7, 0.7)
        end

        local displayNeverMiss = self.data.neverMissDisplay or tostring(self.data.neverMiss)
        GameTooltip:AddDoubleLine(
            "Skill to Never Miss:",
            string.format("|cffffffff%s|r", displayNeverMiss),
            0.9, 0.9, 0.9, 1, 1, 1
        )

        if self.data.minSkill then
            GameTooltip:AddDoubleLine(
                "Minimum to Cast:",
                string.format("|cffffffff%d|r", self.data.minSkill),
                0.9, 0.9, 0.9, 1, 1, 1
            )
        end

        local totalSkill, baseSkill, modSkill = GetPlayerFishingSkill()
        local skillText
        if modSkill > 0 then
            skillText = string.format("%d (%d+%d)", totalSkill, baseSkill, modSkill)
        else
            skillText = string.format("%d", totalSkill)
        end

        local checkSkill = self.data.neverMissMax or self.data.neverMiss
        local statusText, statusR, statusG, statusB
        if totalSkill >= checkSkill then
            statusText = "Guaranteed Catch (0% getaways)"
            statusR, statusG, statusB = 0.1, 1.0, 0.1
        elseif totalSkill >= self.data.neverMiss then
            statusText = "Guaranteed in Inland Waters (Ocean/Coast may get away)"
            statusR, statusG, statusB = 0.5, 0.9, 0.2
        elseif totalSkill >= (self.data.minSkill or 1) then
            local needed = self.data.neverMiss - totalSkill
            statusText = string.format("Getaways Possible (Need +%d skill)", needed)
            statusR, statusG, statusB = 1.0, 0.7, 0.1
        else
            local needed = (self.data.minSkill or 1) - totalSkill
            statusText = string.format("Cannot Fish (Need +%d skill)", needed)
            statusR, statusG, statusB = 1.0, 0.2, 0.2
        end

        GameTooltip:AddDoubleLine("Your Fishing Skill:", skillText, 0.9, 0.9, 0.9, statusR, statusG, statusB)
        GameTooltip:AddLine("Status: " .. statusText, statusR, statusG, statusB)

        if self.data.notable then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cffffd200Notable Fish & Rewards:|r " .. self.data.notable, 1, 1, 1, true)
        end

        if self.data.note then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cff71d5ffNote:|r " .. self.data.note, 1, 0.82, 0.4, true)
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("<Left-Click to toggle Fishing Helper>", 0.5, 0.5, 0.5)
        GameTooltip:AddLine("<Right-Click for Keybindings>", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)

    indicator:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Click interaction
    indicator:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    indicator:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            if FH.UI and FH.UI.CreateSettingsFrame then
                if not FH.UI.settingsFrame then FH.UI:CreateSettingsFrame() end
                if FH.UI.settingsFrame:IsShown() then
                    FH.UI.settingsFrame:Hide()
                else
                    FH.UI.settingsFrame:Show()
                end
            end
        else
            if FH.UI and FH.UI.frame then
                if FH.UI.frame:IsShown() then
                    FH.UI.frame:Hide()
                else
                    FH.UI.frame:Show()
                end
            end
        end
    end)

    return indicator
end

-------------------------------------------------------------------------------
-- Update Indicator Content & Position
-------------------------------------------------------------------------------
local function UpdateMapFishingSkill()
    if not WorldMapFrame or not WorldMapFrame:IsShown() then return end

    local ind = CreateWorldMapIndicator()
    if not ind then return end

    local data, zoneName = GetMapFishingData()
    if not data then
        ind:Hide()
        ind.data = nil
        ind.zoneName = nil
        return
    end

    ind.data = data
    ind.zoneName = zoneName

    -- Format display string
    local playerSkill = GetPlayerFishingSkill()
    local checkSkill = data.neverMissMax or data.neverMiss
    local skillColor
    if playerSkill >= checkSkill then
        skillColor = "|cff20ff20" -- Green: guaranteed catch everywhere in zone
    elseif playerSkill >= data.neverMiss then
        skillColor = "|cff71d5ff" -- Light Blue: guaranteed in base/inland waters
    elseif playerSkill >= (data.minSkill or 1) then
        skillColor = "|cffffa500" -- Orange: can fish, but getaways possible
    else
        skillColor = "|cffff4040" -- Red: cannot fish or far below
    end

    local skillString = data.neverMissDisplay or tostring(data.neverMiss)
    local displayText = string.format("|cffffd200Fishing:|r %s%s|r |cff71d5ff(Never Miss)|r", skillColor, skillString)
    ind.text:SetText(displayText)

    local width = ind.icon:GetWidth() + ind.text:GetStringWidth() + 8
    ind:SetWidth(width)

    -- Anchor relative to the Area Dropdown Menu
    ind:ClearAllPoints()

    local anchored = false

    -- Case 1: WorldMapFrame.NavBar (Modern / Classic 1.15 / Forever)
    if WorldMapFrame.NavBar and WorldMapFrame.NavBar:IsShown() then
        local navBar = WorldMapFrame.NavBar
        ind:SetParent(navBar)
        ind:SetFrameLevel(navBar:GetFrameLevel() + 5)

        -- Find the last visible button in navList (the Area/Zone button with its dropdown arrow)
        local lastBtn = nil
        if navBar.navList and #navBar.navList > 0 then
            for i = #navBar.navList, 1, -1 do
                local btn = navBar.navList[i]
                if btn and btn:IsShown() then
                    lastBtn = btn
                    break
                end
            end
        end

        if not lastBtn and navBar.homeButton and navBar.homeButton:IsShown() then
            lastBtn = navBar.homeButton
        end

        if lastBtn then
            ind:SetPoint("LEFT", lastBtn, "RIGHT", 10, 0)
            anchored = true
        end
    end

    -- Case 2: WorldMapZoneDropDown (Classic 1.12 / older dropdown menu)
    if not anchored and WorldMapZoneDropDown and WorldMapZoneDropDown:IsShown() then
        local parentFrame = WorldMapZoneDropDown:GetParent() or WorldMapFrame.BorderFrame or WorldMapFrame
        ind:SetParent(parentFrame)
        ind:SetFrameLevel(WorldMapZoneDropDown:GetFrameLevel() + 5)
        ind:SetPoint("LEFT", WorldMapZoneDropDown, "RIGHT", 4, 2)
        anchored = true
    end

    -- Case 3: WorldMapContinentDropDown fallback
    if not anchored and WorldMapContinentDropDown and WorldMapContinentDropDown:IsShown() then
        local parentFrame = WorldMapContinentDropDown:GetParent() or WorldMapFrame.BorderFrame or WorldMapFrame
        ind:SetParent(parentFrame)
        ind:SetFrameLevel(WorldMapContinentDropDown:GetFrameLevel() + 5)
        ind:SetPoint("LEFT", WorldMapContinentDropDown, "RIGHT", 4, 2)
        anchored = true
    end

    -- Case 4: General fallback on top header
    if not anchored then
        local parentFrame = WorldMapFrame.BorderFrame or WorldMapFrame
        ind:SetParent(parentFrame)
        ind:SetFrameLevel(parentFrame:GetFrameLevel() + 5)
        ind:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 120, -5)
    end

    ind:Show()
end

local function QueueUpdate()
    UpdateMapFishingSkill()
    if C_Timer and C_Timer.After then
        C_Timer.After(0, UpdateMapFishingSkill)
    end
end

-------------------------------------------------------------------------------
-- Initialization & Event Hooking
-------------------------------------------------------------------------------
local isHooked = false

local function InitWorldMapHooks()
    if isHooked or not WorldMapFrame then return end
    isHooked = true

    WorldMapFrame:HookScript("OnShow", QueueUpdate)

    if WorldMapFrame.OnMapChanged then
        hooksecurefunc(WorldMapFrame, "OnMapChanged", QueueUpdate)
    end

    if WorldMapFrame.SetMapID then
        hooksecurefunc(WorldMapFrame, "SetMapID", QueueUpdate)
    end

    if WorldMapFrame.NavBar and WorldMapFrame.NavBar.Refresh then
        hooksecurefunc(WorldMapFrame.NavBar, "Refresh", QueueUpdate)
    end

    if _G.NavBar_Refresh then
        hooksecurefunc("NavBar_Refresh", function(navBar)
            if navBar == (WorldMapFrame and WorldMapFrame.NavBar) then
                QueueUpdate()
            end
        end)
    end

    if _G.WorldMapZoneDropDown_Update then
        hooksecurefunc("WorldMapZoneDropDown_Update", QueueUpdate)
    end

    -- If map is currently showing, trigger update
    if WorldMapFrame:IsShown() then
        QueueUpdate()
    end
end

local eventWatcher = CreateFrame("Frame")
eventWatcher:RegisterEvent("ADDON_LOADED")
eventWatcher:RegisterEvent("PLAYER_LOGIN")
eventWatcher:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventWatcher:RegisterEvent("ZONE_CHANGED")
eventWatcher:RegisterEvent("ZONE_CHANGED_INDOORS")
eventWatcher:RegisterEvent("SKILL_LINES_CHANGED")

eventWatcher:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "Blizzard_WorldMap" or arg1 == addonName then
            InitWorldMapHooks()
        end
    elseif event == "PLAYER_LOGIN" then
        InitWorldMapHooks()
    else
        if WorldMapFrame and WorldMapFrame:IsShown() then
            QueueUpdate()
        end
    end
end)

-- Direct check in case WorldMapFrame is already loaded
if WorldMapFrame then
    InitWorldMapHooks()
end
