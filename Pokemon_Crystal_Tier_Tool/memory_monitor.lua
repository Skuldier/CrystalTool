-- Test script to verify memory reading is working
-- Run this to check if the tool can read your party data

print("Pokemon Crystal Memory Test")
print("===========================")

-- Helper function to list available memory domains
local function listMemoryDomains()
    print("\nAvailable memory domains:")
    local domains = memory.getmemorydomainlist()
    for i, domain in ipairs(domains) do
        print("  " .. i .. ". " .. domain)
    end
    return domains
end

-- Test memory reading in a specific domain
local function testDomain(domain)
    print("\nTesting domain: " .. domain)
    
    if not memory.usememorydomain then
        print("  ERROR: memory.usememorydomain not available")
        return false
    end
    
    memory.usememorydomain(domain)
    
    -- Test addresses based on domain
    local test_addr
    if domain == "WRAM" then
        test_addr = 0x0CD7  -- Party count without bank offset
    else
        test_addr = 0xDCD7  -- Full address
    end
    
    -- Try to read party count
    local party_count = memory.readbyte(test_addr)
    print(string.format("  Party count at 0x%04X: %d", test_addr, party_count))
    
    if party_count >= 1 and party_count <= 6 then
        print("  ✓ Valid party count!")
        
        -- Try to read species
        print("  Species IDs:")
        for i = 0, party_count - 1 do
            local species = memory.readbyte(test_addr + 1 + i)
            print(string.format("    Slot %d: %d", i + 1, species))
        end
        
        return true
    else
        print("  ✗ Invalid party count")
        return false
    end
end

-- Test reading 16-bit values
local function test16BitReading()
    print("\nTesting 16-bit value reading:")
    
    -- Test if memory.read_u16_le exists
    if memory.read_u16_le then
        print("  ✓ memory.read_u16_le is available")
    else
        print("  ✗ memory.read_u16_le NOT available - using manual method")
        
        -- Test manual 16-bit reading
        local function read_u16_le_manual(addr)
            local low = memory.readbyte(addr)
            local high = memory.readbyte(addr + 1)
            return low + (high * 256)
        end
        
        -- Test on a known address
        local test_value = read_u16_le_manual(0xDCD7)
        print("  Manual 16-bit read test: " .. test_value)
    end
end

-- Main test sequence
local function runTests()
    -- List available domains
    local domains = listMemoryDomains()
    
    -- Test each relevant domain
    local success = false
    for _, domain in ipairs(domains) do
        if domain == "WRAM" or domain == "System Bus" then
            if testDomain(domain) then
                success = true
                print("\n✓ " .. domain .. " domain works!")
            end
        end
    end
    
    -- Test 16-bit reading capabilities
    test16BitReading()
    
    -- Final result
    print("\n" .. string.rep("=", 40))
    if success then
        print("SUCCESS: Memory reading is working!")
        print("The tool should be able to read party data.")
    else
        print("FAILURE: Could not read party data!")
        print("Please run diagnose.lua to find correct addresses.")
    end
    print(string.rep("=", 40))
end

-- Display info while running
local frame = 0
local tests_run = false

while true do
    -- Run tests once after a short delay
    if frame == 60 and not tests_run then
        runTests()
        tests_run = true
    end
    
    -- Display status
    gui.text(10, 10, "Memory Test Running", "Yellow")
    if tests_run then
        gui.text(10, 25, "Check console for results", "White")
        gui.text(10, 40, "Press Stop to exit", "White")
    else
        gui.text(10, 25, "Waiting...", "White")
    end
    
    frame = frame + 1
    emu.frameadvance()
end