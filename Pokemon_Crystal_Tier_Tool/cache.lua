-- Cache Module for Pokemon Crystal Tier Tool
-- Handles caching to reduce memory reads and improve performance

local cache = {}

-- Load required modules
local memory_reader = require("memory_reader")
local config = require("config")

-- Cache storage
local cache_data = {
    pokemon_data = {},
    last_update_frame = 0,
    party_checksum = 0,
    invalidated = false
}

-- Initialize cache
function cache.initialize()
    console.log("Cache system initialized")
    cache_data.last_update_frame = emu.framecount()
end

-- Calculate a simple checksum of party data for change detection
local function calculatePartyChecksum()
    local checksum = 0
    
    -- Include party count
    local party_count = memory.readbyte(memory_reader.addresses.party_count)
    checksum = checksum + party_count
    
    -- Include species IDs
    for i = 0, 5 do
        local species = memory.readbyte(memory_reader.addresses.party_species + i)
        checksum = checksum + (species * (i + 1))
    end
    
    -- Include some key stats from first Pokemon for better change detection
    if party_count > 0 then
        local first_pokemon_addr = memory_reader.addresses.party_data_start
        checksum = checksum + memory.readbyte(first_pokemon_addr + memory_reader.addresses.level_offset)
        checksum = checksum + memory.read_u16_be(first_pokemon_addr + memory_reader.addresses.current_hp_offset)
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

-- Manually invalidate cache
function cache.invalidate()
    cache_data.invalidated = true
    console.log("Cache invalidated")
end

-- Get cache statistics
function cache.getStats()
    local current_frame = emu.framecount()
    local frames_since_update = current_frame - cache_data.last_update_frame
    
    return {
        last_update_frame = cache_data.last_update_frame,
        frames_since_update = frames_since_update,
        party_checksum = cache_data.party_checksum,
        cached_pokemon_count = #cache_data.pokemon_data,
        cache_enabled = config.performance.cache_enabled
    }
end

-- Debug function to print cache status
function cache.debugPrintStatus()
    local stats = cache.getStats()
    
    console.log("=== Cache Status ===")
    console.log("Enabled: " .. tostring(stats.cache_enabled))
    console.log("Last Update: Frame " .. stats.last_update_frame)
    console.log("Frames Since Update: " .. stats.frames_since_update)
    console.log("Party Checksum: " .. stats.party_checksum)
    console.log("Cached Pokemon: " .. stats.cached_pokemon_count)
end

return cache