-- Pokemon Crystal Party Address Diagnostic
-- Finds the correct party count address

print("Pokemon Crystal Party Address Diagnostic")
print("========================================")
print("This will help find the correct party count address")
print("")

-- Common party count addresses to test
local addresses_to_test = {
    {addr = 0xDCD7, name = "Standard Crystal"},        -- Original
    {addr = 0xDCD6, name = "Offset -1"},               -- One byte earlier
    {addr = 0xDCD8, name = "Offset +1"},               -- One byte later
    {addr = 0xDCF7, name = "Offset +32"},              -- Common offset
    {addr = 0xD163, name = "Gold/Silver location"},    -- Gen 2 alternative
    {addr = 0xD273, name = "Alternative 1"},           -- Another possibility
    {addr = 0xDA22, name = "Alternative 2"},           -- Another possibility
    {addr = 0xDA23, name = "Alternative 3"},           -- Another possibility
}

-- Function to validate if an address contains valid party count
local function validatePartyCount(addr)
    local count = memory.readbyte(addr)
    
    -- Valid party count is 1-6 for active party, 0 for empty
    if count >= 0 and count <= 6 then
        -- Check if followed by species IDs
        local species_valid = true
        local species_list = {}
        
        for i = 0, math.min(count - 1, 5) do
            local species = memory.readbyte(addr + 1 + i)
            table.insert(species_list, species)
            
            -- Species should be 1-251 (valid Pokemon)
            if species == 0 or species > 251 then
                species_valid = false
            end
        end
        
        -- Check for 0xFF terminator after party
        local terminator = memory.readbyte(addr + 1 + count)
        local has_terminator = (terminator == 0xFF)
        
        return true, {
            count = count,
            species_valid = species_valid,
            has_terminator = has_terminator,
            species = species_list
        }
    end
    
    return false, nil
end

-- Test each address
local results = {}
for _, test in ipairs(addresses_to_test) do
    local valid, data = validatePartyCount(test.addr)
    
    if valid and data then
        table.insert(results, {
            address = test.addr,
            name = test.name,
            data = data,
            score = (data.species_valid and 50 or 0) + 
                   (data.has_terminator and 30 or 0) + 
                   (data.count > 0 and data.count <= 6 and 20 or 0)
        })
    end
end

-- Sort by score
table.sort(results, function(a, b) return a.score > b.score end)

-- Display results
print("\nResults (sorted by confidence):")
print("-------------------------------")

for i, result in ipairs(results) do
    print(string.format("\n%d. %s (0x%04X) - Score: %d", 
        i, result.name, result.address, result.score))
    print("   Party count: " .. result.data.count)
    print("   Valid species: " .. tostring(result.data.species_valid))
    print("   Has terminator: " .. tostring(result.data.has_terminator))
    
    if #result.data.species > 0 then
        print("   Species: " .. table.concat(result.data.species, ", "))
    end
end

-- Continuous monitoring
print("\n\nMonitoring party data...")
print("Catch a Pokemon or change party to see updates")

local frame = 0
local last_best = nil

while true do
    frame = frame + 1
    
    -- Re-test every 60 frames
    if frame % 60 == 0 then
        -- Find current best
        local best_addr = nil
        local best_score = 0
        local best_data = nil
        
        for _, test in ipairs(addresses_to_test) do
            local valid, data = validatePartyCount(test.addr)
            if valid and data then
                local score = (data.species_valid and 50 or 0) + 
                             (data.has_terminator and 30 or 0) + 
                             (data.count > 0 and data.count <= 6 and 20 or 0)
                
                if score > best_score then
                    best_score = score
                    best_addr = test.addr
                    best_data = data
                end
            end
        end
        
        -- Display on screen
        gui.text(10, 10, "Party Diagnostic Running", "Yellow")
        
        if best_addr then
            gui.text(10, 25, string.format("Best: 0x%04X (Score: %d)", best_addr, best_score), "Green")
            gui.text(10, 40, "Count: " .. best_data.count, "White")
            
            if best_data.count > 0 then
                local species_text = "Species: " .. table.concat(best_data.species, ", ")
                gui.text(10, 55, species_text, "White")
            end
            
            -- Log if changed
            if best_addr ~= last_best then
                print(string.format("\n[Frame %d] Best address: 0x%04X", frame, best_addr))
                last_best = best_addr
            end
        else
            gui.text(10, 25, "No valid party data found", "Red")
            gui.text(10, 40, "Make sure you have Pokemon!", "White")
        end
    end
    
    emu.frameadvance()
end