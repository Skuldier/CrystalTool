#!/usr/bin/env python3
"""
Pokemon Crystal ROM Analyzer for Archipelago
Analyzes ROM and memory patterns to find correct addresses
"""

import struct
import os
import json
from datetime import datetime
from pathlib import Path

class ROMAnalyzer:
    def __init__(self, rom_path):
        self.rom_path = Path(rom_path)
        self.rom_data = None
        self.results = {
            "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "rom_file": str(rom_path),
            "header": {},
            "signatures": {},
            "memory_patterns": {},
            "archipelago_data": {},
            "recommendations": []
        }
        
    def load_rom(self):
        """Load ROM file into memory"""
        try:
            with open(self.rom_path, 'rb') as f:
                self.rom_data = f.read()
            self.results["rom_size"] = len(self.rom_data)
            print(f"Loaded ROM: {self.rom_path.name} ({len(self.rom_data):,} bytes)")
            return True
        except Exception as e:
            print(f"[X] Error loading ROM: {e}")
            return False
            
    def analyze_header(self):
        """Analyze ROM header"""
        print("\n[1/5] Analyzing ROM Header...")
        
        # Nintendo logo (0x104-0x133)
        nintendo_logo = self.rom_data[0x104:0x134]
        
        # Title (0x134-0x143)
        title_bytes = self.rom_data[0x134:0x144]
        title = title_bytes.decode('ascii', errors='ignore').strip('\x00')
        
        # Game code (0x13F-0x142)
        game_code = self.rom_data[0x13F:0x143].decode('ascii', errors='ignore')
        
        # CGB flag
        cgb_flag = self.rom_data[0x143]
        
        # Version
        version = self.rom_data[0x14C]
        
        # Checksum
        header_checksum = self.rom_data[0x14D]
        global_checksum = struct.unpack('>H', self.rom_data[0x14E:0x150])[0]
        
        self.results["header"] = {
            "title": title,
            "game_code": game_code,
            "cgb_flag": f"0x{cgb_flag:02X}",
            "version": version,
            "header_checksum": f"0x{header_checksum:02X}",
            "global_checksum": f"0x{global_checksum:04X}",
            "is_crystal": "CRYSTAL" in title.upper() or game_code == "BYTE"
        }
        
        print(f"  Title: {title}")
        print(f"  Game Code: {game_code}")
        print(f"  Version: {version}")
        print(f"  Is Crystal: {self.results['header']['is_crystal']}")
        
    def find_archipelago_signatures(self):
        """Search for Archipelago-specific signatures"""
        print("\n[2/5] Searching for Archipelago signatures...")
        
        signatures_found = []
        
        # Search patterns
        patterns = [
            (b'ARCHIPELAGO', 'Full name'),
            (b'AP\x00', 'AP marker'),
            (b'randomizer', 'Randomizer text'),
            (b'seed', 'Seed reference'),
            (b'multiworld', 'Multiworld reference')
        ]
        
        for pattern, description in patterns:
            offset = 0
            while True:
                pos = self.rom_data.find(pattern, offset)
                if pos == -1:
                    break
                signatures_found.append({
                    "pattern": pattern.decode('ascii', errors='ignore'),
                    "description": description,
                    "offset": f"0x{pos:06X}",
                    "bank": pos // 0x4000,
                    "local_offset": f"0x{pos % 0x4000:04X}"
                })
                offset = pos + 1
                
        self.results["signatures"]["archipelago_patterns"] = signatures_found
        print(f"  Found {len(signatures_found)} Archipelago-related signatures")
        
    def analyze_save_structure(self):
        """Analyze save data structure locations"""
        print("\n[3/5] Analyzing save structure...")
        
        # Pokemon Crystal save structure patterns
        save_patterns = {
            "party_structure": {
                "original_offset": 0xDCD7,  # In WRAM
                "pattern": "1-6 followed by species IDs",
                "found_locations": []
            },
            "player_name": {
                "original_offset": 0xD47D,
                "pattern": "Text string terminated by 0x50",
                "found_locations": []
            },
            "trainer_id": {
                "original_offset": 0xD47B,
                "pattern": "16-bit value",
                "found_locations": []
            }
        }
        
        # Since we're analyzing ROM, we look for code that references these addresses
        # Search for LDA/STA instructions that use these addresses
        for addr_name, info in save_patterns.items():
            addr = info["original_offset"]
            
            # Look for different addressing modes that might reference this address
            # LD A, (addr) = 0xFA addr_low addr_high
            # LD (addr), A = 0xEA addr_low addr_high
            
            addr_low = addr & 0xFF
            addr_high = (addr >> 8) & 0xFF
            
            # Search for loads from this address
            load_pattern = bytes([0xFA, addr_low, addr_high])
            store_pattern = bytes([0xEA, addr_low, addr_high])
            
            load_refs = []
            store_refs = []
            
            offset = 0
            while offset < len(self.rom_data) - 3:
                if self.rom_data[offset:offset+3] == load_pattern:
                    load_refs.append(f"0x{offset:06X}")
                elif self.rom_data[offset:offset+3] == store_pattern:
                    store_refs.append(f"0x{offset:06X}")
                offset += 1
                
            info["load_references"] = load_refs[:5]  # Limit to first 5
            info["store_references"] = store_refs[:5]
            info["total_references"] = len(load_refs) + len(store_refs)
            
        self.results["memory_patterns"]["save_structure"] = save_patterns
        
        # Summary
        for name, info in save_patterns.items():
            refs = info["total_references"]
            print(f"  {name}: {refs} code references found")
            
    def scan_for_relocated_addresses(self):
        """Scan for potentially relocated memory addresses"""
        print("\n[4/5] Scanning for relocated addresses...")
        
        # Common relocation patterns in randomizers
        relocations = {}
        
        # Look for jump tables or pointer tables that might indicate relocation
        # In GB/GBC, pointer tables often have a pattern of sequential addresses
        
        # Scan for potential WRAM remapping
        wram_base = 0xC000
        wram_patterns = []
        
        # Look for instructions that establish new base addresses
        # LD HL, addr is common for setting up pointers
        for offset in range(0, len(self.rom_data) - 3):
            if self.rom_data[offset] == 0x21:  # LD HL, nn
                addr = struct.unpack('<H', self.rom_data[offset+1:offset+3])[0]
                if 0xC000 <= addr <= 0xDFFF:  # WRAM range
                    # Check if this might be a relocated base address
                    if addr not in [0xDCD7, 0xD47D, 0xD47B]:  # Not original addresses
                        wram_patterns.append({
                            "instruction_offset": f"0x{offset:06X}",
                            "target_address": f"0x{addr:04X}",
                            "bank": offset // 0x4000
                        })
                        
        # Find the most common WRAM addresses being loaded
        addr_counts = {}
        for pattern in wram_patterns:
            addr = pattern["target_address"]
            addr_counts[addr] = addr_counts.get(addr, 0) + 1
            
        # Get top 10 most referenced WRAM addresses
        top_addresses = sorted(addr_counts.items(), key=lambda x: x[1], reverse=True)[:10]
        
        self.results["memory_patterns"]["relocated_addresses"] = {
            "top_wram_references": [
                {"address": addr, "count": count} 
                for addr, count in top_addresses
            ],
            "total_wram_references": len(wram_patterns)
        }
        
        print(f"  Found {len(wram_patterns)} WRAM references")
        if top_addresses:
            print(f"  Most referenced: {top_addresses[0][0]} ({top_addresses[0][1]} times)")
            
    def generate_recommendations(self):
        """Generate recommendations based on analysis"""
        print("\n[5/5] Generating recommendations...")
        
        recs = []
        
        # Check if this is actually Crystal
        if not self.results["header"]["is_crystal"]:
            recs.append({
                "priority": "HIGH",
                "issue": "ROM may not be Pokemon Crystal",
                "solution": "Verify you're using the correct ROM"
            })
            
        # Check for Archipelago signatures
        if self.results["signatures"]["archipelago_patterns"]:
            recs.append({
                "priority": "INFO",
                "issue": "Archipelago signatures detected",
                "solution": "This appears to be a properly patched ROM"
            })
            
        # Check for relocated addresses
        top_refs = self.results["memory_patterns"]["relocated_addresses"]["top_wram_references"]
        if top_refs and top_refs[0]["count"] > 10:
            recs.append({
                "priority": "MEDIUM",
                "issue": f"Possible relocated addresses detected",
                "solution": f"Try using {top_refs[0]['address']} instead of 0xDCD7 for party data"
            })
            
        # Add memory addresses to test
        test_addresses = []
        for ref in top_refs[:3]:
            addr_int = int(ref["address"], 16)
            if 0xDC00 <= addr_int <= 0xDE00:  # Reasonable range for party data
                test_addresses.append(ref["address"])
                
        if test_addresses:
            recs.append({
                "priority": "ACTION",
                "issue": "Alternative memory addresses found",
                "solution": f"Test these addresses for party data: {', '.join(test_addresses)}"
            })
            
        self.results["recommendations"] = recs
        
        print(f"  Generated {len(recs)} recommendations")
        
    def save_results(self):
        """Save analysis results to file"""
        output_file = f"rom_analysis_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(self.results, f, indent=2)
            
        print(f"\n[+] Results saved to: {output_file}")
        
        # Also create a summary file
        summary_file = "rom_analysis_summary.txt"
        with open(summary_file, 'w', encoding='utf-8') as f:
            f.write("Pokemon Crystal ROM Analysis Summary\n")
            f.write("="*50 + "\n\n")
            
            f.write(f"ROM: {self.rom_path.name}\n")
            f.write(f"Date: {self.results['timestamp']}\n")
            f.write(f"Size: {self.results['rom_size']:,} bytes\n\n")
            
            f.write("Header Information:\n")
            for key, value in self.results["header"].items():
                f.write(f"  {key}: {value}\n")
                
            f.write(f"\nArchipelago Signatures: {len(self.results['signatures']['archipelago_patterns'])}\n")
            
            f.write("\nRecommendations:\n")
            for rec in self.results["recommendations"]:
                f.write(f"\n[{rec['priority']}] {rec['issue']}\n")
                f.write(f"  -> {rec['solution']}\n")
                
            # Add test code
            f.write("\n" + "="*50 + "\n")
            f.write("Test Code for memory_reader.lua:\n\n")
            
            # Get test addresses from recommendations
            test_addresses = []
            top_refs = self.results["memory_patterns"]["relocated_addresses"]["top_wram_references"]
            for ref in top_refs[:3]:
                addr_int = int(ref["address"], 16)
                if 0xDC00 <= addr_int <= 0xDE00:
                    test_addresses.append(ref["address"])
            
            if test_addresses:
                f.write("-- Try these alternative addresses:\n")
                for addr in test_addresses[:3]:
                    addr_int = int(addr, 16)
                    f.write(f"party_count = {addr},  -- was 0xDCD7\n")
                    f.write(f"party_species = 0x{addr_int+1:04X},  -- was 0xDCD8\n")
                    f.write(f"party_data_start = 0x{addr_int+8:04X},  -- was 0xDCDF\n\n")
                    
        print(f"[+] Summary saved to: {summary_file}")
        
    def analyze(self):
        """Run complete analysis"""
        print("="*60)
        print("Pokemon Crystal ROM Analyzer for Archipelago")
        print("="*60)
        
        if not self.load_rom():
            return False
            
        self.analyze_header()
        self.find_archipelago_signatures()
        self.analyze_save_structure()
        self.scan_for_relocated_addresses()
        self.generate_recommendations()
        self.save_results()
        
        print("\n[+] Analysis complete!")
        print("Check rom_analysis_summary.txt for recommendations")
        
        return True

def main():
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: python analyze_rom.py <path_to_rom>")
        print("\nThis tool analyzes Pokemon Crystal ROMs patched with Archipelago")
        print("to find the correct memory addresses for the tier rating tool.")
        return
        
    rom_path = sys.argv[1]
    if not os.path.exists(rom_path):
        print(f"Error: ROM file not found: {rom_path}")
        return
        
    analyzer = ROMAnalyzer(rom_path)
    analyzer.analyze()

if __name__ == "__main__":
    main()