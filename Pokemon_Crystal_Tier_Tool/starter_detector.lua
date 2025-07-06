-- Starter Detection Module for Pokemon Crystal
-- Detects and rates starter Pokemon during selection

local starter_detector = {}

-- Memory addresses for starter selection
local starter_addresses = {
    -- During Elm's lab selection
    current_map = 0xDCB5,           -- Current map ID
    elm_lab_map = 0x08,             -- Professor Elm's lab map ID
    
    -- Starter Pokemon data (temporary storage during selection)
    starter_data = {
        -- These addresses hold the three starter options
        slot1 = 0xD8E8,  -- First starter (left)
        slot2 = 0xD8E9,  -- Second starter (middle)  
        slot3 = 0xD8EA,  -- Third starter (right)
    },
    
    -- Alternative locations (some ROMs use these)
    alt_starter_data = {
        slot1 = 0xCC5B,
        slot2 = 0xCC5C,
        slot3 = 0xCC5D,
    },
    
    -- Event flags
    starter_chosen_flag = 0xD9F8,   -- Set when starter is chosen
    in_selection = 0xCE3E,          -- Active during selection
}

-- Cache for starter data
local starter_cache = {
    active = false,
    starters = {},
    last_check = 0
}

-- Check if we're in the starter selection
function starter_detector.isInStarterSelection()
    -- Check if we're in Elm's lab
    local current_map = memory.readbyte(starter_addresses.current_map)
    if current_map ~= starter_addresses.elm_lab_map then
        return false
    end
    
    -- Check if starter hasn't been chosen yet
    local chosen_flag = memory.readbyte(starter_addresses.starter_chosen_flag)
    if chosen_flag ~= 0 then
        return false
    end
    
    -- Additional check for selection state
    local selection_state = memory.readbyte(starter_addresses.in_selection)
    
    return true  -- In Elm's lab and haven't chosen starter
end

-- Read starter Pokemon IDs
function starter_detector.readStarters()
    local starters = {}
    
    -- Try primary addresses
    local s1 = memory.readbyte(starter_addresses.starter_data.slot1)
    local s2 = memory.readbyte(starter_addresses.starter_data.slot2)
    local s3 = memory.readbyte(starter_addresses.starter_data.slot3)
    
    -- Validate
    if s1 > 0 and s1 <= 251 and s2 > 0 and s2 <= 251 and s3 > 0 and s3 <= 251 then
        starters = {s1, s2, s3}
    else
        -- Try alternative addresses
        s1 = memory.readbyte(starter_addresses.alt_starter_data.slot1)
        s2 = memory.readbyte(starter_addresses.alt_starter_data.slot2)
        s3 = memory.readbyte(starter_addresses.alt_starter_data.slot3)
        
        if s1 > 0 and s1 <= 251 and s2 > 0 and s2 <= 251 and s3 > 0 and s3 <= 251 then
            starters = {s1, s2, s3}
        end
    end
    
    -- Default to standard starters if reading fails
    if #starters == 0 then
        -- Try to detect if it's a normal game (not randomized)
        starters = {155, 158, 152}  -- Cyndaquil, Totodile, Chikorita
    end
    
    return starters
end

-- Get starter data with names and types
function starter_detector.getStarterData()
    if not starter_detector.isInStarterSelection() then
        return nil
    end
    
    local species_ids = starter_detector.readStarters()
    local starter_data = {}
    
    -- Load required data modules
    local pokemon_base_stats = require("data.pokemon_base_stats")
    local type_effectiveness = require("data.type_effectiveness")
    
    -- Get data for each starter
    for i, species_id in ipairs(species_ids) do
        local base_stats = pokemon_base_stats.getBaseStats(species_id)
        
        if base_stats then
            starter_data[i] = {
                species_id = species_id,
                name = base_stats.name,
                stats = base_stats,
                position = i  -- 1=left, 2=middle, 3=right
            }
        else
            -- Unknown Pokemon
            starter_data[i] = {
                species_id = species_id,
                name = "Pokemon " .. species_id,
                stats = {
                    hp = 50, attack = 50, defense = 50,
                    speed = 50, sp_attack = 50, sp_defense = 50,
                    total = 300
                },
                position = i
            }
        end
    end
    
    return starter_data
end

-- Calculate tier rating for a starter
function starter_detector.rateStarter(starter_data)
    -- Simplified tier calculation for starters
    local total_stats = starter_data.stats.total
    local tier_score = 0
    
    -- Base stat score (normalized for starters)
    -- Starters typically have 300-320 total stats
    tier_score = ((total_stats - 280) / 40) * 40  -- 0-40 points
    
    -- Speed bonus (important in randomizers)
    if starter_data.stats.speed >= 65 then
        tier_score = tier_score + 20
    elseif starter_data.stats.speed >= 55 then
        tier_score = tier_score + 10
    end
    
    -- Offensive stats bonus
    local offensive = math.max(starter_data.stats.attack, starter_data.stats.sp_attack)
    if offensive >= 65 then
        tier_score = tier_score + 15
    elseif offensive >= 55 then
        tier_score = tier_score + 8
    end
    
    -- Bulk bonus
    local bulk = (starter_data.stats.hp + starter_data.stats.defense + starter_data.stats.sp_defense) / 3
    if bulk >= 60 then
        tier_score = tier_score + 10
    elseif bulk >= 50 then
        tier_score = tier_score + 5
    end
    
    -- Early game viability bonus
    tier_score = tier_score + 15
    
    -- Determine tier
    local tier = "F"
    if tier_score >= 85 then
        tier = "S"
    elseif tier_score >= 70 then
        tier = "A"
    elseif tier_score >= 55 then
        tier = "B"
    elseif tier_score >= 40 then
        tier = "C"
    elseif tier_score >= 25 then
        tier = "D"
    end
    
    return {
        tier = tier,
        score = math.floor(tier_score),
        recommendation = starter_detector.getRecommendation(tier, starter_data)
    }
end

-- Get recommendation text
function starter_detector.getRecommendation(tier, starter_data)
    local speed_tier = ""
    if starter_data.stats.speed >= 65 then
        speed_tier = "Fast"
    elseif starter_data.stats.speed >= 45 then
        speed_tier = "Average"
    else
        speed_tier = "Slow"
    end
    
    local bulk_tier = ""
    local bulk = (starter_data.stats.hp + starter_data.stats.defense + starter_data.stats.sp_defense) / 3
    if bulk >= 60 then
        bulk_tier = "Bulky"
    elseif bulk >= 45 then
        bulk_tier = "Average"
    else
        bulk_tier = "Frail"
    end
    
    if tier == "S" or tier == "A" then
        return "Excellent choice! " .. speed_tier .. " and " .. bulk_tier
    elseif tier == "B" then
        return "Good starter. " .. speed_tier .. " and " .. bulk_tier
    elseif tier == "C" then
        return "Decent option. " .. speed_tier .. " and " .. bulk_tier
    else
        return "Challenging pick. " .. speed_tier .. " and " .. bulk_tier
    end
end

-- Check and update starter detection
function starter_detector.update()
    local frame = emu.framecount()
    
    -- Only check every 30 frames
    if frame - starter_cache.last_check < 30 then
        return starter_cache.active
    end
    
    starter_cache.last_check = frame
    
    if starter_detector.isInStarterSelection() then
        if not starter_cache.active then
            -- Just entered starter selection
            console.log("Starter selection detected!")
            starter_cache.active = true
            starter_cache.starters = starter_detector.getStarterData()
        end
    else
        starter_cache.active = false
        starter_cache.starters = {}
    end
    
    return starter_cache.active
end

-- Get cached starter data
function starter_detector.getCachedData()
    return starter_cache.starters
end

-- Initialize the module
function starter_detector.initialize()
    console.log("Starter detector initialized")
end

return starter_detector