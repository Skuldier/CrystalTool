-- Fixed addresses for Pokemon Crystal
-- Add these to memory_reader.lua

local fixed_addresses = {
    party_count = 0xDCD7,
    party_species = 0xDCC4,
    party_data_start = 0xDCD7
}

return fixed_addresses
