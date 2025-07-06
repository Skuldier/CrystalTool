-- Memory Reader Module for Pokemon Crystal
-- Handles all memory access operations with domain awareness and pattern scanning

local memory_reader = {}

-- Pokemon Crystal Memory Addresses
memory_reader.addresses = {
    party_count = 0xDCD7,           -- Number of party Pokemon (1 byte)
    party_species = 0xDCD8,         -- Species IDs (6 bytes)
    party_data_start = 0xDCDF,      -- First Pokemon data (48 bytes each)
    
    -- Individual Pokemon offsets within 48-byte structure
    species_offset = 0x00,
    held_item_offset = 0x01,
    moves_offset = 0x02,            -- 4 moves (4 bytes)
    dvs_offset = 0x15,              -- IVs/DVs (2 bytes)
    exp_offset = 0x08,              -- Experience (3 bytes)
    level_offset = 0x1F,
    status_offset = 0x20,
    current_hp_offset = 0x22,
    max_hp_offset = 0x24,
    attack_offset = 0x26,
    defense_offset = 0x28,
    speed_offset = 0x2A,
    sp_attack_offset = 0x2C,
    sp_defense_offset = 0x2E,
    
    -- Additional data
    player_name = 0xD47D,
    trainer_id = 0xD47B,
    money = 0xD573,                  -- 3 bytes, big-endian BCD
    
    -- Type data for species (ROM addresses)
    base_stats_start = 0x51424,      -- Base stats in ROM
}

-- State tracking
memory_reader.state = {
    initialized = false,
    valid_addresses = false,
    memory_domain = "WRAM",  -- Default to WRAM
    scan_attempted = false
}

-- Type constants
local TYPES = {
    [0] = "Normal", [1] = "Fighting", [2] = "Flying", [3] = "Poison",
    [4] = "Ground", [5] = "Rock", [6] = "Bug", [7] = "Ghost",
    [8] = "Steel", [9] = "Fire", [10] = "Water", [11] = "Grass",
    [12] = "Electric", [13] = "Psychic", [14] = "Ice", [15] = "Dragon",
    [16] = "Dark"
}

-- Set memory domain safely
local function setMemoryDomain(domain)
    local domains = memory.getmemorydomainlist()
    for _, d in ipairs(domains) do
        if d == domain then
            memory.usememorydomain(domain)
            return true
        end
    end
    console.log("Warning: Memory domain '" .. domain .. "' not found")
    return false
end

-- Pattern scanning for party structure
local function findPartyCount()
    local candidates = {}
    
    -- Try both WRAM and System Bus
    local domains = {"WRAM", "System Bus"}
    
    for _, domain in ipairs(domains) do
        if setMemoryDomain(domain) then
            -- Scan appropriate range based on domain
            local start_addr = domain == "WRAM" and 0x0CD7 or 0xDCD7
            local end_addr = domain == "WRAM" and 0x1FFF or 0xDFFF
            
            for addr = start_addr, end_addr do
                local value = memory.readbyte(addr)
                
                -- Look for valid party count (1-6)
                if value >= 1 and value <= 6 then
                    -- Validate species list follows
                    local valid = true
                    for i = 1, value do
                        local species = memory.readbyte(addr + i)
                        if species == 0 or species > 251 then
                            valid = false
                            break
                        end
                    end
                    
                    -- Check for list terminator
                    if valid then
                        local term = memory.readbyte(addr + value + 1)
                        if term == 0xFF or term == 0x00 then
                            table.insert(candidates, {
                                address = addr,
                                domain = domain,
                                confidence = value == 6 and 90 or 70
                            })
                        end
                    end
                end
            end
        end
    end
    
    return candidates
end

-- Validate addresses
local function validateAddresses()
    -- Try current memory domain first
    local count = memory.readbyte(memory_reader.addresses.party_count)
    
    -- Basic validation
    if count < 1 or count > 6 then
        return false
    end
    
    -- Check species are valid
    for i = 0, count - 1 do
        local species = memory.readbyte(memory_reader.addresses.party_species + i)
        if species == 0 or species > 251 then
            return false
        end
    end
    
    -- Verify first Pokemon has reasonable data
    local first_pokemon = memory_reader.addresses.party_data_start
    local level = memory.readbyte(first_pokemon + memory_reader.addresses.level_offset)
    if level < 1 or level > 100 then
        return false
    end
    
    return true
end

-- Initialize the memory reader with adaptive address finding
function memory_reader.initialize()
    console.log("Memory reader initializing with adaptive address finding...")
    
    -- Try WRAM domain first (correct for party data)
    if setMemoryDomain("WRAM") then
        memory_reader.state.memory_domain = "WRAM"
        
        -- Adjust addresses for WRAM domain (remove bank offset)
        if memory_reader.addresses.party_count > 0xC000 then
            memory_reader.addresses.party_count = memory_reader.addresses.party_count - 0xC000
            memory_reader.addresses.party_species = memory_reader.addresses.party_species - 0xC000
            memory_reader.addresses.party_data_start = memory_reader.addresses.party_data_start - 0xC000
            memory_reader.addresses.player_name = memory_reader.addresses.player_name - 0xC000
            memory_reader.addresses.trainer_id = memory_reader.addresses.trainer_id - 0xC000
            memory_reader.addresses.money = memory_reader.addresses.money - 0xC000
        end
        
        -- Validate addresses
        if validateAddresses() then
            memory_reader.state.valid_addresses = true
            console.log("Memory reader initialized successfully with WRAM domain")
            memory_reader.state.initialized = true
            return true
        end
    end
    
    -- Try System Bus as fallback
    if setMemoryDomain("System Bus") then
        memory_reader.state.memory_domain = "System Bus"
        
        -- Reset addresses to original values
        memory_reader.addresses.party_count = 0xDCD7
        memory_reader.addresses.party_species = 0xDCD8
        memory_reader.addresses.party_data_start = 0xDCDF
        
        if validateAddresses() then
            memory_reader.state.valid_addresses = true
            console.log("Memory reader initialized with System Bus domain")
            memory_reader.state.initialized = true
            return true
        end
    end
    
    -- If standard addresses fail, try pattern scanning
    console.log("Standard addresses failed, attempting pattern scan...")
    local candidates = findPartyCount()
    
    if #candidates > 0 then
        -- Sort by confidence
        table.sort(candidates, function(a, b) return a.confidence > b.confidence end)
        
        -- Try each candidate
        for _, candidate in ipairs(candidates) do
            setMemoryDomain(candidate.domain)
            memory_reader.state.memory_domain = candidate.domain
            
            -- Update addresses based on found location
            local offset = candidate.address - memory_reader.addresses.party_count
            memory_reader.addresses.party_count = candidate.address
            memory_reader.addresses.party_species = candidate.address + 1
            memory_reader.addresses.party_data_start = candidate.address + 8
            
            if validateAddresses() then
                memory_reader.state.valid_addresses = true
                console.log(string.format("Found party data at 0x%04X in %s domain", 
                    candidate.address, candidate.domain))
                memory_reader.state.initialized = true
                return true
            end
        end
    end
    
    console.log("Failed to initialize memory reader - addresses not found")
    memory_reader.state.initialized = false
    return false
end

-- Read moves for a Pokemon
local function readMoves(base_addr)
    local moves = {}
    for i = 0, 3 do
        moves[i + 1] = memory.readbyte(base_addr + i)
    end
    return moves
end

-- Read DVs (IVs in Gen 2) 
local function readDVs(base_addr)
    -- Read as two separate bytes for compatibility
    local byte1 = memory.readbyte(base_addr)
    local byte2 = memory.readbyte(base_addr + 1)
    local dv_data = byte1 * 256 + byte2
    
    return {
        hp = bit.band(bit.rshift(dv_data, 12), 0x0F),
        attack = bit.band(bit.rshift(dv_data, 8), 0x0F),
        defense = bit.band(bit.rshift(dv_data, 4), 0x0F),
        speed = bit.band(dv_data, 0x0F),
        special = bit.band(bit.rshift(dv_data, 4), 0x0F)  -- Sp.Atk and Sp.Def use same DV
    }
end

-- Read types for a species from ROM
local function readSpeciesTypes(species_id)
    if species_id == 0 or species_id > 251 then
        return { type1 = 0, type2 = 0, type1_name = "Unknown", type2_name = "Unknown" }
    end
    
    -- Save current domain
    local current_domain = memory.getcurrentmemorydomain()
    
    -- Switch to ROM domain for reading base stats
    local type1, type2 = 0, 0
    if setMemoryDomain("ROM") then
        -- Each base stat entry is 32 bytes, types are at offset 6 and 7
        local base_addr = memory_reader.addresses.base_stats_start + ((species_id - 1) * 32)
        type1 = memory.readbyte(base_addr + 6)
        type2 = memory.readbyte(base_addr + 7)
    end
    
    -- Restore original domain
    setMemoryDomain(current_domain)
    
    return {
        type1 = type1,
        type2 = type2,
        type1_name = TYPES[type1] or "Unknown",
        type2_name = TYPES[type2] or "Unknown"
    }
end

-- Read individual Pokemon data
function memory_reader.readPokemonData(slot)
    if not memory_reader.state.initialized then
        console.log("Memory reader not initialized!")
        return nil
    end
    
    local base_addr = memory_reader.addresses.party_data_start + (slot * 48)
    
    local species = memory.readbyte(base_addr + memory_reader.addresses.species_offset)
    if species == 0 then
        return nil  -- Empty slot
    end
    
    -- Read 16-bit values with proper endianness
    local function read_u16_le(addr)
        local low = memory.readbyte(addr)
        local high = memory.readbyte(addr + 1)
        return low + (high * 256)
    end
    
    -- Read 24-bit value (for experience)
    local function read_u24_be(addr)
        local b1 = memory.readbyte(addr)
        local b2 = memory.readbyte(addr + 1)
        local b3 = memory.readbyte(addr + 2)
        return (b1 * 65536) + (b2 * 256) + b3
    end
    
    local pokemon = {
        species = species,
        held_item = memory.readbyte(base_addr + memory_reader.addresses.held_item_offset),
        moves = readMoves(base_addr + memory_reader.addresses.moves_offset),
        dvs = readDVs(base_addr + memory_reader.addresses.dvs_offset),
        experience = read_u24_be(base_addr + memory_reader.addresses.exp_offset),
        level = memory.readbyte(base_addr + memory_reader.addresses.level_offset),
        status = memory.readbyte(base_addr + memory_reader.addresses.status_offset),
        current_hp = read_u16_le(base_addr + memory_reader.addresses.current_hp_offset),
        max_hp = read_u16_le(base_addr + memory_reader.addresses.max_hp_offset),
        attack = read_u16_le(base_addr + memory_reader.addresses.attack_offset),
        defense = read_u16_le(base_addr + memory_reader.addresses.defense_offset),
        speed = read_u16_le(base_addr + memory_reader.addresses.speed_offset),
        sp_attack = read_u16_le(base_addr + memory_reader.addresses.sp_attack_offset),
        sp_defense = read_u16_le(base_addr + memory_reader.addresses.sp_defense_offset),
        types = readSpeciesTypes(species)
    }
    
    -- Calculate total stats
    pokemon.total_stats = pokemon.max_hp + pokemon.attack + pokemon.defense + 
                         pokemon.speed + pokemon.sp_attack + pokemon.sp_defense
    
    return pokemon
end

-- Read all party Pokemon
function memory_reader.readPartyData()
    if not memory_reader.state.initialized then
        console.log("Memory reader not initialized!")
        return {}
    end
    
    local party_count = memory.readbyte(memory_reader.addresses.party_count)
    local party_data = {}
    
    -- Sanity check
    if party_count > 6 then
        console.log("Warning: Invalid party count: " .. party_count)
        party_count = 6
    end
    
    for i = 0, party_count - 1 do
        local pokemon = memory_reader.readPokemonData(i)
        if pokemon then
            party_data[i] = pokemon
        end
    end
    
    return party_data
end

-- Read player info
function memory_reader.readPlayerInfo()
    if not memory_reader.state.initialized then
        return nil
    end
    
    local name_bytes = {}
    for i = 0, 10 do  -- Player name is max 11 bytes
        local byte = memory.readbyte(memory_reader.addresses.player_name + i)
        if byte == 0x50 then  -- Terminator
            break
        end
        table.insert(name_bytes, byte)
    end
    
    -- Read 16-bit and 24-bit values properly
    local function read_u16_be(addr)
        local high = memory.readbyte(addr)
        local low = memory.readbyte(addr + 1)
        return (high * 256) + low
    end
    
    local function read_u24_be(addr)
        local b1 = memory.readbyte(addr)
        local b2 = memory.readbyte(addr + 1)
        local b3 = memory.readbyte(addr + 2)
        return (b1 * 65536) + (b2 * 256) + b3
    end
    
    return {
        name = name_bytes,  -- Would need character decoding for actual name
        trainer_id = read_u16_be(memory_reader.addresses.trainer_id),
        money = read_u24_be(memory_reader.addresses.money)
    }
end

-- Debug function to dump Pokemon data
function memory_reader.debugDumpPokemon(slot)
    local pokemon = memory_reader.readPokemonData(slot)
    if not pokemon then
        console.log("No Pokemon in slot " .. slot)
        return
    end
    
    console.log("=== Pokemon Slot " .. slot .. " ===")
    console.log("Species: " .. pokemon.species)
    console.log("Level: " .. pokemon.level)
    console.log("HP: " .. pokemon.current_hp .. "/" .. pokemon.max_hp)
    console.log("Stats: ATK=" .. pokemon.attack .. " DEF=" .. pokemon.defense .. 
                " SPD=" .. pokemon.speed .. " SPA=" .. pokemon.sp_attack .. 
                " SPD=" .. pokemon.sp_defense)
    console.log("Total Stats: " .. pokemon.total_stats)
    console.log("Types: " .. pokemon.types.type1_name .. "/" .. pokemon.types.type2_name)
    console.log("Moves: " .. table.concat(pokemon.moves, ", "))
    console.log("DVs: HP=" .. pokemon.dvs.hp .. " ATK=" .. pokemon.dvs.attack ..
                " DEF=" .. pokemon.dvs.defense .. " SPD=" .. pokemon.dvs.speed ..
                " SPC=" .. pokemon.dvs.special)
end

-- Get current memory reader status
function memory_reader.getStatus()
    return {
        initialized = memory_reader.state.initialized,
        valid_addresses = memory_reader.state.valid_addresses,
        memory_domain = memory_reader.state.memory_domain,
        party_count_addr = string.format("0x%04X", memory_reader.addresses.party_count),
        party_data_addr = string.format("0x%04X", memory_reader.addresses.party_data_start)
    }
end

-- Force re-initialization with different domain
function memory_reader.reinitialize(preferred_domain)
    memory_reader.state.initialized = false
    memory_reader.state.valid_addresses = false
    
    if preferred_domain then
        memory_reader.state.memory_domain = preferred_domain
    end
    
    return memory_reader.initialize()
end

return memory_reader