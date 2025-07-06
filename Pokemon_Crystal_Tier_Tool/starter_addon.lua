-- Starter Detection Add-on for Pokemon Crystal Tier Tool
-- Simple all-in-one module to add starter ratings

-- Just add this line to your main.lua after other requires:
-- require("starter_addon")

local starter_addon = {}

-- Configuration
local STARTER_CONFIG = {
    -- Memory addresses for starters (update if needed)
    addresses = {
        elm_lab_map = 0x08,
        current_map = 0xDCB5,
        starter1 = 0xD8E8,  -- Left starter
        starter2 = 0xD8E9,  -- Middle starter
        starter3 = 0xD8EA,  -- Right starter
    },
    
    -- Display settings
    display = {
        x = 10,
        y = 140,
        enabled = true
    }
}

-- Cache
local cache = {
    active = false,
    starters = {},
    last_check = 0
}

-- Check if in starter selection
local function isInStarterSelection()
    local current_map = memory.readbyte(STARTER_CONFIG.addresses.current_map)
    return current_map == STARTER_CONFIG.addresses.elm_lab_map
end

-- Read starter IDs
local function readStarters()
    local s1 = memory.readbyte(STARTER_CONFIG.addresses.starter1)
    local s2 = memory.readbyte(STARTER_CONFIG.addresses.starter2)
    local s3 = memory.readbyte(STARTER_CONFIG.addresses.starter3)
    
    -- Validate
    if s1 > 0 and s1 <= 251 and s2 > 0 and s2 <= 251 and s3 > 0 and s3 <= 251 then
        return {s1, s2, s3}
    end
    
    -- Default to standard starters
    return {155, 158, 152}  -- Cyndaquil, Totodile, Chikorita
end

-- Simple tier calculation for starters
local function rateStarter(species_id)
    -- Try to get base stats
    local ok, base_stats = pcall(function()
        local pokemon_base_stats = require("data.pokemon_base_stats")
        return pokemon_base_stats.getBaseStats(species_id)
    end)
    
    if not ok or not base_stats then
        return "?", 50  -- Unknown
    end
    
    local total = base_stats.total
    local speed = base_stats.speed
    
    -- Simple tier calculation
    local score = 0
    
    -- Base stat score
    if total >= 500 then score = score + 40
    elseif total >= 400 then score = score + 30
    elseif total >= 320 then score = score + 20
    else score = score + 10 end
    
    -- Speed bonus
    if speed >= 80 then score = score + 30
    elseif speed >= 60 then score = score + 20
    elseif speed >= 45 then score = score + 10
    else score = score + 0 end
    
    -- Early game bonus
    score = score + 20
    
    -- Determine tier
    if score >= 80 then return "S", score
    elseif score >= 65 then return "A", score
    elseif score >= 50 then return "B", score
    elseif score >= 35 then return "C", score
    elseif score >= 20 then return "D", score
    else return "F", score end
end

-- Draw starter overlay
local function drawStarterOverlay()
    if not STARTER_CONFIG.display.enabled then return end
    
    local x = STARTER_CONFIG.display.x
    local y = STARTER_CONFIG.display.y
    
    -- Background
    gui.drawRectangle(x, y, 220, 80, 0xFFFFFFFF, 0x000000DD)
    
    -- Title
    gui.text(x + 5, y + 5, "STARTER SELECTION", "Yellow", "Clear", 11)
    
    -- Get starter data
    local starters = readStarters()
    local positions = {"Left", "Middle", "Right"}
    
    -- Draw each starter
    for i = 1, 3 do
        local start_x = x + 5 + (i-1) * 70
        local species_id = starters[i]
        
        -- Get name
        local name = "???"
        local ok, base_stats = pcall(function()
            local pokemon_base_stats = require("data.pokemon_base_stats")
            return pokemon_base_stats.getBaseStats(species_id)
        end)
        
        if ok and base_stats then
            name = base_stats.name
            if string.len(name) > 8 then
                name = string.sub(name, 1, 7) .. "."
            end
        end
        
        -- Get tier
        local tier, score = rateStarter(species_id)
        
        -- Draw box
        gui.drawRectangle(start_x, y + 20, 65, 55, 0x666666FF, 0x333333EE)
        
        -- Position
        gui.text(start_x + 5, y + 23, positions[i], "White", "Clear", 9)
        
        -- Name
        gui.text(start_x + 5, y + 35, name, "White", "Clear", 9)
        
        -- Tier
        local tier_color = "White"
        if tier == "S" then tier_color = "Red"
        elseif tier == "A" then tier_color = "Orange"
        elseif tier == "B" then tier_color = "Yellow"
        elseif tier == "C" then tier_color = "Green"
        elseif tier == "D" then tier_color = "Blue"
        else tier_color = "Gray" end
        
        gui.text(start_x + 5, y + 47, "Tier " .. tier, tier_color, "Clear", 10)
        gui.text(start_x + 5, y + 60, "(" .. score .. ")", "Gray", "Clear", 8)
    end
end

-- Update function to be called each frame
function starter_addon.update()
    local frame = emu.framecount()
    
    -- Only check every 30 frames
    if frame - cache.last_check < 30 then
        if cache.active then
            drawStarterOverlay()
        end
        return
    end
    
    cache.last_check = frame
    
    -- Check if in starter selection
    if isInStarterSelection() then
        cache.active = true
        drawStarterOverlay()
    else
        cache.active = false
    end
end

-- Hook into the frame update
event.onframeend(starter_addon.update)

console.log("Starter detection add-on loaded!")
console.log("Approach the Pokemon in Elm's lab to see ratings")

return starter_addon