#!/usr/bin/env python3
"""
Simple organizer for Pokemon Crystal Tier Rating Tool
Just puts all the Lua files in a clean directory structure
"""

import os
import shutil
from pathlib import Path

# List of files to organize
FILES = {
    "Core files": [
        "main.lua",
        "memory_reader.lua", 
        "tier_calculator.lua",
        "display.lua",
        "cache.lua",
        "config.lua"
    ],
    "Data files": [
        "data/type_effectiveness.lua",
        "data/move_data.lua",
        "data/pokemon_base_stats.lua"
    ]
}

def main():
    print("Pokemon Crystal Tier Tool - Simple Organizer")
    print("=" * 45)
    
    # Create output directory
    output_dir = Path("Pokemon_Crystal_Tier_Tool")
    output_dir.mkdir(exist_ok=True)
    (output_dir / "data").mkdir(exist_ok=True)
    
    print(f"\nOrganizing files into: {output_dir}/")
    print()
    
    # Copy files
    success_count = 0
    missing_files = []
    
    for category, file_list in FILES.items():
        print(f"{category}:")
        for file_path in file_list:
            source = Path(file_path)
            target = output_dir / file_path
            
            if source.exists():
                shutil.copy2(source, target)
                print(f"  ✓ {file_path}")
                success_count += 1
            else:
                print(f"  ✗ {file_path} (not found)")
                missing_files.append(file_path)
    
    # Create simple launcher
    launcher = output_dir / "LAUNCH_TOOL.lua"
    with open(launcher, 'w') as f:
        f.write('-- Pokemon Crystal Tier Tool Launcher\n')
        f.write('print("Loading Pokemon Crystal Tier Tool...")\n')
        f.write('require("main")\n')
    print(f"\n✓ Created launcher: LAUNCH_TOOL.lua")
    
    # Summary
    print(f"\n{'=' * 45}")
    print(f"Organized {success_count} files successfully!")
    if missing_files:
        print(f"Missing {len(missing_files)} files - check your download")
    print(f"\nTo use: Open LAUNCH_TOOL.lua in BizHawk's Lua Console")
    print(f"{'=' * 45}")

if __name__ == "__main__":
    main()
    input("\nPress Enter to exit...")