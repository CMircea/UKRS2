# UKRS2 Complete Context for Future Maintainers

## What This Document Is

This is a comprehensive archaeology document for the UK Railway Set 2 (UKRS2), a NewGRF train set for OpenTTD. It's written for future maintainers (human or LLM) who need to understand the codebase to fix railtype compatibility issues.

## The Core Problem UKRS2 Solves

Real British trains have complex power systems:
- **Class 73 (Type JB)**: Electro-diesel that runs on diesel by default, but upgrades to electric when 3rd rail power is available
- **Eurostar**: Dual-voltage EMU that runs faster on overhead catenary than on 3rd rail
- **Class 92**: Channel Tunnel freight locomotive using both 3rd rail and catenary

UKRS2 needs to detect what track type the train is currently on and adjust power/speed accordingly.

## The Historical Context

### Timeline (from git history and forum)

| Date | Event |
|------|-------|
| **Jan 2, 2013** | PikkaBird releases UKRS2 **v1.05** (the last official version) |
| **May 2017** | NekoMaster reports speed issues with NuTracks - trains limited to 160 km/h |
| **Feb 16, 2018** | CMircea asks PikkaBird how to fix railtype compatibility |
| **Feb 18, 2018** | PikkaBird [posts the rail table](https://www.tt-forums.net/viewtopic.php?p=1202856#p1202856) with "nutracks nonsense" labels |
| **Feb 21, 2018** | CMircea discovers GRFID change breaks A-Train wagons |
| **Feb 21, 2018 11:08** | PikkaBird's "BAD FEATURES, eh?" post with 89 25 / 8A 25 magic numbers |
| **Feb 22, 2018 23:45** | CMircea commits GRFID change (same day as PikkaBird's post!) |
| **Feb 22, 2018 23:46** | CMircea fixes 89 25 / 8A 25 wagon compatibility checks |
| **Feb 23, 2018** | CMircea releases "UKRS2 - Community Bugfixes" on BaNaNaS |
| **Sept 7, 2020** | CMircea releases **v1.06** with full standard railtype support |
| **2021** | OpenTTD 1.11 adds Variable 63 (too late for UKRS2's architecture) |

**Key insight**: The entire fork happened in ONE WEEK after PikkaBird provided guidance.

### The GRFID Change

The original GRFID was `"DD" 10 00` (hex: `44 44 10 00`). David Dallaston (credited as coder in the GRF description) requested the change to `"MCX" 00` for the community bugfix fork.

This broke wagon compatibility for A-Train and other MU vehicles.

### The Forum Thread That Made It Happen

**Thread**: [UKRS2 - tt-forums.net](https://www.tt-forums.net/viewtopic.php?t=45637) (pages 54-56)

**PikkaBird's rail table post** (Feb 18, 2018):
> Here's the rail table from UKRS2... I guess all you'd have to do is replace the 16 **"nutracks nonsense"** labels with the updated equivalents.

**CMircea discovers the GRFID trap** (Feb 21, 2018):
> It looks like if I change the GRF ID the A-Train breaks - it doesn't accept High-Speed Carriages anymore :(

**PikkaBird's response** (Feb 21, 2018 11:08):
> Oops, yeah, the MUs all check the GRFID as part of the allowed wagon check. **BAD FEATURES, eh?**
>
> The magical number to check for is "89 25" to find these sprites; if you update the GRFID there too it should fix the issue. A bunch of coach liveries also use ID checks for graphics and/or property callbacks in certain consists. "8A 25" will get you those sprites.
>
> Are you getting the feeling this is more trouble than it's worth yet?

**CMircea on NFO** (Feb 23, 2018):
> deciphering NFO without any comments is a real pain in the arse

PikkaBird knew exactly what needed fixing - he wrote the original code. See [GRFID-TRAP.md](GRFID-TRAP.md) for the full story.

## Understanding NFO Format

### NFO Is Not a Programming Language

NFO is **serialized binary data** with human-readable annotations added by grfcodec. Key insight:

```nfo
9441 * 14    02 00 37 81 4A 00 FF 01 37 00 02 20 47 00
↑      ↑     └──────────────────────────────────────┘
│      │                    Actual bytes
│      └── Size in bytes
└── Sprite number
```

The bytes are the actual data. Everything else is presentation.

### There Is No Code Reuse

NFO has no functions, no includes, no macros. If two vehicles need the same callback logic, the bytes are literally copy-pasted. This means:
- Fixing one vehicle doesn't automatically fix others
- Each affected vehicle must be found and updated individually
- "Similar" code may have subtle differences

### The "U" Artifact

When you see `"3RDRU"` in decompiled NFO, it's actually `"3RDR" + 55`:
```nfo
9491 * 9    07 00 04 0E "3RDR" 55
                       ↑↑↑↑↑  ↑↑
                       Label  Jump target (decimal 55 = ASCII 'U')
```

CMircea asked about this in the forum (Feb 19, 2018):
> What I don't understand are the sprites 9931 through 9941 - they are missing the # of sprites to jump over, as well as having a "U" at the end of the rail type. Why?

**PikkaBird's explanation** (Feb 20, 2018):
> The "U" is the byte label 55, which grfcodec has **inappropriately converted to an ASCII character**.

The actual label is "3RDR", and 55 is the Action 7 jump target (label ID to skip to).

## The Two Detection Methods

### Variable 4A: Current UKRS2 Approach

**How it works**:
1. Define a "rail translation table" mapping labels to indexes
2. At runtime, Variable 4A returns the current track's index from your table
3. Use VarAction2 range checks to determine power source

**Translation Table** (Sprite 419, ~line 741):
```nfo
419 * 178 00 08 01 2B 00 12   // 0x2B = 43 entries
    "RAIL"  // 0x00 - Unpowered (diesel only)
    "ELRL"  // 0x01 - Catenary
    "3RDR"  // 0x02 - 3rd rail
    "3RDC"  // 0x03 - 3rd rail + catenary
    ...
    "SUAE"  // 0x2A - Urban catenary
```

**Index Ranges**:
- 3rd rail available: `0x02 - 0x20` (contiguous)
- Catenary available: `0x01, 0x03, 0x05, 0x07, 0x17 - 0x2A` (5 disjoint ranges)

**The Problem**: If a new track set uses a label not in your table, Variable 4A returns 0 and the power detection fails.

### Variable 63: Modern Solution (OpenTTD 1.11+)

**How it works**:
1. Ask the game "would a vehicle requiring railtype X be powered here?"
2. The game handles all equivalence internally

**NML Example**:
```nml
switch(FEAT_TRAINS, SELF, sw_class73_power,
       tile_powers_railtype(SAA3) || tile_powers_railtype(_3RDR)) {
    1: return ELECTRIC_POWER;
    0: return DIESEL_POWER;
}
```

**Why UKRS2 doesn't use it**: Variable 63 was added in 2021. UKRS2 v1.06 was released in 2010.

## The Affected Vehicles

### Type JB (Class 73 Electro-Diesel)
- **Vehicle ID**: 0x79
- **Power callback**: Sprite 9441 (checks Variable 4A range 0x02-0x20)
- **Availability chain**: Sprites 9491-9523 (Action 7 checks for 30+ labels)
- **Behavior**: Diesel by default, electric on 3rd rail

### Brush Class 92
- **Vehicle ID**: 0x62
- **Catenary detection**: Sprite 10092 (5 ranges)
- **3rd rail detection**: Sprite 10093 (5 ranges)
- **Behavior**: Power varies based on available power source

### GEC-Alstom Eurostar
- **Location**: ukrs2-addon.nfo
- **Speed callback**: Checks catenary availability
- **Behavior**: Full speed on catenary, reduced on 3rd rail only

### Hitachi A-Train
- **Vehicle ID**: 0x69
- **Speed callback**: Similar catenary detection as Eurostar
- **Wagon compatibility**: Uses `89 25` GRFID check

## VarAction2 Callback Anatomy

### Single-Range Check (Type JB Power)
```nfo
9441 * 14  02 00 37 81 4A 00 FF 01 37 00 02 20 47 00
           │  │  │  │  │  │  │  │  │  │  │  │  │  │
           │  │  │  │  │  │  │  │  │  │  │  │  └──┴── Default: 0x47 (diesel)
           │  │  │  │  │  │  │  │  │  │  └──┴── Range: 0x02-0x20
           │  │  │  │  │  │  │  │  └──┴── Result: 0x37 (electric)
           │  │  │  │  │  │  │  └── 1 range
           │  │  │  │  │  │  └── Mask: 0xFF
           │  │  │  │  │  └── Shift: 0
           │  │  │  │  └── Variable: 0x4A
           │  │  │  └── Type: 0x81 (byte)
           │  │  └── Set ID: 0x37
           │  └── Feature: trains
           └── Action 2
```

### Multi-Range Check (Catenary Detection)
```nfo
10092 * 30  02 00 11 81 4A 00 FF 05 01 00 01 01 01 00 03 03 01 00 05 05 01 00 07 07 01 00 17 2A 11 00
                              ↑↑ └─────────────────────────────────────────────────────────────────┘
                              5 ranges: 01-01, 03-03, 05-05, 07-07, 17-2A
```

## Action 7 Availability Chains

Type JB is hidden from the purchase menu if no 3rd rail track exists:

```nfo
9491 * 9  07 00 04 0E "3RDR" 55   // If 3RDR defined, jump to label 55
9492 * 9  07 00 04 0E "3RDC" 55   // If 3RDC defined, jump to label 55
...       (30 more checks)
9521 * 9  07 00 04 0E "SUAZ" 55   // Last check
9522 * 7  00 00 01 01 79 06 00    // Hide vehicle 0x79 (reached if no match)
9523 * 2  10 55                    // Label 55: vehicle available
```

## GRFID Checks: The 89 25 / 8A 25 Pattern

Used for wagon compatibility (ensuring wagons are from the same GRF):

```nfo
02 00 A2 89 25 00 "····" 01 A2 00 "MCX" 00 "MCX" 00 E5 80
        ↑↑ ↑↑                     ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑
        │  │                      Compare GRFID to "MCX" 00
        │  └── Variable 25: GRFID
        └── Type 89: related object variables
```

**VarAction2 Type Bytes**:
- `81` = current vehicle's variables
- `82` = lead vehicle in consist
- `89` = related object (articulated part → lead)
- `8A` = related object (different scope)

## Add-on Set Dependency

The add-on set (`ukrs2-addon.nfo`) checks that the main set is loaded:

```nfo
38 * 9  07 88 04 \7G "MCX" 00 01   // If "MCX" 00 active, skip error
39 * 41 0B 03 7F "UKRS2 must be loaded before this grf" 00
40 * 336 08 08 "MCX" 01 "UK Railway Add-on Set..."
```

- Main set GRFID: `"MCX" 00`
- Add-on set GRFID: `"MCX" 01`

## How to Fix Railtype Compatibility Issues

### Symptom: New Track Set Breaks Power Detection

**Cause**: The track set uses a label not in UKRS2's translation table.

**Solution** (Variable 4A approach):
1. Add the new label to sprite 419
2. Note its index position
3. Update VarAction2 ranges if needed (sprites 9441, 10092, 10093)
4. Add to Action 7 availability chains (sprites 9491-9521)

**Solution** (Modern approach):
Convert to NML and use Variable 63 / `tile_powers_railtype()`. This requires significant rewrite but is future-proof.

### Symptom: Wagons Won't Attach

**Cause**: GRFID mismatch in `89 25` / `8A 25` checks.

**Solution**:
```bash
grep -n "89 25\|8A 25" ukrs2.nfo ukrs2-addon.nfo
```
Update all occurrences with the correct GRFID.

## File Locations Summary

| What | File | Sprite | Line |
|------|------|--------|------|
| Rail translation table | ukrs2.nfo | 419 | ~741 |
| Type JB power callback | ukrs2.nfo | 9441 | ~9985 |
| Type JB availability | ukrs2.nfo | 9491-9523 | ~10058-10099 |
| Catenary detection | ukrs2.nfo | 10092-10093 | ~10684-10689 |
| Main set GRFID | ukrs2.nfo | 32 | ~91 |
| Add-on dependency check | ukrs2-addon.nfo | 38 | ~61 |
| Add-on GRFID | ukrs2-addon.nfo | 40 | ~75 |

## External References

- [NewGRF Specs Main Page](https://newgrf-specs.tt-wiki.net/wiki/Main_Page)
- [VarAction2](https://newgrf-specs.tt-wiki.net/wiki/VariationalAction2)
- [VarAction2/Vehicles](https://newgrf-specs.tt-wiki.net/wiki/VariationalAction2/Vehicles) - Variable 4A, 63, 25
- [Action 7](https://newgrf-specs.tt-wiki.net/wiki/Action7) - Conditional skipping
- [Action 0/Railtypes Property 12](https://newgrf-specs.tt-wiki.net/wiki/Action0/Railtypes) - Translation table
- [Standardized Railtype Scheme](https://newgrf-specs.tt-wiki.net/wiki/Standardized_Railtype_Scheme)
