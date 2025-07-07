-- Comprehensive scanner to find ALL party structures
memory.usememorydomain("System Bus")

print("=== Comprehensive Party Structure Scanner ===")
print("Looking for all valid party structures in memory...\n")

local found_parties = {}

-- Scan entire WRAM range
for addr = 0xC000, 0xDFFF do
    local count = memory.readbyte(addr)
    
    if count >= 1 and count <= 6 then
        -- Check if this could be a party structure
        local valid = true
        local species_list = {}
        
        -- Check species bytes
        for i = 1, count do
            if addr + i <= 0xDFFF then
                local species = memory.readbyte(addr + i)
                if species > 0 and species <= 251 then
                    table.insert(species_list, species)
                else
                    valid = false
                    break
                end
            else
                valid = false
                break
            end
        end
        
        -- Check for terminator (optional)
        local has_terminator = false
        if valid and addr + count + 1 <= 0xDFFF then
            local term = memory.readbyte(addr + count + 1)
            if term == 0xFF or term == 0x00 then
                has_terminator = true
            end
        end
        
        -- If valid, check for Pokemon data structure following
        local has_pokemon_data = false
        if valid and addr + 8 <= 0xDFFF then
            -- Check if there's valid Pokemon data 8 bytes after
            local first_species = memory.readbyte(addr + 8)
            local level = memory.readbyte(addr + 8 + 0x1F)
            if first_species == species_list[1] and level > 0 and level <= 100 then
                has_pokemon_data = true
            end
        end
        
        if valid then
            table.insert(found_parties, {
                address = addr,
                count = count,
                species = species_list,
                has_terminator = has_terminator,
                has_pokemon_data = has_pokemon_data,
                confidence = (has_terminator and 20 or 0) + (has_pokemon_data and 50 or 0) + 30
            })
        end
    end
end

-- Sort by confidence
table.sort(found_parties, function(a, b) return a.confidence > b.confidence end)

-- Display results
print(string.format("Found %d potential party structures:\n", #found_parties))

for i, party in ipairs(found_parties) do
    if i <= 10 then  -- Show top 10
        print(string.format("%d. Address: 0x%04X (Confidence: %d%%)", i, party.address, party.confidence))
        print(string.format("   Count: %d, Terminator: %s, Pokemon data: %s", 
            party.count, 
            party.has_terminator and "Yes" or "No",
            party.has_pokemon_data and "Yes" or "No"))
        print("   Species: " .. table.concat(party.species, ", "))
        
        -- Check if this matches known addresses
        if party.address == 0xDCD7 then
            print("   >>> This is the VANILLA address!")
        elseif party.address == 0xD198 then
            print("   >>> This is the Python-detected Archipelago address!")
        elseif party.address == 0xC100 then
            print("   >>> This matches the earlier scan result!")
        end
        
        -- Try to read first Pokemon's details if data exists
        if party.has_pokemon_data then
            local poke_addr = party.address + 8
            local level = memory.readbyte(poke_addr + 0x1F)
            local hp = memory.read_u16_be(poke_addr + 0x22)
            local max_hp = memory.read_u16_be(poke_addr + 0x24)
            print(string.format("   First Pokemon: Level %d, HP %d/%d", level, hp, max_hp))
        end
        
        print("")
    end
end

-- Special check on vanilla address
print("\n=== Detailed check of vanilla address 0xDCD7 ===")
local vanilla_count = memory.readbyte(0xDCD7)
print("Party count: " .. vanilla_count)
if vanilla_count >= 1 and vanilla_count <= 6 then
    print("Species list:")
    for i = 0, vanilla_count - 1 do
        local species = memory.readbyte(0xDCD8 + i)
        print(string.format("  Slot %d: Species #%d", i + 1, species))
    end
    
    -- Check first Pokemon data
    local first_poke = 0xDCDF
    local species = memory.readbyte(first_poke)
    local level = memory.readbyte(first_poke + 0x1F)
    local hp = memory.read_u16_be(first_poke + 0x22)
    local max_hp = memory.read_u16_be(first_poke + 0x24)
    print(string.format("\nFirst Pokemon data at 0xDCDF:"))
    print(string.format("  Species: %d, Level: %d, HP: %d/%d", species, level, hp, max_hp))
end

-- Special check on Python address
print("\n=== Detailed check of Python address 0xD198 ===")
local python_count = memory.readbyte(0xD198)
print("Value at 0xD198: " .. python_count)
print("Next few bytes: ")
for i = 0, 7 do
    print(string.format("  0x%04X: %d", 0xD198 + i, memory.readbyte(0xD198 + i)))
end

emu.frameadvance()