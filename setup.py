#!/usr/bin/env python3
"""
Pokemon Crystal Tier Tool - Interactive Setup
Provides a menu-driven interface for all setup options
"""

import os
import sys
import subprocess
from pathlib import Path

class SetupMenu:
    def __init__(self):
        self.title = "Pokemon Crystal Tier Rating Tool - Setup"
        self.version = "1.0"
        
    def clear_screen(self):
        """Clear the console screen"""
        os.system('cls' if os.name == 'nt' else 'clear')
        
    def print_header(self):
        """Print the header"""
        print("=" * 50)
        print(f"{self.title}")
        print(f"Version {self.version}")
        print("=" * 50)
        print()
        
    def check_requirements(self):
        """Check if all required files are present"""
        required_files = [
            "build.py",
            "build_and_deploy.py", 
            "quick_build.py",
            "organize.py",
            "main.lua",
            "config.lua"
        ]
        
        missing = []
        for file in required_files:
            if not Path(file).exists():
                missing.append(file)
                
        if missing:
            print("⚠️  Warning: Some files are missing:")
            for file in missing:
                print(f"   - {file}")
            print("\nSome options may not work correctly.")
            print()
            
    def run_script(self, script_name, args=None):
        """Run a Python script"""
        try:
            cmd = [sys.executable, script_name]
            if args:
                cmd.extend(args)
            subprocess.run(cmd)
            return True
        except Exception as e:
            print(f"\n❌ Error running {script_name}: {e}")
            return False
            
    def show_main_menu(self):
        """Display the main menu"""
        while True:
            self.clear_screen()
            self.print_header()
            self.check_requirements()
            
            print("Choose an option:\n")
            print("1. 🚀 Full Build & Deploy (Recommended)")
            print("   Creates optimized build with complete package\n")
            
            print("2. 📄 Quick Build - Single File") 
            print("   Creates one self-contained Lua file\n")
            
            print("3. 📁 Organize Files Only")
            print("   Just organizes source files, no building\n")
            
            print("4. 🔧 Advanced Options")
            print("   Build options, BizHawk install, etc.\n")
            
            print("5. 📖 View Documentation")
            print("   Setup guide and instructions\n")
            
            print("6. ❌ Exit")
            print()
            
            choice = input("Enter your choice (1-6): ").strip()
            
            if choice == '1':
                self.full_build_deploy()
            elif choice == '2':
                self.quick_build()
            elif choice == '3':
                self.organize_only()
            elif choice == '4':
                self.advanced_menu()
            elif choice == '5':
                self.view_docs()
            elif choice == '6':
                print("\nGoodbye!")
                break
            else:
                input("\n❌ Invalid choice. Press Enter to continue...")
                
    def full_build_deploy(self):
        """Run full build and deploy"""
        self.clear_screen()
        self.print_header()
        print("🚀 Full Build & Deploy\n")
        print("This will:")
        print("✓ Build optimized versions of all scripts")
        print("✓ Create organized deployment folder")
        print("✓ Include configuration tools")
        print("✓ Add BizHawk installer\n")
        
        if input("Continue? (y/n): ").lower() == 'y':
            print("\nRunning build and deploy...\n")
            self.run_script("build_and_deploy.py", ["--mode", "folder"])
            input("\nPress Enter to continue...")
            
    def quick_build(self):
        """Run quick build"""
        self.clear_screen()
        self.print_header()
        print("📄 Quick Build - Single File\n")
        print("This will create a single pokemon_crystal_tier_tool.lua")
        print("containing everything you need.\n")
        
        if input("Continue? (y/n): ").lower() == 'y':
            print("\nBuilding monolithic script...\n")
            self.run_script("quick_build.py")
            input("\nPress Enter to continue...")
            
    def organize_only(self):
        """Run organize only"""
        self.clear_screen()
        self.print_header()
        print("📁 Organize Files Only\n")
        print("This will organize source files without building.")
        print("Use this if you want to work with the source directly.\n")
        
        if input("Continue? (y/n): ").lower() == 'y':
            print("\nOrganizing files...\n")
            self.run_script("organize.py")
            input("\nPress Enter to continue...")
            
    def advanced_menu(self):
        """Show advanced options"""
        while True:
            self.clear_screen()
            self.print_header()
            print("🔧 Advanced Options\n")
            
            print("1. Build only (no deploy)")
            print("2. Deploy to BizHawk directly")
            print("3. Build + Deploy everywhere")
            print("4. Clean all build artifacts")
            print("5. Back to main menu")
            print()
            
            choice = input("Enter your choice (1-5): ").strip()
            
            if choice == '1':
                print("\nBuilding only...\n")
                self.run_script("build.py")
                input("\nPress Enter to continue...")
            elif choice == '2':
                print("\nDeploying to BizHawk...\n")
                self.run_script("build_and_deploy.py", ["--mode", "bizhawk"])
                input("\nPress Enter to continue...")
            elif choice == '3':
                print("\nBuilding and deploying everywhere...\n")
                self.run_script("build_and_deploy.py", ["--mode", "both"])
                input("\nPress Enter to continue...")
            elif choice == '4':
                self.clean_artifacts()
            elif choice == '5':
                break
                
    def clean_artifacts(self):
        """Clean build artifacts"""
        print("\nCleaning build artifacts...")
        
        dirs_to_clean = ["build", "dist", "Pokemon_Crystal_Tier_Tool"]
        for dir_name in dirs_to_clean:
            dir_path = Path(dir_name)
            if dir_path.exists():
                import shutil
                shutil.rmtree(dir_path)
                print(f"  ✓ Removed {dir_name}/")
                
        # Remove built files
        files_to_clean = ["pokemon_crystal_tier_tool.lua"]
        for file_name in files_to_clean:
            file_path = Path(file_name)
            if file_path.exists():
                file_path.unlink()
                print(f"  ✓ Removed {file_name}")
                
        input("\nClean complete. Press Enter to continue...")
        
    def view_docs(self):
        """View documentation"""
        self.clear_screen()
        self.print_header()
        print("📖 Documentation\n")
        
        # Check for documentation files
        docs = {
            "SETUP_GUIDE.md": "Complete setup guide",
            "README.md": "Quick start guide",
            "INFO.txt": "Build information"
        }
        
        available_docs = []
        for doc, desc in docs.items():
            if Path(doc).exists():
                available_docs.append((doc, desc))
                
        if not available_docs:
            print("No documentation files found.")
            print("\nQuick Start:")
            print("1. Run option 1 (Full Build & Deploy)")
            print("2. Open BizHawk")
            print("3. Load Pokemon Crystal ROM")
            print("4. Open Lua Console")
            print("5. Navigate to Pokemon_Crystal_Tier_Tool")
            print("6. Open LAUNCH.lua")
        else:
            print("Available documentation:\n")
            for i, (doc, desc) in enumerate(available_docs, 1):
                print(f"{i}. {doc} - {desc}")
                
            print(f"\n{len(available_docs)+1}. Back to menu")
            
            choice = input(f"\nView which document (1-{len(available_docs)+1})? ")
            try:
                idx = int(choice) - 1
                if 0 <= idx < len(available_docs):
                    doc_path = Path(available_docs[idx][0])
                    print(f"\n{'='*50}")
                    print(f"Contents of {doc_path.name}:")
                    print('='*50)
                    with open(doc_path, 'r') as f:
                        print(f.read())
            except:
                pass
                
        input("\nPress Enter to continue...")
        
    def run(self):
        """Run the setup menu"""
        try:
            self.show_main_menu()
        except KeyboardInterrupt:
            print("\n\nSetup cancelled.")
        except Exception as e:
            print(f"\n❌ Error: {e}")
            input("\nPress Enter to exit...")

def main():
    menu = SetupMenu()
    menu.run()

if __name__ == "__main__":
    main()