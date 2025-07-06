-- Starter Memory Scanner for Pokemon Crystal
-- Finds where starter Pokemon are stored during selection

print("Starter Memory Scanner")
print("======================")
print("Go to Professor Elm's lab and approach the Pokemon balls")
print("This will scan for the starter Pokemon IDs")

-- Known starter IDs (in case they're not randomized)
local standard_starters = {
    152,  -- Chikorita
    155,  -- Cyndaquil  
    158   -- Totodile
}

-- Memory regions to scan
local scan_regions = {
    {start = 0xC000, stop = 0xC300, name = "Lower WRAM"},
    {start = 0xC800, stop = 0xCB00, name = "Mid WRAM 1"},
    {start = 0xCC00, stop = 0xCF00, name = "Mid WRAM 2"},
    {start = 0xD000, stop = 0xD300, name = "Upper WRAM 1"},
    {start = 0xD800, stop = 0xDB00, name = "Upper WRAM 2"},
    {start = 0xDC00, stop = 0xDF00, name = "Upper WRAM 3"}
}

-- Results storage
local found_addresses = {}
local last_scan = 0

-- Function to check if three consecutive bytes could be starters
local function checkForStarters(addr)
    local val1 = memory.readbyte(addr)
    local val2 = memory.readbyte(addr + 1)
    local val3 = memory.readbyte(addr + 2)
    
    -- Check if all three are valid Pokemon IDs
    if val1 > 0 and val1 <= 251 and
       val2 > 0 and val2 <= 251 and
       val3 > 0 and val3 <= 251 then
        
        -- Extra confidence if they're the standard starters
        local is_standard = false
        for _, starter in ipairs(standard_starters) do
            if val1 == starter or val2 == starter or val3 == starter then
                is_standard = true
                break
            end
        end
        
        return true, {val1, val2, val3}, is_standard
    end
    
    return false, nil, false
end

-- Scan memory regions
local function scanMemory()
    local results = {}
    
    for _, region in ipairs(scan_regions) do
        for addr = region.start, region.stop - 3 do
            local found, values, is_standard = checkForStarters(addr)
            
            if found then
                table.insert(results, {
                    address = addr,
                    values = values,
                    region = region.name,
                    is_standard = is_standard
                })
            end
        end
    end
    
    return results
end

-- Main loop
local frame = 0
local scan_interval = 60  -- Scan every second

while true do
    frame = frame + 1
    
    -- Scan periodically
    if frame % scan_interval == 0 then
        local results = scanMemory()
        
        if #results > 0 and #results ~= #found_addresses then
            found_addresses = results
            
            print("\n[Frame " .. frame .. "] Found potential starter locations:")
            for _, result in ipairs(results) do
                local addr_str = string.format("0x%04X", result.address)
                local vals_str = string.format("%d, %d, %d", 
                    result.values[1], result.values[2], result.values[3])
                local std_str = result.is_standard and " [STANDARD STARTERS!]" or ""
                
                print(string.format("  %s (%s): %s%s", 
                    addr_str, result.region, vals_str, std_str))
            end
            
            -- Save to file
            local file = io.open("starter_addresses.txt", "w")
            if file then
                file:write("Starter Pokemon Memory Locations\n")
                file:write("================================\n\n")
                file:write("Scan Time: Frame " .. frame .. "\n\n")
                
                for _, result in ipairs(results) do
                    file:write(string.format("Address: 0x%04X (%s)\n", 
                        result.address, result.region))
                    file:write(string.format("Values: %d, %d, %d\n", 
                        result.values[1], result.values[2], result.values[3]))
                    if result.is_standard then
                        file:write("*** STANDARD STARTERS DETECTED ***\n")
                    end
                    file:write("\n")
                end
                
                file:write("\nTo use in starter_detector.lua, update:\n")
                file:write("starter_data = {\n")
                if #results > 0 then
                    local best = results[1]
                    for _, result in ipairs(results) do
                        if result.is_standard then
                            best = result
                            break
                        end
                    end
                    file:write(string.format("    slot1 = 0x%04X,\n", best.address))
                    file:write(string.format("    slot2 = 0x%04X,\n", best.address + 1))
                    file:write(string.format("    slot3 = 0x%04X,\n", best.address + 2))
                end
                file:write("}\n")
                
                file:close()
                print("  Saved to starter_addresses.txt")
            end
        end
    end
    
    -- Display status
    gui.text(10, 10, "Starter Scanner Active", "Yellow")
    gui.text(10, 25, "Go to Elm's lab Pokemon balls", "White")
    gui.text(10, 40, "Found locations: " .. #found_addresses, "Cyan")
    
    if #found_addresses > 0 then
        local y = 60
        gui.text(10, y, "Latest finds:", "Green")
        y = y + 15
        
        for i = 1, math.min(3, #found_addresses) do
            local result = found_addresses[i]
            local text = string.format("0x%04X: %d,%d,%d", 
                result.address, 
                result.values[1], result.values[2], result.values[3])
            
            if result.is_standard then
                gui.text(10, y, text, "Green")
            else
                gui.text(10, y, text, "White")
            end
            y = y + 15
        end
    end
    
    emu.frameadvance()
end