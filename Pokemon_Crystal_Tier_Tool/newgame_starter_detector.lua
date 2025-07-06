-- New Game Starter Detection for Archipelago Pokemon Crystal
-- Detects starters during new game creation

local newgame_starter = {}

-- Memory addresses for new game starter selection
local ADDRESSES = {
    -- Game state indicators
    game_state = 0xCE5F,        -- Game state/mode
    menu_state = 0xCF63,        -- Current menu
    
    -- Potential starter locations during new game
    -- These need to be found with the scanner
    starter_option1 = 0xD000,   -- First starter option
    starter_option2 = 0xD001,   -- Second starter option  
    starter_option3 = 0xD002,   -- Third starter option
    
    -- Alternative locations
    alt_starter1 = 0xCFA0,
    alt_starter2 = 0xCFA1,
    alt_starter3 = 0xCFA2,
    
    -- Text/menu related
    text_buffer = 0xC5B9,       -- Where text is stored
    cursor_position = 0xCF64,   -- Menu cursor
}

-- Cache
local cache = {
    active = false,
    starters = {},
    last_check = 0,
    found_addresses = nil
}

-- Scan for starter selection screen patterns
function newgame_starter.scanForStarters()
    local patterns_found = {}
    
    -- Look for three consecutive Pokemon IDs in various memory regions
    local scan_ranges = {
        {0xC000, 0xC500, "Lower WRAM"},
        {0xCF00, 0xD100, "Menu RAM"},
        {0xD000, 0xD500, "Upper WRAM"},
        {0xCC00, 0xCE00, "Mid WRAM"}
    }
    
    for _, range in ipairs(scan_ranges) do
        local start_addr, end_addr, name = range[1], range[2], range[3]
        
        for addr = start_addr, end_addr - 3 do
            local val1 = memory.readbyte(addr)
            local val2 = memory.readbyte(addr + 1)
            local val3 = memory.readbyte(addr + 2)
            
            -- Check if these could be Pokemon IDs
            if val1 > 0 and val1 <= 251 and
               val2 > 0 and val2 <= 251 and
               val3 > 0 and val3 <= 251 and
               val1 ~= val2 and val2 ~= val3 then  -- Different Pokemon
                
                table.insert(patterns_found, {
                    address = addr,
                    values = {val1, val2, val3},
                    region = name
                })
            end
        end
    end
    
    return patterns_found
end

-- Check if we're in new game starter selection
function newgame_starter.isInStarterSelection()
    -- This is tricky - we need to detect the Archipelago starter menu
    -- Look for specific patterns that indicate starter selection
    
    -- Check various indicators
    local game_state = memory.readbyte(ADDRESSES.game_state)
    local menu_state = memory.readbyte(ADDRESSES.menu_state)
    
    -- Try to detect by looking for the starter Pokemon in memory
    if not cache.found_addresses then
        local scan_results = newgame_starter.scanForStarters()
        if #scan_results > 0 then
            cache.found_addresses = scan_results[1].address
            console.log("Found potential starters at: " .. string.format("0x%04X", cache.found_addresses))
        end
    end
    
    return cache.found_addresses ~= nil
end

-- Read starter options
function newgame_starter.readStarters()
    if cache.found_addresses then
        local addr = cache.found_addresses
        return {
            memory.readbyte(addr),
            memory.readbyte(addr + 1),
            memory.readbyte(addr + 2)
        }
    end
    
    -- Try default addresses
    local s1 = memory.readbyte(ADDRESSES.starter_option1)
    local s2 = memory.readbyte(ADDRESSES.starter_option2)
    local s3 = memory.readbyte(ADDRESSES.starter_option3)
    
    if s1 > 0 and s1 <= 251 then
        return {s1, s2, s3}
    end
    
    -- Try alt addresses
    s1 = memory.readbyte(ADDRESSES.alt_starter1)
    s2 = memory.readbyte(ADDRESSES.alt_starter2)
    s3 = memory.readbyte(ADDRESSES.alt_starter3)
    
    if s1 > 0 and s1 <= 251 then
        return {s1, s2, s3}
    end
    
    return {}
end

-- Simple tier calculation
function newgame_starter.rateStarter(species_id)
    local ok, base_stats = pcall(function()
        local pokemon_base_stats = require("data.pokemon_base_stats")
        return pokemon_base_stats.getBaseStats(species_id)
    end)
    
    if not ok or not base_stats then
        return "?", 50, "Unknown Pokemon"
    end
    
    local score = 0
    local total = base_stats.total
    local speed = base_stats.speed
    
    -- Base stat scoring
    score = score + math.min(40, (total - 250) / 10)
    
    -- Speed is crucial early game
    score = score + math.min(30, speed / 3)
    
    -- Offensive presence
    local offense = math.max(base_stats.attack, base_stats.sp_attack)
    score = score + math.min(20, offense / 5)
    
    -- Early game bonus
    score = score + 10
    
    -- Determine tier
    local tier = "F"
    if score >= 85 then tier = "S"
    elseif score >= 70 then tier = "A"
    elseif score >= 55 then tier = "B"
    elseif score >= 40 then tier = "C"
    elseif score >= 25 then tier = "D"
    end
    
    return tier, math.floor(score), base_stats.name
end

-- Draw overlay
function newgame_starter.draw()
    local starters = newgame_starter.readStarters()
    if #starters < 3 then return end
    
    -- Main overlay
    gui.drawRectangle(10, 10, 220, 100, 0xFFFFFFFF, 0x000000DD)
    gui.text(15, 15, "ARCHIPELAGO STARTER SELECTION", "Yellow", "Clear", 11)
    
    -- Draw each starter
    for i = 1, 3 do
        local x = 15 + (i-1) * 70
        local y = 35
        
        local tier, score, name = newgame_starter.rateStarter(starters[i])
        
        -- Box for each starter
        gui.drawRectangle(x, y, 65, 60, 0x666666FF, 0x333333EE)
        
        -- Option number
        gui.text(x + 5, y + 3, "Option " .. i, "White", "Clear", 9)
        
        -- Pokemon name
        if string.len(name) > 8 then
            name = string.sub(name, 1, 7) .. "."
        end
        gui.text(x + 5, y + 15, name, "Cyan", "Clear", 9)
        
        -- Tier
        local tier_color = "White"
        if tier == "S" then tier_color = "Red"
        elseif tier == "A" then tier_color = "Orange" 
        elseif tier == "B" then tier_color = "Yellow"
        elseif tier == "C" then tier_color = "Green"
        elseif tier == "D" then tier_color = "Blue"
        end
        
        gui.text(x + 5, y + 28, "Tier: " .. tier, tier_color, "Clear", 10)
        gui.text(x + 5, y + 42, "Score: " .. score, "White", "Clear", 8)
    end
    
    -- Instructions
    gui.text(15, 115, "Scanning for starters... If wrong, use scanner", "Gray", "Clear", 8)
end

-- Update function
function newgame_starter.update()
    local frame = emu.framecount()
    
    -- Continuous scanning mode
    if frame % 10 == 0 then  -- Scan frequently
        local scan_results = newgame_starter.scanForStarters()
        
        if #scan_results > 0 then
            -- Check if any results look like valid starters
            for _, result in ipairs(scan_results) do
                local vals = result.values
                -- Basic validation - different Pokemon, reasonable IDs
                if vals[1] ~= vals[2] and vals[2] ~= vals[3] then
                    cache.found_addresses = result.address
                    cache.active = true
                    cache.starters = vals
                    break
                end
            end
        end
    end
    
    -- Draw if active
    if cache.active then
        newgame_starter.draw()
    end
end

-- Hook into frame updates
event.onframeend(newgame_starter.update)

console.log("New Game Starter Detector loaded!")
console.log("Start a new game to see starter options")

return newgame_starter