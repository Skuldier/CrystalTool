-- Cache Module for Pokemon Crystal Tier Tool
-- Handles caching to reduce memory reads and improve performance
-- Updated to work with new memory structure

local cache = {}

-- Load required modules
local memory_reader = require("memory_reader")
local config = require("config")

-- Cache storage
local cache_data = {
    pokemon_data = {},
    last_update_frame = 0,
    party_checksum = 0,
    invalidated = false,
    player_info = nil,
    player_info_frame = 0
}

-- Initialize cache
function cache.initialize()
    console.log("Cache system initialized")
    cache_data.last_update_frame = emu.framecount()
end

-- Calculate a comprehensive checksum of party data for change detection
local function calculatePartyChecksum()
    local checksum = 0
    
    -- Include party count
    local party_count = memory.readbyte(memory_reader.addresses.party_count)
    
    -- Validate party count
    if party_count > 6 then
        return 0  -- Invalid state, force cache update
    end
    
    checksum = checksum + party_count
    
    -- Include species IDs with position weighting
    for i = 0, 5 do
        local species = memory.readbyte(memory_reader.addresses.party_species + i)
        checksum = checksum + (species * (i + 1))
    end
    
    -- Include key data from each party Pokemon
    for i = 0, math.min(party_count - 1, 5) do
        local base_addr = memory_reader.addresses.party_data_start + (i * 48)
        
        -- Level
        local level = memory.readbyte(base_addr + memory_reader.addresses.level_offset)
        checksum = checksum + (level * 100)
        
        -- Current HP (to detect healing/damage)
        local current_hp = memory.read_u16_be(base_addr + memory_reader.addresses.current_hp_offset)
        checksum = checksum + current_hp
        
        -- Status (to detect status changes)
        local status = memory.readbyte(base_addr + memory_reader.addresses.status_offset)
        checksum = checksum + (status * 10)
        
        -- First move (to detect move learning)
        local move1 = memory.readbyte(base_addr + memory_reader.addresses.moves_offset)
        checksum = checksum + (move1 * 5)
        
        -- Happiness (changes frequently) - only if we have the offset
        if memory_reader.addresses.happiness_offset then
            local happiness = memory.readbyte(base_addr + memory_reader.addresses.happiness_offset)
            checksum = checksum + happiness
        end
    end
    
    return checksum
end

-- Check if cache needs updating
local function shouldUpdateCache()
    local current_frame = emu.framecount()
    
    -- Check if manually invalidated
    if cache_data.invalidated then
        return true
    end
    
    -- Check frame interval
    local frames_since_update = current_frame - cache_data.last_update_frame
    if frames_since_update < config.performance.update_interval then
        return false
    end
    
    -- Check if party data changed
    local current_checksum = calculatePartyChecksum()
    if current_checksum ~= cache_data.party_checksum then
        console.log("Party checksum changed: " .. cache_data.party_checksum .. " -> " .. current_checksum)
        return true
    end
    
    return false
end

-- Update the cache with fresh data
local function updateCache()
    local current_frame = emu.framecount()
    
    -- Read fresh data
    cache_data.pokemon_data = memory_reader.readPartyData()
    cache_data.last_update_frame = current_frame
    cache_data.party_checksum = calculatePartyChecksum()
    cache_data.invalidated = false
    
    -- Log cache update
    if config.debug_mode then
        console.log("Cache updated at frame " .. current_frame)
        
        -- Log party composition
        local party_count = 0
        for _, pokemon in pairs(cache_data.pokemon_data) do
            if pokemon then
                party_count = party_count + 1
            end
        end
        console.log("Cached " .. party_count .. " Pokemon")
    end
end

-- Get cached Pokemon data
function cache.getCachedPokemonData()
    if not config.performance.cache_enabled then
        -- Bypass cache if disabled
        return memory_reader.readPartyData()
    end
    
    -- Update cache if needed
    if shouldUpdateCache() then
        updateCache()
    end
    
    return cache_data.pokemon_data
end

-- Get cached player info (updates less frequently)
function cache.getCachedPlayerInfo()
    local current_frame = emu.framecount()
    
    -- Update player info every 5 seconds (300 frames)
    if not cache_data.player_info or 
       current_frame - cache_data.player_info_frame > 300 then
        cache_data.player_info = memory_reader.readPlayerInfo()
        cache_data.player_info_frame = current_frame
    end
    
    return cache_data.player_info
end

-- Manually invalidate cache
function cache.invalidate()
    cache_data.invalidated = true
    console.log("Cache invalidated")
end

-- Invalidate specific cache sections
function cache.invalidateSection(section)
    if section == "pokemon" then
        cache_data.invalidated = true
    elseif section == "player" then
        cache_data.player_info = nil
    end
    
    console.log("Cache section '" .. section .. "' invalidated")
end

-- Get cache statistics
function cache.getStats()
    local current_frame = emu.framecount()
    local frames_since_update = current_frame - cache_data.last_update_frame
    
    -- Count cached Pokemon
    local cached_pokemon = 0
    for _, pokemon in pairs(cache_data.pokemon_data) do
        if pokemon then
            cached_pokemon = cached_pokemon + 1
        end
    end
    
    return {
        last_update_frame = cache_data.last_update_frame,
        frames_since_update = frames_since_update,
        party_checksum = cache_data.party_checksum,
        cached_pokemon_count = cached_pokemon,
        cache_enabled = config.performance.cache_enabled,
        update_interval = config.performance.update_interval,
        player_info_cached = cache_data.player_info ~= nil
    }
end

-- Debug function to print cache status
function cache.debugPrintStatus()
    local stats = cache.getStats()
    
    console.log("=== Cache Status ===")
    console.log("Enabled: " .. tostring(stats.cache_enabled))
    console.log("Last Update: Frame " .. stats.last_update_frame)
    console.log("Frames Since Update: " .. stats.frames_since_update .. "/" .. stats.update_interval)
    console.log("Party Checksum: " .. stats.party_checksum)
    console.log("Cached Pokemon: " .. stats.cached_pokemon_count)
    console.log("Player Info Cached: " .. tostring(stats.player_info_cached))
    
    -- Print cached Pokemon names
    if config.debug_mode and stats.cached_pokemon_count > 0 then
        console.log("Cached Pokemon:")
        for i, pokemon in pairs(cache_data.pokemon_data) do
            if pokemon then
                console.log("  Slot " .. i .. ": " .. pokemon.species_name .. 
                           " Lv." .. pokemon.level)
            end
        end
    end
end

-- Performance monitoring
local performance_stats = {
    total_reads = 0,
    cache_hits = 0,
    cache_misses = 0
}

-- Track cache performance
function cache.trackPerformance(hit)
    performance_stats.total_reads = performance_stats.total_reads + 1
    if hit then
        performance_stats.cache_hits = performance_stats.cache_hits + 1
    else
        performance_stats.cache_misses = performance_stats.cache_misses + 1
    end
end

-- Get performance stats
function cache.getPerformanceStats()
    local hit_rate = 0
    if performance_stats.total_reads > 0 then
        hit_rate = (performance_stats.cache_hits / performance_stats.total_reads) * 100
    end
    
    return {
        total_reads = performance_stats.total_reads,
        cache_hits = performance_stats.cache_hits,
        cache_misses = performance_stats.cache_misses,
        hit_rate = hit_rate
    }
end

-- Reset performance stats
function cache.resetPerformanceStats()
    performance_stats.total_reads = 0
    performance_stats.cache_hits = 0
    performance_stats.cache_misses = 0
    console.log("Cache performance stats reset")
end

return cache