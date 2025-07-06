#!/usr/bin/env python3
"""
Quick Build - Creates a single monolithic Lua file
No deployment, just builds pokemon_crystal_tier_tool.lua
"""

import os
import sys
from pathlib import Path

try:
    from build import Builder
except ImportError:
    print("ERROR: build.py not found")
    sys.exit(1)

def quick_build():
    print("Pokemon Crystal Tier Tool - Quick Build")
    print("=" * 40)
    print("\nBuilding monolithic script...")
    
    # Create builder
    builder = Builder()
    
    # Clean build directory
    if builder.build_dir.exists():
        import shutil
        shutil.rmtree(builder.build_dir)
    builder.build_dir.mkdir()
    
    # Build monolithic version only
    output_file = builder.build_monolithic()
    
    # Copy to current directory
    final_path = Path("pokemon_crystal_tier_tool.lua")
    import shutil
    shutil.copy2(output_file, final_path)
    
    print(f"\n✅ Build complete!")
    print(f"📄 Created: {final_path}")
    print("\nTo use:")
    print("1. Copy pokemon_crystal_tier_tool.lua to BizHawk/Lua/")
    print("2. Open it in BizHawk's Lua Console")
    print("\nThat's it! No other files needed.")

if __name__ == "__main__":
    quick_build()
    input("\nPress Enter to exit...")