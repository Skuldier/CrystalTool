#!/usr/bin/env python3
"""
Pokemon Crystal Data Locator GUI
Uses the correct stat order: HP, Atk, Def, Speed, SpA, SpD
"""

import tkinter as tk
from tkinter import ttk, scrolledtext, filedialog, messagebox
import struct
from pathlib import Path
from typing import Tuple, Dict, List


class CrystalPokemonLocator:
    """GUI for locating Pokemon with Crystal's stat order"""
    
    # Crystal uses different stat order!
    # Standard: HP, Atk, Def, SpA, SpD, Speed
    # Crystal:  HP, Atk, Def, Speed, SpA, SpD
    
    POKEMON_DATA = {
        1: ("Bulbasaur", (45, 49, 49, 65, 65, 45), (12, 3)),      # Grass/Poison
        2: ("Ivysaur", (60, 62, 63, 80, 80, 60), (12, 3)),
        3: ("Venusaur", (80, 82, 83, 100, 100, 80), (12, 3)),
        4: ("Charmander", (39, 52, 43, 60, 50, 65), (10, 10)),    # Fire
        5: ("Charmeleon", (58, 64, 58, 80, 65, 80), (10, 10)),
        6: ("Charizard", (78, 84, 78, 109, 85, 100), (10, 2)),    # Fire/Flying
        7: ("Squirtle", (44, 48, 65, 50, 64, 43), (11, 11)),      # Water
        8: ("Wartortle", (59, 63, 80, 65, 80, 58), (11, 11)),
        9: ("Blastoise", (79, 83, 100, 85, 105, 78), (11, 11)),
        25: ("Pikachu", (35, 55, 40, 50, 50, 90), (13, 13)),      # Electric
        150: ("Mewtwo", (106, 110, 90, 154, 90, 130), (14, 14)),  # Psychic
        151: ("Mew", (100, 100, 100, 100, 100, 100), (14, 14)),
        152: ("Chikorita", (45, 49, 65, 49, 65, 45), (12, 12)),   # Grass
        155: ("Cyndaquil", (39, 52, 43, 60, 50, 65), (10, 10)),   # Fire
        158: ("Totodile", (50, 65, 64, 44, 48, 43), (11, 11)),    # Water
        249: ("Lugia", (106, 90, 130, 90, 154, 110), (14, 2)),    # Psychic/Flying
        250: ("Ho-oh", (106, 130, 90, 110, 154, 90), (10, 2)),    # Fire/Flying
        251: ("Celebi", (100, 100, 100, 100, 100, 100), (14, 12)), # Psychic/Grass
    }
    
    def __init__(self, root):
        self.root = root
        self.root.title("🎯 Pokemon Crystal Data Locator - Correct Stat Order")
        self.root.geometry("1200x700")
        
        self.vanilla_path = None
        self.vanilla_data = None
        self.patched_path = None
        self.patched_data = None
        
        self.create_widgets()
        
    def create_widgets(self):
        """Create GUI widgets"""
        # Main frame
        main_frame = ttk.Frame(self.root, padding="10")
        main_frame.pack(fill=tk.BOTH, expand=True)
        
        # Info banner
        info_label = ttk.Label(main_frame, 
                              text="Crystal ROM uses different stat order: HP, Atk, Def, Speed, SpA, SpD (not HP, Atk, Def, SpA, SpD, Speed)",
                              font=("Arial", 11, "bold"), foreground="red")
        info_label.pack(pady=(0, 10))
        
        # File selection
        file_frame = ttk.LabelFrame(main_frame, text="ROM Files", padding="10")
        file_frame.pack(fill=tk.X, pady=(0, 10))
        
        ttk.Button(file_frame, text="Load Vanilla ROM", 
                  command=lambda: self.load_rom('vanilla')).pack(side=tk.LEFT, padx=5)
        self.vanilla_label = ttk.Label(file_frame, text="No vanilla ROM loaded")
        self.vanilla_label.pack(side=tk.LEFT, padx=10)
        
        ttk.Button(file_frame, text="Load Patched ROM", 
                  command=lambda: self.load_rom('patched')).pack(side=tk.LEFT, padx=20)
        self.patched_label = ttk.Label(file_frame, text="No patched ROM loaded")
        self.patched_label.pack(side=tk.LEFT, padx=10)
        
        # Control buttons
        control_frame = ttk.Frame(main_frame)
        control_frame.pack(fill=tk.X, pady=10)
        
        ttk.Button(control_frame, text="🔍 Find All Pokemon", 
                  command=self.find_all_pokemon, style="Accent.TButton").pack(side=tk.LEFT, padx=5)
        ttk.Button(control_frame, text="📍 Locate Data Block", 
                  command=self.locate_data_block).pack(side=tk.LEFT, padx=5)
        ttk.Button(control_frame, text="🔄 Convert Stats", 
                  command=self.show_stat_converter).pack(side=tk.LEFT, padx=5)
        ttk.Button(control_frame, text="💾 Export Findings", 
                  command=self.export_findings).pack(side=tk.LEFT, padx=5)
        ttk.Button(control_frame, text="🗑️ Clear", 
                  command=lambda: self.results_text.delete(1.0, tk.END)).pack(side=tk.LEFT, padx=5)
        
        # Results area
        self.results_text = scrolledtext.ScrolledText(main_frame, wrap=tk.WORD, 
                                                     font=("Consolas", 10), height=25)
        self.results_text.pack(fill=tk.BOTH, expand=True)
        
    def load_rom(self, rom_type):
        """Load ROM file"""
        filename = filedialog.askopenfilename(
            title=f"Select {rom_type} ROM",
            filetypes=[("Game Boy ROMs", "*.gbc *.gb"), ("All files", "*.*")]
        )
        
        if filename:
            path = Path(filename)
            data = path.read_bytes()
            
            if rom_type == 'vanilla':
                self.vanilla_path = path
                self.vanilla_data = data
                self.vanilla_label.config(text=path.name)
            else:
                self.patched_path = path
                self.patched_data = data
                self.patched_label.config(text=path.name)
                
            self.log(f"Loaded {rom_type} ROM: {path.name}")
            
    def convert_to_crystal_order(self, hp, atk, def_, spa, spd, spe):
        """Convert standard stat order to Crystal order"""
        # Standard: HP, Atk, Def, SpA, SpD, Speed
        # Crystal:  HP, Atk, Def, Speed, SpA, SpD
        return (hp, atk, def_, spe, spa, spd)
        
    def find_all_pokemon(self):
        """Find all known Pokemon with correct stat order"""
        if not self.vanilla_data or not self.patched_data:
            messagebox.showerror("Error", "Please load both ROMs first")
            return
            
        self.log("\n🔍 SEARCHING FOR POKEMON WITH CORRECT STAT ORDER")
        self.log("="*70)
        self.log("Using Crystal stat order: HP, Atk, Def, Speed, SpA, SpD\n")
        
        found_vanilla = {}
        found_patched = {}
        
        for dex_num, (name, stats, types) in self.POKEMON_DATA.items():
            hp, atk, def_, spa, spd, spe = stats
            
            # Convert to Crystal order
            crystal_stats = self.convert_to_crystal_order(hp, atk, def_, spa, spd, spe)
            pattern = struct.pack('BBBBBB', *crystal_stats)
            
            self.log(f"\n#{dex_num} {name}:")
            self.log(f"  Standard order: {stats}")
            self.log(f"  Crystal order:  {crystal_stats}")
            
            # Search vanilla
            v_positions = self.find_pattern(self.vanilla_data, pattern)
            if v_positions:
                found_vanilla[dex_num] = v_positions
                self.log(f"  ✓ Vanilla: {[hex(p) for p in v_positions]}")
            else:
                self.log(f"  ✗ Vanilla: Not found")
                
            # Search patched
            p_positions = self.find_pattern(self.patched_data, pattern)
            if p_positions:
                found_patched[dex_num] = p_positions
                self.log(f"  ✓ Patched: {[hex(p) for p in p_positions]}")
            else:
                self.log(f"  ✗ Patched: Not found")
                
            # Show relocation if found in both
            if v_positions and p_positions:
                relocation = p_positions[0] - v_positions[0]
                self.log(f"  → Relocation: {relocation:+d} bytes")
                
        # Summary
        self.log("\n\n📊 SUMMARY")
        self.log("="*70)
        self.log(f"Found in vanilla: {len(found_vanilla)} Pokemon")
        self.log(f"Found in patched: {len(found_patched)} Pokemon")
        
        # Calculate consistent relocation
        if found_vanilla and found_patched:
            relocations = []
            for dex_num in found_vanilla:
                if dex_num in found_patched:
                    rel = found_patched[dex_num][0] - found_vanilla[dex_num][0]
                    relocations.append(rel)
                    
            if relocations and all(r == relocations[0] for r in relocations):
                self.log(f"\n✓ Consistent relocation: {relocations[0]:+d} bytes")
            else:
                self.log(f"\n⚠ Inconsistent relocations: {set(relocations)}")
                
    def locate_data_block(self):
        """Locate the Pokemon data block"""
        if not self.vanilla_data:
            messagebox.showerror("Error", "Please load vanilla ROM first")
            return
            
        self.log("\n\n📍 LOCATING POKEMON DATA BLOCK")
        self.log("="*70)
        
        # Search for Bulbasaur with correct stat order
        bulba_stats = self.convert_to_crystal_order(45, 49, 49, 65, 65, 45)
        bulba_pattern = struct.pack('BBBBBB', *bulba_stats)
        
        self.log(f"\nSearching for Bulbasaur pattern: {bulba_stats}")
        
        positions = self.find_pattern(self.vanilla_data, bulba_pattern)
        
        if positions:
            self.log(f"\n✓ Found Bulbasaur at: {[hex(p) for p in positions]}")
            
            # Use first position
            bulba_offset = positions[0]
            
            # Verify it's the data block by checking subsequent Pokemon
            self.log("\nVerifying data block by checking subsequent Pokemon:")
            
            verified = True
            for i in range(1, 10):  # Check Pokemon 2-10
                offset = bulba_offset + (i * 32)
                if offset + 6 > len(self.vanilla_data):
                    break
                    
                stats = struct.unpack('BBBBBB', self.vanilla_data[offset:offset+6])
                total = sum(stats)
                
                self.log(f"  Pokemon #{i+1} @{hex(offset)}: {stats} (Total: {total})")
                
                # Check if it looks like valid Pokemon stats
                if not (180 <= total <= 720):
                    verified = False
                    self.log(f"    ⚠ Unusual stat total!")
                    
                # Check against known Pokemon
                for dex_num, (name, known_stats, _) in self.POKEMON_DATA.items():
                    if dex_num == i + 1:
                        crystal_stats = self.convert_to_crystal_order(*known_stats)
                        if stats == crystal_stats:
                            self.log(f"    ✓ Matches {name}")
                            
            if verified:
                self.log(f"\n✅ DATA BLOCK CONFIRMED AT: {hex(bulba_offset)}")
                
                # Show offset to Mew
                mew_offset = bulba_offset + (150 * 32)  # Mew is #151
                self.log(f"\nCalculated Mew location: {hex(mew_offset)}")
                
                # Check if it matches known Mew location
                if mew_offset == 0x526e5:
                    self.log("✓ Matches known Mew location!")
                else:
                    self.log(f"⚠ Does not match known Mew location (0x526e5)")
                    
        else:
            self.log("\n✗ Bulbasaur not found!")
            self.log("\nTrying alternative search methods...")
            
            # Try searching near known Mew location
            mew_offset = 0x526e5
            potential_bulba = mew_offset - (150 * 32)
            
            self.log(f"\nChecking calculated Bulbasaur position: {hex(potential_bulba)}")
            
            if potential_bulba >= 0 and potential_bulba + 6 <= len(self.vanilla_data):
                stats = struct.unpack('BBBBBB', self.vanilla_data[potential_bulba:potential_bulba+6])
                self.log(f"Stats at that position: {stats}")
                self.log(f"Total: {sum(stats)}")
                
    def find_pattern(self, data: bytes, pattern: bytes) -> List[int]:
        """Find all occurrences of pattern in data"""
        positions = []
        start = 0
        
        while start < len(data):
            pos = data.find(pattern, start)
            if pos == -1:
                break
            positions.append(pos)
            start = pos + 1
            
        return positions
        
    def show_stat_converter(self):
        """Show stat order converter window"""
        converter = tk.Toplevel(self.root)
        converter.title("Stat Order Converter")
        converter.geometry("400x300")
        
        ttk.Label(converter, text="Convert between stat orders", 
                 font=("Arial", 12, "bold")).pack(pady=10)
        
        # Input frame
        input_frame = ttk.LabelFrame(converter, text="Standard Order Input", padding="10")
        input_frame.pack(fill=tk.X, padx=10, pady=5)
        
        labels = ["HP:", "Attack:", "Defense:", "Sp.Atk:", "Sp.Def:", "Speed:"]
        entries = []
        
        for i, label in enumerate(labels):
            ttk.Label(input_frame, text=label).grid(row=i//3, column=(i%3)*2, sticky=tk.E, padx=5, pady=2)
            entry = ttk.Entry(input_frame, width=8)
            entry.grid(row=i//3, column=(i%3)*2+1, padx=5, pady=2)
            entries.append(entry)
            
        # Result frame
        result_frame = ttk.LabelFrame(converter, text="Crystal Order Output", padding="10")
        result_frame.pack(fill=tk.X, padx=10, pady=5)
        
        result_label = ttk.Label(result_frame, text="", font=("Consolas", 11))
        result_label.pack()
        
        def convert():
            try:
                values = [int(e.get()) for e in entries]
                hp, atk, def_, spa, spd, spe = values
                crystal = self.convert_to_crystal_order(hp, atk, def_, spa, spd, spe)
                
                result_label.config(text=f"Standard: {values}\nCrystal:  {crystal}")
                
                # Also show hex
                hex_str = ' '.join(f"{v:02X}" for v in crystal)
                result_label.config(text=result_label.cget("text") + f"\nHex: {hex_str}")
                
            except ValueError:
                messagebox.showerror("Error", "Please enter valid numbers")
                
        ttk.Button(converter, text="Convert", command=convert).pack(pady=10)
        
    def export_findings(self):
        """Export findings to file"""
        if not self.results_text.get(1.0, tk.END).strip():
            messagebox.showwarning("Warning", "No results to export")
            return
            
        filename = filedialog.asksaveasfilename(
            defaultextension=".txt",
            filetypes=[("Text files", "*.txt"), ("All files", "*.*")]
        )
        
        if filename:
            with open(filename, 'w') as f:
                f.write(self.results_text.get(1.0, tk.END))
            self.log(f"\n✓ Exported to: {filename}")
            
    def log(self, message):
        """Add message to results"""
        self.results_text.insert(tk.END, message + "\n")
        self.results_text.see(tk.END)
        self.root.update()


def main():
    root = tk.Tk()
    app = CrystalPokemonLocator(root)
    root.mainloop()


if __name__ == "__main__":
    main()