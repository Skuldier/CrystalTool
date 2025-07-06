-- Fix Party Structure for Pokemon Crystal
-- Specifically designed to handle the issue where party count shows 5 but species are wrong

print("Pokemon Crystal Party Structure Fixer")
print("=====================================")
print("Analyzing the party structure issue...")
print("")

-- Let's check what's actually at 0xDCD7 and nearby addresses
local base_addr = 0xDCD7

print("Checking memory around 0xDCD7:")
print("-------------------------------")

-- Print memory dump around the area
for offset = -8, 32 do
    local addr = base_addr + offset
    local value = memory.readbyte(addr)
    
    if offset == 0 then
        print(string.format(">>> 0x%04X: %3d (0x%02X) <<< Party count?", addr, value, value))
    elseif offset >= 1 and offset <= 6 then
        print(string.format("    0x%04X: %3d (0x%02X)     Species %d?", addr, value, value, offset))
    else
        print(string.format("    0x%04X: %3d (0x%02X)", addr, value, value))
    end
end

-- Now let's check if the actual species list is elsewhere
print("\nSearching for valid species pattern...")

local party_count = memory.readbyte(base_addr)
print("Party count at 0xDCD7: " .. party_count)

if party_count >= 1 and party_count <= 6 then
    -- Search for a sequence of valid Pokemon species IDs
    print("\nSearching for " .. party_count .. " consecutive valid species IDs...")
    
    for search_offset = -32, 64 do
        local addr = base_addr + search_offset
        local found_valid = true
        local species_list = {}
        
        -- Check if we have valid species at this offset
        for i = 0, party_count - 1 do
            local species = memory.readbyte(addr + i)
            table.insert(species_list, species)
            
            -- Check if it's a valid species (1-251)
            if species < 1 or species > 251 then
                found_valid = false
                break
            end
        end
        
        -- Check for terminator (0xFF or 0x00)
        local terminator = memory.readbyte(addr + party_count)
        local has_terminator = (terminator == 0xFF or terminator == 0x00)
        
        if found_valid then
            print(string.format("\nFound valid species at offset %+d (0x%04X):", 
                search_offset, addr))
            print("  Species: " .. table.concat(species_list, ", "))
            print("  Terminator: " .. string.format("0x%02X", terminator))
            
            -- Now find where the Pokemon data starts
            -- Look for the first species in the data structure
            print("\n  Searching for Pokemon data structure...")
            
            for data_offset = party_count + 1, 64 do
                local data_addr = addr + data_offset
                local first_species = memory.readbyte(data_addr)
                
                if first_species == species_list[1] then
                    -- Check if this looks like Pokemon data
                    local level = memory.readbyte(data_addr + 0x1F)
                    local hp = memory.read_u16_be(data_addr + 0x22)
                    local maxhp = memory.read_u16_be(data_addr + 0x24)
                    
                    if level >= 1 and level <= 100 and hp <= maxhp and maxhp > 0 and maxhp < 1000 then
                        print(string.format("    Found Pokemon data at offset %+d (0x%04X)!", 
                            data_offset, data_addr))
                        print(string.format("    First Pokemon: Species %d, Level %d, HP %d/%d",
                            first_species, level, hp, maxhp))
                        
                        -- Calculate the final addresses
                        print("\n" .. string.rep("=", 50))
                        print("SOLUTION FOUND!")
                        print("Update memory_reader.lua with these addresses:")
                        print(string.format("  party_count = 0x%04X", base_addr))
                        print(string.format("  party_species = 0x%04X  -- offset %+d from party_count", 
                            addr, search_offset))
                        print(string.format("  party_data_start = 0x%04X  -- offset %+d from species list", 
                            data_addr, data_offset))
                        
                        -- Create a fixed memory reader
                        local file = io.open("fixed_addresses.lua", "w")
                        if file then
                            file:write("-- Fixed addresses for Pokemon Crystal\n")
                            file:write("-- Add these to memory_reader.lua\n\n")
                            file:write("local fixed_addresses = {\n")
                            file:write(string.format("    party_count = 0x%04X,\n", base_addr))
                            file:write(string.format("    party_species = 0x%04X,\n", addr))
                            file:write(string.format("    party_data_start = 0x%04X\n", data_addr))
                            file:write("}\n\n")
                            file:write("return fixed_addresses\n")
                            file:close()
                            
                            print("\nFixed addresses saved to fixed_addresses.lua")
                        end
                        
                        return true
                    end
                end
            end
        end
    end
end

-- If we didn't find it with the standard approach, try a different method
print("\nTrying alternative approach...")

-- Look for Pokemon data structures directly
for addr = 0xDC00, 0xDE00 do
    local species = memory.readbyte(addr)
    
    if species >= 1 and species <= 251 then
        -- Check if this looks like Pokemon data
        local level = memory.readbyte(addr + 0x1F)
        local hp = memory.read_u16_be(addr + 0x22)
        local maxhp = memory.read_u16_be(addr + 0x24)
        
        if level >= 1 and level <= 100 and hp > 0 and hp <= maxhp and maxhp < 1000 then
            print(string.format("\nFound Pokemon data at 0x%04X:", addr))
            print(string.format("  Species: %d, Level: %d, HP: %d/%d", species, level, hp, maxhp))
            
            -- Try to work backwards to find party structure
            -- Party data usually starts 8 bytes after species list
            -- So species list might be at addr - 8 - party_count
            
            for test_count = 1, 6 do
                local test_species_addr = addr - 8 - test_count
                local test_count_addr = test_species_addr - 1
                
                if test_count_addr >= 0xD000 then
                    local count_value = memory.readbyte(test_count_addr)
                    
                    if count_value == test_count then
                        -- Check if species match
                        local species_match = true
                        for i = 0, test_count - 1 do
                            local list_species = memory.readbyte(test_species_addr + i)
                            local data_species = memory.readbyte(addr + (i * 48))
                            
                            if list_species ~= data_species then
                                species_match = false
                                break
                            end
                        end
                        
                        if species_match then
                            print("\nReverse lookup successful!")
                            print(string.format("  party_count = 0x%04X", test_count_addr))
                            print(string.format("  party_species = 0x%04X", test_species_addr))
                            print(string.format("  party_data_start = 0x%04X", addr))
                            return true
                        end
                    end
                end
            end
        end
    end
end

print("\nCould not automatically fix the structure.")
print("You may need to manually inspect the memory.")

-- Keep monitoring
while true do
    gui.text(10, 10, "Structure analysis complete", "Yellow")
    gui.text(10, 25, "Check console for results", "White")
    emu.frameadvance()
end