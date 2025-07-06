-- Pokemon Crystal Diagnostic Tool
-- Finds the correct memory addresses for your ROM

print("Pokemon Crystal Diagnostic Tool")
print("===============================")
print("This will find the correct memory addresses")
print("")

-- Common address variations to test
local address_sets = {
    {name = "Original", base = 0xDCD7, offsets = {count = 0, species = 1, data = 8}},
    {name = "Shifted +32", base = 0xDCF7, offsets = {count = 0, species = 1, data = 8}},
    {name = "Shifted -1", base = 0xDCD6, offsets = {count = 0, species = 1, data = 8}},
    {name = "Shifted +16", base = 0xDCE7, offsets = {count = 0, species = 1, data = 8}},
    {name = "Alt Region", base = 0xD1D7, offsets = {count = 0, species = 1, data = 8}},
}

-- Results storage
local results = {
    found = false,
    working_set = nil,
    confidence = 0
}

-- Check if address set contains valid party data
local function validate_address_set(set)
    local count_addr = set.base + set.offsets.count
    local species_addr = set.base + set.offsets.species
    
    local count = memory.readbyte(count_addr)
    
    -- Basic validation
    if count < 1 or count > 6 then
        return false, "Invalid count: " .. count
    end
    
    -- Check species
    local species = {}
    local valid_species = true
    
    for i = 0, count - 1 do
        local s = memory.readbyte(species_addr + i)
        table.insert(species, s)
        
        if s == 0 or s > 251 then
            valid_species = false
        end
    end
    
    -- Check for 0xFF terminator
    local terminator = memory.readbyte(species_addr + count)
    local has_terminator = (terminator == 0xFF)
    
    -- Calculate confidence
    local confidence = 0
    if valid_species then confidence = confidence + 40 end
    if has_terminator then confidence = confidence + 30 end
    if count >= 1 and count <= 3 then confidence = confidence + 20 end  -- Early game likely
    if species[1] and species[1] <= 9 then confidence = confidence + 10 end  -- Starter?
    
    return valid_species or has_terminator, {
        count = count,
        species = species,
        terminator = has_terminator,
        confidence = confidence
    }
end

-- Save results to file
local function save_results()
    local file = io.open("diagnostic_results.txt", "w")
    if not file then
        print("Could not create results file!")
        return
    end
    
    file:write("Pokemon Crystal Diagnostic Results\n")
    file:write("=================================\n\n")
    
    if results.found then
        local set = results.working_set
        file:write("SUCCESS! Found working addresses:\n\n")
        file:write("Add these to memory_reader.lua:\n")
        file:write("```lua\n")
        file:write(string.format("party_count = 0x%04X,\n", set.base + set.offsets.count))
        file:write(string.format("party_species = 0x%04X,\n", set.base + set.offsets.species))
        file:write(string.format("party_data_start = 0x%04X,\n", set.base + set.offsets.data))
        file:write("```\n\n")
        file:write("Confidence: " .. results.confidence .. "%\n")
    else
        file:write("No valid addresses found.\n")
        file:write("Your ROM may use non-standard memory layout.\n")
    end
    
    file:write("\nTested address sets:\n")
    for _, set in ipairs(address_sets) do
        local valid, data = validate_address_set(set)
        file:write(string.format("\n%s (0x%04X):\n", set.name, set.base))
        if valid and type(data) == "table" then
            file:write("  Status: Valid\n")
            file:write("  Pokemon count: " .. data.count .. "\n")
            file:write("  Confidence: " .. data.confidence .. "%\n")
        else
            file:write("  Status: Invalid\n")
        end
    end
    
    file:close()
    print("Results saved to: diagnostic_results.txt")
end

-- Main diagnostic loop
local frame = 0
local test_complete = false

while true do
    -- Run tests every 60 frames
    if frame % 60 == 0 and not test_complete then
        print("\nTesting address sets...")
        
        for _, set in ipairs(address_sets) do
            local valid, data = validate_address_set(set)
            
            if valid and type(data) == "table" and data.confidence > results.confidence then
                results.found = true
                results.working_set = set
                results.confidence = data.confidence
                
                print(string.format("✓ %s works! (confidence: %d%%)", 
                    set.name, data.confidence))
            end
        end
        
        if results.found then
            print("\nBEST MATCH: " .. results.working_set.name)
            print(string.format("Update party_count to: 0x%04X", 
                results.working_set.base + results.working_set.offsets.count))
            
            save_results()
            test_complete = true
        else
            print("\nNo valid addresses found yet...")
            print("Make sure you have Pokemon in your party!")
        end
    end
    
    -- Display status
    gui.text(10, 10, "Pokemon Crystal Diagnostic", "yellow")
    
    if results.found then
        gui.text(10, 30, "SUCCESS! Found working addresses", "green")
        gui.text(10, 45, "Set: " .. results.working_set.name, "green")
        gui.text(10, 60, string.format("Base: 0x%04X", results.working_set.base), "green")
        gui.text(10, 75, "Confidence: " .. results.confidence .. "%", "green")
        gui.text(10, 105, "Check diagnostic_results.txt for details", "white")
    else
        gui.text(10, 30, "Scanning for party data...", "white")
        gui.text(10, 45, "Make sure you have Pokemon in party", "white")
        
        -- Show current test
        local test_idx = (frame / 60) % #address_sets + 1
        local current_set = address_sets[math.floor(test_idx)]
        if current_set then
            gui.text(10, 75, "Testing: " .. current_set.name, "cyan")
        end
    end
    
    frame = frame + 1
    emu.frameadvance()
end