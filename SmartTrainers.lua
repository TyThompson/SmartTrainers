---------------------
---SmartTrainers---
---------------------
-- Addon based on WeaponTrainers
-- Made for Project Epoch
-- Rogues have Axes, Druids have Polearms

SLASH_STRAINERS1, SLASH_STRAINERS2 = '/smarttrainers', '/st';
function SlashCmdList.STRAINERS(msg, editBox)
    msg = string.lower(msg);
    local faction = UnitFactionGroup("player");
    local _, class = UnitClass("player");
    class = string.lower(class); -- Ensure class name is lowercase
    local classColor = RAID_CLASS_COLORS[class:upper()]; -- Retrieve the class color
    local coloredClass = "|c"..classColor.colorStr..class:sub(1,1):upper()..class:sub(2).."|r"; -- Create the colored class string
    local factionColor = faction == "Horde" and "|cFFFF0000" or "|cFF3385FF"; -- Define colors for Horde (red) and Alliance (blue)
    print("You're playing a "..coloredClass.." on the "..factionColor..faction.."|r"); -- Print the colored class name and faction
    local classSkills = {
        warrior = {"Axes", "Swords", "Two-Handed Axes", "Two-Handed Swords", "Two-Handed Maces", "Maces", "Polearms"},
        paladin = {"Axes", "Maces", "Swords", "Two-Handed Axes", "Two-Handed Maces", "Two-Handed Swords"},
        hunter = {"Bows", "Crossbows", "Guns", "Daggers", "Fist Weapons", "Polearms", "Staves", "Thrown Weapons"},
        rogue = {"Bows", "Crossbows", "Guns", "Daggers", "Fist Weapons", "Axes", "Maces", "Swords", "Thrown Weapons"},
        priest = {"Daggers", "Maces", "Staves"},
        shaman = {"Daggers", "Fist Weapons", "Axes", "Staves"},
        mage = {"Daggers", "Swords", "Staves"},
        warlock = {"Daggers", "Swords", "Staves"},
        druid = {"Daggers", "Fist Weapons", "Maces", "Staves", "Polearms"},
    }
    local weaponSkillNames = {
        ["Axes"] = "Axes",
        ["Two-Handed Axes"] = "Two-Handed Axes",
        ["Bows"] = "Bows",
        ["Crossbows"] = "Crossbows",
        ["Daggers"] = "Daggers",
        ["Fist Weapons"] = "Fist Weapons",
        ["Guns"] = "Guns",
        ["Maces"] = "Maces",
        ["Two-Handed Maces"] = "Two-Handed Maces",
        ["Polearms"] = "Polearms",
        ["Swords"] = "Swords",
        ["Two-Handed Swords"] = "Two-Handed Swords",
        ["Staves"] = "Staves",
        ["Thrown Weapons"] = "Thrown",
    }
    local trainers = {
        Horde = {
            ["Undercity (Archibald)"] = "Crossbows, Daggers, Swords, Polearms",
            ["Thunder Bluff (Ansekhwa)"] = "Guns, Maces, Staves",
            ["Orgrimmar (Hanashi)"] = "Bows, Thrown, Axes, Staves",
            ["Orgrimmar (Sayoc)"] = "Bows, Thrown, Axes, Staves, Daggers, Fist Weapons",
        },
        Alliance = {
            ["Ironforge (Buliwyf Stonehand)"] = "Guns, Axes, Maces, Fist Weapons",
            ["Ironforge (Bixi Wobblebonk)"] = "Daggers, Crossbows, Thrown",
            ["Stormwind (Hanashi)"] = "Bows, Thrown, Axes, Staves",
            ["Darnassus (Wooping)"] = "Crossbows, Daggers, Swords, Polearms, Staves",
        },
    };
    if (msg == "group" or msg == "team") then
        msg = "party";
    end
    if (trainers[faction] and trainers[faction][msg]) then
        SendChatMessage(trainers[faction][msg], msg);
    elseif (msg == "") then
        -- Check missing weapon skills for the player's class
        local missingSkills = {};
        if classSkills[class] then
            local knownSkills = {};
            -- print("Debug: Checking skill lines...");
            -- Expand all skill headers to ensure all skills are visible
            local numSkills = GetNumSkillLines();
            for i = 1, numSkills do
                local name, isHeader = GetSkillLineInfo(i);
                if isHeader then
                    ExpandSkillHeader(i);
                end
            end
            -- Re-check skills after expanding headers
            numSkills = GetNumSkillLines(); -- Update after expanding headers
            for i = 1, numSkills do
                local name, isHeader, isExpanded, skillRank = GetSkillLineInfo(i);
                if name and not isHeader and skillRank > 0 then
                    -- print("Found skill: "..name.." (Rank: "..skillRank..")");
                    for skillName, displayName in pairs(weaponSkillNames) do
                        if name == displayName then
                            -- print("Matched skill: "..name.." to "..skillName);
                            table.insert(knownSkills, skillName);
                        end
                    end
                end
            end
            -- print("Debug: Known skills: "..(next(knownSkills) and table.concat(knownSkills, ", ") or "None"));
            for _, skill in ipairs(classSkills[class]) do
                if not tContains(knownSkills, skill) then
                    table.insert(missingSkills, skill);
                end
            end
            if #missingSkills > 0 then
                print("Missing weapon skills for your "..coloredClass..": |cFF9CD6DE"..table.concat(missingSkills, ", "));
            else
                print("|cFF80FF80You know all available weapon skills for your "..coloredClass);
            end
        else
            print("Class skills not found for your "..coloredClass);
            return; -- Exit if class skills are not found
        end
        -- List only trainers who offer missing skills that the class can use
        for npc, weapons in pairs(trainers[faction]) do
            local filteredWeapons = {};
            local offersMissingSkill = false;
            -- Split the trainer's skills into a table
            for weapon in weapons:gmatch("[^,]+") do
                weapon = weapon:match("^%s*(.-)%s*$"); -- Trim whitespace
                -- Check if the skill is in classSkills[class] and missingSkills
                if tContains(classSkills[class], weapon) and tContains(missingSkills, weapon) then
                    table.insert(filteredWeapons, weapon);
                    offersMissingSkill = true;
                end
            end
            -- Only print the trainer if they offer at least one missing skill
            if offersMissingSkill and #filteredWeapons > 0 then
                print("|cFFFFFF00"..npc.."|r: |cFF9CD6DE"..table.concat(filteredWeapons, ", "));
            end
        end
    else
        print("|cFFFFFF00You can type \"/st\" alone to print weapon trainers to yourself.");
    end
end