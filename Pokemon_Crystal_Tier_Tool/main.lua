-- Pokemon Crystal Tier Rating Tool for BizHawk
-- Main entry point and initialization
-- Updated with comprehensive memory support

-- Load required modules
local memory_reader = require("memory_reader")
local tier_calculator = require("tier_calculator")
local display = require("display")
local cache = require("cache")
local config = require("config")
local starter_detector = require("starter_detector")

-- Global state
local tool_state = {
    initialized = false,
    last_error = nil,
    frame_count = 0,
    version = "2.0",
    game_detected = false
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

-- Verify we're running Pokemon Crystal
local function verifyGame()
    -- Check ROM header for Pokemon Crystal
    local title_addr = 0x134
    local title_bytes = {}
    
    for i = 0, 15 do
        local byte = memory.readbyte(title_addr + i, "ROM")
        if byte == 0 then break end
        table.insert(title_bytes, byte)
    end
    
    -- Convert to string and check
    local title = ""
    for _, byte in ipairs(title_bytes) do
        title = title .. string.char(byte)
    end
    
    console.log("ROM Title: " .. title)
    
    -- Check if it's Pokemon Crystal
    if string.find(title, "CRYSTAL") or string.find(title, "PM_CRYSTAL") then
        console.log("Pokemon Crystal detected!")
        tool_state.game_detected = true
        return true
    else
        console.log("Warning: This doesn't appear to be Pokemon Crystal!")
        console.log("Tool may not function correctly.")
        return false
    end
end

-- Main update function called every frame
local function onFrameUpdate()
    if not tool_state.initialized then
        return
    end
    
    tool_state.frame_count = tool_state.frame_count + 1
    
    -- Update starter detector
    local starter_active = starter_detector.update()
    
    -- If in starter selection, show starter overlay
    if starter_active then
        local starter_data = starter_detector.getCachedData()
        if starter_data then
            local ratings = {}
            for i, starter in ipairs(starter_data) do
                ratings[i] = starter_detector.rateStarter(starter)
            end
            display.drawStarterOverlay(starter_data, ratings)
        end
        return  -- Don't show party overlay during starter selection
    end
    
    -- Only update party display based on config interval
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
    
    -- Show debug info if enabled
    if config.debug_mode and tool_state.frame_count % 300 == 0 then
        cache.debugPrintStatus()
    end
end

-- Memory write callback for party changes
local function onMemoryWrite(addr, val, flags)
    console.log("Party composition changed at address: " .. string.format("0x%04X", addr))
    cache.invalidate()
end

-- Handle key presses
local function onKeyPress()
    local keys = input.get()
    
    -- Toggle display with F1
    if keys["F1"] then
        config.display.enabled = not config.display.enabled
        console.log("Display " .. (config.display.enabled and "enabled" or "disabled"))
    end
    
    -- Toggle display mode with F2
    if keys["F2"] then
        display.toggleDisplayMode()
    end
    
    -- Debug dump with F3
    if keys["F3"] and config.debug_mode then
        console.log("=== Debug Dump ===")
        memory_reader.debugDumpPokemon(0)  -- Dump first Pokemon
        cache.debugPrintStatus()
        starter_detector.debug()
    end
    
    -- Show cache performance with F4
    if keys["F4"] then
        local perf = cache.getPerformanceStats()
        console.log(string.format("Cache Performance: %.1f%% hit rate (%d hits/%d total)",
            perf.hit_rate, perf.cache_hits, perf.total_reads))
    end
end

-- Initialize the tool
local function initialize()
    console.log("===========================================")
    console.log("Pokemon Crystal Tier Rating Tool v" .. tool_state.version)
    console.log("For use with Archipelago Randomizer")
    console.log("===========================================")
    
    -- Verify game
    verifyGame()
    
    -- Initialize submodules
    memory_reader.initialize()
    tier_calculator.initialize()
    display.initialize()
    cache.initialize()
    starter_detector.initialize()
    
    -- Set up event handlers
    event.onframeend(onFrameUpdate)
    
    -- Monitor party count changes
    if config.performance.event_driven then
        event.on_bus_write(onMemoryWrite, memory_reader.addresses.party_count, "party_change")
    end
    
    -- Set up key monitoring
    event.onframestart(onKeyPress)
    
    tool_state.initialized = true
    console.log("Initialization complete. Tool is running!")
    console.log("")
    console.log("Controls:")
    console.log("  F1 - Toggle display on/off")
    console.log("  F2 - Toggle between full/minimal display")
    if config.debug_mode then
        console.log("  F3 - Debug dump (debug mode)")
        console.log("  F4 - Show cache performance")
    end
    console.log("")
    console.log("Approach Pokemon balls in Elm's lab to see starter ratings!")
end

-- Cleanup function
local function cleanup()
    console.log("Shutting down Pokemon Crystal Tier Rating Tool...")
    tool_state.initialized = false
    
    -- Clear any remaining GUI elements
    gui.clearGraphics()
    gui.cleartext()
    
    -- Show final cache performance
    if config.performance.cache_enabled then
        local perf = cache.getPerformanceStats()
        console.log(string.format("Final cache performance: %.1f%% hit rate", perf.hit_rate))
    end
end

-- Register cleanup on script stop
event.onexit(cleanup)

-- Handle errors gracefully
local function errorHandler(err)
    console.log("FATAL ERROR: " .. tostring(err))
    console.log("Stack trace:")
    console.log(debug.traceback())
    tool_state.initialized = false
end

-- Start the tool with error handling
xpcall(initialize, errorHandler)