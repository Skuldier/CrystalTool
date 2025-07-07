#!/usr/bin/env python3
"""
Pokemon Crystal Tier Calculator with Manual Move Selection
Allows you to select moves manually and calculate tier ratings for any Pokemon
"""

import tkinter as tk
from tkinter import ttk, filedialog, messagebox
import struct
from pathlib import Path
from typing import Dict, List, Tuple, Optional
import math
import json
import random

# Import move names from Move_names.py (you'll need this file)
MOVE_NAMES = {
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


class PokemonTierCalculator:
    """Main application for calculating Pokemon tiers with manual move selection"""
    
    # Memory addresses (patched ROM)
    POKEMON_DATA_BASE = 0x513F4  # Base address for Pokemon data
    POKEMON_SIZE = 32            # Bytes per Pokemon
    
    # Type IDs
    TYPES = {
        0x00: "Normal",   0x01: "Fighting", 0x02: "Flying",   0x03: "Poison",
        0x04: "Ground",   0x05: "Rock",     0x06: "Bug",      0x07: "Ghost",
        0x08: "Steel",    0x14: "Fire",     0x15: "Water",    0x16: "Grass",
        0x17: "Electric", 0x18: "Psychic",  0x19: "Ice",      0x1A: "Dragon",
        0x1B: "Dark"
    }
    
    # Type effectiveness chart
    TYPE_EFFECTIVENESS = {
        "Fire": {"Water": 0.5, "Grass": 2.0, "Ice": 2.0, "Steel": 2.0, "Fire": 0.5, "Rock": 0.5, "Dragon": 0.5, "Bug": 2.0},
        "Water": {"Fire": 2.0, "Ground": 2.0, "Rock": 2.0, "Water": 0.5, "Grass": 0.5, "Dragon": 0.5},
        "Grass": {"Water": 2.0, "Ground": 2.0, "Rock": 2.0, "Fire": 0.5, "Grass": 0.5, "Flying": 0.5, "Steel": 0.5, "Bug": 0.5, "Poison": 0.5, "Dragon": 0.5},
        "Electric": {"Water": 2.0, "Flying": 2.0, "Ground": 0.0, "Electric": 0.5, "Grass": 0.5, "Dragon": 0.5},
        "Ice": {"Grass": 2.0, "Ground": 2.0, "Flying": 2.0, "Dragon": 2.0, "Fire": 0.5, "Water": 0.5, "Ice": 0.5, "Steel": 0.5},
        "Fighting": {"Normal": 2.0, "Rock": 2.0, "Steel": 2.0, "Ice": 2.0, "Dark": 2.0, "Flying": 0.5, "Psychic": 0.5, "Bug": 0.5, "Poison": 0.5, "Ghost": 0.0},
        "Poison": {"Grass": 2.0, "Poison": 0.5, "Ground": 0.5, "Rock": 0.5, "Ghost": 0.5, "Steel": 0.0},
        "Ground": {"Fire": 2.0, "Electric": 2.0, "Poison": 2.0, "Rock": 2.0, "Steel": 2.0, "Flying": 0.0, "Grass": 0.5, "Bug": 0.5},
        "Flying": {"Grass": 2.0, "Fighting": 2.0, "Bug": 2.0, "Rock": 0.5, "Steel": 0.5, "Electric": 0.5},
        "Psychic": {"Fighting": 2.0, "Poison": 2.0, "Steel": 0.5, "Psychic": 0.5, "Dark": 0.0},
        "Bug": {"Grass": 2.0, "Psychic": 2.0, "Dark": 2.0, "Fire": 0.5, "Fighting": 0.5, "Flying": 0.5, "Steel": 0.5, "Poison": 0.5, "Ghost": 0.5},
        "Rock": {"Fire": 2.0, "Ice": 2.0, "Flying": 2.0, "Bug": 2.0, "Fighting": 0.5, "Ground": 0.5, "Steel": 0.5},
        "Ghost": {"Ghost": 2.0, "Psychic": 2.0, "Normal": 0.0, "Dark": 0.5, "Steel": 0.5},
        "Dragon": {"Dragon": 2.0, "Steel": 0.5},
        "Dark": {"Ghost": 2.0, "Psychic": 2.0, "Fighting": 0.5, "Dark": 0.5, "Steel": 0.5},
        "Steel": {"Rock": 2.0, "Ice": 2.0, "Fire": 0.5, "Water": 0.5, "Electric": 0.5, "Steel": 0.5},
        "Normal": {"Rock": 0.5, "Ghost": 0.0, "Steel": 0.5}
    }
    
    # Move database with power, type, and properties
    MOVE_DATA = {
        # Format: move_id: (power, type, accuracy, pp, is_physical, effect)
        1: (40, "Normal", 100, 35, True, ""),
        2: (50, "Fighting", 100, 25, True, "High crit"),
        3: (15, "Normal", 85, 10, True, "2-5 hits"),
        4: (18, "Normal", 85, 15, True, "2-5 hits"),
        5: (80, "Normal", 85, 20, True, ""),
        6: (40, "Normal", 100, 20, True, "Scatter coins"),
        7: (75, "Fire", 100, 15, True, "10% burn"),
        8: (75, "Ice", 100, 15, True, "10% freeze"),
        9: (75, "Electric", 100, 15, True, "10% paralyze"),
        10: (40, "Normal", 100, 35, True, ""),
        11: (55, "Normal", 100, 30, True, ""),
        12: (0, "Normal", 30, 5, True, "OHKO"),
        13: (80, "Normal", 100, 10, False, "2-turn, high crit"),
        14: (0, "Normal", 100, 30, False, "Attack +2"),
        15: (50, "Normal", 95, 30, True, ""),
        16: (40, "Flying", 100, 35, False, ""),
        17: (60, "Flying", 100, 35, True, ""),
        18: (0, "Normal", 100, 20, False, "Switch target"),
        19: (90, "Flying", 95, 15, True, "2-turn"),
        20: (15, "Normal", 85, 20, True, "Trap 4-5 turns"),
        21: (80, "Normal", 75, 20, True, ""),
        22: (45, "Grass", 100, 25, True, ""),
        23: (65, "Normal", 100, 20, True, "30% flinch"),
        24: (30, "Fighting", 100, 30, True, "2 hits"),
        25: (120, "Normal", 75, 5, True, ""),
        26: (100, "Fighting", 95, 10, True, "Crash damage on miss"),
        27: (60, "Fighting", 85, 15, True, "30% flinch"),
        28: (0, "Ground", 100, 15, False, "Lower accuracy"),
        29: (70, "Normal", 100, 15, True, "30% flinch"),
        30: (65, "Normal", 100, 25, True, ""),
        31: (15, "Normal", 85, 20, True, "2-5 hits"),
        32: (0, "Normal", 30, 5, True, "OHKO"),
        33: (35, "Normal", 95, 35, True, ""),
        34: (85, "Normal", 100, 15, True, "30% paralyze"),
        35: (35, "Normal", 90, 20, True, "Trap 4-5 turns"),
        36: (90, "Normal", 85, 20, True, "Recoil"),
        37: (120, "Normal", 100, 10, True, "2-3 turns, confuse"),
        38: (120, "Normal", 100, 15, True, "Recoil"),
        39: (0, "Normal", 100, 30, False, "Lower defense"),
        40: (15, "Poison", 100, 35, True, "30% poison"),
        41: (25, "Bug", 100, 20, True, "2 hits, 20% poison"),
        42: (14, "Bug", 85, 20, True, "2-5 hits"),
        43: (0, "Normal", 100, 30, False, "Lower defense"),
        44: (60, "Dark", 100, 25, True, "30% flinch"),
        45: (0, "Normal", 100, 40, False, "Lower attack"),
        46: (0, "Normal", 100, 20, False, "Switch target"),
        47: (0, "Normal", 55, 15, False, "Sleep"),
        48: (0, "Normal", 55, 20, False, "Confuse"),
        49: (20, "Normal", 90, 20, False, "Always 20 damage"),
        50: (0, "Psychic", 100, 20, False, "Disable move"),
        51: (40, "Poison", 100, 30, False, "10% lower defense"),
        52: (40, "Fire", 100, 25, False, "10% burn"),
        53: (95, "Fire", 100, 15, False, "10% burn"),
        54: (0, "Ice", 100, 30, False, "Protect team"),
        55: (40, "Water", 100, 25, False, ""),
        56: (120, "Water", 80, 5, False, ""),
        57: (95, "Water", 100, 15, False, ""),
        58: (95, "Ice", 100, 10, False, "10% freeze"),
        59: (120, "Ice", 70, 5, False, "10% freeze"),
        60: (65, "Psychic", 100, 20, False, "10% confuse"),
        61: (65, "Water", 100, 20, False, "10% lower speed"),
        62: (65, "Ice", 100, 20, False, "10% lower attack"),
        63: (150, "Normal", 90, 5, False, "Recharge"),
        64: (35, "Flying", 100, 35, True, ""),
        65: (80, "Flying", 100, 20, True, ""),
        66: (80, "Fighting", 80, 25, True, "Recoil"),
        67: (50, "Fighting", 100, 20, True, "30% flinch"),
        68: (0, "Fighting", 100, 20, True, "Counter physical"),
        69: (0, "Fighting", 100, 20, True, "Level damage"),
        70: (80, "Normal", 100, 15, True, ""),
        71: (20, "Grass", 100, 25, False, "Drain"),
        72: (40, "Grass", 100, 15, False, "Drain"),
        73: (0, "Grass", 90, 10, False, "Leech seed"),
        74: (0, "Normal", 100, 40, False, "SpA/SpD +1"),
        75: (55, "Grass", 95, 25, True, "High crit"),
        76: (120, "Grass", 100, 10, False, "2-turn"),
        77: (0, "Poison", 75, 35, False, "Poison"),
        78: (0, "Grass", 75, 30, False, "Paralyze"),
        79: (0, "Grass", 75, 15, False, "Sleep"),
        80: (120, "Grass", 100, 10, False, "2-3 turns, confuse"),
        81: (0, "Bug", 95, 40, False, "Lower speed"),
        82: (40, "Dragon", 100, 10, False, "Always 40 damage"),
        83: (35, "Fire", 85, 15, False, "Trap 4-5 turns"),
        84: (40, "Electric", 100, 30, False, "10% paralyze"),
        85: (95, "Electric", 100, 15, False, "10% paralyze"),
        86: (0, "Electric", 100, 20, False, "Paralyze"),
        87: (120, "Electric", 70, 10, False, "10% paralyze"),
        88: (50, "Rock", 90, 15, True, ""),
        89: (100, "Ground", 100, 10, True, ""),
        90: (0, "Ground", 30, 5, True, "OHKO"),
        91: (60, "Ground", 100, 10, True, "2-turn"),
        92: (0, "Poison", 85, 10, False, "Badly poison"),
        93: (50, "Psychic", 100, 25, False, "10% confuse"),
        94: (90, "Psychic", 100, 10, False, "10% lower SpD"),
        95: (0, "Psychic", 60, 20, False, "Sleep"),
        96: (0, "Psychic", 100, 40, False, "Attack +1"),
        97: (0, "Psychic", 100, 30, False, "Speed +2"),
        98: (40, "Normal", 100, 30, True, "Priority +1"),
        99: (20, "Normal", 100, 20, True, "Build rage"),
        100: (0, "Psychic", 100, 20, False, "Escape"),
        101: (0, "Ghost", 100, 15, False, "Level damage"),
        102: (0, "Normal", 100, 10, False, "Copy move"),
        103: (0, "Normal", 85, 40, False, "Lower defense -2"),
        104: (0, "Normal", 100, 15, False, "Evasion +1"),
        105: (0, "Normal", 100, 10, False, "Heal 50%"),
        106: (0, "Normal", 100, 30, False, "Defense +1"),
        107: (0, "Normal", 100, 20, False, "Evasion +2"),
        108: (0, "Normal", 100, 20, False, "Lower accuracy"),
        109: (0, "Ghost", 100, 10, False, "Confuse"),
        110: (0, "Water", 100, 40, False, "Defense +1"),
        111: (0, "Normal", 100, 40, False, "Defense +1"),
        112: (0, "Psychic", 100, 30, False, "Defense +2"),
        113: (0, "Psychic", 100, 30, False, "SpD +1"),
        114: (0, "Ice", 100, 30, False, "Reset stats"),
        115: (0, "Psychic", 100, 20, False, "Defense +1"),
        116: (0, "Normal", 100, 30, False, "Crit +2"),
        117: (0, "Normal", 100, 10, True, "Wait 2-3 turns"),
        118: (0, "Normal", 100, 10, False, "Random move"),
        119: (0, "Flying", 100, 20, False, "Copy last move"),
        120: (200, "Normal", 100, 5, True, "User faints"),
        121: (100, "Normal", 75, 10, True, ""),
        122: (30, "Ghost", 100, 30, True, "30% paralyze"),
        123: (30, "Poison", 70, 20, False, "40% poison"),
        124: (65, "Poison", 100, 20, False, "30% poison"),
        125: (65, "Ground", 85, 20, True, "10% flinch"),
        126: (120, "Fire", 85, 5, False, "10% burn"),
        127: (80, "Water", 100, 15, True, "20% flinch"),
        128: (35, "Water", 85, 10, False, "Trap 4-5 turns"),
        129: (60, "Normal", 100, 20, False, "Never miss"),
        130: (130, "Normal", 100, 10, True, "2-turn"),
        131: (15, "Normal", 100, 15, True, "2-5 hits"),
        132: (10, "Normal", 100, 35, False, "10% lower speed"),
        133: (0, "Psychic", 100, 20, False, "SpD +2"),
        134: (0, "Psychic", 80, 15, False, "Lower accuracy"),
        135: (0, "Normal", 100, 10, False, "Heal 50%"),
        136: (130, "Fighting", 90, 10, True, "Crash damage on miss"),
        137: (0, "Normal", 100, 30, False, "Paralyze"),
        138: (100, "Psychic", 100, 15, False, "Need sleep target"),
        139: (0, "Poison", 90, 40, False, "Poison"),
        140: (15, "Normal", 85, 20, True, "2-5 hits"),
        141: (20, "Bug", 100, 15, True, "Drain"),
        142: (0, "Normal", 75, 10, False, "Sleep"),
        143: (140, "Flying", 90, 5, True, "2-turn, high crit"),
        144: (0, "Normal", 100, 10, False, "Transform"),
        145: (20, "Water", 100, 30, False, "10% lower speed"),
        146: (70, "Normal", 100, 10, True, "20% confuse"),
        147: (0, "Grass", 100, 15, False, "Sleep"),
        148: (0, "Normal", 100, 20, False, "Lower accuracy"),
        149: (0, "Psychic", 100, 15, False, "1-1.5x level damage"),
        150: (0, "Normal", 100, 40, False, "No effect"),
        151: (0, "Poison", 100, 40, False, "Defense +2"),
        152: (100, "Water", 90, 10, True, "High crit"),
        153: (250, "Normal", 100, 5, True, "User faints"),
        154: (18, "Normal", 80, 15, True, "2-5 hits"),
        155: (50, "Ground", 90, 10, True, "2 hits"),
        156: (0, "Psychic", 100, 10, False, "Sleep 2 turns"),
        157: (75, "Rock", 90, 10, True, "30% flinch"),
        158: (80, "Normal", 90, 15, True, "10% flinch"),
        159: (0, "Normal", 100, 30, False, "Attack +1"),
        160: (0, "Normal", 100, 30, False, "Change type"),
        161: (80, "Normal", 100, 10, False, "20% status"),
        162: (0, "Normal", 90, 10, True, "Half HP damage"),
        163: (70, "Normal", 100, 20, True, "High crit"),
        164: (0, "Normal", 100, 10, False, "Substitute"),
        165: (50, "Normal", 100, 10, True, "Always usable"),
        166: (0, "Normal", 100, 1, False, "Sketch"),
        167: (10, "Fighting", 90, 10, True, "2-3 hits"),
        168: (40, "Dark", 100, 10, True, "Steal item"),
        169: (0, "Bug", 100, 10, False, "Prevent escape"),
        170: (0, "Normal", 100, 5, False, "Next hit sure"),
        171: (0, "Ghost", 100, 15, False, "Nightmare"),
        172: (60, "Fire", 100, 25, True, "20% burn"),
        173: (40, "Normal", 100, 15, False, "Use while asleep"),
        174: (0, "Ghost", 100, 10, False, "Curse"),
        175: (0, "Normal", 100, 15, True, "More damage at low HP"),
        176: (0, "Normal", 100, 30, False, "Change type"),
        177: (100, "Flying", 95, 5, False, "High crit"),
        178: (0, "Grass", 100, 40, False, "Lower speed -2"),
        179: (0, "Fighting", 100, 15, True, "More damage at low HP"),
        180: (0, "Ghost", 100, 5, False, "Remove PP"),
        181: (40, "Ice", 100, 25, False, "10% freeze"),
        182: (0, "Normal", 100, 10, False, "Protect"),
        183: (40, "Fighting", 100, 30, True, "Priority +1"),
        184: (0, "Normal", 100, 10, False, "Lower speed -2"),
        185: (60, "Dark", 100, 20, True, "Never miss"),
        186: (0, "Normal", 75, 10, False, "Confuse"),
        187: (0, "Normal", 100, 10, False, "Attack to max"),
        188: (90, "Poison", 100, 10, False, "30% poison"),
        189: (20, "Ground", 100, 10, False, "Lower accuracy"),
        190: (65, "Water", 85, 10, False, "50% lower accuracy"),
        191: (0, "Ground", 100, 20, False, "Spikes"),
        192: (100, "Electric", 50, 5, False, "100% paralyze"),
        193: (0, "Normal", 100, 40, False, "Identify target"),
        194: (0, "Ghost", 100, 5, False, "Destiny bond"),
        195: (0, "Normal", 100, 5, False, "Perish in 3 turns"),
        196: (55, "Ice", 95, 15, False, "100% lower speed"),
        197: (0, "Fighting", 100, 5, False, "Protect"),
        198: (25, "Ground", 80, 10, True, "2-5 hits"),
        199: (0, "Normal", 100, 5, False, "Next hit sure"),
        200: (90, "Dragon", 100, 15, True, "2-3 turns, confuse"),
        201: (0, "Rock", 100, 10, False, "Sandstorm"),
        202: (60, "Grass", 100, 5, False, "Drain"),
        203: (0, "Normal", 100, 10, False, "Endure"),
        204: (0, "Normal", 100, 20, False, "Lower attack -2"),
        205: (30, "Rock", 90, 20, True, "Doubles each turn"),
        206: (40, "Normal", 100, 40, True, "Leave 1 HP"),
        207: (0, "Normal", 90, 15, False, "Confuse, attack +2"),
        208: (0, "Normal", 100, 10, False, "Heal 50%"),
        209: (65, "Electric", 100, 20, True, "30% paralyze"),
        210: (10, "Bug", 95, 20, True, "Doubles each turn"),
        211: (70, "Steel", 90, 25, True, "10% raise defense"),
        212: (0, "Normal", 100, 5, False, "Prevent escape"),
        213: (0, "Normal", 100, 15, False, "Infatuate"),
        214: (0, "Normal", 100, 10, False, "Use while asleep"),
        215: (0, "Normal", 100, 5, False, "Heal status"),
        216: (0, "Normal", 100, 20, True, "Happiness damage"),
        217: (0, "Normal", 90, 15, True, "Random damage"),
        218: (0, "Normal", 100, 20, True, "Reverse happiness"),
        219: (0, "Normal", 100, 25, False, "Safeguard"),
        220: (0, "Normal", 100, 20, False, "Split HP"),
        221: (100, "Fire", 95, 5, True, "50% burn"),
        222: (0, "Ground", 100, 30, True, "Magnitude"),
        223: (100, "Fighting", 50, 5, True, "100% confuse"),
        224: (120, "Bug", 85, 10, True, ""),
        225: (60, "Dragon", 100, 20, False, "30% flinch"),
        226: (0, "Normal", 100, 40, False, "Pass stats"),
        227: (0, "Normal", 100, 5, False, "Encore"),
        228: (40, "Dark", 100, 20, True, "Double if switch"),
        229: (20, "Normal", 100, 40, True, "Remove hazards"),
        230: (0, "Normal", 100, 20, False, "Lower evasion -2"),
        231: (100, "Steel", 75, 15, True, "30% lower defense"),
        232: (50, "Steel", 95, 35, True, "10% raise attack"),
        233: (70, "Fighting", 100, 10, True, "Never miss"),
        234: (0, "Normal", 100, 5, False, "Heal 50%"),
        235: (0, "Grass", 100, 5, False, "Heal 50%"),
        236: (0, "Normal", 100, 5, False, "Heal 50%"),
        237: (60, "Normal", 100, 15, False, "Random type"),
        238: (100, "Fighting", 80, 5, True, "High crit"),
        239: (40, "Dragon", 100, 20, False, "20% flinch"),
        240: (0, "Water", 100, 5, False, "Rain"),
        241: (0, "Fire", 100, 5, False, "Sun"),
        242: (80, "Dark", 100, 15, True, "20% lower defense"),
        243: (0, "Psychic", 100, 20, False, "Counter special"),
        244: (0, "Normal", 100, 10, False, "Copy stats"),
        245: (80, "Normal", 100, 5, True, "Priority +2"),
        246: (60, "Rock", 100, 5, False, "10% all stats +1"),
        247: (80, "Ghost", 100, 15, False, "20% lower SpD"),
        248: (80, "Psychic", 90, 15, False, "2-3 turns later"),
        249: (20, "Fighting", 100, 15, True, "50% lower defense"),
        250: (15, "Water", 70, 15, False, "Trap 2-5 turns"),
        251: (10, "Dark", 100, 10, True, "Hits per party member")
    }
    
    # Pokemon names
    POKEMON_NAMES = {
        1: "Bulbasaur", 2: "Ivysaur", 3: "Venusaur", 4: "Charmander", 5: "Charmeleon",
        6: "Charizard", 7: "Squirtle", 8: "Wartortle", 9: "Blastoise", 10: "Caterpie",
        11: "Metapod", 12: "Butterfree", 13: "Weedle", 14: "Kakuna", 15: "Beedrill",
        16: "Pidgey", 17: "Pidgeotto", 18: "Pidgeot", 19: "Rattata", 20: "Raticate",
        21: "Spearow", 22: "Fearow", 23: "Ekans", 24: "Arbok", 25: "Pikachu",
        26: "Raichu", 27: "Sandshrew", 28: "Sandslash", 29: "Nidoran♀", 30: "Nidorina",
        31: "Nidoqueen", 32: "Nidoran♂", 33: "Nidorino", 34: "Nidoking", 35: "Clefairy",
        36: "Clefable", 37: "Vulpix", 38: "Ninetales", 39: "Jigglypuff", 40: "Wigglytuff",
        41: "Zubat", 42: "Golbat", 43: "Oddish", 44: "Gloom", 45: "Vileplume",
        46: "Paras", 47: "Parasect", 48: "Venonat", 49: "Venomoth", 50: "Diglett",
        51: "Dugtrio", 52: "Meowth", 53: "Persian", 54: "Psyduck", 55: "Golduck",
        56: "Mankey", 57: "Primeape", 58: "Growlithe", 59: "Arcanine", 60: "Poliwag",
        61: "Poliwhirl", 62: "Poliwrath", 63: "Abra", 64: "Kadabra", 65: "Alakazam",
        66: "Machop", 67: "Machoke", 68: "Machamp", 69: "Bellsprout", 70: "Weepinbell",
        71: "Victreebel", 72: "Tentacool", 73: "Tentacruel", 74: "Geodude", 75: "Graveler",
        76: "Golem", 77: "Ponyta", 78: "Rapidash", 79: "Slowpoke", 80: "Slowbro",
        81: "Magnemite", 82: "Magneton", 83: "Farfetch'd", 84: "Doduo", 85: "Dodrio",
        86: "Seel", 87: "Dewgong", 88: "Grimer", 89: "Muk", 90: "Shellder",
        91: "Cloyster", 92: "Gastly", 93: "Haunter", 94: "Gengar", 95: "Onix",
        96: "Drowzee", 97: "Hypno", 98: "Krabby", 99: "Kingler", 100: "Voltorb",
        101: "Electrode", 102: "Exeggcute", 103: "Exeggutor", 104: "Cubone", 105: "Marowak",
        106: "Hitmonlee", 107: "Hitmonchan", 108: "Lickitung", 109: "Koffing", 110: "Weezing",
        111: "Rhyhorn", 112: "Rhydon", 113: "Chansey", 114: "Tangela", 115: "Kangaskhan",
        116: "Horsea", 117: "Seadra", 118: "Goldeen", 119: "Seaking", 120: "Staryu",
        121: "Starmie", 122: "Mr. Mime", 123: "Scyther", 124: "Jynx", 125: "Electabuzz",
        126: "Magmar", 127: "Pinsir", 128: "Tauros", 129: "Magikarp", 130: "Gyarados",
        131: "Lapras", 132: "Ditto", 133: "Eevee", 134: "Vaporeon", 135: "Jolteon",
        136: "Flareon", 137: "Porygon", 138: "Omanyte", 139: "Omastar", 140: "Kabuto",
        141: "Kabutops", 142: "Aerodactyl", 143: "Snorlax", 144: "Articuno", 145: "Zapdos",
        146: "Moltres", 147: "Dratini", 148: "Dragonair", 149: "Dragonite", 150: "Mewtwo",
        151: "Mew", 152: "Chikorita", 153: "Bayleef", 154: "Meganium", 155: "Cyndaquil",
        156: "Quilava", 157: "Typhlosion", 158: "Totodile", 159: "Croconaw", 160: "Feraligatr",
        161: "Sentret", 162: "Furret", 163: "Hoothoot", 164: "Noctowl", 165: "Ledyba",
        166: "Ledian", 167: "Spinarak", 168: "Ariados", 169: "Crobat", 170: "Chinchou",
        171: "Lanturn", 172: "Pichu", 173: "Cleffa", 174: "Igglybuff", 175: "Togepi",
        176: "Togetic", 177: "Natu", 178: "Xatu", 179: "Mareep", 180: "Flaaffy",
        181: "Ampharos", 182: "Bellossom", 183: "Marill", 184: "Azumarill", 185: "Sudowoodo",
        186: "Politoed", 187: "Hoppip", 188: "Skiploom", 189: "Jumpluff", 190: "Aipom",
        191: "Sunkern", 192: "Sunflora", 193: "Yanma", 194: "Wooper", 195: "Quagsire",
        196: "Espeon", 197: "Umbreon", 198: "Murkrow", 199: "Slowking", 200: "Misdreavus",
        201: "Unown", 202: "Wobbuffet", 203: "Girafarig", 204: "Pineco", 205: "Forretress",
        206: "Dunsparce", 207: "Gligar", 208: "Steelix", 209: "Snubbull", 210: "Granbull",
        211: "Qwilfish", 212: "Scizor", 213: "Shuckle", 214: "Heracross", 215: "Sneasel",
        216: "Teddiursa", 217: "Ursaring", 218: "Slugma", 219: "Magcargo", 220: "Swinub",
        221: "Piloswine", 222: "Corsola", 223: "Remoraid", 224: "Octillery", 225: "Delibird",
        226: "Mantine", 227: "Skarmory", 228: "Houndour", 229: "Houndoom", 230: "Kingdra",
        231: "Phanpy", 232: "Donphan", 233: "Porygon2", 234: "Stantler", 235: "Smeargle",
        236: "Tyrogue", 237: "Hitmontop", 238: "Smoochum", 239: "Elekid", 240: "Magby",
        241: "Miltank", 242: "Blissey", 243: "Raikou", 244: "Entei", 245: "Suicune",
        246: "Larvitar", 247: "Pupitar", 248: "Tyranitar", 249: "Lugia", 250: "Ho-Oh",
        251: "Celebi"
    }
    
    def __init__(self, root):
        self.root = root
        self.root.title("🎮 Pokemon Crystal Tier Calculator - Manual Move Selection")
        self.root.geometry("1400x900")
        
        self.rom_path = None
        self.rom_data = None
        self.current_pokemon = None
        self.selected_moves = []
        
        self.create_widgets()
        
    def create_widgets(self):
        """Create the GUI layout"""
        # Main container
        main_frame = ttk.Frame(self.root, padding="10")
        main_frame.pack(fill=tk.BOTH, expand=True)
        
        # Header
        header_frame = ttk.Frame(main_frame)
        header_frame.pack(fill=tk.X, pady=(0, 10))
        
        ttk.Label(header_frame, text="Pokemon Crystal Tier Calculator", 
                 font=("Arial", 16, "bold")).pack(side=tk.LEFT)
        
        ttk.Button(header_frame, text="Load ROM", command=self.load_rom,
                  style="Accent.TButton").pack(side=tk.RIGHT, padx=5)
        
        ttk.Button(header_frame, text="Load Party", command=self.load_party_data,
                  style="Accent.TButton").pack(side=tk.RIGHT, padx=5)
        
        self.rom_label = ttk.Label(header_frame, text="No ROM loaded", foreground="gray")
        self.rom_label.pack(side=tk.RIGHT, padx=10)
        
        # Search frame
        search_frame = ttk.LabelFrame(main_frame, text="Select Pokemon", padding="10")
        search_frame.pack(fill=tk.X, pady=(0, 10))
        
        # Search by number
        ttk.Label(search_frame, text="Dex #:").grid(row=0, column=0, sticky=tk.W, padx=5)
        self.dex_var = tk.StringVar()
        dex_entry = ttk.Entry(search_frame, textvariable=self.dex_var, width=10)
        dex_entry.grid(row=0, column=1, padx=5)
        
        # Search by name
        ttk.Label(search_frame, text="Name:").grid(row=0, column=2, sticky=tk.W, padx=5)
        self.name_var = tk.StringVar()
        name_combo = ttk.Combobox(search_frame, textvariable=self.name_var, width=20)
        name_combo['values'] = [f"{num}: {name}" for num, name in self.POKEMON_NAMES.items()]
        name_combo.grid(row=0, column=3, padx=5)
        
        ttk.Button(search_frame, text="Load Pokemon", command=self.search_pokemon).grid(row=0, column=4, padx=10)
        ttk.Button(search_frame, text="Random", command=self.random_pokemon).grid(row=0, column=5, padx=5)
        
        # Main content area with three columns
        content_frame = ttk.Frame(main_frame)
        content_frame.pack(fill=tk.BOTH, expand=True)
        
        # Left panel - Pokemon info
        left_panel = ttk.LabelFrame(content_frame, text="Pokemon Data", padding="10")
        left_panel.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=(0, 5))
        
        # Basic info
        self.info_frame = ttk.Frame(left_panel)
        self.info_frame.pack(fill=tk.X, pady=(0, 10))
        
        # Stats display
        self.stats_frame = ttk.LabelFrame(left_panel, text="Base Stats", padding="10")
        self.stats_frame.pack(fill=tk.X, pady=(0, 10))
        
        # Type effectiveness
        self.type_frame = ttk.LabelFrame(left_panel, text="Type Matchups", padding="10")
        self.type_frame.pack(fill=tk.BOTH, expand=True)
        
        # Middle panel - Move selection
        middle_panel = ttk.LabelFrame(content_frame, text="Move Selection", padding="10")
        middle_panel.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=5)
        
        # Instructions
        ttk.Label(middle_panel, text="Select up to 4 moves:", font=("Arial", 10, "bold")).pack()
        
        # Search box for moves
        search_move_frame = ttk.Frame(middle_panel)
        search_move_frame.pack(fill=tk.X, pady=5)
        
        ttk.Label(search_move_frame, text="Search:").pack(side=tk.LEFT, padx=5)
        self.move_search_var = tk.StringVar()
        self.move_search_var.trace('w', self.filter_moves)
        search_entry = ttk.Entry(search_move_frame, textvariable=self.move_search_var)
        search_entry.pack(side=tk.LEFT, fill=tk.X, expand=True, padx=5)
        
        # Move list with scrollbar
        move_list_frame = ttk.Frame(middle_panel)
        move_list_frame.pack(fill=tk.BOTH, expand=True, pady=5)
        
        scrollbar = ttk.Scrollbar(move_list_frame)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        
        self.move_listbox = tk.Listbox(move_list_frame, height=15, selectmode=tk.SINGLE,
                                       yscrollcommand=scrollbar.set)
        self.move_listbox.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        scrollbar.config(command=self.move_listbox.yview)
        
        # Populate move list
        self.all_moves = []
        for move_id, move_name in sorted(MOVE_NAMES.items()):
            if move_id in self.MOVE_DATA:
                power, type_, acc, pp, is_phys, effect = self.MOVE_DATA[move_id]
                display_text = f"{move_name} ({type_}, Pow: {power})"
                self.move_listbox.insert(tk.END, display_text)
                self.all_moves.append((move_id, move_name, display_text))
            else:
                display_text = f"{move_name} (???)"
                self.move_listbox.insert(tk.END, display_text)
                self.all_moves.append((move_id, move_name, display_text))
        
        # Buttons
        button_frame = ttk.Frame(middle_panel)
        button_frame.pack(fill=tk.X, pady=5)
        
        ttk.Button(button_frame, text="Add Move →", command=self.add_move).pack(side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="← Remove", command=self.remove_move).pack(side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="Clear All", command=self.clear_moves).pack(side=tk.LEFT, padx=5)
        
        # Selected moves
        ttk.Label(middle_panel, text="Selected Moves:", font=("Arial", 10, "bold")).pack(pady=(10, 5))
        
        self.selected_moves_frame = ttk.Frame(middle_panel)
        self.selected_moves_frame.pack(fill=tk.BOTH, expand=True)
        
        # Right panel - Tier rating
        right_panel = ttk.LabelFrame(content_frame, text="Tier Analysis", padding="10")
        right_panel.pack(side=tk.RIGHT, fill=tk.BOTH, expand=True)
        
        self.tier_display = ttk.Frame(right_panel)
        self.tier_display.pack(fill=tk.BOTH, expand=True)
        
        # Calculate button
        self.calculate_button = ttk.Button(right_panel, text="Calculate Tier", 
                                         command=self.calculate_and_display_tier,
                                         style="Accent.TButton", state=tk.DISABLED)
        self.calculate_button.pack(side=tk.BOTTOM, pady=10)
        
        # Status bar
        self.status_var = tk.StringVar(value="Ready - Select a Pokemon to begin")
        status_bar = ttk.Label(main_frame, textvariable=self.status_var, relief=tk.SUNKEN)
        status_bar.pack(fill=tk.X, pady=(5, 0))
        
    def load_rom(self):
        """Load a ROM file"""
        filename = filedialog.askopenfilename(
            title="Select Pokemon Crystal ROM",
            filetypes=[("Game Boy ROMs", "*.gbc *.gb"), ("All files", "*.*")]
        )
        
        if filename:
            self.rom_path = Path(filename)
            self.rom_data = self.rom_path.read_bytes()
            self.rom_label.config(text=self.rom_path.name, foreground="black")
            self.status_var.set(f"Loaded: {self.rom_path.name}")
            
    def load_party_data(self):
        """Load party data from BizHawk export"""
        party_file = Path("party_data.json")
        if not party_file.exists():
            messagebox.showerror("Error", "No party data found!\n\nRun party_exporter.lua in BizHawk first.")
            return
            
        try:
            with open(party_file, 'r') as f:
                party_data = json.load(f)
                
            self.status_var.set(f"Loaded party data: {party_data['count']} Pokemon")
            self.show_party_selection(party_data)
            
        except Exception as e:
            messagebox.showerror("Error", f"Failed to load party data: {str(e)}")
            
    def show_party_selection(self, party_data):
        """Show dialog to select Pokemon from party"""
        dialog = tk.Toplevel(self.root)
        dialog.title("Select Pokemon from Party")
        dialog.geometry("400x300")
        
        ttk.Label(dialog, text="Your Current Party:", font=("Arial", 12, "bold")).pack(pady=10)
        
        listbox = tk.Listbox(dialog, height=6, font=("Arial", 11))
        listbox.pack(pady=10, padx=20, fill=tk.BOTH, expand=True)
        
        for poke in party_data['pokemon']:
            name = self.POKEMON_NAMES.get(poke['species'], f"Unknown #{poke['species']}")
            listbox.insert(tk.END, f"Slot {poke['slot']}: {name} Lv.{poke['level']}")
            
        def select_pokemon():
            selection = listbox.curselection()
            if selection:
                idx = selection[0]
                pokemon = party_data['pokemon'][idx]
                dialog.destroy()
                self.display_party_pokemon(pokemon)
                
        ttk.Button(dialog, text="Select", command=select_pokemon).pack(pady=10)
        
    def display_party_pokemon(self, party_poke):
        """Display party Pokemon and pre-select their moves"""
        # Set the dex number
        self.dex_var.set(str(party_poke['species']))
        
        # Load the Pokemon
        self.search_pokemon()
        
        # Pre-select their current moves
        self.clear_moves()
        for move_id in party_poke['moves']:
            if move_id > 0:
                # Find and select this move
                for i, (mid, mname, display) in enumerate(self.all_moves):
                    if mid == move_id:
                        self.move_listbox.selection_clear(0, tk.END)
                        self.move_listbox.selection_set(i)
                        self.move_listbox.see(i)
                        self.add_move()
                        break
                        
    def filter_moves(self, *args):
        """Filter move list based on search"""
        search_term = self.move_search_var.get().lower()
        
        self.move_listbox.delete(0, tk.END)
        for move_id, move_name, display_text in self.all_moves:
            if search_term in move_name.lower() or search_term in display_text.lower():
                self.move_listbox.insert(tk.END, display_text)
                
    def search_pokemon(self):
        """Search for a Pokemon by number or name"""
        if not self.rom_data:
            messagebox.showerror("Error", "Please load a ROM first")
            return
            
        # Try to get dex number
        dex_num = None
        
        if self.dex_var.get():
            try:
                dex_num = int(self.dex_var.get())
            except ValueError:
                messagebox.showerror("Error", "Invalid dex number")
                return
                
        elif self.name_var.get():
            # Extract number from combo selection
            try:
                dex_num = int(self.name_var.get().split(":")[0])
            except:
                # Try to find by name
                name = self.name_var.get().strip()
                for num, pname in self.POKEMON_NAMES.items():
                    if pname.lower() == name.lower():
                        dex_num = num
                        break
                        
        if not dex_num or dex_num < 1 or dex_num > 251:
            messagebox.showerror("Error", "Please enter a valid Pokemon (1-251)")
            return
            
        self.display_pokemon(dex_num)
        
    def random_pokemon(self):
        """Display a random Pokemon"""
        if not self.rom_data:
            messagebox.showerror("Error", "Please load a ROM first")
            return
            
        dex_num = random.randint(1, 251)
        self.dex_var.set(str(dex_num))
        self.display_pokemon(dex_num)
        
    def read_pokemon_data(self, dex_num: int) -> Dict:
        """Read Pokemon data from ROM"""
        offset = self.POKEMON_DATA_BASE + ((dex_num - 1) * self.POKEMON_SIZE)
        
        if offset + self.POKEMON_SIZE > len(self.rom_data):
            raise ValueError("Pokemon data beyond ROM size")
            
        data = struct.unpack('BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB', 
                           self.rom_data[offset:offset + self.POKEMON_SIZE])
        
        pokemon = {
            'dex_num': dex_num,
            'name': self.POKEMON_NAMES.get(dex_num, f"Pokemon #{dex_num}"),
            'hp': data[1],
            'attack': data[2],
            'defense': data[3],
            'speed': data[4],
            'sp_attack': data[5],
            'sp_defense': data[6],
            'type1': data[7],
            'type2': data[8],
            'catch_rate': data[9],
            'base_exp': data[10],
        }
        
        # Calculate BST
        pokemon['bst'] = sum([pokemon['hp'], pokemon['attack'], pokemon['defense'],
                             pokemon['speed'], pokemon['sp_attack'], pokemon['sp_defense']])
        
        return pokemon
        
    def display_pokemon(self, dex_num: int):
        """Display Pokemon information"""
        try:
            pokemon = self.read_pokemon_data(dex_num)
            self.current_pokemon = pokemon
            
            # Clear previous displays
            for widget in self.info_frame.winfo_children():
                widget.destroy()
            for widget in self.stats_frame.winfo_children():
                widget.destroy()
            for widget in self.type_frame.winfo_children():
                widget.destroy()
            for widget in self.tier_display.winfo_children():
                widget.destroy()
                
            # Clear selected moves
            self.clear_moves()
                
            # Basic info
            info_text = f"#{pokemon['dex_num']:03d} {pokemon['name']}"
            ttk.Label(self.info_frame, text=info_text, font=("Arial", 14, "bold")).pack()
            
            # Types
            type1_name = self.TYPES.get(pokemon['type1'], f"Type {pokemon['type1']}")
            type2_name = self.TYPES.get(pokemon['type2'], f"Type {pokemon['type2']}")
            
            if pokemon['type1'] == pokemon['type2']:
                type_text = f"Type: {type1_name}"
            else:
                type_text = f"Types: {type1_name} / {type2_name}"
                
            ttk.Label(self.info_frame, text=type_text, font=("Arial", 11)).pack()
            ttk.Label(self.info_frame, text=f"BST: {pokemon['bst']}", font=("Arial", 11)).pack()
            
            # Stats
            self.display_stats(pokemon)
            
            # Type effectiveness
            self.display_type_matchups(pokemon)
            
            # Enable calculate button
            self.calculate_button.config(state=tk.NORMAL)
            
            self.status_var.set(f"Loaded: {pokemon['name']} - Select moves and click Calculate Tier")
            
        except Exception as e:
            messagebox.showerror("Error", f"Failed to read Pokemon data: {str(e)}")
            
    def display_stats(self, pokemon: Dict):
        """Display stat bars"""
        stats = [
            ("HP", pokemon['hp'], "#FF0000"),
            ("Attack", pokemon['attack'], "#F08030"),
            ("Defense", pokemon['defense'], "#F8D030"),
            ("Speed", pokemon['speed'], "#78C850"),
            ("Sp.Atk", pokemon['sp_attack'], "#6890F0"),
            ("Sp.Def", pokemon['sp_defense'], "#F85888")
        ]
        
        for i, (stat_name, value, color) in enumerate(stats):
            # Stat name and value
            ttk.Label(self.stats_frame, text=f"{stat_name}:").grid(row=i, column=0, sticky=tk.W, padx=5, pady=2)
            ttk.Label(self.stats_frame, text=str(value), width=5).grid(row=i, column=1, padx=5, pady=2)
            
            # Stat bar
            bar_frame = ttk.Frame(self.stats_frame)
            bar_frame.grid(row=i, column=2, sticky=tk.W+tk.E, padx=5, pady=2)
            
            # Create canvas for bar
            canvas = tk.Canvas(bar_frame, height=20, width=200, highlightthickness=0)
            canvas.pack(fill=tk.X, expand=True)
            
            # Draw bar
            bar_width = (value / 255) * 200  # Max stat is 255
            canvas.create_rectangle(0, 0, bar_width, 20, fill=color, outline="")
            canvas.create_rectangle(0, 0, 200, 20, outline="gray")
            
        # Configure grid weights
        self.stats_frame.grid_columnconfigure(2, weight=1)
        
    def display_type_matchups(self, pokemon: Dict):
        """Display type effectiveness"""
        type1_name = self.TYPES.get(pokemon['type1'], "Unknown")
        type2_name = self.TYPES.get(pokemon['type2'], "Unknown") if pokemon['type1'] != pokemon['type2'] else None
        
        # Calculate offensive coverage
        offensive_label = ttk.Label(self.type_frame, text="Offensive Coverage:", font=("Arial", 10, "bold"))
        offensive_label.pack(anchor=tk.W)
        
        super_effective = []
        not_very_effective = []
        
        for defender_type, effectiveness in self.TYPE_EFFECTIVENESS.get(type1_name, {}).items():
            if effectiveness > 1:
                super_effective.append(defender_type)
            elif effectiveness < 1 and effectiveness > 0:
                not_very_effective.append(defender_type)
                
        if type2_name and type2_name in self.TYPE_EFFECTIVENESS:
            for defender_type, effectiveness in self.TYPE_EFFECTIVENESS.get(type2_name, {}).items():
                if effectiveness > 1 and defender_type not in super_effective:
                    super_effective.append(defender_type)
                    
        if super_effective:
            ttk.Label(self.type_frame, text=f"  Super Effective vs: {', '.join(super_effective[:8])}", 
                     foreground="green", wraplength=250, justify=tk.LEFT).pack(anchor=tk.W)
        if not_very_effective:
            ttk.Label(self.type_frame, text=f"  Not Very Effective vs: {', '.join(not_very_effective[:8])}", 
                     foreground="red", wraplength=250, justify=tk.LEFT).pack(anchor=tk.W)
                     
        # Calculate defensive matchups
        ttk.Label(self.type_frame, text="\nDefensive Matchups:", font=("Arial", 10, "bold")).pack(anchor=tk.W)
        
        weaknesses = []
        resistances = []
        immunities = []
        
        # Check all types against this Pokemon
        for attacker_type, matchups in self.TYPE_EFFECTIVENESS.items():
            effectiveness = matchups.get(type1_name, 1.0)
            if type2_name:
                effectiveness *= matchups.get(type2_name, 1.0)
                
            if effectiveness > 1:
                weaknesses.append(attacker_type)
            elif effectiveness < 1 and effectiveness > 0:
                resistances.append(attacker_type)
            elif effectiveness == 0:
                immunities.append(attacker_type)
                
        if weaknesses:
            ttk.Label(self.type_frame, text=f"  Weak to: {', '.join(weaknesses[:8])}", 
                     foreground="red", wraplength=250, justify=tk.LEFT).pack(anchor=tk.W)
        if resistances:
            ttk.Label(self.type_frame, text=f"  Resists: {', '.join(resistances[:8])}", 
                     foreground="green", wraplength=250, justify=tk.LEFT).pack(anchor=tk.W)
        if immunities:
            ttk.Label(self.type_frame, text=f"  Immune to: {', '.join(immunities)}", 
                     foreground="blue", wraplength=250, justify=tk.LEFT).pack(anchor=tk.W)
                     
    def add_move(self):
        """Add selected move to Pokemon's moveset"""
        selection = self.move_listbox.curselection()
        if not selection:
            return
            
        if len(self.selected_moves) >= 4:
            messagebox.showwarning("Warning", "Pokemon can only have 4 moves!")
            return
            
        # Get the selected move
        selected_text = self.move_listbox.get(selection[0])
        
        # Find the move ID
        move_id = None
        for mid, mname, display in self.all_moves:
            if display == selected_text:
                move_id = mid
                break
                
        if move_id and move_id not in [m[0] for m in self.selected_moves]:
            self.selected_moves.append((move_id, MOVE_NAMES[move_id]))
            self.update_selected_moves_display()
            
    def remove_move(self):
        """Remove a move from the selected list"""
        if not self.selected_moves:
            return
            
        # Simple approach: remove the last move
        self.selected_moves.pop()
        self.update_selected_moves_display()
        
    def clear_moves(self):
        """Clear all selected moves"""
        self.selected_moves = []
        self.update_selected_moves_display()
        
    def update_selected_moves_display(self):
        """Update the display of selected moves"""
        # Clear previous display
        for widget in self.selected_moves_frame.winfo_children():
            widget.destroy()
            
        if not self.selected_moves:
            ttk.Label(self.selected_moves_frame, text="No moves selected", 
                     foreground="gray").pack(pady=20)
            return
            
        # Display each selected move
        for i, (move_id, move_name) in enumerate(self.selected_moves):
            move_frame = ttk.Frame(self.selected_moves_frame)
            move_frame.pack(fill=tk.X, pady=2)
            
            # Move slot and name
            ttk.Label(move_frame, text=f"{i+1}. {move_name}", 
                     font=("Arial", 10, "bold")).pack(side=tk.LEFT, padx=5)
            
            # Move details if available
            if move_id in self.MOVE_DATA:
                power, type_, acc, pp, is_phys, effect = self.MOVE_DATA[move_id]
                details = f"({type_}, Pow: {power}, Acc: {acc}%)"
                ttk.Label(move_frame, text=details, foreground="gray").pack(side=tk.LEFT, padx=10)
                
        # Show how many moves selected
        count_text = f"{len(self.selected_moves)}/4 moves selected"
        ttk.Label(self.selected_moves_frame, text=count_text, 
                 font=("Arial", 9), foreground="blue").pack(pady=(10, 0))
                 
    def calculate_and_display_tier(self):
        """Calculate and display the tier rating"""
        if not self.current_pokemon:
            messagebox.showerror("Error", "Please select a Pokemon first")
            return
            
        # Clear previous tier display
        for widget in self.tier_display.winfo_children():
            widget.destroy()
            
        # Calculate tier
        tier, total_score, breakdown, color = self.calculate_tier(self.current_pokemon)
        
        # Tier display
        tier_label = ttk.Label(self.tier_display, text=f"Tier: {tier}", 
                              font=("Arial", 24, "bold"), foreground=color)
        tier_label.pack(pady=10)
        
        score_label = ttk.Label(self.tier_display, text=f"Score: {total_score:.1f}/100",
                               font=("Arial", 14))
        score_label.pack()
        
        # Move count indicator
        move_count = len(self.selected_moves)
        move_text = f"Based on {move_count} moves"
        ttk.Label(self.tier_display, text=move_text, font=("Arial", 10), 
                 foreground="gray").pack()
        
        # Breakdown
        ttk.Label(self.tier_display, text="\nScore Breakdown:", 
                 font=("Arial", 12, "bold")).pack(pady=(20, 10))
        
        breakdown_frame = ttk.Frame(self.tier_display)
        breakdown_frame.pack(fill=tk.X, padx=20)
        
        for category, score in breakdown.items():
            row_frame = ttk.Frame(breakdown_frame)
            row_frame.pack(fill=tk.X, pady=2)
            
            ttk.Label(row_frame, text=f"{category}:", width=10).pack(side=tk.LEFT)
            
            # Progress bar
            progress = ttk.Progressbar(row_frame, length=150, mode='determinate')
            progress['value'] = (score / (total_score / 100)) * 100 if total_score > 0 else 0
            progress.pack(side=tk.LEFT, padx=10)
            
            ttk.Label(row_frame, text=f"{score:.1f}").pack(side=tk.LEFT)
            
        # Analysis text
        ttk.Label(self.tier_display, text="\nAnalysis:", 
                 font=("Arial", 12, "bold")).pack(pady=(20, 10))
        
        analysis_frame = ttk.Frame(self.tier_display)
        analysis_frame.pack(fill=tk.BOTH, expand=True, padx=20)
        
        analysis_text = self.generate_analysis(self.current_pokemon, tier, breakdown)
        
        analysis_label = ttk.Label(analysis_frame, text=analysis_text, 
                                  wraplength=300, justify=tk.LEFT)
        analysis_label.pack(anchor=tk.W)
        
        self.status_var.set(f"Tier calculated: {tier} ({total_score:.1f}/100)")
        
    def calculate_tier(self, pokemon: Dict) -> Tuple[str, float, Dict, str]:
        """Calculate tier rating based on stats and selected moves"""
        scores = {}
        
        # 1. Base Stat Total (20% weight)
        bst_score = min((pokemon['bst'] - 200) / 4, 100)
        scores['BST'] = bst_score * 0.20
        
        # 2. Speed Tier (25% weight)
        speed = pokemon['speed']
        if speed >= 120:
            speed_score = 100
        elif speed >= 100:
            speed_score = 90
        elif speed >= 80:
            speed_score = 75
        elif speed >= 60:
            speed_score = 50
        elif speed >= 40:
            speed_score = 25
        else:
            speed_score = 10
        scores['Speed'] = speed_score * 0.25
        
        # 3. Offensive Potential (15% weight)
        offensive_stats = max(pokemon['attack'], pokemon['sp_attack'])
        offensive_score = min(offensive_stats / 1.5, 100)
        scores['Offense'] = offensive_score * 0.15
        
        # 4. Defensive Bulk (15% weight)
        bulk = (pokemon['hp'] + pokemon['defense'] + pokemon['sp_defense']) / 3
        bulk_score = min(bulk / 1.2, 100)
        scores['Bulk'] = bulk_score * 0.15
        
        # 5. Type Quality (10% weight)
        type_score = self.evaluate_type_quality(pokemon)
        scores['Type'] = type_score * 0.10
        
        # 6. Movepool Quality (15% weight) - Based on selected moves
        movepool_score = self.analyze_selected_moves(pokemon)
        scores['Moves'] = movepool_score * 0.15
        
        # Calculate total
        total_score = sum(scores.values())
        
        # Determine tier
        if total_score >= 85:
            tier = "S"
            color = "#FF0000"
        elif total_score >= 70:
            tier = "A"
            color = "#FF8C00"
        elif total_score >= 55:
            tier = "B"
            color = "#FFD700"
        elif total_score >= 40:
            tier = "C"
            color = "#00FF00"
        elif total_score >= 25:
            tier = "D"
            color = "#00CED1"
        else:
            tier = "F"
            color = "#808080"
            
        return tier, total_score, scores, color
        
    def evaluate_type_quality(self, pokemon: Dict) -> float:
        """Evaluate how good a type combination is"""
        type1_name = self.TYPES.get(pokemon['type1'], "Unknown")
        type2_name = self.TYPES.get(pokemon['type2'], "Unknown") if pokemon['type1'] != pokemon['type2'] else None
        
        # Base scores for types
        type_scores = {
            "Dragon": 90, "Steel": 85, "Water": 80, "Ground": 75,
            "Fighting": 75, "Fire": 70, "Electric": 70, "Psychic": 65,
            "Dark": 65, "Flying": 60, "Rock": 55, "Ghost": 60,
            "Poison": 45, "Ice": 50, "Grass": 45, "Bug": 40,
            "Normal": 35, "Unknown": 30
        }
        
        score = type_scores.get(type1_name, 30)
        
        if type2_name and type2_name != type1_name:
            score = (score + type_scores.get(type2_name, 30)) / 2
            # Bonus for good dual typing
            score += 10
            
        return min(score, 100)
        
    def analyze_selected_moves(self, pokemon: Dict) -> float:
        """Analyze the quality of selected moves"""
        if not self.selected_moves:
            return 0
            
        score = 0
        damaging_moves = []
        status_moves = []
        
        # Categorize moves
        for move_id, move_name in self.selected_moves:
            if move_id in self.MOVE_DATA:
                power, type_, acc, pp, is_phys, effect = self.MOVE_DATA[move_id]
                if power > 0:
                    damaging_moves.append((move_id, power, type_, is_phys))
                else:
                    status_moves.append((move_id, move_name, effect))
                    
        # STAB moves (30 points)
        type1_name = self.TYPES.get(pokemon['type1'], "Unknown")
        type2_name = self.TYPES.get(pokemon['type2'], "Unknown")
        
        stab_moves = []
        for move_id, power, type_, is_phys in damaging_moves:
            if type_ in [type1_name, type2_name]:
                stab_moves.append((power, is_phys))
                
        if stab_moves:
            best_stab_power = max(m[0] for m in stab_moves)
            # Check if STAB matches the right attacking stat
            has_physical_stab = any(m[1] for m in stab_moves)
            has_special_stab = any(not m[1] for m in stab_moves)
            
            if best_stab_power >= 90:
                score += 30
            elif best_stab_power >= 75:
                score += 20
            elif best_stab_power >= 60:
                score += 10
            else:
                score += 5
                
            # Bonus for matching attacking stat
            if (has_physical_stab and pokemon['attack'] > pokemon['sp_attack']) or \
               (has_special_stab and pokemon['sp_attack'] > pokemon['attack']):
                score += 5
                
        # Coverage (25 points)
        coverage_types = set()
        for move_id, power, type_, is_phys in damaging_moves:
            if type_ not in [type1_name, type2_name]:
                coverage_types.add(type_)
                
        score += min(len(coverage_types) * 8, 25)
        
        # High power moves (15 points)
        power_moves = [m for m in damaging_moves if m[1] >= 90]
        score += min(len(power_moves) * 7, 15)
        
        # Status moves (15 points)
        valuable_status = ['Thunder Wave', 'Toxic', 'Swords Dance', 'Agility', 
                          'Sleep Powder', 'Spore', 'Rest', 'Protect', 'Leech seed']
        has_valuable = any(name in valuable_status for _, name, _ in status_moves)
        if has_valuable:
            score += 15
        elif status_moves:
            score += 8
            
        # Accuracy bonus (10 points)
        if damaging_moves:
            # Estimate average accuracy
            total_acc = 0
            for move_id, _, _, _ in damaging_moves:
                if move_id in self.MOVE_DATA:
                    acc = self.MOVE_DATA[move_id][2]
                    total_acc += acc
            avg_acc = total_acc / len(damaging_moves) if damaging_moves else 0
            
            if avg_acc >= 95:
                score += 10
            elif avg_acc >= 85:
                score += 5
                
        # Move count bonus (5 points)
        if len(self.selected_moves) == 4:
            score += 5
        elif len(self.selected_moves) == 3:
            score += 3
            
        return min(score, 100)
        
    def generate_analysis(self, pokemon: Dict, tier: str, breakdown: Dict) -> str:
        """Generate detailed analysis text"""
        analysis = []
        
        # Speed analysis
        speed = pokemon['speed']
        if speed >= 100:
            analysis.append("• Excellent speed tier")
        elif speed >= 80:
            analysis.append("• Good speed tier")
        elif speed >= 60:
            analysis.append("• Average speed")
        else:
            analysis.append("• Low speed - needs Trick Room")
            
        # Offensive analysis
        phys_atk = pokemon['attack']
        spec_atk = pokemon['sp_attack']
        if max(phys_atk, spec_atk) >= 110:
            analysis.append("• Powerful offensive stats")
        elif max(phys_atk, spec_atk) >= 90:
            analysis.append("• Solid offensive presence")
        elif phys_atk >= 70 and spec_atk >= 70:
            analysis.append("• Mixed attacker potential")
        else:
            analysis.append("• Limited offensive power")
            
        # Defensive analysis
        bulk_score = (pokemon['hp'] + pokemon['defense'] + pokemon['sp_defense']) / 3
        if bulk_score >= 100:
            analysis.append("• Exceptional bulk")
        elif bulk_score >= 75:
            analysis.append("• Good defensive stats")
        elif pokemon['hp'] >= 90:
            analysis.append("• High HP helps survivability")
            
        # Move analysis
        if self.selected_moves:
            analysis.append(f"• {len(self.selected_moves)} moves selected")
            
            # Check for STAB
            has_stab = False
            for move_id, _ in self.selected_moves:
                if move_id in self.MOVE_DATA:
                    _, type_, _, _, _, _ = self.MOVE_DATA[move_id]
                    type1_name = self.TYPES.get(pokemon['type1'], "Unknown")
                    type2_name = self.TYPES.get(pokemon['type2'], "Unknown")
                    if type_ in [type1_name, type2_name]:
                        has_stab = True
                        break
                        
            if not has_stab:
                analysis.append("• ⚠️ No STAB moves!")
        else:
            analysis.append("• ⚠️ No moves selected!")
            
        # Role suggestion
        if tier in ['S', 'A']:
            analysis.append(f"\n✅ Excellent for randomizers!")
        elif tier == 'B':
            analysis.append(f"\n✓ Solid choice")
        elif tier == 'C':
            analysis.append(f"\n• Usable with support")
        else:
            analysis.append(f"\n⚠️ Challenging pick")
            
        return '\n'.join(analysis)


def main():
    root = tk.Tk()
    app = PokemonTierCalculator(root)
    root.mainloop()


if __name__ == "__main__":
    main()