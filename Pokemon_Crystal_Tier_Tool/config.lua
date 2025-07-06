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
        show_type_effectiveness = true,
        show_dvs = false     -- Show DVs/IVs in display
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
    show_calculation_breakdown = true,
    
    -- Starter detection settings
    starter_detection = {
        enabled = true,
        show_recommendations = true,
        highlight_best = true
    },
    
    -- Advanced settings
    advanced = {
        -- Memory address overrides (if needed for different ROM versions)
        memory_overrides = {
            -- Example: party_count = 0xDCD7
        },
        
        -- Custom tier boundaries
        tier_boundaries = {
            S = 85,  -- 85+ = S tier
            A = 70,  -- 70-84 = A tier
            B = 55,  -- 55-69 = B tier
            C = 40,  -- 40-54 = C tier
            D = 25,  -- 25-39 = D tier
            F = 0    -- 0-24 = F tier
        }
    }
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
    
    -- Validate tier boundaries
    local last_value = 100
    for tier, min_value in pairs(config.advanced.tier_boundaries) do
        if min_value > last_value then
            console.log("Warning: Invalid tier boundaries detected")
            -- Reset to defaults
            config.advanced.tier_boundaries = {
                S = 85, A = 70, B = 55, C = 40, D = 25, F = 0
            }
            break
        end
        last_value = min_value
    end
end

-- Save configuration to file
function config.save()
    -- This would save to a file if BizHawk supported it
    console.log("Configuration saved (in memory)")
end

-- Load configuration from file
function config.load()
    -- This would load from a file if BizHawk supported it
    console.log("Configuration loaded (defaults)")
end

-- Get a config value with fallback
function config.get(path, default)
    local value = config
    for part in string.gmatch(path, "[^.]+") do
        if type(value) == "table" and value[part] ~= nil then
            value = value[part]
        else
            return default
        end
    end
    return value
end

-- Set a config value
function config.set(path, value)
    local parts = {}
    for part in string.gmatch(path, "[^.]+") do
        table.insert(parts, part)
    end
    
    local current = config
    for i = 1, #parts - 1 do
        if type(current[parts[i]]) ~= "table" then
            current[parts[i]] = {}
        end
        current = current[parts[i]]
    end
    
    current[parts[#parts]] = value
    validateConfig()
end

-- Apply configuration
validateConfig()

return config