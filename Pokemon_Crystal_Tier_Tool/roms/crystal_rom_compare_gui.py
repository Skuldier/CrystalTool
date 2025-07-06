#!/usr/bin/env python3
"""
Pokemon Crystal ROM Comparison Tool - Complete Standalone GUI Version
No external dependencies except Python standard library!
"""

import tkinter as tk
from tkinter import ttk, filedialog, messagebox, scrolledtext
import threading
import struct
import hashlib
import json
from pathlib import Path
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass
import time

@dataclass
class MemoryMapping:
    """Represents a memory address relocation"""
    vanilla_addr: int
    patched_addr: int
    data_type: str
    confidence: float
    evidence: List[str]

@dataclass
class CodeChange:
    """Represents a code modification in the ROM"""
    offset: int
    vanilla_bytes: bytes
    patched_bytes: bytes
    instruction_type: str
    affected_addresses: List[int]

class CrystalROMAnalyzer:
    """Analyzer engine for comparing Pokemon Crystal ROMs"""
    
    def __init__(self, vanilla_path: str, patched_path: str):
        self.vanilla_path = Path(vanilla_path)
        self.patched_path = Path(patched_path)
        self.vanilla_rom = None
        self.patched_rom = None
        self.mappings = {}
        self.code_changes = []
        
        # Known memory structures for pattern matching
        self.known_structures = {
            'party_count': {
                'vanilla_addr': 0xDCD7,
                'signature': self._party_signature,
                'size': 8,
                'description': 'Party Pokemon count'
            },
            'party_species': {
                'vanilla_addr': 0xDCD8,
                'signature': None,
                'size': 7,
                'description': 'Party species list'
            },
            'party_data': {
                'vanilla_addr': 0xDCDF,
                'signature': self._party_signature,
                'size': 48 * 6,
                'description': 'Party Pokemon data'
            },
            'player_id': {
                'vanilla_addr': 0xD47B,
                'signature': self._player_signature,
                'size': 2,
                'description': 'Player trainer ID'
            },
            'player_name': {
                'vanilla_addr': 0xD47D,
                'signature': self._player_signature,
                'size': 11,
                'description': 'Player name'
            },
            'current_box': {
                'vanilla_addr': 0xD8BC,
                'signature': None,
                'size': 1,
                'description': 'Current PC box'
            },
            'pc_boxes': {
                'vanilla_addr': 0xAD6C,
                'signature': self._box_signature,
                'size': 32 * 20 + 22,
                'description': 'PC Box data'
            },
            'pokedex_caught': {
                'vanilla_addr': 0xDE99,
                'signature': None,
                'size': 32,
                'description': 'Pokedex caught flags'
            },
            'pokedex_seen': {
                'vanilla_addr': 0xDEB9,
                'signature': None,
                'size': 32,
                'description': 'Pokedex seen flags'
            },
            'badges_johto': {
                'vanilla_addr': 0xD57C,
                'signature': None,
                'size': 1,
                'description': 'Johto badges'
            },
            'badges_kanto': {
                'vanilla_addr': 0xD57D,
                'signature': None,
                'size': 1,
                'description': 'Kanto badges'
            }
        }
        
    def load_roms(self) -> bool:
        """Load both ROM files"""
        try:
            with open(self.vanilla_path, 'rb') as f:
                self.vanilla_rom = f.read()
            with open(self.patched_path, 'rb') as f:
                self.patched_rom = f.read()
            return True
        except Exception as e:
            return False
            
    def _verify_crystal_rom(self, rom_data: bytes) -> bool:
        """Verify this is a Pokemon Crystal ROM"""
        title = rom_data[0x134:0x144].decode('ascii', errors='ignore')
        return 'CRYSTAL' in title.upper() or 'PM_CRYSTAL' in title
        
    def find_binary_differences(self) -> List[Tuple[int, int]]:
        """Find all byte ranges that differ between ROMs"""
        differences = []
        i = 0
        
        while i < min(len(self.vanilla_rom), len(self.patched_rom)):
            if self.vanilla_rom[i] != self.patched_rom[i]:
                start = i
                while i < min(len(self.vanilla_rom), len(self.patched_rom)) and \
                      self.vanilla_rom[i] != self.patched_rom[i]:
                    i += 1
                differences.append((start, i))
            else:
                i += 1
                
        return differences
        
    def analyze_code_changes(self, differences: List[Tuple[int, int]]) -> None:
        """Analyze code changes that might affect memory layout"""
        for start, end in differences:
            if end - start < 3:
                continue
                
            vanilla_bytes = self.vanilla_rom[start:end]
            patched_bytes = self.patched_rom[start:end]
            
            memory_instructions = self._find_memory_instructions(
                start, vanilla_bytes, patched_bytes
            )
            
            if memory_instructions:
                self.code_changes.extend(memory_instructions)
                
    def _find_memory_instructions(self, offset: int, vanilla: bytes, 
                                  patched: bytes) -> List[CodeChange]:
        """Find GB/GBC instructions that reference memory addresses"""
        changes = []
        
        # Common memory-related GB opcodes
        memory_opcodes = {
            0x01: ('LD BC,nn', 3),
            0x11: ('LD DE,nn', 3),
            0x21: ('LD HL,nn', 3),
            0x31: ('LD SP,nn', 3),
            0xEA: ('LD (nn),A', 3),
            0xFA: ('LD A,(nn)', 3),
            0x08: ('LD (nn),SP', 3),
            0x2A: ('LD A,(HL+)', 1),
            0x3A: ('LD A,(HL-)', 1),
            0x22: ('LD (HL+),A', 1),
            0x32: ('LD (HL-),A', 1),
        }
        
        # Scan both vanilla and patched for memory instructions
        max_len = max(len(vanilla), len(patched))
        i = 0
        
        while i < max_len:
            # Check vanilla
            if i < len(vanilla) - 2:
                v_opcode = vanilla[i]
                if v_opcode in memory_opcodes:
                    mnemonic, size = memory_opcodes[v_opcode]
                    if size >= 3 and i + 2 < len(vanilla):
                        v_addr = struct.unpack('<H', vanilla[i+1:i+3])[0]
                        
                        # Check if patched has different address
                        if i < len(patched) - 2:
                            p_opcode = patched[i]
                            if p_opcode == v_opcode:
                                p_addr = struct.unpack('<H', patched[i+1:i+3])[0]
                                
                                if v_addr != p_addr and ((0xC000 <= v_addr <= 0xDFFF) or 
                                                         (0xC000 <= p_addr <= 0xDFFF)):
                                    changes.append(CodeChange(
                                        offset=offset + i,
                                        vanilla_bytes=vanilla[i:i+size],
                                        patched_bytes=patched[i:i+size],
                                        instruction_type=mnemonic,
                                        affected_addresses=[v_addr, p_addr]
                                    ))
            
            # Check patched for new memory instructions
            if i < len(patched) - 2:
                p_opcode = patched[i]
                if p_opcode in memory_opcodes:
                    mnemonic, size = memory_opcodes[p_opcode]
                    if size >= 3 and i + 2 < len(patched):
                        p_addr = struct.unpack('<H', patched[i+1:i+3])[0]
                        
                        # If vanilla doesn't have this instruction or has different opcode
                        if i >= len(vanilla) or (i < len(vanilla) and vanilla[i] != p_opcode):
                            if 0xC000 <= p_addr <= 0xDFFF:
                                v_addr = 0
                                if i < len(vanilla) - 2 and vanilla[i] in memory_opcodes:
                                    # Get vanilla address if it's also a memory instruction
                                    v_addr = struct.unpack('<H', vanilla[i+1:i+3])[0]
                                
                                changes.append(CodeChange(
                                    offset=offset + i,
                                    vanilla_bytes=vanilla[i:i+size] if i < len(vanilla) else b'',
                                    patched_bytes=patched[i:i+size],
                                    instruction_type=mnemonic,
                                    affected_addresses=[v_addr, p_addr] if v_addr else [p_addr]
                                ))
            
            i += 1
                
        return changes
        
    def find_data_structure_relocations(self) -> None:
        """Find relocated data structures using pattern matching"""
        # First pass: Check direct code references
        for name, info in self.known_structures.items():
            vanilla_addr = info['vanilla_addr']
            
            # Check in code changes first
            for change in self.code_changes:
                if vanilla_addr in change.affected_addresses:
                    idx = change.affected_addresses.index(vanilla_addr)
                    if idx < len(change.affected_addresses) - 1:
                        patched_addr = change.affected_addresses[idx + 1]
                    else:
                        patched_addr = change.affected_addresses[0]
                        
                    if patched_addr != vanilla_addr and 0xC000 <= patched_addr <= 0xDFFF:
                        self.mappings[name] = MemoryMapping(
                            vanilla_addr=vanilla_addr,
                            patched_addr=patched_addr,
                            data_type=name,
                            confidence=0.95,
                            evidence=[f"Found in {change.instruction_type} at 0x{change.offset:04X}"]
                        )
                        break
        
        # Second pass: Check common offsets
        common_offsets = [0x20, 0x40, 0x80, 0x100, -0x20, -0x40, -0x80, -0x100]
        
        for name, info in self.known_structures.items():
            if name in self.mappings:
                continue  # Already found
                
            vanilla_addr = info['vanilla_addr']
            
            for offset in common_offsets:
                test_addr = vanilla_addr + offset
                
                # Check if this address appears in any code changes
                for change in self.code_changes:
                    if test_addr in change.affected_addresses:
                        self.mappings[name] = MemoryMapping(
                            vanilla_addr=vanilla_addr,
                            patched_addr=test_addr,
                            data_type=name,
                            confidence=0.7,
                            evidence=[f"Common offset pattern (+{offset})"]
                        )
                        break
                if name in self.mappings:
                    break
        
        # Third pass: Heuristic analysis based on found patterns
        if len(self.mappings) >= 2:
            # Find most common offset
            offsets = {}
            for mapping in self.mappings.values():
                offset = mapping.patched_addr - mapping.vanilla_addr
                offsets[offset] = offsets.get(offset, 0) + 1
            
            # Get most common offset
            common_offset = max(offsets.items(), key=lambda x: x[1])[0] if offsets else None
            
            if common_offset is not None:
                # Apply to remaining structures
                for name, info in self.known_structures.items():
                    if name not in self.mappings:
                        test_addr = info['vanilla_addr'] + common_offset
                        if 0xC000 <= test_addr <= 0xDFFF:
                            self.mappings[name] = MemoryMapping(
                                vanilla_addr=info['vanilla_addr'],
                                patched_addr=test_addr,
                                data_type=name,
                                confidence=0.5,
                                evidence=[f"Heuristic: common offset pattern ({common_offset:+d})"]
                            )
                            
    def _party_signature(self, addr: int, rom_section: bytes) -> float:
        """Signature detector for party Pokemon data"""
        if addr + 8 > len(rom_section):
            return 0.0
            
        count = rom_section[addr]
        if count < 1 or count > 6:
            return 0.0
            
        score = 0.5
        
        for i in range(1, min(count + 1, 7)):
            if addr + i < len(rom_section):
                species = rom_section[addr + i]
                if 1 <= species <= 251:
                    score += 0.08
                    
        return min(score, 1.0)
        
    def _box_signature(self, addr: int, rom_section: bytes) -> float:
        """Signature detector for PC box data"""
        if addr + 22 > len(rom_section):
            return 0.0
            
        count = rom_section[addr]
        if count > 20:
            return 0.0
            
        return 0.5
        
    def _player_signature(self, addr: int, rom_section: bytes) -> float:
        """Signature detector for player data"""
        if addr + 13 > len(rom_section):
            return 0.0
            
        trainer_id = struct.unpack('<H', rom_section[addr:addr+2])[0]
        if trainer_id == 0 or trainer_id == 0xFFFF:
            return 0.0
            
        return 0.5
        
    def generate_lua_module(self) -> str:
        """Generate a Lua module for BizHawk with detected addresses"""
        lua_code = '''-- Auto-generated Pokemon Crystal Memory Addresses
-- Generated by ROM comparison tool

local addresses = {}

addresses.rom_type = "archipelago"

addresses.mappings = {
'''
        
        for name, mapping in self.mappings.items():
            lua_code += f'''    {name} = {{
        vanilla = 0x{mapping.vanilla_addr:04X},
        patched = 0x{mapping.patched_addr:04X},
        confidence = {mapping.confidence:.2f}
    }},
'''
        
        lua_code += '''}

function addresses.get(name)
    local mapping = addresses.mappings[name]
    if not mapping then
        error("Unknown address: " .. name)
    end
    
    if addresses.rom_type == "archipelago" then
        return mapping.patched
    else
        return mapping.vanilla
    end
end

return addresses
'''
        
        return lua_code
        
    def generate_report(self, output_path: str) -> None:
        """Generate a detailed analysis report"""
        report = {
            'summary': {
                'vanilla_rom': str(self.vanilla_path),
                'patched_rom': str(self.patched_path),
                'relocations_found': len(self.mappings),
                'code_changes': len(self.code_changes)
            },
            'relocations': {},
            'code_changes': []
        }
        
        for name, mapping in self.mappings.items():
            report['relocations'][name] = {
                'vanilla_address': f"0x{mapping.vanilla_addr:04X}",
                'patched_address': f"0x{mapping.patched_addr:04X}",
                'offset': mapping.patched_addr - mapping.vanilla_addr,
                'confidence': mapping.confidence,
                'evidence': mapping.evidence
            }
            
        for change in self.code_changes[:50]:
            report['code_changes'].append({
                'offset': f"0x{change.offset:06X}",
                'instruction': change.instruction_type,
                'addresses': [f"0x{addr:04X}" for addr in change.affected_addresses]
            })
            
        with open(output_path, 'w') as f:
            json.dump(report, f, indent=2)

# GUI Application
class ROMCompareGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("Pokemon Crystal ROM Comparison Tool")
        self.root.geometry("900x700")
        
        # Variables
        self.vanilla_path = tk.StringVar()
        self.patched_path = tk.StringVar()
        self.analysis_running = False
        self.analyzer = None
        
        # Style
        self.setup_styles()
        
        # Create UI
        self.create_widgets()
        
        # Center window
        self.center_window()
        
    def setup_styles(self):
        """Configure ttk styles for a modern look"""
        style = ttk.Style()
        
        self.colors = {
            'bg': '#f0f0f0',
            'fg': '#333333',
            'accent': '#4a90e2',
            'success': '#27ae60',
            'warning': '#f39c12',
            'error': '#e74c3c',
            'hover': '#3498db'
        }
        
        self.root.configure(bg=self.colors['bg'])
        
        style.configure('Accent.TButton', font=('Arial', 11, 'bold'))
        
    def create_widgets(self):
        """Create all GUI elements"""
        self.create_header()
        self.create_rom_selection()
        self.create_analysis_section()
        self.create_progress_section()
        self.create_results_section()
        self.create_status_bar()
        
    def create_header(self):
        """Create header with title and description"""
        header_frame = tk.Frame(self.root, bg=self.colors['accent'], height=80)
        header_frame.pack(fill='x', padx=0, pady=0)
        header_frame.pack_propagate(False)
        
        title = tk.Label(header_frame, 
                        text="Pokemon Crystal ROM Comparison Tool",
                        font=('Arial', 20, 'bold'),
                        bg=self.colors['accent'],
                        fg='white')
        title.pack(pady=(15, 5))
        
        subtitle = tk.Label(header_frame,
                           text="Compare vanilla and Archipelago ROMs to find memory relocations",
                           font=('Arial', 11),
                           bg=self.colors['accent'],
                           fg='white')
        subtitle.pack()
        
    def create_rom_selection(self):
        """Create ROM file selection section"""
        selection_frame = ttk.LabelFrame(self.root, text="ROM Selection", padding=20)
        selection_frame.pack(fill='x', padx=20, pady=(20, 10))
        
        # Vanilla ROM
        vanilla_label = ttk.Label(selection_frame, text="Vanilla ROM:", font=('Arial', 10))
        vanilla_label.grid(row=0, column=0, sticky='w', pady=5)
        
        vanilla_entry = ttk.Entry(selection_frame, textvariable=self.vanilla_path, width=50)
        vanilla_entry.grid(row=0, column=1, padx=10, pady=5)
        
        vanilla_btn = ttk.Button(selection_frame, text="Browse...",
                                command=lambda: self.browse_rom('vanilla'))
        vanilla_btn.grid(row=0, column=2, pady=5)
        
        # Patched ROM
        patched_label = ttk.Label(selection_frame, text="Patched ROM:", font=('Arial', 10))
        patched_label.grid(row=1, column=0, sticky='w', pady=5)
        
        patched_entry = ttk.Entry(selection_frame, textvariable=self.patched_path, width=50)
        patched_entry.grid(row=1, column=1, padx=10, pady=5)
        
        patched_btn = ttk.Button(selection_frame, text="Browse...",
                                command=lambda: self.browse_rom('patched'))
        patched_btn.grid(row=1, column=2, pady=5)
        
        # Quick info labels
        self.vanilla_info = ttk.Label(selection_frame, text="", foreground='gray')
        self.vanilla_info.grid(row=0, column=3, padx=10)
        
        self.patched_info = ttk.Label(selection_frame, text="", foreground='gray')
        self.patched_info.grid(row=1, column=3, padx=10)
        
    def create_analysis_section(self):
        """Create analysis control section"""
        control_frame = tk.Frame(self.root, bg=self.colors['bg'])
        control_frame.pack(fill='x', padx=20, pady=10)
        
        self.analyze_btn = tk.Button(control_frame,
                                    text="🔍 Analyze ROMs",
                                    command=self.start_analysis,
                                    font=('Arial', 14, 'bold'),
                                    bg=self.colors['accent'],
                                    fg='white',
                                    activebackground=self.colors['hover'],
                                    activeforeground='white',
                                    relief='flat',
                                    padx=30,
                                    pady=10,
                                    cursor='hand2')
        self.analyze_btn.pack()
        
        options_frame = ttk.Frame(control_frame)
        options_frame.pack(pady=10)
        
        self.deep_scan_var = tk.BooleanVar(value=True)
        deep_scan_cb = ttk.Checkbutton(options_frame, 
                                       text="Deep scan for structures",
                                       variable=self.deep_scan_var)
        deep_scan_cb.grid(row=0, column=0, padx=10)
        
        self.export_lua_var = tk.BooleanVar(value=True)
        export_lua_cb = ttk.Checkbutton(options_frame,
                                        text="Generate Lua module",
                                        variable=self.export_lua_var)
        export_lua_cb.grid(row=0, column=1, padx=10)
        
    def create_progress_section(self):
        """Create progress display section"""
        self.progress_frame = ttk.LabelFrame(self.root, text="Analysis Progress", padding=10)
        self.progress_frame.pack(fill='x', padx=20, pady=10)
        
        self.progress_var = tk.DoubleVar()
        self.progress_bar = ttk.Progressbar(self.progress_frame,
                                           variable=self.progress_var,
                                           maximum=100,
                                           length=400)
        self.progress_bar.pack(pady=5)
        
        self.progress_text = tk.StringVar(value="Ready to analyze")
        progress_label = ttk.Label(self.progress_frame, 
                                  textvariable=self.progress_text,
                                  font=('Arial', 10))
        progress_label.pack()
        
        self.progress_frame.pack_forget()
        
    def create_results_section(self):
        """Create results display section"""
        self.results_notebook = ttk.Notebook(self.root)
        self.results_notebook.pack(fill='both', expand=True, padx=20, pady=10)
        
        # Summary tab
        self.summary_frame = ttk.Frame(self.results_notebook)
        self.results_notebook.add(self.summary_frame, text="Summary")
        
        self.summary_text = scrolledtext.ScrolledText(self.summary_frame,
                                                      wrap=tk.WORD,
                                                      width=80,
                                                      height=15,
                                                      font=('Consolas', 10))
        self.summary_text.pack(fill='both', expand=True, padx=10, pady=10)
        
        # Relocations tab
        self.relocations_frame = ttk.Frame(self.results_notebook)
        self.results_notebook.add(self.relocations_frame, text="Address Relocations")
        
        self.create_relocations_view()
        
        # Code Changes tab
        self.code_frame = ttk.Frame(self.results_notebook)
        self.results_notebook.add(self.code_frame, text="Code Changes")
        
        self.code_text = scrolledtext.ScrolledText(self.code_frame,
                                                   wrap=tk.WORD,
                                                   width=80,
                                                   height=15,
                                                   font=('Consolas', 9))
        self.code_text.pack(fill='both', expand=True, padx=10, pady=10)
        
        self.results_notebook.pack_forget()
        
    def create_relocations_view(self):
        """Create treeview for showing address relocations"""
        tree_frame = ttk.Frame(self.relocations_frame)
        tree_frame.pack(fill='both', expand=True, padx=10, pady=10)
        
        scrollbar = ttk.Scrollbar(tree_frame)
        scrollbar.pack(side='right', fill='y')
        
        self.relocations_tree = ttk.Treeview(tree_frame,
                                            columns=('vanilla', 'patched', 'offset', 'confidence'),
                                            show='tree headings',
                                            yscrollcommand=scrollbar.set)
        
        self.relocations_tree.heading('#0', text='Structure')
        self.relocations_tree.heading('vanilla', text='Vanilla Address')
        self.relocations_tree.heading('patched', text='Patched Address')
        self.relocations_tree.heading('offset', text='Offset')
        self.relocations_tree.heading('confidence', text='Confidence')
        
        self.relocations_tree.column('#0', width=200)
        self.relocations_tree.column('vanilla', width=120)
        self.relocations_tree.column('patched', width=120)
        self.relocations_tree.column('offset', width=100)
        self.relocations_tree.column('confidence', width=100)
        
        scrollbar.config(command=self.relocations_tree.yview)
        self.relocations_tree.pack(fill='both', expand=True)
        
        button_frame = ttk.Frame(self.relocations_frame)
        button_frame.pack(fill='x', padx=10, pady=5)
        
        export_json_btn = ttk.Button(button_frame, text="Export JSON",
                                    command=self.export_json)
        export_json_btn.pack(side='left', padx=5)
        
        export_lua_btn = ttk.Button(button_frame, text="Export Lua Module",
                                   command=self.export_lua)
        export_lua_btn.pack(side='left', padx=5)
        
        copy_btn = ttk.Button(button_frame, text="Copy to Clipboard",
                             command=self.copy_results)
        copy_btn.pack(side='left', padx=5)
        
    def create_status_bar(self):
        """Create status bar at bottom"""
        self.status_bar = ttk.Label(self.root, text="Ready", relief='sunken')
        self.status_bar.pack(side='bottom', fill='x')
        
    def center_window(self):
        """Center the window on screen"""
        self.root.update_idletasks()
        width = self.root.winfo_width()
        height = self.root.winfo_height()
        x = (self.root.winfo_screenwidth() // 2) - (width // 2)
        y = (self.root.winfo_screenheight() // 2) - (height // 2)
        self.root.geometry(f'{width}x{height}+{x}+{y}')
        
    def browse_rom(self, rom_type):
        """Browse for ROM file"""
        filename = filedialog.askopenfilename(
            title=f"Select {rom_type.title()} ROM",
            filetypes=[("Game Boy ROM", "*.gbc *.gb"), ("All files", "*.*")]
        )
        
        if filename:
            if rom_type == 'vanilla':
                self.vanilla_path.set(filename)
                self.update_rom_info('vanilla', filename)
            else:
                self.patched_path.set(filename)
                self.update_rom_info('patched', filename)
                
    def update_rom_info(self, rom_type, path):
        """Update ROM info label"""
        try:
            size = Path(path).stat().st_size
            size_mb = size / (1024 * 1024)
            info_text = f"{size_mb:.1f} MB"
            
            if rom_type == 'vanilla':
                self.vanilla_info.config(text=info_text)
            else:
                self.patched_info.config(text=info_text)
        except:
            pass
            
    def start_analysis(self):
        """Start ROM analysis in background thread"""
        if not self.vanilla_path.get() or not self.patched_path.get():
            messagebox.showerror("Error", "Please select both ROM files")
            return
            
        if self.analysis_running:
            messagebox.showinfo("Info", "Analysis already in progress")
            return
            
        self.analyze_btn.config(state='disabled', text="Analyzing...")
        self.analysis_running = True
        
        self.progress_frame.pack(fill='x', padx=20, pady=10)
        self.results_notebook.pack_forget()
        
        thread = threading.Thread(target=self.run_analysis)
        thread.daemon = True
        thread.start()
        
    def run_analysis(self):
        """Run the actual analysis (in background thread)"""
        try:
            self.analyzer = CrystalROMAnalyzer(self.vanilla_path.get(), 
                                             self.patched_path.get())
            
            self.update_progress(10, "Loading ROM files...")
            if not self.analyzer.load_roms():
                raise Exception("Failed to load ROM files")
                
            self.update_progress(20, "Finding binary differences...")
            differences = self.analyzer.find_binary_differences()
            
            self.update_progress(40, "Analyzing code changes...")
            self.analyzer.analyze_code_changes(differences)
            
            if self.deep_scan_var.get():
                self.update_progress(60, "Scanning for relocated structures...")
                self.analyzer.find_data_structure_relocations()
            
            self.update_progress(80, "Generating results...")
            self.display_results()
            
            self.update_progress(100, "Analysis complete!")
            self.status_bar.config(text="Analysis completed successfully")
            
        except Exception as e:
            self.root.after(0, lambda: messagebox.showerror("Analysis Error", str(e)))
            self.status_bar.config(text=f"Error: {str(e)}")
            
        finally:
            self.analysis_running = False
            self.root.after(0, lambda: self.analyze_btn.config(
                state='normal', text="🔍 Analyze ROMs"))
            
    def update_progress(self, value, text):
        """Update progress bar and text (thread-safe)"""
        self.root.after(0, lambda: self.progress_var.set(value))
        self.root.after(0, lambda: self.progress_text.set(text))
        
    def display_results(self):
        """Display analysis results in GUI"""
        self.root.after(0, self._display_results)
        
    def _display_results(self):
        """Display results (must be called from main thread)"""
        self.results_notebook.pack(fill='both', expand=True, padx=20, pady=10)
        
        summary = self.generate_summary()
        self.summary_text.delete(1.0, tk.END)
        self.summary_text.insert(1.0, summary)
        
        self.populate_relocations()
        self.populate_code_changes()
        
        self.results_notebook.select(0)
        
    def generate_summary(self):
        """Generate summary text"""
        if not self.analyzer:
            return "No analysis results"
            
        summary = []
        summary.append("=" * 60)
        summary.append("POKEMON CRYSTAL ROM COMPARISON RESULTS")
        summary.append("=" * 60)
        summary.append("")
        
        summary.append("ROM Information:")
        summary.append(f"  Vanilla: {Path(self.vanilla_path.get()).name}")
        summary.append(f"  Patched: {Path(self.patched_path.get()).name}")
        summary.append("")
        
        summary.append("Analysis Statistics:")
        summary.append(f"  Code changes found: {len(self.analyzer.code_changes)}")
        summary.append(f"  Memory relocations: {len(self.analyzer.mappings)}")
        summary.append("")
        
        if self.analyzer.mappings:
            summary.append("Key Relocations Found:")
            for name, mapping in self.analyzer.mappings.items():
                offset = mapping.patched_addr - mapping.vanilla_addr
                summary.append(f"  • {name}: 0x{mapping.vanilla_addr:04X} → "
                             f"0x{mapping.patched_addr:04X} (offset: {offset:+d})")
        else:
            summary.append("No memory relocations detected.")
            summary.append("The patched ROM appears to use standard addresses.")
            
        summary.append("")
        summary.append("Use the tabs above to explore detailed results.")
        
        return "\n".join(summary)
        
    def populate_relocations(self):
        """Populate relocations treeview"""
        for item in self.relocations_tree.get_children():
            self.relocations_tree.delete(item)
            
        if not self.analyzer or not self.analyzer.mappings:
            return
            
        for name, mapping in self.analyzer.mappings.items():
            offset = mapping.patched_addr - mapping.vanilla_addr
            
            if mapping.confidence >= 0.9:
                icon = "✓"
            elif mapping.confidence >= 0.7:
                icon = "?"
            else:
                icon = "!"
                
            self.relocations_tree.insert('', 'end',
                                       text=f"{icon} {name}",
                                       values=(
                                           f"0x{mapping.vanilla_addr:04X}",
                                           f"0x{mapping.patched_addr:04X}",
                                           f"{offset:+d}",
                                           f"{mapping.confidence:.0%}"
                                       ))
                                       
    def populate_code_changes(self):
        """Populate code changes text"""
        self.code_text.delete(1.0, tk.END)
        
        if not self.analyzer or not self.analyzer.code_changes:
            self.code_text.insert(1.0, "No significant code changes detected.")
            return
            
        text = []
        text.append("Memory-Related Code Changes (first 50):")
        text.append("=" * 60)
        text.append("")
        
        for i, change in enumerate(self.analyzer.code_changes[:50]):
            text.append(f"Change #{i+1}:")
            text.append(f"  Location: 0x{change.offset:06X}")
            text.append(f"  Instruction: {change.instruction_type}")
            
            if len(change.affected_addresses) >= 2:
                old_addr = change.affected_addresses[0]
                new_addr = change.affected_addresses[1]
                text.append(f"  Address change: 0x{old_addr:04X} → 0x{new_addr:04X}")
            
            text.append("")
            
        self.code_text.insert(1.0, "\n".join(text))
        
    def export_json(self):
        """Export results as JSON"""
        if not self.analyzer:
            messagebox.showwarning("Warning", "No analysis results to export")
            return
            
        filename = filedialog.asksaveasfilename(
            defaultextension=".json",
            filetypes=[("JSON files", "*.json"), ("All files", "*.*")]
        )
        
        if filename:
            try:
                self.analyzer.generate_report(filename)
                messagebox.showinfo("Success", f"Results exported to:\n{filename}")
            except Exception as e:
                messagebox.showerror("Export Error", str(e))
                
    def export_lua(self):
        """Export Lua module"""
        if not self.analyzer:
            messagebox.showwarning("Warning", "No analysis results to export")
            return
            
        filename = filedialog.asksaveasfilename(
            defaultextension=".lua",
            filetypes=[("Lua files", "*.lua"), ("All files", "*.*")]
        )
        
        if filename:
            try:
                lua_code = self.analyzer.generate_lua_module()
                with open(filename, 'w') as f:
                    f.write(lua_code)
                messagebox.showinfo("Success", f"Lua module exported to:\n{filename}")
            except Exception as e:
                messagebox.showerror("Export Error", str(e))
                
    def copy_results(self):
        """Copy results summary to clipboard"""
        summary = self.generate_summary()
        self.root.clipboard_clear()
        self.root.clipboard_append(summary)
        messagebox.showinfo("Success", "Results copied to clipboard!")


def main():
    """Main entry point"""
    root = tk.Tk()
    app = ROMCompareGUI(root)
    root.mainloop()


if __name__ == "__main__":
    main()