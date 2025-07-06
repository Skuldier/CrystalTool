-- Configuration for Pokemon Crystal Tier Rating Tool
-- Modify these settings to customize the tool's behavior

local config = {
    -- Display settings
    display = {
        enabled = true,
        position = { x = 10, y = 10 },
        transparency = 0.7,  -- 0.0 = transparent, 1.0 = opaque
        show_stats = true,
        show_moves = true,
        show_type_effectiveness = true
    },
    
    -- Performance settings
    performance = {
        update_interval = 30,    -- Frames between updates (30 = 0.5 seconds at 60fps)
        cache_enabled = true,
        event_driven = true      -- Use memory write events for instant updates
    },
    
    -- Tier calculation weights
    -- These weights determine how much each factor contributes to the final tier
    -- Must sum to 1.0
    tier_weights = {
        base_stats = 0.25,       -- Raw stats importance
        type_advantage = 0.20,   -- Type matchup importance
        movepool = 0.25,         -- Move quality and coverage
        adaptability = 0.30      -- Flexibility in randomized contexts
    },
    
    -- Archipelago-specific settings
    archipelago_mode = true,
    archipelago_early_game_multiplier = true,
    
    -- Debug settings
    debug_mode = false,
    log_memory_reads = false,
    show_calculation_breakdown = true
}

-- Validate configuration
local function validateConfig()
    -- Check tier weights sum to 1.0
    local weight_sum = 0
    for _, weight in pairs(config.tier_weights) do
        weight_sum = weight_sum + weight
    end
    
    if math.abs(weight_sum - 1.0) > 0.01 then
        console.log("Warning: Tier weights sum to " .. weight_sum .. " instead of 1.0")
        console.log("Normalizing weights...")
        
        -- Normalize weights
        for key, weight in pairs(config.tier_weights) do
            config.tier_weights[key] = weight / weight_sum
        end
    end
    
    -- Ensure transparency is in valid range
    config.display.transparency = math.max(0, math.min(1, config.display.transparency))
    
    -- Ensure update interval is reasonable
    config.performance.update_interval = math.max(1, config.performance.update_interval)
end

-- Apply configuration
validateConfig()

return config