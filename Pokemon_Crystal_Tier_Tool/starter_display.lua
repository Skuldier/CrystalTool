-- Starter Display Module for Pokemon Crystal
-- Shows tier ratings during starter selection

local starter_display = {}

-- Display configuration
local display_config = {
    x = 10,
    y = 140,
    width = 220,
    height = 100,
    bg_color = 0x000000DD,
    border_color = 0xFFFFFFFF,
    
    -- Starter positions (roughly where they appear on screen)
    positions = {
        {x = 10, label = "Left"},    -- Cyndaquil position
        {x = 80, label = "Middle"},  -- Totodile position  
        {x = 150, label = "Right"}   -- Chikorita position
    }
}

-- Tier colors
local tier_colors = {
    ["S"] = 0xFF0000FF,  -- Red
    ["A"] = 0xFFA500FF,  -- Orange
    ["B"] = 0xFFFF00FF,  -- Yellow
    ["C"] = 0x00FF00FF,  -- Green
    ["D"] = 0x0000FFFF,  -- Blue
    ["F"] = 0x808080FF   -- Gray
}

-- Draw individual starter info
local function drawStarterInfo(x, y, starter, rating)
    local width = 65
    local height = 80
    
    -- Background box
    gui.drawRectangle(x, y, width, height, 0x333333FF, 0x222222EE)
    
    -- Position label
    gui.text(x + 5, y + 3, display_config.positions[starter.position].label, "White", "Clear", 9)
    
    -- Pokemon name
    local name = starter.name
    if string.len(name) > 9 then
        name = string.sub(name, 1, 8) .. "."
    end
    gui.text(x + 5, y + 15, name, "White", "Clear", 9)
    
    -- Tier badge
    local tier_color = tier_colors[rating.tier] or 0x808080FF
    gui.drawRectangle(x + 5, y + 28, 55, 16, tier_color, tier_color)
    gui.text(x + 20, y + 31, "Tier " .. rating.tier, "White", "Clear", 10)
    
    -- Score
    gui.text(x + 5, y + 48, "Score: " .. rating.score, "White", "Clear", 9)
    
    -- Mini stats
    local stats = starter.stats
    gui.text(x + 5, y + 60, "BST: " .. stats.total, "Gray", "Clear", 8)
    gui.text(x + 5, y + 70, "SPD: " .. stats.speed, "Cyan", "Clear", 8)
end

-- Draw the complete starter selection overlay
function starter_display.drawStarterOverlay(starter_data, ratings)
    if not starter_data or #starter_data == 0 then
        return
    end
    
    -- Main background
    gui.drawRectangle(display_config.x, display_config.y, 
                     display_config.width, display_config.height,
                     display_config.border_color, display_config.bg_color)
    
    -- Title
    gui.text(display_config.x + 5, display_config.y + 5, 
            "STARTER SELECTION - Choose Wisely!", "Yellow", "Clear", 11)
    
    -- Draw each starter
    local start_x = display_config.x + 5
    for i = 1, 3 do
        if starter_data[i] and ratings[i] then
            drawStarterInfo(start_x + (i-1) * 70, display_config.y + 20, 
                          starter_data[i], ratings[i])
        end
    end
    
    -- Best choice indicator
    local best_score = 0
    local best_index = 1
    for i, rating in ipairs(ratings) do
        if rating.score > best_score then
            best_score = rating.score
            best_index = i
        end
    end
    
    -- Highlight best choice
    local best_x = start_x + (best_index-1) * 70
    gui.drawRectangle(best_x - 2, display_config.y + 18, 69, 84, 0xFFFF00FF, 0x00000000)
    
    -- Recommendation text
    if ratings[best_index] then
        gui.text(display_config.x + 5, display_config.y + 105,
                "Recommended: " .. display_config.positions[best_index].label .. 
                " - " .. ratings[best_index].recommendation,
                "Yellow", "Clear", 9)
    end
end

-- Simple display for debugging
function starter_display.drawDebugInfo(active, data)
    gui.text(10, 10, "Starter Detection: " .. (active and "ACTIVE" or "Inactive"), 
            active and "Green" or "Gray")
    
    if active and data then
        local y = 25
        for i, starter in ipairs(data) do
            gui.text(10, y, string.format("%d: %s (#%d)", 
                    i, starter.name or "???", starter.species_id), "White")
            y = y + 15
        end
    end
end

return starter_display