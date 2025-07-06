-- Deep Memory Scanner for Pokemon Crystal
-- Finds the correct memory structure by analyzing patterns

print("Pokemon Crystal Deep Memory Scanner")
print("===================================")
print("This will analyze memory structure to find correct addresses")
print("")

-- Function to check if a value could be a valid Pokemon species
local function isValidSpecies(val)
    return val >= 1 and val <= 251
end

-- Function to check if a sequence looks like Pokemon data
local function analyzePokemonStructure(addr)
    -- Pokemon structure should have:
    -- Species, Item, Moves (4), OT ID (2), Exp (3), etc.
    
    local species = memory.readbyte(addr)
    if not isValidSpecies(species) then
        return false, nil
    end
    
    -- Check moves (should be 0-251, with 0 being no move)
    local moves_valid = true
    local moves = {}
    for i = 2, 5 do
        local move = memory.readbyte(addr + i)
        table.insert(moves, move)
        if move > 251 then
            moves_valid = false
        end
    end
    
    -- Check level (offset 0x1F in structure)
    local level = memory.readbyte(addr + 0x1F)
    local level_valid = level >= 1 and level <= 100
    
    -- Check HP (offset 0x22-0x23)
    local current_hp = memory.read_u16_be(addr + 0x22)
    local max_hp = memory.read_u16_be(addr + 0x24)
    local hp_valid = current_hp <= max_hp and max_hp > 0 and max_hp < 1000
    
    local score = 0
    if moves_valid then score = score + 25 end
    if level_valid then score = score + 25 end
    if hp_valid then score = score + 50 end
    
    return score > 50, {
        species = species,
        moves = moves,
        level = level,
        current_hp = current_hp,
        max_hp = max_hp,
        score = score
    }
end

-- Function to find party structure
local function findPartyStructure()
    print("Scanning for party structure...")
    
    local results = {}
    
    -- Scan memory regions
    for addr = 0xD000, 0xE000 do
        local count = memory.readbyte(addr)
        
        -- Check if this could be party count (1-6)
        if count >= 1 and count <= 6 then
            -- Check different possible offsets for species list
            local offsets_to_try = {1, 2, 7, 8, 16, 32}
            
            for _, species_offset in ipairs(offsets_to_try) do
                local species_list = {}
                local all_valid = true
                
                -- Read potential species list
                for i = 0, count - 1 do
                    local species = memory.readbyte(addr + species_offset + i)
                    table.insert(species_list, species)
                    
                    if not isValidSpecies(species) then
                        all_valid = false
                    end
                end
                
                -- Check for terminator
                local terminator = memory.readbyte(addr + species_offset + count)
                local has_terminator = (terminator == 0xFF or terminator == 0x00)
                
                -- Now check different offsets for Pokemon data
                if all_valid or (count == #species_list and species_list[1] > 0) then
                    local data_offsets_to_try = {8, 9, 16, 32, species_offset + count + 1}
                    
                    for _, data_offset in ipairs(data_offsets_to_try) do
                        -- Check if first Pokemon data matches first species
                        local first_pokemon_species = memory.readbyte(addr + data_offset)
                        
                        if first_pokemon_species == species_list[1] then
                            -- Analyze Pokemon structure
                            local valid, poke_data = analyzePokemonStructure(addr + data_offset)
                            
                            if valid then
                                table.insert(results, {
                                    party_count_addr = addr,
                                    species_offset = species_offset,
                                    data_offset = data_offset,
                                    count = count,
                                    species_list = species_list,
                                    has_terminator = has_terminator,
                                    pokemon_data = poke_data,
                                    score = (all_valid and 50 or 25) + 
                                           (has_terminator and 25 or 0) + 
                                           (poke_data.score or 0)
                                })
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Sort by score
    table.sort(results, function(a, b) return a.score > b.score end)
    
    return results
end

-- Run the scan
local scan_results = findPartyStructure()

print("\nScan complete. Found " .. #scan_results .. " potential structures")
print("")

if #scan_results > 0 then
    print("Top results:")
    print("============")
    
    for i = 1, math.min(5, #scan_results) do
        local r = scan_results[i]
        print(string.format("\n%d. Score: %d", i, r.score))
        print(string.format("   Party count at: 0x%04X = %d", r.party_count_addr, r.count))
        print(string.format("   Species at: 0x%04X (offset +%d)", 
            r.party_count_addr + r.species_offset, r.species_offset))
        print(string.format("   Pokemon data at: 0x%04X (offset +%d)", 
            r.party_count_addr + r.data_offset, r.data_offset))
        print("   Species list: " .. table.concat(r.species_list, ", "))
        
        if r.pokemon_data then
            print(string.format("   First Pokemon: Species %d, Level %d, HP %d/%d",
                r.pokemon_data.species, r.pokemon_data.level,
                r.pokemon_data.current_hp, r.pokemon_data.max_hp))
        end
    end
    
    -- Best match
    local best = scan_results[1]
    print("\n" .. string.rep("=", 50))
    print("RECOMMENDED memory_reader.lua updates:")
    print(string.format("  party_count = 0x%04X", best.party_count_addr))
    print(string.format("  party_species = 0x%04X  -- offset +%d", 
        best.party_count_addr + best.species_offset, best.species_offset))
    print(string.format("  party_data_start = 0x%04X  -- offset +%d", 
        best.party_count_addr + best.data_offset, best.data_offset))
    
    -- Save to file
    local file = io.open("memory_structure.txt", "w")
    if file then
        file:write("Pokemon Crystal Memory Structure Analysis\n")
        file:write("=========================================\n\n")
        file:write(string.format("Best match (score: %d):\n", best.score))
        file:write(string.format("  party_count = 0x%04X\n", best.party_count_addr))
        file:write(string.format("  party_species = 0x%04X\n", best.party_count_addr + best.species_offset))
        file:write(string.format("  party_data_start = 0x%04X\n", best.party_count_addr + best.data_offset))
        file:write(string.format("\nParty count: %d\n", best.count))
        file:write("Species: " .. table.concat(best.species_list, ", ") .. "\n")
        file:close()
        print("\nResults saved to memory_structure.txt")
    end
else
    print("No valid party structure found!")
    print("Please make sure you have Pokemon in your party")
end

-- Monitor the best result
print("\nMonitoring best result... (Press Stop to exit)")

while true do
    if #scan_results > 0 then
        local best = scan_results[1]
        
        -- Read current data
        local count = memory.readbyte(best.party_count_addr)
        gui.text(10, 10, string.format("Party Count: %d at 0x%04X", count, best.party_count_addr), "Yellow")
        
        -- Read species
        local species_text = "Species: "
        for i = 0, math.min(count - 1, 5) do
            local species = memory.readbyte(best.party_count_addr + best.species_offset + i)
            species_text = species_text .. species .. " "
        end
        gui.text(10, 25, species_text, "White")
        
        -- Read first Pokemon data
        local first_species = memory.readbyte(best.party_count_addr + best.data_offset)
        local first_level = memory.readbyte(best.party_count_addr + best.data_offset + 0x1F)
        local first_hp = memory.read_u16_be(best.party_count_addr + best.data_offset + 0x22)
        local first_maxhp = memory.read_u16_be(best.party_count_addr + best.data_offset + 0x24)
        
        gui.text(10, 40, string.format("First Pokemon: #%d Lv%d HP:%d/%d", 
            first_species, first_level, first_hp, first_maxhp), "Green")
    else
        gui.text(10, 10, "No party structure found", "Red")
    end
    
    emu.frameadvance()
end