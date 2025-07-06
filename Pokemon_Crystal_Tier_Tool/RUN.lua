-- Pokemon Crystal Tier Tool Runner
-- This properly handles the main loop with the new memory system

print("Starting Pokemon Crystal Tier Tool...")
print("=====================================")

-- Load required modules
local memory_reader = require("memory_reader")
local tier_calculator = require("tier_calculator")
local display = require("display")
local cache = require("cache")
local config = require("config")

-- Optional starter addon
local has_starter = pcall(require, "starter_addon")

-- Initialize memory reader first
print("Initializing memory reader...")
if not memory_reader.initialize() then
    print("ERROR: Failed to initialize memory reader!")
    print("")
    print("Troubleshooting steps:")
    print("1. Make sure you have Pokemon in your party")
    print("2. Run diagnose.lua to find correct addresses")
    print("3. Check that this is Pokemon Crystal (not Gold/Silver)")
    print("")
    print("Press Stop to exit")
    
    -- Display error on screen
    while true do
        gui.drawBox(5, 5, 250, 60, 0x000000CC, 0x000000CC)
        gui.drawText(10, 10, "Memory Reader Failed!", 0xFFFF0000, 11)
        gui.drawText(10, 25, "Run diagnose.lua to fix", 0xFFFFFFFF)
        gui.drawText(10, 40, "See console for details", 0xFFFFFFFF)
        emu.frameadvance()
    end
end

-- Show status
local status = memory_reader.getStatus()
print("Memory reader initialized successfully!")
print("  Domain: " .. status.memory_domain)
print("  Party address: " .. status.party_count_addr)

-- Load and run main
print("Loading main tool...")
dofile("main.lua")

-- Note: main.lua sets up its own frame advance loop
-- This script ends here and main.lua takes over