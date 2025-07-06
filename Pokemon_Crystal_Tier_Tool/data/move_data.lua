-- Move Data for Pokemon Crystal
-- Contains move information for tier calculations

local move_data = {}

-- Move categories
local PHYSICAL = "Physical"
local SPECIAL = "Special"
local STATUS = "Status"

-- Common important moves in Pokemon Crystal
-- Format: [move_id] = { name, type, power, accuracy, category, priority }
local moves = {
    -- Normal moves
    [1] = { name = "Pound", type = 0, type_name = "Normal", power = 40, accuracy = 100, category = PHYSICAL, priority = 0 },
    [3] = { name = "Double Slap", type = 0, type_name = "Normal", power = 15, accuracy = 85, category = PHYSICAL, priority = 0 },
    [8] = { name = "Punch", type = 0, type_name = "Normal", power = 50, accuracy = 100, category = PHYSICAL, priority = 0 },
    [10] = { name = "Scratch", type = 0, type_name = "Normal", power = 40, accuracy = 100, category = PHYSICAL, priority = 0 },
    [21] = { name = "Slam", type = 0, type_name = "Normal", power = 80, accuracy = 75, category = PHYSICAL, priority = 0 },
    [36] = { name = "Take Down", type = 0, type_name = "Normal", power = 90, accuracy = 85, category = PHYSICAL, priority = 0 },
    [38] = { name = "Double-Edge", type = 0, type_name = "Normal", power = 120, accuracy = 100, category = PHYSICAL, priority = 0 },
    [63] = { name = "Hyper Beam", type = 0, type_name = "Normal", power = 150, accuracy = 90, category = SPECIAL, priority = 0 },
    [98] = { name = "Quick Attack", type = 0, type_name = "Normal", power = 40, accuracy = 100, category = PHYSICAL, priority = 1 },
    [129] = { name = "Swift", type = 0, type_name = "Normal", power = 60, accuracy = 100, category = SPECIAL, priority = 0 },
    [237] = { name = "Hidden Power", type = 0, type_name = "Normal", power = 70, accuracy = 100, category = SPECIAL, priority = 0 },
    [241] = { name = "Extreme Speed", type = 0, type_name = "Normal", power = 80, accuracy = 100, category = PHYSICAL, priority = 2 },
    
    -- Fighting moves
    [2] = { name = "Karate Chop", type = 1, type_name = "Fighting", power = 50, accuracy = 100, category = PHYSICAL, priority = 0 },
    [24] = { name = "Double Kick", type = 1, type_name = "Fighting", power = 30, accuracy = 100, category = PHYSICAL, priority = 0 },
    [26] = { name = "Jump Kick", type = 1, type_name = "Fighting", power = 70, accuracy = 95, category = PHYSICAL, priority = 0 },
    [27] = { name = "Rolling Kick", type = 1, type_name = "Fighting", power = 60, accuracy = 85, category = PHYSICAL, priority = 0 },
    [68] = { name = "Counter", type = 1, type_name = "Fighting", power = 0, accuracy = 100, category = PHYSICAL, priority = -5 },
    [69] = { name = "Seismic Toss", type = 1, type_name = "Fighting", power = 0, accuracy = 100, category = PHYSICAL, priority = 0 },
    [136] = { name = "Hi Jump Kick", type = 1, type_name = "Fighting", power = 85, accuracy = 90, category = PHYSICAL, priority = 0 },
    [183] = { name = "Mach Punch", type = 1, type_name = "Fighting", power = 40, accuracy = 100, category = PHYSICAL, priority = 1 },
    [223] = { name = "Dynamic Punch", type = 1, type_name = "Fighting", power = 100, accuracy = 50, category = PHYSICAL, priority = 0 },
    [238] = { name = "Cross Chop", type = 1, type_name = "Fighting", power = 100, accuracy = 80, category = PHYSICAL, priority = 0 },
    
    -- Flying moves
    [16] = { name = "Gust", type = 2, type_name = "Flying", power = 40, accuracy = 100, category = SPECIAL, priority = 0 },
    [17] = { name = "Wing Attack", type = 2, type_name = "Flying", power = 60, accuracy = 100, category = PHYSICAL, priority = 0 },
    [19] = { name = "Fly", type = 2, type_name = "Flying", power = 70, accuracy = 95, category = PHYSICAL, priority = 0 },
    [65] = { name = "Drill Peck", type = 2, type_name = "Flying", power = 80, accuracy = 100, category = PHYSICAL, priority = 0 },
    [143] = { name = "Sky Attack", type = 2, type_name = "Flying", power = 140, accuracy = 90, category = PHYSICAL, priority = 0 },
    [211] = { name = "Aeroblast", type = 2, type_name = "Flying", power = 100, accuracy = 95, category = SPECIAL, priority = 0 },
    
    -- Poison moves
    [40] = { name = "Poison Sting", type = 3, type_name = "Poison", power = 15, accuracy = 100, category = PHYSICAL, priority = 0 },
    [51] = { name = "Acid", type = 3, type_name = "Poison", power = 40, accuracy = 100, category = SPECIAL, priority = 0 },
    [77] = { name = "Poison Powder", type = 3, type_name = "Poison", power = 0, accuracy = 75, category = STATUS, priority = 0 },
    [92] = { name = "Toxic", type = 3, type_name = "Poison", power = 0, accuracy = 85, category = STATUS, priority = 0 },
    [124] = { name = "Sludge", type = 3, type_name = "Poison", power = 65, accuracy = 100, category = SPECIAL, priority = 0 },
    [188] = { name = "Sludge Bomb", type = 3, type_name = "Poison", power = 90, accuracy = 100, category = SPECIAL, priority = 0 },
    
    -- Ground moves
    [28] = { name = "Sand-Attack", type = 4, type_name = "Ground", power = 0, accuracy = 100, category = STATUS, priority = 0 },
    [89] = { name = "Earthquake", type = 4, type_name = "Ground", power = 100, accuracy = 100, category = PHYSICAL, priority = 0 },
    [90] = { name = "Fissure", type = 4, type_name = "Ground", power = 0, accuracy = 30, category = PHYSICAL, priority = 0 },
    [91] = { name = "Dig", type = 4, type_name = "Ground", power = 60, accuracy = 100, category = PHYSICAL, priority = 0 },
    [189] = { name = "Mud-Slap", type = 4, type_name = "Ground", power = 20, accuracy = 100, category = SPECIAL, priority = 0 },
    [222] = { name = "Magnitude", type = 4, type_name = "Ground", power = 0, accuracy = 100, category = PHYSICAL, priority = 0 },
    
    -- Rock moves
    [88] = { name = "Rock Throw", type = 5, type_name = "Rock", power = 50, accuracy = 90, category = PHYSICAL, priority = 0 },
    [157] = { name = "Rock Slide", type = 5, type_name = "Rock", power = 75, accuracy = 90, category = PHYSICAL, priority = 0 },
    [205] = { name = "Rollout", type = 5, type_name = "Rock", power = 30, accuracy = 90, category = PHYSICAL, priority = 0 },
    [246] = { name = "Ancient Power", type = 5, type_name = "Rock", power = 60, accuracy = 100, category = SPECIAL, priority = 0 },
    
    -- Bug moves
    [41] = { name = "Twineedle", type = 6, type_name = "Bug", power = 25, accuracy = 100, category = PHYSICAL, priority = 0 },
    [42] = { name = "Pin Missile", type = 6, type_name = "Bug", power = 14, accuracy = 85, category = PHYSICAL, priority = 0 },
    [81] = { name = "String Shot", type = 6, type_name = "Bug", power = 0, accuracy = 95, category = STATUS, priority = 0 },
    [93] = { name = "Leech Life", type = 6, type_name = "Bug", power = 20, accuracy = 100, category = PHYSICAL, priority = 0 },
    [224] = { name = "Megahorn", type = 6, type_name = "Bug", power = 120, accuracy = 85, category = PHYSICAL, priority = 0 },
    
    -- Ghost moves
    [95] = { name = "Hypnosis", type = 13, type_name = "Psychic", power = 0, accuracy = 60, category = STATUS, priority = 0 },
    [101] = { name = "Night Shade", type = 7, type_name = "Ghost", power = 0, accuracy = 100, category = SPECIAL, priority = 0 },
    [109] = { name = "Confuse Ray", type = 7, type_name = "Ghost", power = 0, accuracy = 100, category = STATUS, priority = 0 },
    [123] = { name = "Lick", type = 7, type_name = "Ghost", power = 20, accuracy = 100, category = PHYSICAL, priority = 0 },
    [174] = { name = "Curse", type = 7, type_name = "Ghost", power = 0, accuracy = 100, category = STATUS, priority = 0 },
    [194] = { name = "Destiny Bond", type = 7, type_name = "Ghost", power = 0, accuracy = 100, category = STATUS, priority = 0 },
    [247] = { name = "Shadow Ball", type = 7, type_name = "Ghost", power = 80, accuracy = 100, category = SPECIAL, priority = 0 },
    
    -- Steel moves
    [211] = { name = "Steel Wing", type = 8, type_name = "Steel", power = 70, accuracy = 90, category = PHYSICAL, priority = 0 },
    [231] = { name = "Iron Tail", type = 8, type_name = "Steel", power = 100, accuracy = 75, category = PHYSICAL, priority = 0 },
    [232] = { name = "Metal Claw", type = 8, type_name = "Steel", power = 50, accuracy = 95, category = PHYSICAL, priority = 0 },
    
    -- Fire moves
    [52] = { name = "Ember", type = 9, type_name = "Fire", power = 40, accuracy = 100, category = SPECIAL, priority = 0 },
    [53] = { name = "Flamethrower", type = 9, type_name = "Fire", power = 95, accuracy = 100, category = SPECIAL, priority = 0 },
    [83] = { name = "Fire Spin", type = 9, type_name = "Fire", power = 15, accuracy = 70, category = SPECIAL, priority = 0 },
    [126] = { name = "Fire Blast", type = 9, type_name = "Fire", power = 120, accuracy = 85, category = SPECIAL, priority = 0 },
    [172] = { name = "Flame Wheel", type = 9, type_name = "Fire", power = 60, accuracy = 100, category = PHYSICAL, priority = 0 },
    [221] = { name = "Sacred Fire", type = 9, type_name = "Fire", power = 100, accuracy = 95, category = PHYSICAL, priority = 0 },
    
    -- Water moves
    [55] = { name = "Water Gun", type = 10, type_name = "Water", power = 40, accuracy = 100, category = SPECIAL, priority = 0 },
    [56] = { name = "Hydro Pump", type = 10, type_name = "Water", power = 120, accuracy = 80, category = SPECIAL, priority = 0 },
    [57] = { name = "Surf", type = 10, type_name = "Water", power = 95, accuracy = 100, category = SPECIAL, priority = 0 },
    [58] = { name = "Ice Beam", type = 14, type_name = "Ice", power = 95, accuracy = 100, category = SPECIAL, priority = 0 },
    [59] = { name = "Blizzard", type = 14, type_name = "Ice", power = 120, accuracy = 70, category = SPECIAL, priority = 0 },
    [61] = { name = "Bubble Beam", type = 10, type_name = "Water", power = 65, accuracy = 100, category = SPECIAL, priority = 0 },
    [127] = { name = "Waterfall", type = 10, type_name = "Water", power = 80, accuracy = 100, category = PHYSICAL, priority = 0 },
    [145] = { name = "Bubble", type = 10, type_name = "Water", power = 20, accuracy = 100, category = SPECIAL, priority = 0 },
    [240] = { name = "Rain Dance", type = 10, type_name = "Water", power = 0, accuracy = 100, category = STATUS, priority = 0 },
    [250] = { name = "Whirlpool", type = 10, type_name = "Water", power = 15, accuracy = 70, category = SPECIAL, priority = 0 },
    
    -- Grass moves
    [71] = { name = "Absorb", type = 11, type_name = "Grass", power = 20, accuracy = 100, category = SPECIAL, priority = 0 },
    [72] = { name = "Mega Drain", type = 11, type_name = "Grass", power = 40, accuracy = 100, category = SPECIAL, priority = 0 },
    [73] = { name = "Leech Seed", type = 11, type_name = "Grass", power = 0, accuracy = 90, category = STATUS, priority = 0 },
    [74] = { name = "Growth", type = 0, type_name = "Normal", power = 0, accuracy = 100, category = STATUS, priority = 0 },
    [75] = { name = "Razor Leaf", type = 11, type_name = "Grass", power = 55, accuracy = 95, category = PHYSICAL, priority = 0 },
    [76] = { name = "Solar Beam", type = 11, type_name = "Grass", power = 120, accuracy = 100, category = SPECIAL, priority = 0 },
    [77] = { name = "Poison Powder", type = 3, type_name = "Poison", power = 0, accuracy = 75, category = STATUS, priority = 0 },
    [78] = { name = "Stun Spore", type = 11, type_name = "Grass", power = 0, accuracy = 75, category = STATUS, priority = 0 },
    [79] = { name = "Sleep Powder", type = 11, type_name = "Grass", power = 0, accuracy = 75, category = STATUS, priority = 0 },
    [80] = { name = "Petal Dance", type = 11, type_name = "Grass", power = 70, accuracy = 100, category = SPECIAL, priority = 0 },
    [202] = { name = "Giga Drain", type = 11, type_name = "Grass", power = 60, accuracy = 100, category = SPECIAL, priority = 0 },
    
    -- Electric moves
    [84] = { name = "Thunder Shock", type = 12, type_name = "Electric", power = 40, accuracy = 100, category = SPECIAL, priority = 0 },
    [85] = { name = "Thunderbolt", type = 12, type_name = "Electric", power = 95, accuracy = 100, category = SPECIAL, priority = 0 },
    [86] = { name = "Thunder Wave", type = 12, type_name = "Electric", power = 0, accuracy = 100, category = STATUS, priority = 0 },
    [87] = { name = "Thunder", type = 12, type_name = "Electric", power = 120, accuracy = 70, category = SPECIAL, priority = 0 },
    [192] = { name = "Zap Cannon", type = 12, type_name = "Electric", power = 100, accuracy = 50, category = SPECIAL, priority = 0 },
    [209] = { name = "Spark", type = 12, type_name = "Electric", power = 65, accuracy = 100, category = PHYSICAL, priority = 0 },
    
    -- Psychic moves
    [60] = { name = "Psybeam", type = 13, type_name = "Psychic", power = 65, accuracy = 100, category = SPECIAL, priority = 0 },
    [93] = { name = "Confusion", type = 13, type_name = "Psychic", power = 50, accuracy = 100, category = SPECIAL, priority = 0 },
    [94] = { name = "Psychic", type = 13, type_name = "Psychic", power = 90, accuracy = 100, category = SPECIAL, priority = 0 },
    [95] = { name = "Hypnosis", type = 13, type_name = "Psychic", power = 0, accuracy = 60, category = STATUS, priority = 0 },
    [113] = { name = "Light Screen", type = 13, type_name = "Psychic", power = 0, accuracy = 100, category = STATUS, priority = 0 },
    [115] = { name = "Reflect", type = 13, type_name = "Psychic", power = 0, accuracy = 100, category = STATUS, priority = 0 },
    [134] = { name = "Kinesis", type = 13, type_name = "Psychic", power = 0, accuracy = 80, category = STATUS, priority = 0 },
    [138] = { name = "Dream Eater", type = 13, type_name = "Psychic", power = 100, accuracy = 100, category = SPECIAL, priority = 0 },
    [248] = { name = "Future Sight", type = 13, type_name = "Psychic", power = 80, accuracy = 90, category = SPECIAL, priority = 0 },
    
    -- Ice moves
    [8] = { name = "Ice Punch", type = 14, type_name = "Ice", power = 75, accuracy = 100, category = PHYSICAL, priority = 0 },
    [58] = { name = "Ice Beam", type = 14, type_name = "Ice", power = 95, accuracy = 100, category = SPECIAL, priority = 0 },
    [59] = { name = "Blizzard", type = 14, type_name = "Ice", power = 120, accuracy = 70, category = SPECIAL, priority = 0 },
    [181] = { name = "Powder Snow", type = 14, type_name = "Ice", power = 40, accuracy = 100, category = SPECIAL, priority = 0 },
    [196] = { name = "Icy Wind", type = 14, type_name = "Ice", power = 55, accuracy = 95, category = SPECIAL, priority = 0 },
    
    -- Dragon moves
    [82] = { name = "Dragon Rage", type = 15, type_name = "Dragon", power = 0, accuracy = 100, category = SPECIAL, priority = 0 },
    [200] = { name = "Outrage", type = 15, type_name = "Dragon", power = 90, accuracy = 100, category = PHYSICAL, priority = 0 },
    [225] = { name = "Dragon Breath", type = 15, type_name = "Dragon", power = 60, accuracy = 100, category = SPECIAL, priority = 0 },
    [239] = { name = "Twister", type = 15, type_name = "Dragon", power = 40, accuracy = 100, category = SPECIAL, priority = 0 },
    
    -- Dark moves
    [44] = { name = "Bite", type = 16, type_name = "Dark", power = 60, accuracy = 100, category = PHYSICAL, priority = 0 },
    [185] = { name = "Faint Attack", type = 16, type_name = "Dark", power = 60, accuracy = 100, category = PHYSICAL, priority = 0 },
    [207] = { name = "Pursuit", type = 16, type_name = "Dark", power = 40, accuracy = 100, category = PHYSICAL, priority = 0 },
    [228] = { name = "Beat Up", type = 16, type_name = "Dark", power = 10, accuracy = 100, category = PHYSICAL, priority = 0 },
    [242] = { name = "Crunch", type = 16, type_name = "Dark", power = 80, accuracy = 100, category = PHYSICAL, priority = 0 },
    
    -- Status moves
    [14] = { name = "Swords Dance", type = 0, type_name = "Normal", power = 0, accuracy = 100, category = STATUS, priority = 0 },
    [18] = { name = "Whirlwind", type = 0, type_name = "Normal", power = 0, accuracy = 100, category = STATUS, priority = -6 },
    [45] = { name = "Growl", type = 0, type_name = "Normal", power = 0, accuracy = 100, category = STATUS, priority = 0 },
    [46] = { name = "Roar", type = 0, type_name = "Normal", power = 0, accuracy = 100, category = STATUS, priority = -6 },
    [47] = { name = "Sing", type = 0, type_name = "Normal", power = 0, accuracy = 55, category = STATUS, priority = 0 },
    [48] = { name = "Supersonic", type = 0, type_name = "Normal", power = 0, accuracy = 55, category = STATUS, priority = 0 },
    [73] = { name = "Leech Seed", type = 11, type_name = "Grass", power = 0, accuracy = 90, category = STATUS, priority = 0 },
    [86] = { name = "Thunder Wave", type = 12, type_name = "Electric", power = 0, accuracy = 100, category = STATUS, priority = 0 },
    [92] = { name = "Toxic", type = 3, type_name = "Poison", power = 0, accuracy = 85, category = STATUS, priority = 0 },
    [97] = { name = "Agility", type = 13, type_name = "Psychic", power = 0, accuracy = 100, category = STATUS, priority = 0 },
    [104] = { name = "Double Team", type = 0, type_name = "Normal", power = 0, accuracy = 100, category = STATUS, priority = 0 },
    [105] = { name = "Recover", type = 0, type_name = "Normal", power = 0, accuracy = 100, category = STATUS, priority = 0 },
    [106] = { name = "Harden", type = 0, type_name = "Normal", power = 0, accuracy = 100, category = STATUS, priority = 0 },
    [107] = { name = "Minimize", type = 0, type_name = "Normal", power = 0, accuracy = 100, category = STATUS, priority = 0 },
    [108] = { name = "Smoke Screen", type = 0, type_name = "Normal", power = 0, accuracy = 100, category = STATUS, priority = 0 },
    [112] = { name = "Barrier", type = 13, type_name = "Psychic", power = 0, accuracy = 100, category = STATUS, priority = 0 },
    [133] = { name = "Amnesia", type = 13, type_name = "Psychic", power = 0, accuracy = 100, category = STATUS, priority = 0 },
    [147] = { name = "Spikes", type = 4, type_name = "Ground", power = 0, accuracy = 100, category = STATUS, priority = 0 },
    [148] = { name = "Thunder Wave", type = 12, type_name = "Electric", power = 0, accuracy = 100, category = STATUS, priority = 0 },
    [156] = { name = "Rest", type = 13, type_name = "Psychic", power = 0, accuracy = 100, category = STATUS, priority = 0 },
    [164] = { name = "Substitute", type = 0, type_name = "Normal", power = 0, accuracy = 100, category = STATUS, priority = 0 },
    [182] = { name = "Protect", type = 0, type_name = "Normal", power = 0, accuracy = 100, category = STATUS, priority = 4 },
    [187] = { name = "Belly Drum", type = 0, type_name = "Normal", power = 0, accuracy = 100, category = STATUS, priority = 0 },
    [197] = { name = "Detect", type = 1, type_name = "Fighting", power = 0, accuracy = 100, category = STATUS, priority = 4 },
    [203] = { name = "Endure", type = 0, type_name = "Normal", power = 0, accuracy = 100, category = STATUS, priority = 4 },
    [212] = { name = "Mean Look", type = 0, type_name = "Normal", power = 0, accuracy = 100, category = STATUS, priority = 0 },
    [213] = { name = "Attract", type = 0, type_name = "Normal", power = 0, accuracy = 100, category = STATUS, priority = 0 },
    [214] = { name = "Sleep Talk", type = 0, type_name = "Normal", power = 0, accuracy = 100, category = STATUS, priority = 0 },
    [219] = { name = "Safeguard", type = 0, type_name = "Normal", power = 0, accuracy = 100, category = STATUS, priority = 0 },
    [226] = { name = "Baton Pass", type = 0, type_name = "Normal", power = 0, accuracy = 100, category = STATUS, priority = 0 },
    [227] = { name = "Encore", type = 0, type_name = "Normal", power = 0, accuracy = 100, category = STATUS, priority = 0 },
    [235] = { name = "Synthesis", type = 11, type_name = "Grass", power = 0, accuracy = 100, category = STATUS, priority = 0 },
    [236] = { name = "Moonlight", type = 0, type_name = "Normal", power = 0, accuracy = 100, category = STATUS, priority = 0 },
    [240] = { name = "Rain Dance", type = 10, type_name = "Water", power = 0, accuracy = 100, category = STATUS, priority = 0 },
    [241] = { name = "Sunny Day", type = 9, type_name = "Fire", power = 0, accuracy = 100, category = STATUS, priority = 0 },
    [249] = { name = "Rock Smash", type = 1, type_name = "Fighting", power = 20, accuracy = 100, category = PHYSICAL, priority = 0 }
}

-- Utility moves list (moves that provide significant strategic value)
local utility_moves = {
    [14] = true,   -- Swords Dance
    [73] = true,   -- Leech Seed
    [86] = true,   -- Thunder Wave
    [92] = true,   -- Toxic
    [95] = true,   -- Hypnosis
    [97] = true,   -- Agility
    [104] = true,  -- Double Team
    [105] = true,  -- Recover
    [113] = true,  -- Light Screen
    [115] = true,  -- Reflect
    [133] = true,  -- Amnesia
    [147] = true,  -- Spikes
    [156] = true,  -- Rest
    [164] = true,  -- Substitute
    [182] = true,  -- Protect
    [187] = true,  -- Belly Drum
    [203] = true,  -- Endure
    [213] = true,  -- Attract
    [214] = true,  -- Sleep Talk
    [219] = true,  -- Safeguard
    [226] = true,  -- Baton Pass
    [227] = true,  -- Encore
    [235] = true,  -- Synthesis
    [236] = true,  -- Moonlight
    [240] = true,  -- Rain Dance
    [241] = true   -- Sunny Day
}

-- Get move data by ID
function move_data.getMoveData(move_id)
    return moves[move_id] or {
        name = "Move " .. move_id,
        type = 0,
        type_name = "Unknown",
        power = 0,
        accuracy = 0,
        category = STATUS,
        priority = 0
    }
end

-- Check if a move is a utility move
function move_data.isUtilityMove(move_id)
    return utility_moves[move_id] or false
end

-- Get move category distribution
function move_data.getMoveCategoryStats(move_ids)
    local stats = {
        physical = 0,
        special = 0,
        status = 0,
        total_power = 0,
        max_power = 0,
        has_priority = false,
        has_stab = false
    }
    
    for _, move_id in ipairs(move_ids) do
        local move = move_data.getMoveData(move_id)
        
        if move.category == PHYSICAL then
            stats.physical = stats.physical + 1
        elseif move.category == SPECIAL then
            stats.special = stats.special + 1
        else
            stats.status = stats.status + 1
        end
        
        if move.power > 0 then
            stats.total_power = stats.total_power + move.power
            stats.max_power = math.max(stats.max_power, move.power)
        end
        
        if move.priority > 0 then
            stats.has_priority = true
        end
    end
    
    return stats
end

return move_data