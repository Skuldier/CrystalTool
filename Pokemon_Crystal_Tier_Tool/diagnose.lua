-- Pokemon Crystal Diagnostic Tool
-- Finds the correct memory addresses for your ROM

print("Pokemon Crystal Diagnostic Tool")
print("===============================")
print("This will find the correct memory addresses")
print("")

-- Helper function to set memory domain
local function setMemoryDomain(domain)
    local domains = memory.getmemorydomainlist()
    for _, d in ipairs(domains) do
        if d == domain then
            memory.usememorydomain(domain)
            return true
        end
    end
    return false
end

-- Common address variations to test
local address_sets = {
    -- WRAM addresses (without bank offset)
    {name = "WRAM Standard", base = 0x0CD7, domain = "WRAM", offsets = {count = 0, species = 1, data = 8}},
    {name = "WRAM Shifted +32", base = 0x0CF7, domain = "WRAM", offsets = {count = 0, species = 1, data = 8}},
    {name = "WRAM Shifted -1", base = 0x0CD6, domain = "WRAM", offsets = {count = 0, species = 1, data = 8}},
    {name = "WRAM Shifted +16", base = 0x0CE7, domain = "WRAM", offsets = {count = 0, species = 1, data = 8}},
    {name = "WRAM Alt Region", base = 0x01D7, domain = "WRAM", offsets = {count = 0, species = 1, data = 8}},
    
    -- System Bus addresses (with full address)
    {name = "System Bus Original", base = 0xDCD7, domain = "System Bus", offsets = {count = 0, species = 1, data = 8}},
    {name = "System Bus Shifted +32", base = 0xDCF7, domain = "System Bus", offsets = {count = 0, species = 1, data = 8}},
    {name = "System Bus Shifted -1", base = 0xDCD6, domain = "System Bus", offsets = {count = 0, species = 1, data = 8}},
    {name = "System Bus Shifted +16", base = 0xDCE7, domain = "System Bus", offsets = {count = 0, species = 1, data = 8}},
    {name = "System Bus Alt Region", base = 0xD1D7, domain = "System Bus", offsets = {count = 0, species = 1, data = 8}},
}

-- Results storage
local results = {
    found = false,
    working_set = nil,
    confidence = 0
}

-- Check if address set contains valid party data
local function validate_address_set(set)
    -- Switch to appropriate domain
    if not setMemoryDomain(set.domain) then
        return false, "Domain not available: " .. set.domain
    end
    
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
    if species[1] and species[1] >= 152 and species[1] <= 158 then confidence = confidence + 10 end  -- Starter range?
    
    -- Additional validation: check first Pokemon level
    if confidence > 50 then
        local first_pokemon = set.base + set.offsets.data
        local level = memory.readbyte(first_pokemon + 0x1F)  -- Level offset
        if level >= 1 and level <= 100 then
            confidence = confidence + 10
        else
            confidence = confidence - 20
        end
    end
    
    return valid_species or has_terminator, {
        count = count,
        species = species,
        terminator = has_terminator,
        confidence = confidence,
        domain = set.domain
    }
end

-- Pattern scanning function
local function pattern_scan()
    print("\nPerforming deep pattern scan...")
    local candidates = {}
    
    -- Test both domains
    local domains = {"WRAM", "System Bus"}
    
    for _, domain in ipairs(domains) do
        if setMemoryDomain(domain) then
            print("Scanning " .. domain .. " domain...")
            
            -- Determine scan range based on domain
            local start_addr, end_addr
            if domain == "WRAM" then
                start_addr = 0x0000
                end_addr = 0x1FFF
            else
                start_addr = 0xC000
                end_addr = 0xDFFF
            end
            
            -- Scan for party structure
            for addr = start_addr, end_addr do
                local value = memory.readbyte(addr)
                
                -- Look for valid party count
                if value >= 1 and value <= 6 then
                    local valid = true
                    
                    -- Check if followed by valid species
                    for i = 1, value do
                        local species = memory.readbyte(addr + i)
                        if species == 0 or species > 251 then
                            valid = false
                            break
                        end
                    end
                    
                    if valid then
                        -- Check for terminator
                        local term = memory.readbyte(addr + value + 1)
                        if term == 0xFF or term == 0x00 then
                            table.insert(candidates, {
                                address = addr,
                                domain = domain,
                                count = value
                            })
                        end
                    end
                end
            end
        end
    end
    
    return candidates
end

-- Save results to file
local function save_results(scan_candidates)
    local file = io.open("diagnostic_results.txt", "w")
    if not file then
        print("Could not create results file!")
        return
    end
    
    file:write("Pokemon Crystal Diagnostic Results\n")
    file:write("=================================\n\n")
    file:write("Generated: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n\n")
    
    if results.found then
        local set = results.working_set
        file:write("SUCCESS! Found working addresses:\n\n")
        file:write("Domain: " .. set.domain .. "\n")
        file:write("Add these to memory_reader.lua:\n")
        file:write("```lua\n")
        file:write("-- Use domain: " .. set.domain .. "\n")
        file:write(string.format("party_count = 0x%04X,\n", set.base + set.offsets.count))
        file:write(string.format("party_species = 0x%04X,\n", set.base + set.offsets.species))
        file:write(string.format("party_data_start = 0x%04X,\n", set.base + set.offsets.data))
        file:write("```\n\n")
        file:write("Confidence: " .. results.confidence .. "%\n")
    else
        file:write("No valid addresses found in predefined sets.\n")
        file:write("Your ROM may use non-standard memory layout.\n\n")
        
        if scan_candidates and #scan_candidates > 0 then
            file:write("Pattern scan found " .. #scan_candidates .. " candidates:\n\n")
            for i, candidate in ipairs(scan_candidates) do
                file:write(string.format("Candidate %d:\n", i))
                file:write(string.format("  Domain: %s\n", candidate.domain))
                file:write(string.format("  Address: 0x%04X\n", candidate.address))
                file:write(string.format("  Party count: %d\n", candidate.count))
                file:write("\n")
            end
        end
    end
    
    file:write("\nTested address sets:\n")
    for _, set in ipairs(address_sets) do
        local valid, data = validate_address_set(set)
        file:write(string.format("\n%s (0x%04X in %s):\n", set.name, set.base, set.domain))
        if valid and type(data) == "table" then
            file:write("  Status: Valid\n")
            file:write("  Pokemon count: " .. data.count .. "\n")
            file:write("  Confidence: " .. data.confidence .. "%\n")
        else
            file:write("  Status: Invalid\n")
            if type(data) == "string" then
                file:write("  Reason: " .. data .. "\n")
            end
        end
    end
    
    file:close()
    print("Results saved to: diagnostic_results.txt")
end

-- Main diagnostic loop
local frame = 0
local test_complete = false
local scan_candidates = {}

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
            print("Domain: " .. results.working_set.domain)
            print(string.format("Update party_count to: 0x%04X", 
                results.working_set.base + results.working_set.offsets.count))
        else
            print("\nNo valid addresses in predefined sets.")
            print("Running deep pattern scan...")
            scan_candidates = pattern_scan()
            
            if #scan_candidates > 0 then
                print("Found " .. #scan_candidates .. " candidates!")
            else
                print("No candidates found. Make sure you have Pokemon in your party!")
            end
        end
        
        save_results(scan_candidates)
        test_complete = true
    end
    
    -- Display status
    gui.text(10, 10, "Pokemon Crystal Diagnostic", "yellow")
    
    if results.found then
        gui.text(10, 30, "SUCCESS! Found working addresses", "green")
        gui.text(10, 45, "Domain: " .. results.working_set.domain, "green")
        gui.text(10, 60, "Set: " .. results.working_set.name, "green")
        gui.text(10, 75, string.format("Base: 0x%04X", results.working_set.base), "green")
        gui.text(10, 90, "Confidence: " .. results.confidence .. "%", "green")
        gui.text(10, 120, "Check diagnostic_results.txt for details", "white")
    elseif #scan_candidates > 0 then
        gui.text(10, 30, "Pattern scan found candidates!", "yellow")
        gui.text(10, 45, "Found: " .. #scan_candidates .. " possible locations", "yellow")
        gui.text(10, 60, "Check diagnostic_results.txt for details", "white")
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