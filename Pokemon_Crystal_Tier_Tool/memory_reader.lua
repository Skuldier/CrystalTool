-- Memory Reader Module for Pokemon Crystal
-- Fixed to handle BizHawk's memory domain addressing correctly

local memory_reader = {}

-- IMPORTANT: BizHawk's WRAM domain uses offsets, not absolute addresses!
-- System Bus uses absolute addresses

-- Archipelago relocated addresses (from Python analysis)
local archipelago_addresses = {
    party_count = 0xD198,         -- was 0xDCD7
    party_species = 0xD0E7,       -- was 0xDCD8  
    party_data_start = 0xDF17,    -- was 0xDCDF
    player_id = 0xC400,           -- was 0xD47B
    player_name = 0xD156,         -- was 0xD47D
    current_box = 0xD991,         -- was 0xD8BC
    pokedex_caught = 0xD107,      -- was 0xDE99
    pokedex_seen = 0xDF39,        -- was 0xDEB9
    badges_johto = 0xCA3D,        -- was 0xD57C
    badges_kanto = 0xD47D,        -- was 0xD57D
    money = 0xD573,               -- keeping original
}

-- Standard vanilla addresses
local vanilla_addresses = {
    party_count = 0xDCD7,
    party_species = 0xDCD8,
    party_data_start = 0xDCDF,
    player_id = 0xD47B,
    player_name = 0xD47D,
    current_box = 0xD8BC,
    pokedex_caught = 0xDE99,
    pokedex_seen = 0xDEB9,
    badges_johto = 0xD57C,
    badges_kanto = 0xD57D,
    money = 0xD573,
}

-- Pokemon structure offsets (these don't change)
local pokemon_offsets = {
    species_offset = 0x00,
    held_item_offset = 0x01,
    moves_offset = 0x02,
    dvs_offset = 0x15,
    exp_offset = 0x08,
    level_offset = 0x1F,
    status_offset = 0x20,
    current_hp_offset = 0x22,
    max_hp_offset = 0x24,
    attack_offset = 0x26,
    defense_offset = 0x28,
    speed_offset = 0x2A,
    sp_attack_offset = 0x2C,
    sp_defense_offset = 0x2E,
}

-- Active configuration
memory_reader.addresses = {}
memory_reader.use_system_bus = true  -- We'll use System Bus for simplicity

-- Initialize the memory reader
function memory_reader.initialize()
    console.log("Initializing memory reader...")
    
    -- Always use System Bus for Archipelago - it's simpler
    memory.usememorydomain("System Bus")
    memory_reader.use_system_bus = true
    
    -- Test Archipelago addresses first
    local party_count = memory.readbyte(archipelago_addresses.party_count)
    
    if party_count >= 1 and party_count <= 6 then
        -- Validate it's actually party data
        local valid = true
        for i = 0, party_count - 1 do
            local species = memory.readbyte(archipelago_addresses.party_species + i)
            if species == 0 or species > 251 then
                valid = false
                break
            end
        end
        
        if valid then
            memory_reader.addresses = archipelago_addresses
            console.log("Using Archipelago relocated addresses")
            console.log(string.format("Party at 0x%04X with %d Pokemon", 
                archipelago_addresses.party_count, party_count))
            return
        end
    end
    
    -- Try vanilla addresses
    party_count = memory.readbyte(vanilla_addresses.party_count)
    if party_count >= 1 and party_count <= 6 then
        memory_reader.addresses = vanilla_addresses
        console.log("Using vanilla addresses")
        return
    end
    
    -- If both fail, scan for party
    console.log("Standard addresses failed, scanning for party...")
    local found_addr = memory_reader.scanForParty()
    
    if found_addr then
        -- Update addresses based on found location
        local offset = found_addr - vanilla_addresses.party_count
        console.log(string.format("Found party at 0x%04X (offset %+d from vanilla)", 
            found_addr, offset))
        
        -- Apply offset to all addresses
        memory_reader.addresses = {}
        for key, addr in pairs(vanilla_addresses) do
            memory_reader.addresses[key] = addr + offset
        end
    else
        -- Default to vanilla and hope for the best
        memory_reader.addresses = vanilla_addresses
        console.log("Could not find party, defaulting to vanilla addresses")
    end
end

-- Scan memory for party structure
function memory_reader.scanForParty()
    memory.usememorydomain("System Bus")
    
    -- Common regions where party data might be
    local regions = {
        {start = 0xC000, stop = 0xCFFF},  -- WRAM Bank 0
        {start = 0xD000, stop = 0xDFFF},  -- WRAM Bank 1
    }
    
    for _, region in ipairs(regions) do
        for addr = region.start, region.stop - 8 do
            local count = memory.readbyte(addr)
            
            if count >= 1 and count <= 6 then
                -- Validate species list
                local valid = true
                for i = 1, count do
                    local species = memory.readbyte(addr + i)
                    if species == 0 or species > 251 then
                        valid = false
                        break
                    end
                end
                
                if valid then
                    -- Check for terminator
                    local term = memory.readbyte(addr + count + 1)
                    if term == 0xFF or term == 0x00 then
                        return addr  -- Found it!
                    end
                end
            end
        end
    end
    
    return nil
end

-- Helper to read bytes with domain handling
local function readByte(addr)
    return memory.readbyte(addr)
end

local function readU16BE(addr)
    return memory.read_u16_be(addr)
end

local function readU24BE(addr)
    local b1 = memory.readbyte(addr)
    local b2 = memory.readbyte(addr + 1)
    local b3 = memory.readbyte(addr + 2)
    return (b1 * 65536) + (b2 * 256) + b3
end

-- Read moves for a Pokemon
local function readMoves(base_addr)
    local moves = {}
    for i = 0, 3 do
        moves[i + 1] = readByte(base_addr + i)
    end
    return moves
end

-- Read DVs (IVs in Gen 2)
local function readDVs(base_addr)
    local dv1 = readByte(base_addr)
    local dv2 = readByte(base_addr + 1)
    local dv_data = (dv1 * 256) + dv2
    
    return {
        hp = bit.band(bit.rshift(dv_data, 12), 0x0F),
        attack = bit.band(bit.rshift(dv_data, 8), 0x0F),
        defense = bit.band(bit.rshift(dv_data, 4), 0x0F),
        speed = bit.band(dv_data, 0x0F),
        special = bit.band(bit.rshift(dv_data, 4), 0x0F)
    }
end

-- Read individual Pokemon data
function memory_reader.readPokemonData(slot)
    local base_addr = memory_reader.addresses.party_data_start + (slot * 48)
    
    local species = readByte(base_addr + pokemon_offsets.species_offset)
    if species == 0 or species > 251 then
        return nil
    end
    
    local pokemon = {
        species = species,
        held_item = readByte(base_addr + pokemon_offsets.held_item_offset),
        moves = readMoves(base_addr + pokemon_offsets.moves_offset),
        dvs = readDVs(base_addr + pokemon_offsets.dvs_offset),
        experience = readU24BE(base_addr + pokemon_offsets.exp_offset),
        level = readByte(base_addr + pokemon_offsets.level_offset),
        status = readByte(base_addr + pokemon_offsets.status_offset),
        current_hp = readU16BE(base_addr + pokemon_offsets.current_hp_offset),
        max_hp = readU16BE(base_addr + pokemon_offsets.max_hp_offset),
        attack = readU16BE(base_addr + pokemon_offsets.attack_offset),
        defense = readU16BE(base_addr + pokemon_offsets.defense_offset),
        speed = readU16BE(base_addr + pokemon_offsets.speed_offset),
        sp_attack = readU16BE(base_addr + pokemon_offsets.sp_attack_offset),
        sp_defense = readU16BE(base_addr + pokemon_offsets.sp_defense_offset),
        types = {type1 = 0, type2 = 0, type1_name = "Normal", type2_name = "Normal"}
    }
    
    -- Calculate total stats
    pokemon.total_stats = pokemon.max_hp + pokemon.attack + pokemon.defense + 
                         pokemon.speed + pokemon.sp_attack + pokemon.sp_defense
    
    return pokemon
end

-- Read all party Pokemon
function memory_reader.readPartyData()
    -- Ensure we're using the right domain
    if memory_reader.use_system_bus then
        memory.usememorydomain("System Bus")
    end
    
    local party_count = readByte(memory_reader.addresses.party_count)
    local party_data = {}
    
    if party_count < 1 or party_count > 6 then
        -- Try to re-initialize if we get invalid data
        memory_reader.initialize()
        party_count = readByte(memory_reader.addresses.party_count)
        
        if party_count < 1 or party_count > 6 then
            return party_data  -- Still invalid
        end
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
    local name_bytes = {}
    for i = 0, 10 do
        local byte = readByte(memory_reader.addresses.player_name + i)
        if byte == 0x50 then
            break
        end
        table.insert(name_bytes, byte)
    end
    
    return {
        name = name_bytes,
        trainer_id = readU16BE(memory_reader.addresses.player_id),
        money = readU24BE(memory_reader.addresses.money)
    }
end

-- Debug function
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
end

return memory_reader