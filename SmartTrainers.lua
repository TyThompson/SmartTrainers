---------------------
---SmartTrainers---
---------------------
-- Addon based on WeaponTrainers
-- Made for Project Epoch
-- Rogues have Axes and Guns
-- Druids have Polearms

-- Define SavedVariables table
SmartTrainersDB = SmartTrainersDB or {}

-- Create a frame to handle events
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("SKILL_LINES_CHANGED")

-- Debounce variables
local lastSkillUpdate = 0
local debounceTime = 5 -- seconds to ignore additional SKILL_LINES_CHANGED events
local isProcessingSkills = false

-- Delay function using OnUpdate and GetTime()
local function Delay(duration, callback)
    local delayFrame = CreateFrame("Frame")
    local startTime = GetTime()
    delayFrame:SetScript("OnUpdate", function(self, elapsed)
        if GetTime() >= startTime + duration then
            callback()
            self:SetScript("OnUpdate", nil) -- Clean up the OnUpdate script
        end
    end)
end

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "SmartTrainers" then
        -- Initialize debug setting if not set
        SmartTrainersDB.debugEnabled = SmartTrainersDB.debugEnabled or false
        -- Debug check for SavedVariables
        if SmartTrainersDB then
            local playerName = UnitName("player")
            if SmartTrainersDB[playerName] and SmartTrainersDB[playerName].missingSkills then
                print("|cFF00FF00SmartTrainers: SavedVariables loaded successfully for " .. playerName .. " with " .. #SmartTrainersDB[playerName].missingSkills .. " missing skills.")
            else
                print("|cFF00FF00SmartTrainers: SavedVariables initialized, no data for " .. playerName .. " yet.")
            end
            if SmartTrainersDB.debugEnabled then
                print("|cFF00FF00SmartTrainers: Debug mode is enabled.")
            end
        else
            print("|cFFFF0000SmartTrainers: Error - SavedVariables (SmartTrainersDB) failed to load.")
        end
        -- Unregister ADDON_LOADED to avoid redundant checks
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "SKILL_LINES_CHANGED" then
        -- Check if within debounce window
        local currentTime = GetTime()
        if currentTime - lastSkillUpdate < debounceTime then
            if SmartTrainersDB.debugEnabled then
                print("|cFF00FF00SmartTrainers: SKILL_LINES_CHANGED skipped (debounce, last update " .. (currentTime - lastSkillUpdate) .. "s ago)")
            end
            return
        end
        -- Skip if already processing
        if isProcessingSkills then
            if SmartTrainersDB.debugEnabled then
                print("|cFF00FF00SmartTrainers: SKILL_LINES_CHANGED skipped (already processing)")
            end
            return
        end
        isProcessingSkills = true
        -- Delay execution to avoid running during heavy loading
        Delay(1, function()
            local playerName = UnitName("player")
            local _, class = UnitClass("player")
            class = string.lower(class)
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
            if classSkills[class] and SmartTrainersDB[playerName] then
                if SmartTrainersDB.debugEnabled then
                    print("|cFF00FF00SmartTrainers: Processing SKILL_LINES_CHANGED for " .. playerName)
                end
                local knownSkills = {}
                -- Expand all skill headers to ensure all skills are visible
                local numSkills = GetNumSkillLines()
                for i = 1, numSkills do
                    local name, isHeader = GetSkillLineInfo(i)
                    if isHeader then
                        ExpandSkillHeader(i)
                    end
                end
                -- Re-check skills after expanding headers
                numSkills = GetNumSkillLines()
                for i = 1, numSkills do
                    local name, isHeader, isExpanded, skillRank = GetSkillLineInfo(i)
                    if name and not isHeader and skillRank > 0 then
                        for skillName, displayName in pairs(weaponSkillNames) do
                            if name == displayName then
                                table.insert(knownSkills, skillName)
                            end
                        end
                    end
                end
                -- Update missingSkills by keeping only skills not known
                local missingSkills = {}
                for _, skill in ipairs(classSkills[class]) do
                    if not tContains(knownSkills, skill) then
                        table.insert(missingSkills, skill)
                    end
                end
                -- Update SavedVariables with new missingSkills
                SmartTrainersDB[playerName].missingSkills = missingSkills
                -- Update last processed time
                lastSkillUpdate = GetTime()
                -- Debug message to confirm skill update
                if SmartTrainersDB.debugEnabled then
                    print("|cFF00FF00SmartTrainers: Updated missing skills for " .. playerName .. ". Missing skills: " .. (#missingSkills > 0 and table.concat(missingSkills, ", ") or "None"))
                end
            end
            isProcessingSkills = false
        end)
    end
end)

SLASH_STRAINERS1, SLASH_STRAINERS2 = '/smarttrainers', '/st';
function SlashCmdList.STRAINERS(msg, editBox)
    msg = string.lower(msg);
    local faction = UnitFactionGroup("player");
    local _, class = UnitClass("player");
    class = string.lower(class); -- Ensure class name is lowercase
    local classColor = RAID_CLASS_COLORS[class:upper()];
    -- Create the colored class string using RGB values
    local coloredClass;
    if classColor and classColor.r and classColor.g and classColor.b then
        local hexColor = string.format("%02x%02x%02x", classColor.r * 255, classColor.g * 255, classColor.b * 255);
        coloredClass = "|cFF" .. hexColor .. class:sub(1,1):upper()..class:sub(2) .. "|r";
    else
        coloredClass = class:sub(1,1):upper()..class:sub(2); -- Fallback to uncolored class name
    end
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
            ["Thunder Bluff (Ansekhwa)"] = "Guns, Maces, Two-Handed Maces, Staves",
            ["Orgrimmar (Hanashi)"] = "Bows, Thrown, Axes, Two-Handed Axes, Staves",
            ["Orgrimmar (Sayoc)"] = "Bows, Thrown, Axes, Two-Handed Axes, Staves, Daggers, Fist Weapons",
        },
        Alliance = {
            ["Ironforge (Buliwyf Stonehand)"] = "Guns, Axes, Two-Handed Axes, Maces, Two-Handed Maces, Fist Weapons",
            ["Ironforge (Bixi Wobblebonk)"] = "Daggers, Crossbows, Thrown",
            ["Stormwind (Woo Ping)"] = "Bows, Thrown, Axes, Two-Handed Axes, Staves",
            ["Darnassus (Ilyenia Moonfire)"] = "Crossbows, Daggers, Swords, Polearms, Staves, Fist Weapons",
        },
    };
    if (msg == "group" or msg == "team") then
        msg = "party";
    end
    if (trainers[faction] and trainers[faction][msg]) then
        SendChatMessage(trainers[faction][msg], msg);
    elseif (msg == "reset") then
        -- Reset command: clear player's data from SavedVariables and recalculate
        local playerName = UnitName("player");
        SmartTrainersDB[playerName] = nil;
        print("|cFFFF0000SmartTrainers: Data reset for " .. playerName .. ". Recalculating missing skills...");
        -- Trigger recalculation by calling the function with empty msg
        SlashCmdList.STRAINERS("", editBox);
    elseif (msg == "debug") then
        -- Debug command: toggle debug mode and print current SavedVariables data
        local playerName = UnitName("player");
        SmartTrainersDB.debugEnabled = not SmartTrainersDB.debugEnabled;
        print("|cFF00FF00SmartTrainers: Debug mode " .. (SmartTrainersDB.debugEnabled and "enabled" or "disabled") .. ".");
        if SmartTrainersDB[playerName] then
            local data = SmartTrainersDB[playerName];
            print("|cFF00FF00SmartTrainers Debug: Data for " .. playerName);
            print("Faction: " .. (data.faction or "None"));
            print("Class: " .. (data.class and data.class:sub(1,1):upper()..data.class:sub(2) or "None"));
            print("Missing Skills: " .. (data.missingSkills and #data.missingSkills > 0 and table.concat(data.missingSkills, ", ") or "None"));
        else
            print("|cFF00FF00SmartTrainers Debug: No data found for " .. playerName);
        end
    elseif (msg == "") then
        -- Initialize SavedVariables for this player if not exists
        local playerName = UnitName("player");
        SmartTrainersDB[playerName] = SmartTrainersDB[playerName] or {};
        SmartTrainersDB[playerName].faction = faction;
        SmartTrainersDB[playerName].class = class;

        -- Check if we have saved data for this player's faction and class
        if SmartTrainersDB[playerName].missingSkills then
            -- Use saved data
            local missingSkills = SmartTrainersDB[playerName].missingSkills;
            if #missingSkills > 0 then
                print("Missing weapon skills for your "..coloredClass..": |cFF9CD6DE"..table.concat(missingSkills, ", "));
            else
                print("|cFF80FF80You know all available weapon skills for your "..coloredClass);
            end
            -- List trainers for saved missing skills
            for npc, weapons in pairs(trainers[faction]) do
                local filteredWeapons = {};
                local offersMissingSkill = false;
                for weapon in weapons:gmatch("[^,]+") do
                    weapon = weapon:match("^%s*(.-)%s*$"); -- Trim whitespace
                    if tContains(classSkills[class], weapon) and tContains(missingSkills, weapon) then
                        table.insert(filteredWeapons, weapon);
                        offersMissingSkill = true;
                    end
                end
                if offersMissingSkill and #filteredWeapons > 0 then
                    print("|cFFFFFF00"..npc.."|r: |cFF9CD6DE"..table.concat(filteredWeapons, ", "));
                end
            end
        else
            -- Calculate missing skills and save them
            local missingSkills = {};
            if classSkills[class] then
                local knownSkills = {};
                -- Expand all skill headers to ensure all skills are visible
                local numSkills = GetNumSkillLines();
                for i = 1, numSkills do
                    local name, isHeader = GetSkillLineInfo(i);
                    if isHeader then
                        ExpandSkillHeader(i);
                    end
                end
                -- Re-check skills after expanding headers
                numSkills = GetNumSkillLines();
                for i = 1, numSkills do
                    local name, isHeader, isExpanded, skillRank = GetSkillLineInfo(i);
                    if name and not isHeader and skillRank > 0 then
                        for skillName, displayName in pairs(weaponSkillNames) do
                            if name == displayName then
                                table.insert(knownSkills, skillName);
                            end
                        end
                    end
                end
                for _, skill in ipairs(classSkills[class]) do
                    if not tContains(knownSkills, skill) then
                        table.insert(missingSkills, skill);
                    end
                end
                -- Save missing skills to SavedVariables
                SmartTrainersDB[playerName].missingSkills = missingSkills;
                if #missingSkills > 0 then
                    print("Missing weapon skills for your "..coloredClass..": |cFF9CD6DE"..table.concat(missingSkills, ", "));
                else
                    print("|cFF80FF80You know all available weapon skills for your "..coloredClass);
                end
                -- List trainers for missing skills
                for npc, weapons in pairs(trainers[faction]) do
                    local filteredWeapons = {};
                    local offersMissingSkill = false;
                    for weapon in weapons:gmatch("[^,]+") do
                        weapon = weapon:match("^%s*(.-)%s*$"); -- Trim whitespace
                        if tContains(classSkills[class], weapon) and tContains(missingSkills, weapon) then
                            table.insert(filteredWeapons, weapon);
                            offersMissingSkill = true;
                        end
                    end
                    if offersMissingSkill and #filteredWeapons > 0 then
                        print("|cFFFFFF00"..npc.."|r: |cFF9CD6DE"..table.concat(filteredWeapons, ", "));
                    end
                end
            else
                print("Class skills not found for your "..coloredClass);
                return;
            end
        end
    else
        print("|cFFFFFF00You can type \"/st\" alone to print weapon trainers, \"/st reset\" to clear saved data, or \"/st debug\" to toggle debug mode and inspect saved data.");
    end
end