-- Pokemon Crystal Tier Tool Launcher
-- Simply run this file in BizHawk to start the tool

-- Clear console
console.clear()

-- Set up the Lua path to find our modules
-- Add current directory to package path
local script_dir = debug.getinfo(1).source:match("@(.*\\)") or ""
package.path = package.path .. ";" .. script_dir .. "?.lua"
package.path = package.path .. ";" .. script_dir .. "data\\?.lua"

-- Load and run the main module
local success, err = pcall(function()
    require("main")
end)

if not success then
    console.log("Failed to start Pokemon Crystal Tier Tool!")
    console.log("Error: " .. tostring(err))
    console.log("")
    console.log("Make sure all files are in the correct folders:")
    console.log("  main.lua")
    console.log("  memory_reader.lua")
    console.log("  tier_calculator.lua")
    console.log("  display.lua")
    console.log("  cache.lua")
    console.log("  config.lua")
    console.log("  starter_detector.lua")
    console.log("  data/pokemon_base_stats.lua")
    console.log("  data/type_effectiveness.lua")
    console.log("  data/move_data.lua")
end

-- Keep the script running
while true do
    emu.frameadvance()
end