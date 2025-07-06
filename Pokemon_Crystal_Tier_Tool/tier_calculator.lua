-- Tier Calculator Module for Pokemon Crystal
-- Calculates tier ratings based on randomizer context

local tier_calculator = {}

-- Load configuration and data
local config = require("config")
local type_effectiveness = require("data.type_effectiveness")
local move_data = require("data.move_data")
local pokemon_base_stats = require("data.pokemon_base_stats")

-- Tier boundaries
local TIER_BOUNDARIES = {
    { tier = "S", min = 85, color = "Red" },
    { tier = "A", min = 70, color = "Orange" },
    { tier = "B", min = 55, color = "Yellow" },
    { tier = "C", min = 40, color = "Green" },
    { tier = "D", min = 25, color = "Blue" },
    { tier = "F", min = 0, color = "Gray" }
}

-- Initialize the tier calculator
function tier_calculator.initialize()
    console.log("Tier calculator initialized")
end

-- Calculate BST score with randomizer weighting
local function calculateBSTScore(pokemon)
    -- Weight factors for randomizer context (HP and Speed are crucial)
    local weights = {
        hp = 1.5,
        attack = 1.2,
        defense = 1.0,
        sp_attack = 1.2,
        sp_defense = 1.0,
        speed = 1.3
    }
    
    local weighted_bst = 
        (pokemon.max_hp * weights.hp) +
        (pokemon.attack * weights.attack) +
        (pokemon.defense * weights.defense) +
        (pokemon.sp_attack * weights.sp_attack) +
        (pokemon.sp_defense * weights.sp_defense) +
        (pokemon.speed * weights.speed)
    
    -- Normalize to 0-100 scale
    -- Assuming min weighted BST ~300, max ~850
    local normalized = ((weighted_bst - 300) / 550) * 100
    return math.max(0, math.min(100, normalized))
end

-- Calculate type effectiveness score
local function calculateTypeScore(pokemon)
    local type1 = pokemon.types.type1
    local type2 = pokemon.types.type2
    
    local offensive_score = 0
    local defensive_score = 0
    
    -- Calculate offensive coverage
    local offensive_coverage = type_effectiveness.getOffensiveCoverage(type1, type2)
    offensive_score = (offensive_coverage.super_effective_count * 5) - 
                     (offensive_coverage.not_very_effective_count * 3)
    
    -- Calculate defensive resilience
    local defensive_matchups = type_effectiveness.getDefensiveMatchups(type1, type2)
    defensive_score = (defensive_matchups.resist_count * 4) + 
                     (defensive_matchups.immune_count * 8) - 
                     (defensive_matchups.weak_count * 5)
    
    -- Bonus for good type combinations
    local type_synergy = 0
    if type2 ~= type1 and type2 ~= 0 then
        type_synergy = type_effectiveness.getTypeSynergy(type1, type2) * 10
    end
    
    -- Normalize to 0-100
    local total_type_score = offensive_score + defensive_score + type_synergy
    return math.max(0, math.min(100, 50 + (total_type_score * 2)))
end

-- Calculate movepool quality score
local function calculateMovepoolScore(pokemon)
    local score = 0
    local move_types = {}
    local move_categories = { physical = 0, special = 0, status = 0 }
    local total_power = 0
    local has_stab = false
    
    for _, move_id in ipairs(pokemon.moves) do
        if move_id > 0 then
            local move = move_data.getMoveData(move_id)
            if move then
                -- Track move diversity
                move_types[move.type] = true
                
                -- Track move categories
                if move.category == "Physical" then
                    move_categories.physical = move_categories.physical + 1
                elseif move.category == "Special" then
                    move_categories.special = move_categories.special + 1
                else
                    move_categories.status = move_categories.status + 1
                end
                
                -- Add power with accuracy weight
                if move.power > 0 then
                    total_power = total_power + (move.power * (move.accuracy / 100))
                end
                
                -- Check for STAB
                if move.type == pokemon.types.type1 or move.type == pokemon.types.type2 then
                    has_stab = true
                end
                
                -- Bonus for priority moves
                if move.priority > 0 then
                    score = score + 10
                end
                
                -- Bonus for utility moves
                if move_data.isUtilityMove(move_id) then
                    score = score + 15
                end
            end
        end
    end
    
    -- Calculate type coverage score
    local type_coverage = 0
    for _ in pairs(move_types) do
        type_coverage = type_coverage + 1
    end
    score = score + (type_coverage * 10)
    
    -- STAB bonus
    if has_stab then
        score = score + 20
    end
    
    -- Move category balance bonus
    local balance_score = 0
    if move_categories.physical > 0 and move_categories.special > 0 then
        balance_score = 15  -- Mixed attacker bonus
    end
    if move_categories.status > 0 then
        balance_score = balance_score + 10  -- Utility bonus
    end
    score = score + balance_score
    
    -- Average power bonus
    local avg_power = total_power / 4
    score = score + (avg_power / 3)
    
    return math.max(0, math.min(100, score))
end

-- Calculate adaptability score for randomizer context
local function calculateAdaptabilityScore(pokemon)
    local score = 50 -- Base score
    
    -- Speed tier bonus (critical in randomizers)
    if pokemon.speed >= 100 then
        score = score + 25
    elseif pokemon.speed >= 80 then
        score = score + 15
    elseif pokemon.speed >= 60 then
        score = score + 5
    end
    
    -- Bulk score (HP * Defenses)
    local physical_bulk = pokemon.max_hp * pokemon.defense / 1000
    local special_bulk = pokemon.max_hp * pokemon.sp_defense / 1000
    local bulk_score = (physical_bulk + special_bulk) * 10
    score = score + math.min(25, bulk_score)
    
    -- Offensive presence
    local offensive_presence = math.max(pokemon.attack, pokemon.sp_attack)
    if offensive_presence >= 100 then
        score = score + 20
    elseif offensive_presence >= 80 then
        score = score + 10
    end
    
    -- Level scaling factor (early game viability)
    if pokemon.level <= 25 then
        score = score + 15  -- Early game bonus
    elseif pokemon.level <= 40 then
        score = score + 5   -- Mid game bonus
    end
    
    -- Item synergy
    if pokemon.held_item > 0 then
        score = score + 5
    end
    
    return math.max(0, math.min(100, score))
end

-- Assign tier based on score
local function assignTier(score)
    for _, boundary in ipairs(TIER_BOUNDARIES) do
        if score >= boundary.min then
            return {
                tier = boundary.tier,
                score = score,
                color = boundary.color
            }
        end
    end
    return { tier = "F", score = score, color = "Gray" }
end

-- Main tier calculation function
function tier_calculator.calculateTierRating(pokemon)
    -- Get weight configuration
    local weights = config.tier_weights
    
    -- Calculate individual scores
    local bst_score = calculateBSTScore(pokemon)
    local type_score = calculateTypeScore(pokemon)
    local movepool_score = calculateMovepoolScore(pokemon)
    local adaptability_score = calculateAdaptabilityScore(pokemon)
    
    -- Apply weights
    local total_score = 
        (bst_score * weights.base_stats) +
        (type_score * weights.type_advantage) +
        (movepool_score * weights.movepool) +
        (adaptability_score * weights.adaptability)
    
    -- Get base tier
    local tier_result = assignTier(total_score)
    
    -- Add detailed breakdown
    tier_result.breakdown = {
        bst = math.floor(bst_score),
        type = math.floor(type_score),
        movepool = math.floor(movepool_score),
        adaptability = math.floor(adaptability_score)
    }
    
    -- Archipelago-specific adjustments
    if config.archipelago_mode then
        tier_result = tier_calculator.adjustForArchipelago(tier_result, pokemon)
    end
    
    return tier_result
end

-- Archipelago-specific tier adjustments
function tier_calculator.adjustForArchipelago(tier_result, pokemon)
    local adjusted_score = tier_result.score
    
    -- Early game multiplier
    if pokemon.level <= 25 and config.archipelago_early_game_multiplier then
        adjusted_score = adjusted_score * 1.2
    end
    
    -- Adjust for randomized stats (if detected)
    local expected_stats = pokemon_base_stats.getBaseStats(pokemon.species)
    if expected_stats then
        local stat_deviation = math.abs(pokemon.total_stats - expected_stats.total) / expected_stats.total
        if stat_deviation > 0.2 then  -- Stats differ by more than 20%
            -- Recalculate based on actual stats
            console.log("Detected randomized stats for species " .. pokemon.species)
            adjusted_score = tier_result.score * 0.9  -- Slight penalty for uncertainty
        end
    end
    
    -- Re-assign tier if score changed
    if adjusted_score ~= tier_result.score then
        local new_result = assignTier(adjusted_score)
        new_result.breakdown = tier_result.breakdown
        new_result.archipelago_adjusted = true
        return new_result
    end
    
    return tier_result
end

-- Debug function to print tier calculation
function tier_calculator.debugTierCalculation(pokemon)
    local result = tier_calculator.calculateTierRating(pokemon)
    
    console.log("=== Tier Calculation Debug ===")
    console.log("Species: " .. pokemon.species .. " Level: " .. pokemon.level)
    console.log("Final Tier: " .. result.tier .. " (Score: " .. string.format("%.1f", result.score) .. ")")
    console.log("Breakdown:")
    console.log("  BST Score: " .. result.breakdown.bst)
    console.log("  Type Score: " .. result.breakdown.type)
    console.log("  Movepool Score: " .. result.breakdown.movepool)
    console.log("  Adaptability Score: " .. result.breakdown.adaptability)
    if result.archipelago_adjusted then
        console.log("  [Archipelago Adjusted]")
    end
end

return tier_calculator