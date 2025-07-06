-- Memory Reader Module for Pokemon Crystal
-- Handles all memory access operations
-- Updated with comprehensive memory addresses

local memory_reader = {}

-- Pokemon Crystal Memory Addresses (US Version)
-- Compatible with Archipelago Randomizer
memory_reader.addresses = {
    -- Party Pokemon System
    party_count = 0xDCD7,                  -- Number of Pokemon in party (1-6)
    party_species = 0xDCD8,                -- Species IDs (6 bytes + 0xFF terminator)
    party_data_start = 0xDCDF,             -- First Pokemon data (48 bytes each)
    
    -- Individual Pokemon offsets within 48-byte structure
    species_offset = 0x00,                 -- Species ID
    held_item_offset = 0x01,               -- Held item ID
    moves_offset = 0x02,                   -- 4 moves (4 bytes)
    trainer_id_offset = 0x06,              -- Trainer ID (2 bytes)
    exp_offset = 0x08,                     -- Experience (3 bytes, big-endian)
    hp_ev_offset = 0x0B,                   -- HP EV (2 bytes)
    attack_ev_offset = 0x0D,               -- Attack EV (2 bytes)
    defense_ev_offset = 0x0F,              -- Defense EV (2 bytes)
    speed_ev_offset = 0x11,                -- Speed EV (2 bytes)
    special_ev_offset = 0x13,              -- Special EV (2 bytes)
    dvs_offset = 0x14,                     -- IVs/DVs (2 bytes)
    pp_offset = 0x17,                      -- PP values (4 bytes)
    happiness_offset = 0x1B,               -- Friendship value
    pokerus_offset = 0x1C,                 -- Pokerus status
    caught_data_offset = 0x1D,             -- Caught data (2 bytes)
    level_offset = 0x1F,                   -- Current level
    status_offset = 0x20,                  -- Status condition
    current_hp_offset = 0x22,              -- Current HP (2 bytes)
    max_hp_offset = 0x24,                  -- Max HP (2 bytes)
    attack_offset = 0x26,                  -- Attack (2 bytes)
    defense_offset = 0x28,                 -- Defense (2 bytes)
    speed_offset = 0x2A,                   -- Speed (2 bytes)
    sp_attack_offset = 0x2C,               -- Special Attack (2 bytes)
    sp_defense_offset = 0x2E,              -- Special Defense (2 bytes)
    
    -- Nickname and OT names
    nicknames_start = 0xDE41,              -- Pokemon nicknames (11 bytes each)
    ot_names_start = 0xDDFF,               -- Original trainer names (11 bytes each)
    
    -- Player data
    player_name = 0xD47D,                  -- Player name (11 bytes)
    trainer_id = 0xD47B,                   -- Trainer ID (2 bytes)
    money = 0xD573,                        -- Money (3 bytes, BCD format)
    johto_badges = 0xD57C,                 -- Johto badges (bitflags)
    kanto_badges = 0xD57D,                 -- Kanto badges (bitflags)
    
    -- Map and position
    current_map_bank = 0xDA00,             -- Current map bank
    current_map_number = 0xDA01,           -- Current map number
    player_x = 0xD20D,                     -- Player X coordinate
    player_y = 0xD20E,                     -- Player Y coordinate
    
    -- Battle system
    enemy_pokemon_start = 0xD204,          -- Enemy Pokemon data start
    battle_type = 0xD22D,                  -- Type of battle
    wild_pokemon_species = 0xD0ED,         -- Wild Pokemon species
    wild_pokemon_level = 0xD0FC,           -- Wild Pokemon level
    
    -- PC Box system
    current_box = 0xD8BC,                  -- Current box number
    box_pokemon_count = 0xAD6C,            -- Pokemon count in current box
    box_species_list = 0xAD6D,             -- Species list in box
    box_data_start = 0xAD82,               -- Box Pokemon data (32 bytes each)
    
    -- Pokedex
    pokedex_caught = 0xDE99,               -- Caught flags (32 bytes)
    pokedex_seen = 0xDEB9,                 -- Seen flags (32 bytes)
    unown_dex = 0xDED9,                    -- Unown forms data
    
    -- Daycare
    daycare_1_occupied = 0xDEF5,           -- Daycare slot 1 occupied
    daycare_1_data = 0xDEF6,               -- Daycare Pokemon 1 data
    daycare_2_occupied = 0xDF2C,           -- Daycare slot 2 occupied
    daycare_2_data = 0xDF2D,               -- Daycare Pokemon 2 data
    
    -- Roaming Pokemon
    raikou_data = 0xDFCF,                  -- Raikou roaming data
    entei_data = 0xDFD6,                   -- Entei roaming data
    suicune_data = 0xDFDD,                 -- Suicune roaming data
    
    -- Game state
    game_time_played = 0xD4C4,             -- Play time (5 bytes)
    options = 0xD199,                      -- Game options byte
    
    -- ROM addresses for static data
    rom = {
        pokemon_names = 0x1B0B74,          -- Pokemon names in ROM
        pokemon_name_length = 10,          -- Each name is 10 bytes
        base_stats_start = 0x51424,        -- Base stats in ROM
        base_stats_length = 32,            -- Each entry is 32 bytes
        move_names = 0x1C9F29,             -- Move names in ROM
        move_name_length = 13,             -- Each move name is 13 bytes
        move_data = 0x41AFE,               -- Move data table
        move_data_length = 7,              -- Each move entry is 7 bytes
        type_names = 0x50964,              -- Type names
        type_name_length = 9,              -- Each type name is 9 bytes
        type_chart = 0x34BB1               -- Type effectiveness chart
    }
}

-- Type constants
local TYPES = {
    [0] = "Normal", [1] = "Fighting", [2] = "Flying", [3] = "Poison",
    [4] = "Ground", [5] = "Rock", [6] = "Bug", [7] = "Ghost",
    [8] = "Steel", [9] = "Fire", [10] = "Water", [11] = "Grass",
    [12] = "Electric", [13] = "Psychic", [14] = "Ice", [15] = "Dragon",
    [16] = "Dark"
}

-- Character encoding for Pokemon names
local CHAR_MAP = {
    [0x50] = "",     -- String terminator
    [0x7F] = " ",    -- Space
    [0x80] = "A", [0x81] = "B", [0x82] = "C", [0x83] = "D",
    [0x84] = "E", [0x85] = "F", [0x86] = "G", [0x87] = "H",
    [0x88] = "I", [0x89] = "J", [0x8A] = "K", [0x8B] = "L",
    [0x8C] = "M", [0x8D] = "N", [0x8E] = "O", [0x8F] = "P",
    [0x90] = "Q", [0x91] = "R", [0x92] = "S", [0x93] = "T",
    [0x94] = "U", [0x95] = "V", [0x96] = "W", [0x97] = "X",
    [0x98] = "Y", [0x99] = "Z",
    [0xA0] = "a", [0xA1] = "b", [0xA2] = "c", [0xA3] = "d",
    [0xA4] = "e", [0xA5] = "f", [0xA6] = "g", [0xA7] = "h",
    [0xA8] = "i", [0xA9] = "j", [0xAA] = "k", [0xAB] = "l",
    [0xAC] = "m", [0xAD] = "n", [0xAE] = "o", [0xAF] = "p",
    [0xB0] = "q", [0xB1] = "r", [0xB2] = "s", [0xB3] = "t",
    [0xB4] = "u", [0xB5] = "v", [0xB6] = "w", [0xB7] = "x",
    [0xB8] = "y", [0xB9] = "z",
    [0xBA] = "é",
    [0xE0] = "'", [0xE3] = "-", [0xE8] = ".",
    [0xF6] = "0", [0xF7] = "1", [0xF8] = "2", [0xF9] = "3",
    [0xFA] = "4", [0xFB] = "5", [0xFC] = "6", [0xFD] = "7",
    [0xFE] = "8", [0xFF] = "9"
}

-- Initialize the memory reader
function memory_reader.initialize()
    console.log("Memory reader initialized with comprehensive addresses")
end

-- Decode Game Boy text to string
local function decodeText(bytes)
    local text = ""
    for _, byte in ipairs(bytes) do
        if byte == 0x50 then break end  -- String terminator
        text = text .. (CHAR_MAP[byte] or "?")
    end
    return text
end

-- Read text from memory
local function readText(addr, maxLength)
    local bytes = {}
    for i = 0, maxLength - 1 do
        local byte = memory.readbyte(addr + i)
        if byte == 0x50 then break end
        table.insert(bytes, byte)
    end
    return decodeText(bytes)
end

-- Read moves for a Pokemon
local function readMoves(base_addr)
    local moves = {}
    for i = 0, 3 do
        moves[i + 1] = memory.readbyte(base_addr + i)
    end
    return moves
end

-- Read PP values
local function readPP(base_addr)
    local pp = {}
    for i = 0, 3 do
        pp[i + 1] = memory.readbyte(base_addr + i)
    end
    return pp
end

-- Read DVs (IVs in Gen 2) 
local function readDVs(base_addr)
    local dv1 = memory.readbyte(base_addr)
    local dv2 = memory.readbyte(base_addr + 1)
    
    return {
        attack = (dv1 & 0xF0) >> 4,
        defense = dv1 & 0x0F,
        speed = (dv2 & 0xF0) >> 4,
        special = dv2 & 0x0F,
        -- HP DV is calculated from other DVs
        hp = (
            ((dv1 & 0x10) ~= 0 and 8 or 0) |
            ((dv1 & 0x01) ~= 0 and 4 or 0) |
            ((dv2 & 0x10) ~= 0 and 2 or 0) |
            ((dv2 & 0x01) ~= 0 and 1 or 0)
        ) & 0x0F
    }
end

-- Read types for a species from ROM
local function readSpeciesTypes(species_id)
    if species_id == 0 or species_id > 251 then
        return { type1 = 0, type2 = 0 }
    end
    
    -- Each base stat entry is 32 bytes, types are at offset 6 and 7
    local base_addr = memory_reader.addresses.rom.base_stats_start + ((species_id - 1) * 32)
    local type1 = memory.readbyte(base_addr + 6, "ROM")
    local type2 = memory.readbyte(base_addr + 7, "ROM")
    
    return {
        type1 = type1,
        type2 = type2,
        type1_name = TYPES[type1] or "Unknown",
        type2_name = TYPES[type2] or "Unknown"
    }
end

-- Read Pokemon name from ROM
local function readPokemonName(species_id)
    if species_id == 0 or species_id > 251 then
        return "???"
    end
    
    local addr = memory_reader.addresses.rom.pokemon_names + 
                 ((species_id - 1) * memory_reader.addresses.rom.pokemon_name_length)
    
    local bytes = {}
    for i = 0, memory_reader.addresses.rom.pokemon_name_length - 1 do
        local byte = memory.readbyte(addr + i, "ROM")
        if byte == 0x50 then break end
        table.insert(bytes, byte)
    end
    
    return decodeText(bytes)
end

-- Read move name from ROM
local function readMoveName(move_id)
    if move_id == 0 or move_id > 251 then
        return "---"
    end
    
    local addr = memory_reader.addresses.rom.move_names + 
                 ((move_id - 1) * memory_reader.addresses.rom.move_name_length)
    
    local bytes = {}
    for i = 0, memory_reader.addresses.rom.move_name_length - 1 do
        local byte = memory.readbyte(addr + i, "ROM")
        if byte == 0x50 then break end
        table.insert(bytes, byte)
    end
    
    return decodeText(bytes)
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
        species_name = readPokemonName(species),
        held_item = memory.readbyte(base_addr + memory_reader.addresses.held_item_offset),
        moves = readMoves(base_addr + memory_reader.addresses.moves_offset),
        move_names = {},
        trainer_id = memory.read_u16_be(base_addr + memory_reader.addresses.trainer_id_offset),
        experience = memory.read_u24_be(base_addr + memory_reader.addresses.exp_offset),
        hp_ev = memory.read_u16_be(base_addr + memory_reader.addresses.hp_ev_offset),
        attack_ev = memory.read_u16_be(base_addr + memory_reader.addresses.attack_ev_offset),
        defense_ev = memory.read_u16_be(base_addr + memory_reader.addresses.defense_ev_offset),
        speed_ev = memory.read_u16_be(base_addr + memory_reader.addresses.speed_ev_offset),
        special_ev = memory.read_u16_be(base_addr + memory_reader.addresses.special_ev_offset),
        dvs = readDVs(base_addr + memory_reader.addresses.dvs_offset),
        pp = readPP(base_addr + memory_reader.addresses.pp_offset),
        happiness = memory.readbyte(base_addr + memory_reader.addresses.happiness_offset),
        pokerus = memory.readbyte(base_addr + memory_reader.addresses.pokerus_offset),
        caught_data = memory.read_u16_be(base_addr + memory_reader.addresses.caught_data_offset),
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
    
    -- Read move names
    for i, move_id in ipairs(pokemon.moves) do
        pokemon.move_names[i] = readMoveName(move_id)
    end
    
    -- Read nickname
    local nickname_addr = memory_reader.addresses.nicknames_start + (slot * 11)
    pokemon.nickname = readText(nickname_addr, 11)
    if pokemon.nickname == "" then
        pokemon.nickname = pokemon.species_name
    end
    
    -- Calculate total stats
    pokemon.total_stats = pokemon.max_hp + pokemon.attack + pokemon.defense + 
                         pokemon.speed + pokemon.sp_attack + pokemon.sp_defense
    
    return pokemon
end

-- Read all party Pokemon
function memory_reader.readPartyData()
    local party_count = memory.readbyte(memory_reader.addresses.party_count)
    local party_data = {}
    
    -- Sanity check - party count should be 0-6
    if party_count > 6 then
        if party_count == 255 then
            -- 255 usually means uninitialized memory
            return {}
        end
        console.log("Warning: Invalid party count: " .. party_count .. " (limiting to 6)")
        party_count = 6
    end
    
    -- Return empty if no Pokemon
    if party_count == 0 then
        return {}
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
    return {
        name = readText(memory_reader.addresses.player_name, 11),
        trainer_id = memory.read_u16_be(memory_reader.addresses.trainer_id),
        money = memory.read_u24_be(memory_reader.addresses.money),
        johto_badges = memory.readbyte(memory_reader.addresses.johto_badges),
        kanto_badges = memory.readbyte(memory_reader.addresses.kanto_badges),
        map_bank = memory.readbyte(memory_reader.addresses.current_map_bank),
        map_number = memory.readbyte(memory_reader.addresses.current_map_number),
        x_position = memory.readbyte(memory_reader.addresses.player_x),
        y_position = memory.readbyte(memory_reader.addresses.player_y)
    }
end

-- Read current box data
function memory_reader.readCurrentBox()
    local box_number = memory.readbyte(memory_reader.addresses.current_box)
    local box_count = memory.readbyte(memory_reader.addresses.box_pokemon_count)
    
    return {
        number = box_number,
        count = box_count
    }
end

-- Read wild Pokemon data
function memory_reader.readWildPokemon()
    return {
        species = memory.readbyte(memory_reader.addresses.wild_pokemon_species),
        level = memory.readbyte(memory_reader.addresses.wild_pokemon_level)
    }
end

-- Read game options
function memory_reader.readGameOptions()
    local options_byte = memory.readbyte(memory_reader.addresses.options)
    
    return {
        text_speed = options_byte & 0x07,                    -- Bits 0-2
        text_delay = ((options_byte >> 4) & 0x01) == 1,     -- Bit 4
        stereo = ((options_byte >> 5) & 0x01) == 1,         -- Bit 5
        battle_style = ((options_byte >> 6) & 0x01) == 1,   -- Bit 6
        battle_animations = ((options_byte >> 7) & 0x01) == 1 -- Bit 7
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
    console.log("Species: " .. pokemon.species .. " (" .. pokemon.species_name .. ")")
    console.log("Nickname: " .. pokemon.nickname)
    console.log("Level: " .. pokemon.level)
    console.log("HP: " .. pokemon.current_hp .. "/" .. pokemon.max_hp)
    console.log("Stats: ATK=" .. pokemon.attack .. " DEF=" .. pokemon.defense .. 
                " SPD=" .. pokemon.speed .. " SPA=" .. pokemon.sp_attack .. 
                " SPD=" .. pokemon.sp_defense)
    console.log("Total Stats: " .. pokemon.total_stats)
    console.log("Types: " .. pokemon.types.type1_name .. "/" .. pokemon.types.type2_name)
    console.log("Moves: " .. table.concat(pokemon.move_names, ", "))
    console.log("DVs: HP=" .. pokemon.dvs.hp .. " ATK=" .. pokemon.dvs.attack ..
                " DEF=" .. pokemon.dvs.defense .. " SPD=" .. pokemon.dvs.speed ..
                " SPC=" .. pokemon.dvs.special)
    console.log("Happiness: " .. pokemon.happiness)
end

return memory_reader