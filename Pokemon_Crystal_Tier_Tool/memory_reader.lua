-- Memory Reader Module for Pokemon Crystal
-- Handles all memory access operations

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

-- Type constants
local TYPES = {
    [0] = "Normal", [1] = "Fighting", [2] = "Flying", [3] = "Poison",
    [4] = "Ground", [5] = "Rock", [6] = "Bug", [7] = "Ghost",
    [8] = "Steel", [9] = "Fire", [10] = "Water", [11] = "Grass",
    [12] = "Electric", [13] = "Psychic", [14] = "Ice", [15] = "Dragon",
    [16] = "Dark"
}

-- Initialize the memory reader
function memory_reader.initialize()
    console.log("Memory reader initialized")
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
    local dv_data = memory.read_u16_be(base_addr)
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
        return { type1 = 0, type2 = 0 }
    end
    
    -- Each base stat entry is 32 bytes, types are at offset 6 and 7
    local base_addr = memory_reader.addresses.base_stats_start + ((species_id - 1) * 32)
    local type1 = memory.readbyte(base_addr + 6, "ROM")
    local type2 = memory.readbyte(base_addr + 7, "ROM")
    
    return {
        type1 = type1,
        type2 = type2,
        type1_name = TYPES[type1] or "Unknown",
        type2_name = TYPES[type2] or "Unknown"
    }
end

-- Read individual Pokemon data
function memory_reader.readPokemonData(slot)
    local base_addr = memory_reader.addresses.party_data_start + (slot * 48)
    
    local species = memory.readbyte(base_addr + memory_reader.addresses.species_offset)
    if species == 0 then
        return nil  -- Empty slot
    end
    
    local pokemon = {
        species = species,
        held_item = memory.readbyte(base_addr + memory_reader.addresses.held_item_offset),
        moves = readMoves(base_addr + memory_reader.addresses.moves_offset),
        dvs = readDVs(base_addr + memory_reader.addresses.dvs_offset),
        experience = memory.read_u24_be(base_addr + memory_reader.addresses.exp_offset),
        level = memory.readbyte(base_addr + memory_reader.addresses.level_offset),
        status = memory.readbyte(base_addr + memory_reader.addresses.status_offset),
        current_hp = memory.read_u16_be(base_addr + memory_reader.addresses.current_hp_offset),
        max_hp = memory.read_u16_be(base_addr + memory_reader.addresses.max_hp_offset),
        attack = memory.read_u16_be(base_addr + memory_reader.addresses.attack_offset),
        defense = memory.read_u16_be(base_addr + memory_reader.addresses.defense_offset),
        speed = memory.read_u16_be(base_addr + memory_reader.addresses.speed_offset),
        sp_attack = memory.read_u16_be(base_addr + memory_reader.addresses.sp_attack_offset),
        sp_defense = memory.read_u16_be(base_addr + memory_reader.addresses.sp_defense_offset),
        types = readSpeciesTypes(species)
    }
    
    -- Calculate total stats
    pokemon.total_stats = pokemon.max_hp + pokemon.attack + pokemon.defense + 
                         pokemon.speed + pokemon.sp_attack + pokemon.sp_defense
    
    return pokemon
end

-- Read all party Pokemon
function memory_reader.readPartyData()
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
    local name_bytes = {}
    for i = 0, 10 do  -- Player name is max 11 bytes
        local byte = memory.readbyte(memory_reader.addresses.player_name + i)
        if byte == 0x50 then  -- Terminator
            break
        end
        table.insert(name_bytes, byte)
    end
    
    return {
        name = name_bytes,  -- Would need character decoding for actual name
        trainer_id = memory.read_u16_be(memory_reader.addresses.trainer_id),
        money = memory.read_u24_be(memory_reader.addresses.money)
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

return memory_reader