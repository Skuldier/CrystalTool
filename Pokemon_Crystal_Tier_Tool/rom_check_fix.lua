-- Quick ROM check to verify what game is loaded

print("ROM Check Tool")
print("==============")

-- Check multiple memory domains
local domains = memory.getmemorydomainlist()
print("Available domains: " .. table.concat(domains, ", "))

-- Try to read game header
local checks = {}

-- Check 1: Try ROM domain
if memory.usememorydomain then
    for _, domain in ipairs(domains) do
        if domain == "ROM" or domain == "CartROM" then
            memory.usememorydomain(domain)
            
            -- Read title area (0x134-0x143)
            local title = ""
            for i = 0x134, 0x143 do
                local byte = memory.readbyte(i)
                if byte >= 32 and byte <= 126 then  -- Printable ASCII
                    title = title .. string.char(byte)
                end
            end
            
            checks[domain] = {
                title = title,
                byte134 = memory.readbyte(0x134),
                byte135 = memory.readbyte(0x135),
                byte136 = memory.readbyte(0x136),
                byte137 = memory.readbyte(0x137)
            }
            
            print("\n" .. domain .. " header info:")
            print("  Title: " .. title)
            print(string.format("  Bytes: %02X %02X %02X %02X", 
                checks[domain].byte134,
                checks[domain].byte135,
                checks[domain].byte136,
                checks[domain].byte137))
        end
    end
end

-- Check 2: Try System Bus
memory.usememorydomain("System Bus")
print("\nSystem Bus party check:")
local party_count = memory.readbyte(0xDCD7)
print("  Party count at 0xDCD7: " .. party_count)

if party_count >= 1 and party_count <= 6 then
    print("  ✓ Valid party count detected!")
    print("  This appears to be a Pokemon game")
    
    -- Check species
    print("  Species IDs:")
    for i = 0, party_count - 1 do
        local species = memory.readbyte(0xDCD8 + i)
        print(string.format("    Slot %d: %d", i + 1, species))
    end
end

-- Check 3: Crystal-specific addresses
print("\nCrystal-specific checks:")
local map_id = memory.readbyte(0xDCB5)
print("  Current map ID: " .. map_id)

-- Display results
print("\n" .. string.rep("=", 40))
print("RESULTS:")
if party_count >= 1 and party_count <= 6 then
    print("✓ Pokemon game data structure detected")
    print("✓ Tool should work correctly")
else
    print("✗ No valid party data found")
    print("  Make sure you have Pokemon in your party")
end

-- Keep displaying info
local frame = 0
while true do
    gui.text(10, 10, "ROM Check - See console", "Yellow")
    gui.text(10, 25, "Party count: " .. party_count, "White")
    gui.text(10, 40, "Press Stop to exit", "White")
    
    frame = frame + 1
    emu.frameadvance()
end