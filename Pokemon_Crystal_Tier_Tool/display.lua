-- Display Module for Pokemon Crystal Tier Tool
-- Handles all GUI rendering and overlay display

local display = {}

-- Load configuration
local config = require("config")
local pokemon_base_stats = require("data.pokemon_base_stats")

-- Display configuration
local display_config = {
    x = config.display.position.x or 10,
    y = config.display.position.y or 10,
    width = 240,
    height = 180,
    bg_color = 0x000000CC,    -- Semi-transparent black
    border_color = 0x333333FF,
    text_color = "White",
    
    -- Positioning
    padding = 5,
    line_height = 14,
    section_spacing = 20,
    
    -- Stat bar configuration
    stat_bar_width = 60,
    stat_bar_height = 4,
    stat_bar_spacing = 2
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

-- Type colors for display
local type_colors = {
    Normal = 0xA8A878FF,
    Fighting = 0xC03028FF,
    Flying = 0xA890F0FF,
    Poison = 0xA040A0FF,
    Ground = 0xE0C068FF,
    Rock = 0xB8A038FF,
    Bug = 0xA8B820FF,
    Ghost = 0x705898FF,
    Steel = 0xB8B8D0FF,
    Fire = 0xF08030FF,
    Water = 0x6890F0FF,
    Grass = 0x78C850FF,
    Electric = 0xF8D030FF,
    Psychic = 0xF85888FF,
    Ice = 0x98D8D8FF,
    Dragon = 0x7038F8FF,
    Dark = 0x705848FF
}

-- Initialize display module
function display.initialize()
    console.log("Display module initialized")
end

-- Draw a stat bar
local function drawStatBar(x, y, value, max_value, color)
    local bar_width = display_config.stat_bar_width
    local bar_height = display_config.stat_bar_height
    local filled_width = math.floor((value / max_value) * bar_width)
    
    -- Background
    gui.drawRectangle(x, y, bar_width, bar_height, 0x404040FF, 0x404040FF)
    
    -- Filled portion
    if filled_width > 0 then
        gui.drawRectangle(x, y, filled_width, bar_height, color, color)
    end
end

-- Draw Pokemon stats bars
local function drawStatBars(x, y, pokemon)
    local stats = {
        { name = "HP", value = pokemon.current_hp, max = pokemon.max_hp, color = 0xFF0000FF },
        { name = "ATK", value = pokemon.attack, max = 255, color = 0xFFA500FF },
        { name = "DEF", value = pokemon.defense, max = 255, color = 0xFFFF00FF },
        { name = "SPD", value = pokemon.speed, max = 255, color = 0x00FF00FF },
        { name = "SPA", value = pokemon.sp_attack, max = 255, color = 0x00FFFFFF },
        { name = "SPD", value = pokemon.sp_defense, max = 255, color = 0xFF00FFFF }
    }
    
    local current_y = y
    for i, stat in ipairs(stats) do
        -- Draw stat name
        gui.pixelText(x, current_y, stat.name .. ":", "White", 0x00000000)
        
        -- Draw stat bar
        drawStatBar(x + 25, current_y, stat.value, stat.max, stat.color)
        
        -- Draw value
        gui.pixelText(x + 90, current_y, tostring(stat.value), "White", 0x00000000)
        
        current_y = current_y + display_config.stat_bar_height + display_config.stat_bar_spacing
    end
end

-- Draw type badges
local function drawTypes(x, y, types)
    local type1_color = type_colors[types.type1_name] or 0x808080FF
    local type2_color = type_colors[types.type2_name] or 0x808080FF
    
    -- Type 1
    gui.drawRectangle(x, y, 40, 12, type1_color, type1_color)
    gui.pixelText(x + 2, y + 2, types.type1_name, "White", 0x00000000)
    
    -- Type 2 (if different)
    if types.type2 ~= types.type1 and types.type2 ~= 0 then
        gui.drawRectangle(x + 45, y, 40, 12, type2_color, type2_color)
        gui.pixelText(x + 47, y + 2, types.type2_name, "White", 0x00000000)
    end
end

-- Draw move list
local function drawMoves(x, y, pokemon)
    local move_data = require("data.move_data")
    local current_y = y
    
    gui.pixelText(x, current_y, "Moves:", "White", 0x00000000)
    current_y = current_y + 10
    
    for i, move_id in ipairs(pokemon.moves) do
        if move_id > 0 then
            local move = move_data.getMoveData(move_id)
            if move then
                local move_text = string.format("%s (P:%d)", move.name, move.power or 0)
                local move_color = type_colors[move.type_name] or 0x808080FF
                
                -- Draw move with type color background
                gui.drawRectangle(x, current_y, 80, 10, move_color, move_color)
                gui.pixelText(x + 2, current_y + 1, move_text, "White", 0x00000000)
                
                current_y = current_y + 11
            end
        end
    end
end

-- Draw a single Pokemon panel
local function drawPokemonPanel(x, y, pokemon, tier_result, slot)
    local panel_width = display_config.width - (display_config.padding * 2)
    local panel_height = config.display.show_stats and 140 or 60
    
    -- Panel background
    gui.drawRectangle(x, y, panel_width, panel_height, 0x333333FF, 0x222222DD)
    
    -- Header with species name and tier
    local species_name = pokemon_base_stats.getSpeciesName(pokemon.species) or ("Species " .. pokemon.species)
    local header_text = string.format("Slot %d: %s Lv.%d", slot + 1, species_name, pokemon.level)
    gui.pixelText(x + 5, y + 5, header_text, "White", 0x00000000)
    
    -- Tier badge
    local tier_x = x + panel_width - 50
    local tier_color = tier_colors[tier_result.tier] or 0x808080FF
    gui.drawRectangle(tier_x, y + 3, 45, 16, tier_color, tier_color)
    gui.pixelText(tier_x + 5, y + 6, "Tier " .. tier_result.tier, "White", 0x00000000)
    
    -- Score
    local score_text = string.format("%.1f", tier_result.score)
    gui.pixelText(tier_x + 5, y + 20, score_text, "White", 0x00000000)
    
    local current_y = y + 25
    
    -- Types
    if config.display.show_type_effectiveness then
        drawTypes(x + 5, current_y, pokemon.types)
        current_y = current_y + 15
    end
    
    -- Stats
    if config.display.show_stats then
        drawStatBars(x + 5, current_y, pokemon)
        current_y = current_y + 40
    end
    
    -- Moves
    if config.display.show_moves then
        drawMoves(x + 5, current_y, pokemon)
    end
    
    -- Tier breakdown (if space allows)
    if tier_result.breakdown and y < 100 then
        local breakdown_y = y + panel_height - 15
        local breakdown_text = string.format("B:%d T:%d M:%d A:%d", 
            tier_result.breakdown.bst,
            tier_result.breakdown.type,
            tier_result.breakdown.movepool,
            tier_result.breakdown.adaptability)
        gui.pixelText(x + 5, breakdown_y, breakdown_text, "Gray", 0x00000000)
    end
end

-- Main overlay drawing function
function display.drawTierOverlay(pokemon_data, tier_results)
    if not config.display.enabled then
        return
    end
    
    -- Clear previous graphics
    gui.clearGraphics()
    
    -- Count valid Pokemon
    local pokemon_count = 0
    for _, pokemon in pairs(pokemon_data) do
        if pokemon and pokemon.species > 0 then
            pokemon_count = pokemon_count + 1
        end
    end
    
    if pokemon_count == 0 then
        return  -- No Pokemon to display
    end
    
    -- Calculate dynamic height based on content
    local total_height = 30 + (pokemon_count * 150)  -- Rough estimate
    if not config.display.show_stats then
        total_height = 30 + (pokemon_count * 70)
    end
    
    -- Main background
    local bg_alpha = math.floor(config.display.transparency * 255)
    local bg_color = (0x000000 * 0x100) + bg_alpha
    gui.drawRectangle(display_config.x, display_config.y, 
                     display_config.width, math.min(total_height, 400),
                     display_config.border_color, bg_color)
    
    -- Title
    gui.drawText(display_config.x + 5, display_config.y + 5, 
                "Pokemon Tier Ratings", "White", 12)
    
    -- Draw each Pokemon
    local current_y = display_config.y + 25
    for slot = 0, 5 do
        local pokemon = pokemon_data[slot]
        local tier_result = tier_results[slot]
        
        if pokemon and tier_result then
            drawPokemonPanel(display_config.x + display_config.padding, 
                           current_y, pokemon, tier_result, slot)
            current_y = current_y + (config.display.show_stats and 145 or 65)
        end
    end
    
    -- Footer with timestamp
    local timestamp = os.date("%H:%M:%S")
    gui.pixelText(display_config.x + 5, current_y + 5, 
                 "Updated: " .. timestamp, "Gray", 0x00000000)
end

-- Draw minimal overlay (just tiers)
function display.drawMinimalOverlay(pokemon_data, tier_results)
    gui.clearGraphics()
    
    local x = display_config.x
    local y = display_config.y
    
    -- Background
    gui.drawRectangle(x, y, 200, 100, 0x333333FF, 0x000000CC)
    
    -- Title
    gui.pixelText(x + 5, y + 5, "Pokemon Tiers", "White", 0x00000000)
    
    -- List each Pokemon with tier
    local current_y = y + 15
    for slot = 0, 5 do
        local pokemon = pokemon_data[slot]
        local tier_result = tier_results[slot]
        
        if pokemon and tier_result then
            local species_name = pokemon_base_stats.getSpeciesName(pokemon.species) or ("?" .. pokemon.species)
            local text = string.format("%d. %s - %s", slot + 1, species_name, tier_result.tier)
            local color = tier_colors[tier_result.tier] or 0x808080FF
            
            gui.pixelText(x + 5, current_y, text, color, 0x00000000)
            current_y = current_y + 12
        end
    end
end

-- Toggle between full and minimal display
function display.toggleDisplayMode()
    config.display.show_stats = not config.display.show_stats
    config.display.show_moves = not config.display.show_moves
    console.log("Display mode: " .. (config.display.show_stats and "Full" or "Minimal"))
end

return display