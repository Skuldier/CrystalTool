-- Pokemon Crystal Tier Rating Tool for BizHawk
-- Main entry point and initialization

-- Load required modules
local memory_reader = require("memory_reader")
local tier_calculator = require("tier_calculator")
local display = require("display")
local cache = require("cache")
local config = require("config")

-- Optional: Load starter detection addon
local has_starter_addon = pcall(require, "starter_addon")
if has_starter_addon then
    console.log("Starter detection enabled!")
end

-- Global state
local tool_state = {
    initialized = false,
    last_error = nil,
    frame_count = 0
}

-- Error handling wrapper
local function safe_call(func, ...)
    local status, result = pcall(func, ...)
    if not status then
        tool_state.last_error = result
        console.log("Error: " .. tostring(result))
        return nil
    end
    return result
end

-- Main update function called every frame
local function onFrameUpdate()
    if not tool_state.initialized then
        return
    end
    
    tool_state.frame_count = tool_state.frame_count + 1
    
    -- Only update based on config interval
    if tool_state.frame_count % config.performance.update_interval ~= 0 then
        return
    end
    
    -- Get Pokemon data (cached or fresh)
    local pokemon_data = nil
    if config.performance.cache_enabled then
        pokemon_data = cache.getCachedPokemonData()
    else
        pokemon_data = memory_reader.readPartyData()
    end
    
    if pokemon_data then
        -- Calculate tiers for each Pokemon
        local tier_results = {}
        for i, pokemon in pairs(pokemon_data) do
            if pokemon.species > 0 then  -- Valid Pokemon
                tier_results[i] = tier_calculator.calculateTierRating(pokemon)
            end
        end
        
        -- Display results
        if config.display.enabled then
            display.drawTierOverlay(pokemon_data, tier_results)
        end
    end
end

-- Memory write callback for party changes
local function onMemoryWrite(addr, val, flags)
    console.log("Party composition changed at address: " .. string.format("0x%04X", addr))
    cache.invalidate()
end

-- Initialize the tool
local function initialize()
    console.log("===========================================")
    console.log("Pokemon Crystal Tier Rating Tool v1.0")
    console.log("For use with Archipelago Randomizer")
    console.log("===========================================")
    
    -- Verify we're running Pokemon Crystal
    local game_code = memory.read_u32_be(0x134)
    if game_code ~= 0x504F4B45 then  -- "POKE" in hex
        console.log("Warning: This doesn't appear to be Pokemon Crystal!")
        console.log("Tool may not function correctly.")
    end
    
    -- Initialize submodules
    memory_reader.initialize()
    tier_calculator.initialize()
    display.initialize()
    cache.initialize()
    
    -- Set up event handlers
    event.onframeend(onFrameUpdate)
    
    -- Monitor party count changes
    if config.performance.event_driven then
        event.on_bus_write(onMemoryWrite, memory_reader.addresses.party_count, "party_change")
    end
    
    tool_state.initialized = true
    console.log("Initialization complete. Tool is running!")
    console.log("Press Lua Console 'Stop' button to disable.")
end

-- Cleanup function
local function cleanup()
    console.log("Shutting down Pokemon Crystal Tier Rating Tool...")
    tool_state.initialized = false
    -- Clear any remaining GUI elements
    gui.clearGraphics()
    gui.cleartext()
end

-- Register cleanup on script stop
event.onexit(cleanup)

-- Start the tool
safe_call(initialize)