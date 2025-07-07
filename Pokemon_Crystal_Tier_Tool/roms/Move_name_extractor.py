#!/usr/bin/env python3
"""
Pokemon Crystal Move Names Manager
Extracts and manages move names from various sources
"""

import tkinter as tk
from tkinter import ttk, scrolledtext, filedialog, messagebox
import csv
import json
from pathlib import Path


class MoveNamesManager:
    """Tool to manage Pokemon move names"""
    
    # Known move names from various sources
    KNOWN_MOVES = {
        1: "Pound", 2: "Karate Chop", 3: "Double Slap", 4: "Comet Punch",
        5: "Mega Punch", 6: "Pay Day", 7: "Fire Punch", 8: "Ice Punch",
        9: "Thunder Punch", 10: "Scratch", 11: "Vice Grip", 12: "Guillotine",
        13: "Razor Wind", 14: "Swords Dance", 15: "Cut", 16: "Gust",
        17: "Wing Attack", 18: "Whirlwind", 19: "Fly", 20: "Bind",
        21: "Slam", 22: "Vine Whip", 23: "Stomp", 24: "Double Kick",
        25: "Mega Kick", 26: "Jump Kick", 27: "Rolling Kick", 28: "Sand Attack",
        29: "Headbutt", 30: "Horn Attack", 31: "Fury Attack", 32: "Horn Drill",
        33: "Tackle", 34: "Body Slam", 35: "Wrap", 36: "Take Down",
        37: "Thrash", 38: "Double-Edge", 39: "Tail Whip", 40: "Poison Sting",
        41: "Twineedle", 42: "Pin Missile", 43: "Leer", 44: "Bite",
        45: "Growl", 46: "Roar", 47: "Sing", 48: "Supersonic",
        49: "Sonic Boom", 50: "Disable", 51: "Acid", 52: "Ember",
        53: "Flamethrower", 54: "Mist", 55: "Water Gun", 56: "Hydro Pump",
        57: "Surf", 58: "Ice Beam", 59: "Blizzard", 60: "Psybeam",
        61: "Bubble Beam", 62: "Aurora Beam", 63: "Hyper Beam", 64: "Peck",
        65: "Drill Peck", 66: "Submission", 67: "Low Kick", 68: "Counter",
        69: "Seismic Toss", 70: "Strength", 71: "Absorb", 72: "Mega Drain",
        73: "Leech Seed", 74: "Growth", 75: "Razor Leaf", 76: "Solar Beam",
        77: "Poison Powder", 78: "Stun Spore", 79: "Sleep Powder", 80: "Petal Dance",
        81: "String Shot", 82: "Dragon Rage", 83: "Fire Spin", 84: "Thunder Shock",
        85: "Thunderbolt", 86: "Thunder Wave", 87: "Thunder", 88: "Rock Throw",
        89: "Earthquake", 90: "Fissure", 91: "Dig", 92: "Toxic",
        93: "Confusion", 94: "Psychic", 95: "Hypnosis", 96: "Meditate",
        97: "Agility", 98: "Quick Attack", 99: "Rage", 100: "Teleport",
        101: "Night Shade", 102: "Mimic", 103: "Screech", 104: "Double Team",
        105: "Recover", 106: "Harden", 107: "Minimize", 108: "Smokescreen",
        109: "Confuse Ray", 110: "Withdraw", 111: "Defense Curl", 112: "Barrier",
        113: "Light Screen", 114: "Haze", 115: "Reflect", 116: "Focus Energy",
        117: "Bide", 118: "Metronome", 119: "Mirror Move", 120: "Self-Destruct",
        121: "Egg Bomb", 122: "Lick", 123: "Smog", 124: "Sludge",
        125: "Bone Club", 126: "Fire Blast", 127: "Waterfall", 128: "Clamp",
        129: "Swift", 130: "Skull Bash", 131: "Spike Cannon", 132: "Constrict",
        133: "Amnesia", 134: "Kinesis", 135: "Soft-Boiled", 136: "High Jump Kick",
        137: "Glare", 138: "Dream Eater", 139: "Poison Gas", 140: "Barrage",
        141: "Leech Life", 142: "Lovely Kiss", 143: "Sky Attack", 144: "Transform",
        145: "Bubble", 146: "Dizzy Punch", 147: "Spore", 148: "Flash",
        149: "Psywave", 150: "Splash", 151: "Acid Armor", 152: "Crabhammer",
        153: "Explosion", 154: "Fury Swipes", 155: "Bonemerang", 156: "Rest",
        157: "Rock Slide", 158: "Hyper Fang", 159: "Sharpen", 160: "Conversion",
        161: "Tri Attack", 162: "Super Fang", 163: "Slash", 164: "Substitute",
        165: "Struggle", 166: "Sketch", 167: "Triple Kick", 168: "Thief",
        169: "Spider Web", 170: "Mind Reader", 171: "Nightmare", 172: "Flame Wheel",
        173: "Snore", 174: "Curse", 175: "Flail", 176: "Conversion 2",
        177: "Aeroblast", 178: "Cotton Spore", 179: "Reversal", 180: "Spite",
        181: "Powder Snow", 182: "Protect", 183: "Mach Punch", 184: "Scary Face",
        185: "Faint Attack", 186: "Sweet Kiss", 187: "Belly Drum", 188: "Sludge Bomb",
        189: "Mud-Slap", 190: "Octazooka", 191: "Spikes", 192: "Zap Cannon",
        193: "Foresight", 194: "Destiny Bond", 195: "Perish Song", 196: "Icy Wind",
        197: "Detect", 198: "Bone Rush", 199: "Lock-On", 200: "Outrage",
        201: "Sandstorm", 202: "Giga Drain", 203: "Endure", 204: "Charm",
        205: "Rollout", 206: "False Swipe", 207: "Swagger", 208: "Milk Drink",
        209: "Spark", 210: "Fury Cutter", 211: "Steel Wing", 212: "Mean Look",
        213: "Attract", 214: "Sleep Talk", 215: "Heal Bell", 216: "Return",
        217: "Present", 218: "Frustration", 219: "Safeguard", 220: "Pain Split",
        221: "Sacred Fire", 222: "Magnitude", 223: "Dynamic Punch", 224: "Megahorn",
        225: "Dragon Breath", 226: "Baton Pass", 227: "Encore", 228: "Pursuit",
        229: "Rapid Spin", 230: "Sweet Scent", 231: "Iron Tail", 232: "Metal Claw",
        233: "Vital Throw", 234: "Morning Sun", 235: "Synthesis", 236: "Moonlight",
        237: "Hidden Power", 238: "Cross Chop", 239: "Twister", 240: "Rain Dance",
        241: "Sunny Day", 242: "Crunch", 243: "Mirror Coat", 244: "Psych Up",
        245: "Extreme Speed", 246: "Ancient Power", 247: "Shadow Ball", 248: "Future Sight",
        249: "Rock Smash", 250: "Whirlpool", 251: "Beat Up"
    }
    
    def __init__(self, root):
        self.root = root
        self.root.title("Pokemon Crystal Move Names Manager")
        self.root.geometry("1000x700")
        
        self.move_data = {}
        self.create_widgets()
        
    def create_widgets(self):
        """Create GUI"""
        main_frame = ttk.Frame(self.root, padding="10")
        main_frame.pack(fill=tk.BOTH, expand=True)
        
        # Header
        ttk.Label(main_frame, text="Move Names Manager", 
                 font=("Arial", 14, "bold")).pack(pady=(0, 10))
        
        # Controls
        control_frame = ttk.Frame(main_frame)
        control_frame.pack(fill=tk.X, pady=10)
        
        ttk.Button(control_frame, text="Load Moves.csv", 
                  command=self.load_csv).pack(side=tk.LEFT, padx=5)
        ttk.Button(control_frame, text="Extract from Notes", 
                  command=self.extract_from_notes).pack(side=tk.LEFT, padx=5)
        ttk.Button(control_frame, text="Fill Missing", 
                  command=self.fill_missing).pack(side=tk.LEFT, padx=5)
        ttk.Button(control_frame, text="Export Complete List", 
                  command=self.export_list).pack(side=tk.LEFT, padx=5)
        ttk.Button(control_frame, text="Export for Code", 
                  command=self.export_for_code).pack(side=tk.LEFT, padx=5)
        
        # Results
        self.results_text = scrolledtext.ScrolledText(main_frame, wrap=tk.WORD, 
                                                     font=("Consolas", 10))
        self.results_text.pack(fill=tk.BOTH, expand=True)
        
        # Initialize with known moves
        self.display_known_moves()
        
    def display_known_moves(self):
        """Display the known moves"""
        self.log("KNOWN MOVE NAMES")
        self.log("="*50)
        self.log(f"Total known: {len(self.KNOWN_MOVES)}\n")
        
        for move_id in sorted(self.KNOWN_MOVES.keys()):
            self.log(f"{move_id:3d}: {self.KNOWN_MOVES[move_id]}")
            
        self.log(f"\nMissing: {251 - len(self.KNOWN_MOVES)} moves")
        
    def load_csv(self):
        """Load Moves.csv file"""
        filename = filedialog.askopenfilename(
            title="Select Moves.csv",
            filetypes=[("CSV files", "*.csv"), ("All files", "*.*")]
        )
        
        if not filename:
            return
            
        try:
            with open(filename, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                self.move_data = {}
                
                for row in reader:
                    move_id = int(row['Move_ID'])
                    self.move_data[move_id] = row
                    
            self.log(f"\n\nLoaded {len(self.move_data)} moves from CSV")
            messagebox.showinfo("Success", f"Loaded {len(self.move_data)} moves")
            
        except Exception as e:
            messagebox.showerror("Error", f"Failed to load CSV: {e}")
            
    def extract_from_notes(self):
        """Extract move names from Notes column"""
        if not self.move_data:
            messagebox.showerror("Error", "Please load Moves.csv first")
            return
            
        self.log("\n\nEXTRACTING NAMES FROM NOTES")
        self.log("="*50)
        
        extracted = {}
        
        for move_id, data in self.move_data.items():
            notes = data.get('Notes', '')
            
            # Common patterns in notes:
            # "Pound", "Move name", etc.
            if notes and not notes.startswith('Unknown'):
                # Clean up the notes
                name = notes.split(';')[0].strip()  # Take first part before semicolon
                if name and not name.startswith('0x'):  # Not a hex value
                    extracted[move_id] = name
                    
        self.log(f"Extracted {len(extracted)} move names from notes:")
        for move_id, name in sorted(extracted.items()):
            if move_id not in self.KNOWN_MOVES:
                self.log(f"  {move_id}: {name} (NEW)")
                self.KNOWN_MOVES[move_id] = name
            elif self.KNOWN_MOVES[move_id] != name:
                self.log(f"  {move_id}: {name} (was: {self.KNOWN_MOVES[move_id]})")
                
    def fill_missing(self):
        """Fill in missing move names"""
        self.log("\n\nFILLING MISSING MOVES")
        self.log("="*50)
        
        missing = []
        for i in range(1, 252):
            if i not in self.KNOWN_MOVES:
                missing.append(i)
                
        self.log(f"Missing moves: {missing}")
        
        # For missing moves, create placeholder names
        for move_id in missing:
            if self.move_data and move_id in self.move_data:
                # Try to create name from type and power
                data = self.move_data[move_id]
                type_name = data.get('Type_Name', 'Unknown')
                power = int(data.get('Power', 0))
                
                if power > 0:
                    self.KNOWN_MOVES[move_id] = f"{type_name}_Move_{power}"
                else:
                    self.KNOWN_MOVES[move_id] = f"{type_name}_Status_{move_id}"
            else:
                self.KNOWN_MOVES[move_id] = f"Move_{move_id}"
                
        self.log(f"\nTotal moves now: {len(self.KNOWN_MOVES)}")
        
    def export_list(self):
        """Export complete move list"""
        filename = filedialog.asksaveasfilename(
            defaultextension=".txt",
            filetypes=[("Text files", "*.txt"), ("CSV files", "*.csv"), ("All files", "*.*")]
        )
        
        if not filename:
            return
            
        try:
            if filename.endswith('.csv'):
                with open(filename, 'w', newline='') as f:
                    writer = csv.writer(f)
                    writer.writerow(['Move_ID', 'Move_Name'])
                    for move_id in sorted(self.KNOWN_MOVES.keys()):
                        writer.writerow([move_id, self.KNOWN_MOVES[move_id]])
            else:
                with open(filename, 'w') as f:
                    for move_id in sorted(self.KNOWN_MOVES.keys()):
                        f.write(f"{move_id}: {self.KNOWN_MOVES[move_id]}\n")
                        
            messagebox.showinfo("Success", f"Exported to {filename}")
            
        except Exception as e:
            messagebox.showerror("Error", f"Export failed: {e}")
            
    def export_for_code(self):
        """Export as Python dictionary"""
        filename = filedialog.asksaveasfilename(
            defaultextension=".py",
            filetypes=[("Python files", "*.py"), ("All files", "*.*")]
        )
        
        if not filename:
            return
            
        try:
            with open(filename, 'w') as f:
                f.write("# Pokemon Crystal Move Names\n")
                f.write("MOVE_NAMES = {\n")
                
                for move_id in sorted(self.KNOWN_MOVES.keys()):
                    name = self.KNOWN_MOVES[move_id]
                    f.write(f'    {move_id}: "{name}",\n')
                    
                f.write("}\n")
                
            messagebox.showinfo("Success", f"Exported Python code to {filename}")
            
        except Exception as e:
            messagebox.showerror("Error", f"Export failed: {e}")
            
    def log(self, message):
        """Add message to results"""
        self.results_text.insert(tk.END, message + "\n")
        self.results_text.see(tk.END)
        self.root.update()


def main():
    root = tk.Tk()
    app = MoveNamesManager(root)
    root.mainloop()


if __name__ == "__main__":
    main()