#!/usr/bin/env python3
"""
Pokemon Crystal Move Data Locator GUI - UPDATED VERSION
Now with correct addresses and type detection!
"""

import tkinter as tk
from tkinter import ttk, scrolledtext, filedialog, messagebox
import struct
from pathlib import Path
from typing import Tuple, Dict, List, Optional


class CrystalMoveLocator:
    """GUI for locating move data in Crystal ROMs"""
    
    # Pokemon Crystal move data structure (7 bytes per move):
    # Byte 0: Animation ID
    # Byte 1: Effect ID
    # Byte 2: Power
    # Byte 3: Type
    # Byte 4: Accuracy (value/255 * 100%)
    # Byte 5: PP
    # Byte 6: Effect chance (value/255 * 100%)
    
    # Type IDs in Crystal (from disassembly)
    TYPES = {
        0x00: "Normal",   0x01: "Fighting", 0x02: "Flying",   0x03: "Poison",
        0x04: "Ground",   0x05: "Rock",     0x06: "Bug",      0x07: "Ghost", 
        0x08: "Steel",    0x09: "???",      0x0A: "???_A",    0x0B: "???_B",
        0x0C: "???_C",    0x0D: "???_D",    0x0E: "???_E",    0x0F: "???_F",
        0x10: "???_10",   0x11: "???_11",   0x12: "???_12",   0x13: "???_13",
        0x14: "Fire",     0x15: "Water",    0x16: "Grass",    0x17: "Electric",
        0x18: "Psychic",  0x19: "Ice",      0x1A: "Dragon",   0x1B: "Dark"
    }
    
    # Known working moves (confirmed found)
    KNOWN_MOVES = {
        1: ("Pound", (0x01, 0x00, 40, 0x00, 255, 35, 0)),
        10: ("Scratch", (0x0A, 0x00, 40, 0x00, 255, 35, 0)),
        33: ("Tackle", (0x21, 0x00, 35, 0x00, 242, 35, 0)),    # 95% = 242/255
    }
    
    # Moves to find (with unknown types)
    MOVES_TO_FIND = {
        # These need their types determined
        "Ember": {"id": 52, "pattern": [0x34, 0x04, 40, None, 255, 25, 25]},
        "Water Gun": {"id": 55, "pattern": [0x37, 0x00, 40, None, 255, 25, 0]},
        "Thunder Shock": {"id": 84, "pattern": [0x54, 0x06, 40, None, 255, 30, 25]},
        "Thunderbolt": {"id": 85, "pattern": [0x55, 0x06, 95, None, 255, 15, 25]},
        "Thunder Wave": {"id": 86, "pattern": [0x56, 0x43, 0, None, 255, 20, 0]},
        "Earthquake": {"id": 89, "pattern": [0x59, 0x00, 100, None, 255, 10, 0]},
        "Psychic": {"id": 94, "pattern": [0x5E, 0x48, 90, None, 255, 10, 25]},
        "Fire Blast": {"id": 126, "pattern": [0x7E, 0x04, 120, None, 216, 5, 25]}, # 85% acc
        "Surf": {"id": 57, "pattern": [0x39, 0x00, 95, None, 255, 15, 0]},
        "Ice Beam": {"id": 58, "pattern": [0x3A, 0x05, 95, None, 255, 10, 25]},
        "Blizzard": {"id": 59, "pattern": [0x3B, 0x05, 120, None, 178, 5, 25]},  # 70% acc
    }
    
    def __init__(self, root):
        self.root = root
        self.root.title("🎯 Pokemon Crystal Move Data Locator v2.0")
        self.root.geometry("1400x800")
        
        self.vanilla_path = None
        self.vanilla_data = None
        self.patched_path = None
        self.patched_data = None
        
        # Store found addresses - UPDATED!
        self.move_data_address_vanilla = 0x41AFB  # Found address
        self.move_data_address_patched = 0x41B23  # Found address (+40 bytes)
        self.relocation_offset = 40  # Positive 40 bytes
        
        # Store discovered move data
        self.discovered_moves = {}
        
        self.create_widgets()
        
    def create_widgets(self):
        """Create GUI widgets"""
        # Main frame
        main_frame = ttk.Frame(self.root, padding="10")
        main_frame.pack(fill=tk.BOTH, expand=True)
        
        # Info banner
        info_label = ttk.Label(main_frame, 
                              text="Crystal Move Structure: Animation, Effect, Power, Type, Accuracy/255, PP, Effect%/255",
                              font=("Arial", 11, "bold"), foreground="blue")
        info_label.pack(pady=(0, 5))
        
        # Additional info - UPDATED!
        self.info2_label = ttk.Label(main_frame,
                               text="✓ Move data found at 0x41AFB (vanilla) → 0x41B23 (patched) | Relocation: +40 bytes",
                               font=("Arial", 10), foreground="darkgreen")
        self.info2_label.pack(pady=(0, 10))
        
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
        
        # Control buttons - First row
        control_frame = ttk.Frame(main_frame)
        control_frame.pack(fill=tk.X, pady=5)
        
        ttk.Button(control_frame, text="🔍 Find Known Moves", 
                  command=self.find_known_moves, style="Accent.TButton").pack(side=tk.LEFT, padx=5)
        ttk.Button(control_frame, text="🎯 Auto-Detect Types", 
                  command=self.auto_detect_types, style="Accent.TButton").pack(side=tk.LEFT, padx=5)
        ttk.Button(control_frame, text="📊 Verify All Moves", 
                  command=self.verify_all_moves).pack(side=tk.LEFT, padx=5)
        ttk.Button(control_frame, text="🔬 Analyze Move Table", 
                  command=self.analyze_move_table).pack(side=tk.LEFT, padx=5)
        ttk.Button(control_frame, text="📐 Calculate Any Move", 
                  command=self.calculate_move_offset).pack(side=tk.LEFT, padx=5)
        
        # Control buttons - Second row
        control_frame2 = ttk.Frame(main_frame)
        control_frame2.pack(fill=tk.X, pady=5)
        
        ttk.Button(control_frame2, text="🔎 Find Move by Pattern", 
                  command=self.find_move_by_pattern).pack(side=tk.LEFT, padx=5)
        ttk.Button(control_frame2, text="📝 List All 251 Moves", 
                  command=self.list_all_moves).pack(side=tk.LEFT, padx=5)
        ttk.Button(control_frame2, text="💾 Export Move Data", 
                  command=self.export_move_data).pack(side=tk.LEFT, padx=5)
        ttk.Button(control_frame2, text="🗑️ Clear", 
                  command=lambda: self.results_text.delete(1.0, tk.END)).pack(side=tk.LEFT, padx=5)
        
        # Results area
        self.results_text = scrolledtext.ScrolledText(main_frame, wrap=tk.WORD, 
                                                     font=("Consolas", 10), height=30)
        self.results_text.pack(fill=tk.BOTH, expand=True)
        
        # Status bar
        self.status_label = ttk.Label(main_frame, text="Ready", relief=tk.SUNKEN)
        self.status_label.pack(fill=tk.X, pady=(5, 0))
        
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
            self.status_label.config(text=f"Loaded {rom_type} ROM")
            
    def find_known_moves(self):
        """Find the known working moves"""
        if not self.vanilla_data:
            messagebox.showerror("Error", "Please load vanilla ROM first")
            return
            
        self.log("\n🔍 FINDING KNOWN MOVES")
        self.log("="*70)
        self.log(f"Using confirmed addresses: Vanilla=0x{self.move_data_address_vanilla:06X}, " +
                f"Patched=0x{self.move_data_address_patched:06X}")
        self.log(f"Relocation offset: +{self.relocation_offset} bytes\n")
        
        # Verify known moves are at expected locations
        for move_id, (name, pattern) in self.KNOWN_MOVES.items():
            expected_offset = self.move_data_address_vanilla + ((move_id - 1) * 7)
            
            if expected_offset + 7 <= len(self.vanilla_data):
                actual_data = self.vanilla_data[expected_offset:expected_offset+7]
                expected_data = struct.pack('BBBBBBB', *pattern)
                
                self.log(f"Move #{move_id:03d} ({name}) @ 0x{expected_offset:06X}:")
                self.log(f"  Expected: {' '.join(f'{b:02X}' for b in expected_data)}")
                self.log(f"  Actual:   {' '.join(f'{b:02X}' for b in actual_data)}")
                
                if actual_data == expected_data:
                    self.log(f"  ✓ MATCH!")
                else:
                    self.log(f"  ✗ Mismatch")
                    
            # Check patched ROM
            if self.patched_data:
                patched_offset = self.move_data_address_patched + ((move_id - 1) * 7)
                if patched_offset + 7 <= len(self.patched_data):
                    patched_data = self.patched_data[patched_offset:patched_offset+7]
                    self.log(f"  Patched:  {' '.join(f'{b:02X}' for b in patched_data)}")
                    
                    if patched_data == expected_data:
                        self.log(f"  ✓ Patched ROM matches too!")
                        
    def auto_detect_types(self):
        """Auto-detect type IDs for moves that weren't found"""
        if not self.vanilla_data:
            messagebox.showerror("Error", "Please load vanilla ROM first")
            return
            
        self.log("\n🎯 AUTO-DETECTING TYPE IDS")
        self.log("="*70)
        self.log("Searching for moves with unknown type values...\n")
        
        self.discovered_moves.clear()
        
        for move_name, move_info in self.MOVES_TO_FIND.items():
            move_id = move_info["id"]
            pattern = move_info["pattern"].copy()
            
            self.log(f"\nSearching for {move_name} (Move #{move_id}):")
            self.log(f"  Pattern: {pattern} (None = unknown type)")
            
            # Calculate where this move should be
            expected_offset = self.move_data_address_vanilla + ((move_id - 1) * 7)
            
            if expected_offset + 7 <= len(self.vanilla_data):
                actual_data = list(self.vanilla_data[expected_offset:expected_offset+7])
                self.log(f"  Data at expected offset 0x{expected_offset:06X}: {actual_data}")
                
                # Check if everything except type matches
                matches = True
                for i, expected in enumerate(pattern):
                    if expected is not None and actual_data[i] != expected:
                        matches = False
                        break
                        
                if matches:
                    # Found it! The type is at position 3
                    found_type = actual_data[3]
                    self.log(f"  ✓ FOUND! Type ID is 0x{found_type:02X}")
                    
                    # Update our knowledge
                    complete_pattern = pattern.copy()
                    complete_pattern[3] = found_type
                    self.discovered_moves[move_id] = {
                        "name": move_name,
                        "pattern": complete_pattern,
                        "type_id": found_type
                    }
                    
                    # Guess what type this might be
                    type_guess = self._guess_type(move_name, found_type)
                    self.log(f"  Type guess: {type_guess}")
                else:
                    self.log(f"  ✗ Pattern doesn't match at expected location")
                    
                    # Try searching for partial pattern
                    self.log(f"  Searching entire ROM for partial pattern...")
                    found_locations = self._search_partial_pattern(pattern)
                    
                    if found_locations:
                        self.log(f"  Found {len(found_locations)} potential matches:")
                        for loc, data, type_id in found_locations[:3]:
                            self.log(f"    0x{loc:06X}: {data} (type=0x{type_id:02X})")
                            
        # Summary
        self.log("\n\n📊 DISCOVERY SUMMARY")
        self.log("="*70)
        
        if self.discovered_moves:
            self.log(f"Successfully identified {len(self.discovered_moves)} moves:\n")
            
            # Group by type
            types_found = {}
            for move_data in self.discovered_moves.values():
                type_id = move_data["type_id"]
                if type_id not in types_found:
                    types_found[type_id] = []
                types_found[type_id].append(move_data["name"])
                
            for type_id, moves in sorted(types_found.items()):
                self.log(f"Type 0x{type_id:02X}: {', '.join(moves)}")
                
            # Update type mapping
            self._update_type_mapping()
        else:
            self.log("No moves discovered. Check if ROM is loaded correctly.")
            
    def _guess_type(self, move_name: str, type_id: int) -> str:
        """Guess the type based on move name and ID"""
        move_lower = move_name.lower()
        
        # Name-based guesses
        if "ember" in move_lower or "fire" in move_lower or "flame" in move_lower:
            return f"Fire (0x{type_id:02X})"
        elif "water" in move_lower or "surf" in move_lower or "hydro" in move_lower:
            return f"Water (0x{type_id:02X})"
        elif "thunder" in move_lower or "electric" in move_lower or "shock" in move_lower:
            return f"Electric (0x{type_id:02X})"
        elif "psychic" in move_lower or "psych" in move_lower:
            return f"Psychic (0x{type_id:02X})"
        elif "earthquake" in move_lower or "ground" in move_lower:
            return f"Ground (0x{type_id:02X})"
        elif "ice" in move_lower or "blizzard" in move_lower or "freeze" in move_lower:
            return f"Ice (0x{type_id:02X})"
            
        return f"Unknown (0x{type_id:02X})"
        
    def _search_partial_pattern(self, pattern: List[Optional[int]]) -> List[Tuple[int, List[int], int]]:
        """Search for partial pattern in ROM"""
        results = []
        
        # Only search near the expected move data area
        start = self.move_data_address_vanilla - 1000
        end = self.move_data_address_vanilla + 2000
        
        for offset in range(max(0, start), min(len(self.vanilla_data) - 7, end)):
            data = list(self.vanilla_data[offset:offset+7])
            
            # Check if non-None values match
            matches = True
            for i, expected in enumerate(pattern):
                if expected is not None and data[i] != expected:
                    matches = False
                    break
                    
            if matches:
                # Found a match, record the type (position 3)
                results.append((offset, data, data[3]))
                
        return results
        
    def _update_type_mapping(self):
        """Update type mapping based on discoveries"""
        if not self.discovered_moves:
            return
            
        self.log("\n\n🗺️ UPDATED TYPE MAPPING")
        self.log("="*70)
        
        # Collect all discovered types
        type_updates = {}
        
        for move_data in self.discovered_moves.values():
            move_name = move_data["name"]
            type_id = move_data["type_id"]
            
            # Determine type name
            if "ember" in move_name.lower() or "fire" in move_name.lower():
                type_updates[type_id] = "Fire"
            elif "water" in move_name.lower() or "surf" in move_name.lower():
                type_updates[type_id] = "Water"
            elif "thunder" in move_name.lower() or "electric" in move_name.lower():
                type_updates[type_id] = "Electric"
            elif "earthquake" in move_name.lower():
                type_updates[type_id] = "Ground"
            elif "psychic" in move_name.lower():
                type_updates[type_id] = "Psychic"
            elif "ice" in move_name.lower() or "blizzard" in move_name.lower():
                type_updates[type_id] = "Ice"
                
        # Update TYPES dictionary
        for type_id, type_name in type_updates.items():
            old_name = self.TYPES.get(type_id, f"Unknown_0x{type_id:02X}")
            self.TYPES[type_id] = type_name
            self.log(f"Type 0x{type_id:02X}: {old_name} → {type_name}")
            
    def verify_all_moves(self):
        """Verify all moves at the found addresses"""
        if not self.vanilla_data:
            messagebox.showerror("Error", "Please load vanilla ROM first")
            return
            
        self.log("\n📊 VERIFYING ALL 251 MOVES")
        self.log("="*70)
        self.log(f"Base address: 0x{self.move_data_address_vanilla:06X}\n")
        
        # Check first 20 moves in detail
        self.log("First 20 moves:")
        self.log("-"*70)
        
        for move_id in range(1, 21):
            offset = self.move_data_address_vanilla + ((move_id - 1) * 7)
            
            if offset + 7 <= len(self.vanilla_data):
                data = struct.unpack('BBBBBBB', self.vanilla_data[offset:offset+7])
                
                # Format move data
                acc_percent = int((data[4] / 255) * 100) if data[4] > 0 else 0
                eff_percent = int((data[6] / 255) * 100) if data[6] > 0 else 0
                
                self.log(f"Move #{move_id:03d} @ 0x{offset:06X}: {' '.join(f'{b:02X}' for b in data)}")
                self.log(f"  Power={data[2]:3d}, Type=0x{data[3]:02X}, Acc={acc_percent:3d}%, " +
                        f"PP={data[5]:2d}, Effect%={eff_percent:3d}%")
                
                # Check validity
                issues = []
                if data[5] == 0 or data[5] > 40:
                    issues.append(f"Invalid PP ({data[5]})")
                if data[3] > 0x1B:  # Max type ID
                    issues.append(f"Invalid type (0x{data[3]:02X})")
                    
                if issues:
                    self.log(f"  ⚠️ Issues: {', '.join(issues)}")
                    
                # Check if it matches any known move
                for known_id, (name, pattern) in self.KNOWN_MOVES.items():
                    if known_id == move_id and data == pattern:
                        self.log(f"  ✓ Confirmed as {name}")
                        
                # Check discovered moves
                if move_id in self.discovered_moves:
                    name = self.discovered_moves[move_id]["name"]
                    self.log(f"  ✓ Identified as {name}")
                    
        # Summary statistics
        self.log("\n\nMOVE DATA STATISTICS:")
        self.log("-"*50)
        
        # Count valid moves
        valid_count = 0
        type_counts = {}
        pp_distribution = {}
        
        for move_id in range(1, 252):  # 251 moves
            offset = self.move_data_address_vanilla + ((move_id - 1) * 7)
            
            if offset + 7 <= len(self.vanilla_data):
                data = struct.unpack('BBBBBBB', self.vanilla_data[offset:offset+7])
                
                # Check validity
                if 0 < data[5] <= 40 and data[3] <= 0x1B:
                    valid_count += 1
                    
                    # Count types
                    type_counts[data[3]] = type_counts.get(data[3], 0) + 1
                    
                    # Count PP
                    pp_distribution[data[5]] = pp_distribution.get(data[5], 0) + 1
                    
        self.log(f"\nValid moves: {valid_count}/251")
        
        self.log("\nType distribution:")
        for type_id, count in sorted(type_counts.items()):
            type_name = self.TYPES.get(type_id, f"Unknown_0x{type_id:02X}")
            self.log(f"  {type_name}: {count} moves")
            
        self.log("\nMost common PP values:")
        for pp, count in sorted(pp_distribution.items(), key=lambda x: x[1], reverse=True)[:5]:
            self.log(f"  {pp} PP: {count} moves")
            
    def analyze_move_table(self):
        """Analyze the entire move table structure"""
        if not self.vanilla_data:
            messagebox.showerror("Error", "Please load vanilla ROM first")
            return
            
        self.log("\n🔬 ANALYZING MOVE TABLE STRUCTURE")
        self.log("="*70)
        
        base_addr = self.move_data_address_vanilla
        self.log(f"Base address: 0x{base_addr:06X}")
        self.log(f"Size: {251 * 7} bytes (251 moves × 7 bytes)\n")
        
        # Analyze each byte position across all moves
        self.log("BYTE POSITION ANALYSIS:")
        self.log("-"*50)
        
        for byte_pos in range(7):
            values = []
            
            for move_id in range(1, 252):
                offset = base_addr + ((move_id - 1) * 7) + byte_pos
                if offset < len(self.vanilla_data):
                    values.append(self.vanilla_data[offset])
                    
            if not values:
                continue
                
            # Analyze this byte position
            unique = len(set(values))
            min_val = min(values)
            max_val = max(values)
            avg_val = sum(values) / len(values)
            
            self.log(f"\nByte {byte_pos} analysis:")
            self.log(f"  Range: {min_val}-{max_val} (0x{min_val:02X}-0x{max_val:02X})")
            self.log(f"  Unique values: {unique}")
            self.log(f"  Average: {avg_val:.1f}")
            
            # Specific interpretations
            if byte_pos == 0:
                self.log(f"  Interpretation: Animation ID")
            elif byte_pos == 1:
                self.log(f"  Interpretation: Effect ID")
                # Count effect types
                effect_counts = {}
                for v in values:
                    effect_counts[v] = effect_counts.get(v, 0) + 1
                common_effects = sorted(effect_counts.items(), key=lambda x: x[1], reverse=True)[:5]
                self.log(f"  Most common effects: {common_effects}")
            elif byte_pos == 2:
                self.log(f"  Interpretation: Power")
                self.log(f"  Non-damaging moves (power=0): {values.count(0)}")
            elif byte_pos == 3:
                self.log(f"  Interpretation: Type")
                # Show type distribution
                type_counts = {}
                for v in values:
                    type_counts[v] = type_counts.get(v, 0) + 1
                self.log(f"  Type distribution: {len(type_counts)} different types")
            elif byte_pos == 4:
                self.log(f"  Interpretation: Accuracy (/255)")
                self.log(f"  100% accurate (255): {values.count(255)} moves")
                self.log(f"  Never miss (0): {values.count(0)} moves")
            elif byte_pos == 5:
                self.log(f"  Interpretation: PP")
                # PP distribution
                pp_counts = {}
                for v in values:
                    if v > 0:
                        pp_counts[v] = pp_counts.get(v, 0) + 1
                common_pp = sorted(pp_counts.items(), key=lambda x: x[1], reverse=True)[:5]
                self.log(f"  Most common PP values: {common_pp}")
            elif byte_pos == 6:
                self.log(f"  Interpretation: Effect chance (/255)")
                self.log(f"  No effect (0): {values.count(0)} moves")
                self.log(f"  10% chance (25): {values.count(25)} moves")
                self.log(f"  30% chance (76): {values.count(76)} moves")
                
    def calculate_move_offset(self):
        """Calculate offset for any move ID"""
        dialog = tk.Toplevel(self.root)
        dialog.title("Calculate Move Offset")
        dialog.geometry("400x300")
        
        ttk.Label(dialog, text="Enter Move ID (1-251):").pack(pady=10)
        
        move_var = tk.StringVar()
        entry = ttk.Entry(dialog, textvariable=move_var, width=10)
        entry.pack(pady=5)
        
        result_label = ttk.Label(dialog, text="", font=("Consolas", 11))
        result_label.pack(pady=20)
        
        def calculate():
            try:
                move_id = int(move_var.get())
                if 1 <= move_id <= 251:
                    vanilla_offset = self.move_data_address_vanilla + ((move_id - 1) * 7)
                    patched_offset = self.move_data_address_patched + ((move_id - 1) * 7)
                    
                    result_text = f"Move #{move_id:03d} offsets:\n"
                    result_text += f"Vanilla: 0x{vanilla_offset:06X}\n"
                    result_text += f"Patched: 0x{patched_offset:06X}\n"
                    
                    # Read actual data if ROM is loaded
                    if self.vanilla_data and vanilla_offset + 7 <= len(self.vanilla_data):
                        data = self.vanilla_data[vanilla_offset:vanilla_offset+7]
                        result_text += f"\nData: {' '.join(f'{b:02X}' for b in data)}"
                        
                    result_label.config(text=result_text)
                    
                    # Also log to main window
                    self.log(f"\n{result_text}")
                else:
                    messagebox.showerror("Error", "Move ID must be between 1 and 251")
            except ValueError:
                messagebox.showerror("Error", "Please enter a valid number")
                
        ttk.Button(dialog, text="Calculate", command=calculate).pack(pady=10)
        
    def find_move_by_pattern(self):
        """Find a move by entering its pattern"""
        dialog = tk.Toplevel(self.root)
        dialog.title("Find Move by Pattern")
        dialog.geometry("500x400")
        
        ttk.Label(dialog, text="Enter move data pattern (use ? for unknown bytes):").pack(pady=10)
        
        # Input fields
        fields_frame = ttk.Frame(dialog)
        fields_frame.pack(pady=10)
        
        labels = ["Animation:", "Effect:", "Power:", "Type:", "Accuracy:", "PP:", "Effect%:"]
        entries = []
        
        for i, label in enumerate(labels):
            ttk.Label(fields_frame, text=label).grid(row=i, column=0, sticky=tk.E, padx=5, pady=2)
            entry = ttk.Entry(fields_frame, width=10)
            entry.grid(row=i, column=1, padx=5, pady=2)
            entries.append(entry)
            
        result_text = scrolledtext.ScrolledText(dialog, wrap=tk.WORD, height=10, width=60)
        result_text.pack(pady=10, padx=10, fill=tk.BOTH, expand=True)
        
        def search():
            if not self.vanilla_data:
                messagebox.showerror("Error", "Please load vanilla ROM first")
                return
                
            pattern = []
            for entry in entries:
                val = entry.get().strip()
                if val == '?' or val == '':
                    pattern.append(None)
                else:
                    try:
                        pattern.append(int(val))
                    except ValueError:
                        messagebox.showerror("Error", f"Invalid value: {val}")
                        return
                        
            result_text.delete(1.0, tk.END)
            result_text.insert(tk.END, "Searching...\n")
            
            # Search at known move locations
            found = []
            for move_id in range(1, 252):
                offset = self.move_data_address_vanilla + ((move_id - 1) * 7)
                if offset + 7 <= len(self.vanilla_data):
                    data = list(self.vanilla_data[offset:offset+7])
                    
                    # Check if pattern matches
                    match = True
                    for i, expected in enumerate(pattern):
                        if expected is not None and data[i] != expected:
                            match = False
                            break
                            
                    if match:
                        found.append((move_id, data))
                        
            # Display results
            if found:
                result_text.insert(tk.END, f"\nFound {len(found)} matches:\n\n")
                for move_id, data in found[:20]:  # Show first 20
                    result_text.insert(tk.END, f"Move #{move_id:03d}: {data}\n")
            else:
                result_text.insert(tk.END, "\nNo matches found.\n")
                
        ttk.Button(dialog, text="Search", command=search).pack(pady=10)
        
    def list_all_moves(self):
        """List all 251 moves with their data"""
        if not self.vanilla_data:
            messagebox.showerror("Error", "Please load vanilla ROM first")
            return
            
        self.log("\n📝 LISTING ALL 251 MOVES")
        self.log("="*70)
        self.log(f"Base address: 0x{self.move_data_address_vanilla:06X}\n")
        
        # Header
        self.log("ID  | Offset   | Hex Data                    | Power Type Acc% PP  | Notes")
        self.log("-"*85)
        
        for move_id in range(1, 252):
            offset = self.move_data_address_vanilla + ((move_id - 1) * 7)
            
            if offset + 7 <= len(self.vanilla_data):
                data = struct.unpack('BBBBBBB', self.vanilla_data[offset:offset+7])
                hex_str = ' '.join(f'{b:02X}' for b in data)
                
                # Calculate percentages
                acc_percent = int((data[4] / 255) * 100) if data[4] > 0 else 0
                
                # Format type
                type_name = self.TYPES.get(data[3], f"0x{data[3]:02X}")
                if len(type_name) > 8:
                    type_name = type_name[:8]
                    
                # Notes
                notes = []
                if data[2] == 0:
                    notes.append("Status")
                if data[4] == 255:
                    notes.append("Never miss")
                if data[5] > 40:
                    notes.append("Invalid PP!")
                    
                # Check if it's a known move
                for known_id, (name, _) in self.KNOWN_MOVES.items():
                    if known_id == move_id:
                        notes.append(name)
                        
                if move_id in self.discovered_moves:
                    notes.append(self.discovered_moves[move_id]["name"])
                    
                notes_str = ", ".join(notes) if notes else ""
                
                self.log(f"{move_id:03d} | 0x{offset:06X} | {hex_str} | "
                        f"{data[2]:3d} {type_name:8s} {acc_percent:3d}% {data[5]:2d} | {notes_str}")
                
    def export_move_data(self):
        """Export move data to CSV"""
        if not self.vanilla_data:
            messagebox.showerror("Error", "Please load vanilla ROM first")
            return
            
        filename = filedialog.asksaveasfilename(
            defaultextension=".csv",
            filetypes=[("CSV files", "*.csv"), ("All files", "*.*")]
        )
        
        if not filename:
            return
            
        try:
            with open(filename, 'w') as f:
                # Header
                f.write("Move_ID,Offset_Hex,Animation,Effect,Power,Type_ID,Type_Name,")
                f.write("Accuracy_Raw,Accuracy_Percent,PP,Effect_Chance_Raw,Effect_Chance_Percent,")
                f.write("Hex_Pattern,Notes\n")
                
                # Data
                for move_id in range(1, 252):
                    offset = self.move_data_address_vanilla + ((move_id - 1) * 7)
                    
                    if offset + 7 <= len(self.vanilla_data):
                        data = struct.unpack('BBBBBBB', self.vanilla_data[offset:offset+7])
                        
                        # Calculate values
                        acc_percent = int((data[4] / 255) * 100) if data[4] > 0 else 0
                        eff_percent = int((data[6] / 255) * 100) if data[6] > 0 else 0
                        type_name = self.TYPES.get(data[3], f"Unknown_0x{data[3]:02X}")
                        hex_pattern = ' '.join(f'{b:02X}' for b in data)
                        
                        # Notes
                        notes = []
                        for known_id, (name, _) in self.KNOWN_MOVES.items():
                            if known_id == move_id:
                                notes.append(name)
                        if move_id in self.discovered_moves:
                            notes.append(self.discovered_moves[move_id]["name"])
                            
                        notes_str = "; ".join(notes)
                        
                        # Write line
                        f.write(f"{move_id},0x{offset:06X},{data[0]},{data[1]},{data[2]},")
                        f.write(f"{data[3]},{type_name},{data[4]},{acc_percent}%,{data[5]},")
                        f.write(f"{data[6]},{eff_percent}%,{hex_pattern},{notes_str}\n")
                        
            self.log(f"\n✓ Exported move data to: {filename}")
            self.status_label.config(text=f"Exported to {Path(filename).name}")
            
        except Exception as e:
            messagebox.showerror("Error", f"Failed to export: {str(e)}")
            
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
        
    def log(self, message):
        """Add message to results"""
        self.results_text.insert(tk.END, message + "\n")
        self.results_text.see(tk.END)
        self.root.update()


def main():
    root = tk.Tk()
    app = CrystalMoveLocator(root)
    root.mainloop()


if __name__ == "__main__":
    main()