-- Type Effectiveness Data for Pokemon Crystal
-- Gen 2 type matchup chart

local type_effectiveness = {}

-- Type IDs (matching Pokemon Crystal's internal representation)
local TYPES = {
    NORMAL = 0,
    FIGHTING = 1,
    FLYING = 2,
    POISON = 3,
    GROUND = 4,
    ROCK = 5,
    BUG = 6,
    GHOST = 7,
    STEEL = 8,
    FIRE = 9,
    WATER = 10,
    GRASS = 11,
    ELECTRIC = 12,
    PSYCHIC = 13,
    ICE = 14,
    DRAGON = 15,
    DARK = 16
}

-- Type effectiveness multipliers
local SUPER_EFFECTIVE = 2.0
local NOT_VERY_EFFECTIVE = 0.5
local NO_EFFECT = 0.0

-- Type effectiveness chart
-- [attacker_type][defender_type] = multiplier
local effectiveness_chart = {
    [TYPES.NORMAL] = {
        [TYPES.ROCK] = NOT_VERY_EFFECTIVE,
        [TYPES.GHOST] = NO_EFFECT,
        [TYPES.STEEL] = NOT_VERY_EFFECTIVE
    },
    [TYPES.FIGHTING] = {
        [TYPES.NORMAL] = SUPER_EFFECTIVE,
        [TYPES.FLYING] = NOT_VERY_EFFECTIVE,
        [TYPES.POISON] = NOT_VERY_EFFECTIVE,
        [TYPES.ROCK] = SUPER_EFFECTIVE,
        [TYPES.BUG] = NOT_VERY_EFFECTIVE,
        [TYPES.GHOST] = NO_EFFECT,
        [TYPES.STEEL] = SUPER_EFFECTIVE,
        [TYPES.PSYCHIC] = NOT_VERY_EFFECTIVE,
        [TYPES.ICE] = SUPER_EFFECTIVE,
        [TYPES.DARK] = SUPER_EFFECTIVE
    },
    [TYPES.FLYING] = {
        [TYPES.FIGHTING] = SUPER_EFFECTIVE,
        [TYPES.ROCK] = NOT_VERY_EFFECTIVE,
        [TYPES.BUG] = SUPER_EFFECTIVE,
        [TYPES.STEEL] = NOT_VERY_EFFECTIVE,
        [TYPES.GRASS] = SUPER_EFFECTIVE,
        [TYPES.ELECTRIC] = NOT_VERY_EFFECTIVE
    },
    [TYPES.POISON] = {
        [TYPES.POISON] = NOT_VERY_EFFECTIVE,
        [TYPES.GROUND] = NOT_VERY_EFFECTIVE,
        [TYPES.ROCK] = NOT_VERY_EFFECTIVE,
        [TYPES.GHOST] = NOT_VERY_EFFECTIVE,
        [TYPES.STEEL] = NO_EFFECT,
        [TYPES.GRASS] = SUPER_EFFECTIVE
    },
    [TYPES.GROUND] = {
        [TYPES.FLYING] = NO_EFFECT,
        [TYPES.POISON] = SUPER_EFFECTIVE,
        [TYPES.ROCK] = SUPER_EFFECTIVE,
        [TYPES.BUG] = NOT_VERY_EFFECTIVE,
        [TYPES.STEEL] = SUPER_EFFECTIVE,
        [TYPES.FIRE] = SUPER_EFFECTIVE,
        [TYPES.GRASS] = NOT_VERY_EFFECTIVE,
        [TYPES.ELECTRIC] = SUPER_EFFECTIVE
    },
    [TYPES.ROCK] = {
        [TYPES.FIGHTING] = NOT_VERY_EFFECTIVE,
        [TYPES.FLYING] = SUPER_EFFECTIVE,
        [TYPES.GROUND] = NOT_VERY_EFFECTIVE,
        [TYPES.BUG] = SUPER_EFFECTIVE,
        [TYPES.STEEL] = NOT_VERY_EFFECTIVE,
        [TYPES.FIRE] = SUPER_EFFECTIVE,
        [TYPES.ICE] = SUPER_EFFECTIVE
    },
    [TYPES.BUG] = {
        [TYPES.FIGHTING] = NOT_VERY_EFFECTIVE,
        [TYPES.FLYING] = NOT_VERY_EFFECTIVE,
        [TYPES.POISON] = NOT_VERY_EFFECTIVE,
        [TYPES.GHOST] = NOT_VERY_EFFECTIVE,
        [TYPES.STEEL] = NOT_VERY_EFFECTIVE,
        [TYPES.FIRE] = NOT_VERY_EFFECTIVE,
        [TYPES.GRASS] = SUPER_EFFECTIVE,
        [TYPES.PSYCHIC] = SUPER_EFFECTIVE,
        [TYPES.DARK] = SUPER_EFFECTIVE
    },
    [TYPES.GHOST] = {
        [TYPES.NORMAL] = NO_EFFECT,
        [TYPES.GHOST] = SUPER_EFFECTIVE,
        [TYPES.STEEL] = NOT_VERY_EFFECTIVE,
        [TYPES.PSYCHIC] = SUPER_EFFECTIVE,
        [TYPES.DARK] = NOT_VERY_EFFECTIVE
    },
    [TYPES.STEEL] = {
        [TYPES.ROCK] = SUPER_EFFECTIVE,
        [TYPES.STEEL] = NOT_VERY_EFFECTIVE,
        [TYPES.FIRE] = NOT_VERY_EFFECTIVE,
        [TYPES.WATER] = NOT_VERY_EFFECTIVE,
        [TYPES.ELECTRIC] = NOT_VERY_EFFECTIVE,
        [TYPES.ICE] = SUPER_EFFECTIVE
    },
    [TYPES.FIRE] = {
        [TYPES.ROCK] = NOT_VERY_EFFECTIVE,
        [TYPES.BUG] = SUPER_EFFECTIVE,
        [TYPES.STEEL] = SUPER_EFFECTIVE,
        [TYPES.FIRE] = NOT_VERY_EFFECTIVE,
        [TYPES.WATER] = NOT_VERY_EFFECTIVE,
        [TYPES.GRASS] = SUPER_EFFECTIVE,
        [TYPES.ICE] = SUPER_EFFECTIVE,
        [TYPES.DRAGON] = NOT_VERY_EFFECTIVE
    },
    [TYPES.WATER] = {
        [TYPES.GROUND] = SUPER_EFFECTIVE,
        [TYPES.ROCK] = SUPER_EFFECTIVE,
        [TYPES.FIRE] = SUPER_EFFECTIVE,
        [TYPES.WATER] = NOT_VERY_EFFECTIVE,
        [TYPES.GRASS] = NOT_VERY_EFFECTIVE,
        [TYPES.DRAGON] = NOT_VERY_EFFECTIVE
    },
    [TYPES.GRASS] = {
        [TYPES.FLYING] = NOT_VERY_EFFECTIVE,
        [TYPES.POISON] = NOT_VERY_EFFECTIVE,
        [TYPES.GROUND] = SUPER_EFFECTIVE,
        [TYPES.ROCK] = SUPER_EFFECTIVE,
        [TYPES.BUG] = NOT_VERY_EFFECTIVE,
        [TYPES.STEEL] = NOT_VERY_EFFECTIVE,
        [TYPES.FIRE] = NOT_VERY_EFFECTIVE,
        [TYPES.WATER] = SUPER_EFFECTIVE,
        [TYPES.GRASS] = NOT_VERY_EFFECTIVE,
        [TYPES.DRAGON] = NOT_VERY_EFFECTIVE
    },
    [TYPES.ELECTRIC] = {
        [TYPES.FLYING] = SUPER_EFFECTIVE,
        [TYPES.GROUND] = NO_EFFECT,
        [TYPES.WATER] = SUPER_EFFECTIVE,
        [TYPES.GRASS] = NOT_VERY_EFFECTIVE,
        [TYPES.ELECTRIC] = NOT_VERY_EFFECTIVE,
        [TYPES.DRAGON] = NOT_VERY_EFFECTIVE
    },
    [TYPES.PSYCHIC] = {
        [TYPES.FIGHTING] = SUPER_EFFECTIVE,
        [TYPES.POISON] = SUPER_EFFECTIVE,
        [TYPES.STEEL] = NOT_VERY_EFFECTIVE,
        [TYPES.PSYCHIC] = NOT_VERY_EFFECTIVE,
        [TYPES.DARK] = NO_EFFECT
    },
    [TYPES.ICE] = {
        [TYPES.FLYING] = SUPER_EFFECTIVE,
        [TYPES.GROUND] = SUPER_EFFECTIVE,
        [TYPES.STEEL] = NOT_VERY_EFFECTIVE,
        [TYPES.FIRE] = NOT_VERY_EFFECTIVE,
        [TYPES.WATER] = NOT_VERY_EFFECTIVE,
        [TYPES.GRASS] = SUPER_EFFECTIVE,
        [TYPES.ICE] = NOT_VERY_EFFECTIVE,
        [TYPES.DRAGON] = SUPER_EFFECTIVE
    },
    [TYPES.DRAGON] = {
        [TYPES.STEEL] = NOT_VERY_EFFECTIVE,
        [TYPES.DRAGON] = SUPER_EFFECTIVE
    },
    [TYPES.DARK] = {
        [TYPES.FIGHTING] = NOT_VERY_EFFECTIVE,
        [TYPES.GHOST] = SUPER_EFFECTIVE,
        [TYPES.STEEL] = NOT_VERY_EFFECTIVE,
        [TYPES.PSYCHIC] = SUPER_EFFECTIVE,
        [TYPES.DARK] = NOT_VERY_EFFECTIVE
    }
}

-- Get effectiveness multiplier
function type_effectiveness.getMultiplier(attacker_type, defender_type)
    if effectiveness_chart[attacker_type] and effectiveness_chart[attacker_type][defender_type] then
        return effectiveness_chart[attacker_type][defender_type]
    end
    return 1.0  -- Normal damage
end

-- Calculate offensive coverage for a type combination
function type_effectiveness.getOffensiveCoverage(type1, type2)
    local super_effective_count = 0
    local not_very_effective_count = 0
    local no_effect_count = 0
    
    -- Check against all defender types
    for defender_type = 0, 16 do
        local multiplier1 = type_effectiveness.getMultiplier(type1, defender_type)
        local multiplier2 = 1.0
        
        if type2 ~= type1 and type2 ~= 0 then
            multiplier2 = type_effectiveness.getMultiplier(type2, defender_type)
        end
        
        -- Use the better multiplier
        local best_multiplier = math.max(multiplier1, multiplier2)
        
        if best_multiplier >= SUPER_EFFECTIVE then
            super_effective_count = super_effective_count + 1
        elseif best_multiplier <= NOT_VERY_EFFECTIVE and best_multiplier > 0 then
            not_very_effective_count = not_very_effective_count + 1
        elseif best_multiplier == NO_EFFECT then
            no_effect_count = no_effect_count + 1
        end
    end
    
    return {
        super_effective_count = super_effective_count,
        not_very_effective_count = not_very_effective_count,
        no_effect_count = no_effect_count
    }
end

-- Calculate defensive matchups for a type combination
function type_effectiveness.getDefensiveMatchups(type1, type2)
    local resist_count = 0
    local weak_count = 0
    local immune_count = 0
    
    -- Check against all attacker types
    for attacker_type = 0, 16 do
        local multiplier1 = type_effectiveness.getMultiplier(attacker_type, type1)
        local multiplier2 = 1.0
        
        if type2 ~= type1 and type2 ~= 0 then
            multiplier2 = type_effectiveness.getMultiplier(attacker_type, type2)
        end
        
        -- Combined multiplier for dual types
        local combined_multiplier = multiplier1 * multiplier2
        
        if combined_multiplier >= SUPER_EFFECTIVE then
            weak_count = weak_count + 1
        elseif combined_multiplier <= NOT_VERY_EFFECTIVE and combined_multiplier > 0 then
            resist_count = resist_count + 1
        elseif combined_multiplier == NO_EFFECT then
            immune_count = immune_count + 1
        end
    end
    
    return {
        resist_count = resist_count,
        weak_count = weak_count,
        immune_count = immune_count
    }
end

-- Calculate type synergy score
function type_effectiveness.getTypeSynergy(type1, type2)
    if type2 == type1 or type2 == 0 then
        return 0  -- No synergy for mono-type
    end
    
    local synergy_score = 0
    
    -- Check if types cover each other's weaknesses
    for attacker_type = 0, 16 do
        local mult1 = type_effectiveness.getMultiplier(attacker_type, type1)
        local mult2 = type_effectiveness.getMultiplier(attacker_type, type2)
        
        -- Type 2 resists what Type 1 is weak to
        if mult1 >= SUPER_EFFECTIVE and mult2 <= NOT_VERY_EFFECTIVE then
            synergy_score = synergy_score + 1
        end
        
        -- Type 1 resists what Type 2 is weak to
        if mult2 >= SUPER_EFFECTIVE and mult1 <= NOT_VERY_EFFECTIVE then
            synergy_score = synergy_score + 1
        end
    end
    
    return synergy_score
end

return type_effectiveness