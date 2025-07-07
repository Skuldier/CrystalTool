#!/usr/bin/env python3
"""Find where moves are stored in Pokemon data"""

from pathlib import Path
import struct

# Known move IDs to search for
PSYWAVE = 149
POWDER_SNOW = 181
COTTON_SPORE = 178
QUICK_ATTACK = 98

# Move names for reference
MOVE_NAMES = {
    5: "Mega Punch",
    85: "Thunderbolt",
    98: "Quick Attack", 
    149: "Psywave",
    178: "Cotton Spore",
    181: "Powder Snow"
}

def find_psyduck_moves(rom_path):
    """Find Psyduck's move data"""
    rom_data = Path(rom_path).read_bytes()
    
    # Pokemon base address (from your data)
    POKEMON_BASE = 0x513F4
    PSYDUCK_NUM = 54
    
    # Get Psyduck's data offset
    psyduck_offset = POKEMON_BASE + ((PSYDUCK_NUM - 1) * 32)
    
    print(f"Psyduck data starts at: 0x{psyduck_offset:06X}")
    print("\nScanning 32-byte structure for moves...")
    print("="*60)
    
    # Read the 32 bytes
    psyduck_data = rom_data[psyduck_offset:psyduck_offset + 32]
    
    # Display all bytes
    print("Offset | Hex  | Dec | Possible Move")
    print("-"*60)
    
    for i, byte_val in enumerate(psyduck_data):
        move_name = MOVE_NAMES.get(byte_val, "")
        if move_name:
            print(f"  {i:2d}   | 0x{byte_val:02X} | {byte_val:3d} | *** {move_name} ***")
        else:
            print(f"  {i:2d}   | 0x{byte_val:02X} | {byte_val:3d} |")
    
    # Look for move patterns
    print("\n\nSearching for move sequence patterns...")
    
    # Search for the known moves in sequence
    target_moves = [PSYWAVE, POWDER_SNOW, COTTON_SPORE, QUICK_ATTACK]
    
    for start in range(0, 29):  # 32 - 4 + 1
        sequence = list(psyduck_data[start:start+4])
        if all(m in sequence for m in target_moves):
            print(f"\n✓ FOUND! Moves at offsets {start}-{start+3}:")
            for i in range(4):
                move_id = psyduck_data[start + i]
                print(f"  Move {i+1}: {move_id} = {MOVE_NAMES.get(move_id, 'Unknown')}")
            return start
    
    # Try looking for any subset
    print("\nLooking for partial matches...")
    for start in range(0, 32):
        byte_val = psyduck_data[start]
        if byte_val in target_moves:
            print(f"  Found {MOVE_NAMES.get(byte_val, f'Move {byte_val}')} at offset {start}")

# Run it
if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1:
        find_psyduck_moves(sys.argv[1])
    else:
        print("Usage: python find_moves.py <rom_file>")