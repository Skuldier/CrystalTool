#!/usr/bin/env python3
"""
Build System for Pokemon Crystal Tier Rating Tool
Combines all modules into optimized distribution files
"""

import os
import re
import json
from pathlib import Path
from datetime import datetime

class Builder:
    def __init__(self):
        self.source_dir = Path.cwd()
        self.build_dir = Path("build")
        self.dist_dir = Path("dist")
        self.version = "1.0"
        self.build_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
    def clean_dirs(self):
        """Clean build and dist directories"""
        print("🧹 Cleaning build directories...")
        
        for dir_path in [self.build_dir, self.dist_dir]:
            if dir_path.exists():
                import shutil
                shutil.rmtree(dir_path)
            dir_path.mkdir(exist_ok=True)
            
    def read_lua_file(self, filepath):
        """Read and process a Lua file"""
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            
        # Remove the module return statement for embedded modules
        if filepath.name != "main.lua":
            content = re.sub(r'\nreturn\s+\w+\s*$', '', content)
            
        return content
        
    def build_monolithic(self):
        """Build a single monolithic Lua file with all modules embedded"""
        print("\n📦 Building monolithic script...")
        
        # Module load order is important
        modules = [
            ("config", "config.lua"),
            ("type_effectiveness", "data/type_effectiveness.lua"),
            ("move_data", "data/move_data.lua"),
            ("pokemon_base_stats", "data/pokemon_base_stats.lua"),
            ("memory_reader", "memory_reader.lua"),
            ("cache", "cache.lua"),
            ("tier_calculator", "tier_calculator.lua"),
            ("display", "display.lua")
        ]
        
        # Start with header
        output = f"""-- Pokemon Crystal Tier Rating Tool (Monolithic Build)
-- Version: {self.version}
-- Built: {self.build_time}
-- This is a self-contained build with all modules embedded

-- Module storage
local _MODULES = {{}}

-- Custom require function for embedded modules
local _require = require
local function require(name)
    if _MODULES[name] then
        return _MODULES[name]
    end
    return _require(name)
end

"""
        
        # Embed each module
        for module_name, module_path in modules:
            print(f"  📄 Embedding {module_name}...")
            
            module_content = self.read_lua_file(Path(module_path))
            
            # Wrap module in a function
            output += f"""-- ===== MODULE: {module_name} =====
_MODULES["{module_name}"] = (function()
    local {module_name} = {{}}
    
{module_content}
    
    return {module_name}
end)()

"""
        
        # Add main.lua content (modified to work with embedded modules)
        print("  📄 Adding main script...")
        main_content = self.read_lua_file(Path("main.lua"))
        
        # Replace require statements in main
        main_content = re.sub(
            r'local (\w+) = require\("(\w+)"\)',
            r'local \1 = require("\2")',
            main_content
        )
        
        output += """-- ===== MAIN SCRIPT =====
""" + main_content
        
        # Save monolithic build
        monolithic_path = self.build_dir / "pokemon_crystal_tier_tool.lua"
        with open(monolithic_path, 'w', encoding='utf-8') as f:
            f.write(output)
            
        print(f"  ✅ Created monolithic build: {monolithic_path}")
        return monolithic_path
        
    def build_minimal(self):
        """Build a minimal two-file version (main + data)"""
        print("\n📦 Building minimal distribution...")
        
        # Build data file with all data modules
        data_modules = [
            ("type_effectiveness", "data/type_effectiveness.lua"),
            ("move_data", "data/move_data.lua"),
            ("pokemon_base_stats", "data/pokemon_base_stats.lua")
        ]
        
        data_output = f"""-- Pokemon Crystal Tier Tool - Data Module
-- Version: {self.version}
-- Contains all Pokemon, move, and type data

local data = {{}}

"""
        
        for module_name, module_path in data_modules:
            print(f"  📄 Adding {module_name} data...")
            module_content = self.read_lua_file(Path(module_path))
            
            data_output += f"""-- ===== {module_name.upper()} =====
data.{module_name} = (function()
    local {module_name} = {{}}
    
{module_content}
    
    return {module_name}
end)()

"""
        
        data_output += "return data"
        
        # Save data file
        data_path = self.build_dir / "pokemon_crystal_data.lua"
        with open(data_path, 'w', encoding='utf-8') as f:
            f.write(data_output)
            
        # Build main file with embedded code modules
        code_modules = [
            ("config", "config.lua"),
            ("memory_reader", "memory_reader.lua"),
            ("cache", "cache.lua"),
            ("tier_calculator", "tier_calculator.lua"),
            ("display", "display.lua")
        ]
        
        main_output = f"""-- Pokemon Crystal Tier Rating Tool (Minimal Build)
-- Version: {self.version}
-- Built: {self.build_time}

-- Load data module
local data = require("pokemon_crystal_data")

-- Module storage
local _MODULES = {{
    type_effectiveness = data.type_effectiveness,
    move_data = data.move_data,
    pokemon_base_stats = data.pokemon_base_stats
}}

-- Custom require function
local _require = require
local function require(name)
    if _MODULES[name] then
        return _MODULES[name]
    end
    return _require(name)
end

"""
        
        # Embed code modules
        for module_name, module_path in code_modules:
            print(f"  📄 Embedding {module_name}...")
            module_content = self.read_lua_file(Path(module_path))
            
            main_output += f"""-- ===== MODULE: {module_name} =====
_MODULES["{module_name}"] = (function()
    local {module_name} = {{}}
    
{module_content}
    
    return {module_name}
end)()

"""
        
        # Add main.lua content
        main_content = self.read_lua_file(Path("main.lua"))
        main_output += """-- ===== MAIN SCRIPT =====
""" + main_content
        
        # Save main file
        main_path = self.build_dir / "pokemon_crystal_main.lua"
        with open(main_path, 'w', encoding='utf-8') as f:
            f.write(main_output)
            
        print(f"  ✅ Created minimal build: {main_path} + {data_path}")
        return main_path, data_path
        
    def create_distributable(self):
        """Create final distribution package"""
        print("\n📦 Creating distribution package...")
        
        # Copy monolithic build
        monolithic_src = self.build_dir / "pokemon_crystal_tier_tool.lua"
        if monolithic_src.exists():
            import shutil
            shutil.copy2(monolithic_src, self.dist_dir / "pokemon_crystal_tier_tool.lua")
            print("  ✅ Added monolithic version")
            
        # Create simple launcher
        launcher_content = f"""-- Pokemon Crystal Tier Tool Launcher
-- Version: {self.version}
-- Simply load the monolithic build

print("==============================================")
print("Pokemon Crystal Tier Rating Tool v{self.version}")
print("==============================================")
print("")

-- Load the tool
dofile("pokemon_crystal_tier_tool.lua")
"""
        
        launcher_path = self.dist_dir / "LAUNCH.lua"
        with open(launcher_path, 'w') as f:
            f.write(launcher_content)
        print("  ✅ Created launcher")
        
        # Create README for distribution
        readme_content = f"""Pokemon Crystal Tier Rating Tool v{self.version}
==========================================

QUICK START:
1. Open BizHawk
2. Load Pokemon Crystal ROM
3. Open Lua Console (Tools → Lua Console)
4. Open script: LAUNCH.lua

FILES:
- LAUNCH.lua - Click this to start!
- pokemon_crystal_tier_tool.lua - The complete tool (monolithic build)

FEATURES:
- Real-time tier ratings (S-F)
- Visual stat displays
- Move analysis with power/coverage
- Type effectiveness calculations
- Optimized for Archipelago randomizer

CONFIGURATION:
To modify settings, open pokemon_crystal_tier_tool.lua and find
the CONFIG section near the top of the file.

Built: {self.build_time}
"""
        
        readme_path = self.dist_dir / "README.txt"
        with open(readme_path, 'w') as f:
            f.write(readme_content)
        print("  ✅ Created README")
        
    def build(self):
        """Run the complete build process"""
        print("🔨 Pokemon Crystal Tier Tool - Build System")
        print("=" * 50)
        
        # Clean directories
        self.clean_dirs()
        
        # Build monolithic version
        self.build_monolithic()
        
        # Build minimal version (optional)
        # self.build_minimal()
        
        # Create distribution
        self.create_distributable()
        
        print("\n✅ Build complete!")
        print(f"📁 Distribution ready in: {self.dist_dir}/")
        print("\nFiles created:")
        for file in self.dist_dir.iterdir():
            print(f"  - {file.name}")

def main():
    builder = Builder()
    builder.build()

if __name__ == "__main__":
    main()