# UKRS2 NFO Archaeology: Deep Technical Dive

## Understanding grfcodec Output

### The NFO Line Format

```
9441 * 14  02 00 37 81 4A 00 FF 01 37 00 02 20 47 00
↑      ↑   └──────────────────────────────────────┘
│      │                  Raw bytes
│      └── Size: 14 bytes
└── Sprite number
```

grfcodec converts GRF files to NFO (human-readable) and back. The sprite number and size are metadata; the actual data is the hex bytes.

### ASCII Interpretation Artifacts

grfcodec interprets byte sequences as ASCII when possible:

```nfo
07 00 04 0E "3RDR" 55
            ↑↑↑↑↑  ↑↑
            ASCII  Interpreted as 'U' (0x55 = 85 decimal)
```

The byte 55 (decimal 85, ASCII 'U') is the Action 7 jump target, NOT part of the label. But grfcodec displays it after the string, making `"3RDR" 55` look like `"3RDRU"` in some contexts.

### Little-Endian Byte Order

All multi-byte values use little-endian:
- `37 00` = 0x0037 (decimal 55)
- `20 00` = 0x0020 (decimal 32)

## Rail Translation Table (Sprite 419)

### Byte-Level Breakdown

```nfo
419 * 178 00 08 01 2B 00 12
          │  │  │  │  │  └── Property 12: rail translation table
          │  │  │  │  └── First ID (ignored for feature 08)
          │  │  │  └── Number of entries: 0x2B = 43
          │  │  └── Number of properties: 1
          │  └── Feature: 08 (global settings)
          └── Action 0
```

### Label to Index Mapping

The labels follow immediately:
```nfo
"RAIL"  // Index 0x00
"ELRL"  // Index 0x01
"3RDR"  // Index 0x02
"3RDC"  // Index 0x03
...
"SUAE"  // Index 0x2A
```

Each label is 4 bytes. Total: 43 × 4 = 172 bytes of labels + 6 bytes header = 178 bytes.

### Adding a New Label

To add label "NEWR" at the end:
1. Change `2B` → `2C` (44 entries)
2. Change `178` → `182` (+4 bytes)
3. Add `"NEWR"` after `"SUAE"`

The new label gets index 0x2B.

## VarAction2 Callback Structures

### Type Byte Meanings

The byte after `02 00` (Action 2, Feature trains) determines the variable scope:

| Byte | Binary | Meaning |
|------|--------|---------|
| 81 | 1000 0001 | Basic byte variable, current vehicle |
| 82 | 1000 0010 | Basic byte variable, lead vehicle |
| 85 | 1000 0101 | Extended word variable, current vehicle |
| 86 | 1000 0110 | Extended word variable, lead vehicle |
| 89 | 1000 1001 | Basic byte, **related object** |
| 8A | 1000 1010 | Basic byte, **related object (alt scope)** |

Bit 3 (0x08) indicates "related object" scope.

### Range Entry Format

Each range is 4 bytes for byte variables:
```
[result_lo] [result_hi] [min] [max]
```

For Type JB power callback:
```nfo
37 00 02 20
│  │  │  └── Max: 0x20
│  │  └── Min: 0x02
└──┴── Result: callback 0x0037
```

Interpretation: If Variable 4A is between 0x02 and 0x20 (inclusive), return callback 0x37.

### Sprite 9441: Complete Disassembly

```nfo
9441 * 14  02 00 37 81 4A 00 FF 01 37 00 02 20 47 00
```

| Offset | Bytes | Meaning |
|--------|-------|---------|
| 0 | 02 | Action 2 |
| 1 | 00 | Feature: trains |
| 2 | 37 | Set ID (this callback = 0x37) |
| 3 | 81 | Type: basic byte, current vehicle |
| 4 | 4A | Variable: railtype index |
| 5 | 00 | Shift: 0 bits |
| 6 | FF | Mask: 0xFF (full byte) |
| 7 | 01 | Range count: 1 |
| 8-11 | 37 00 02 20 | Range 1: result=0x37 if 0x02 ≤ var ≤ 0x20 |
| 12-13 | 47 00 | Default: callback 0x47 |

### Sprite 10092: Multi-Range Catenary Detection

```nfo
10092 * 30  02 00 11 81 4A 00 FF 05 01 00 01 01 01 00 03 03 01 00 05 05 01 00 07 07 01 00 17 2A 11 00
```

| Offset | Bytes | Meaning |
|--------|-------|---------|
| 0-6 | 02 00 11 81 4A 00 FF | Header (callback 0x11, Variable 4A) |
| 7 | 05 | Range count: 5 |
| 8-11 | 01 00 01 01 | Range 1: result=0x01 if var=0x01 (ELRL) |
| 12-15 | 01 00 03 03 | Range 2: result=0x01 if var=0x03 (3RDC) |
| 16-19 | 01 00 05 05 | Range 3: result=0x01 if var=0x05 (CLOW) |
| 20-23 | 01 00 07 07 | Range 4: result=0x01 if var=0x07 (CMED) |
| 24-27 | 01 00 17 2A | Range 5: result=0x01 if 0x17 ≤ var ≤ 0x2A |
| 28-29 | 11 00 | Default: callback 0x11 |

## Action 7 Conditional Skipping

### Format

```nfo
07 [var] [size] [cond] [value...] [skip]
```

For railtype label checks:
- Variable 0x00 with size 4 and condition 0x0E tests if a railtype label is defined

### Sprite 9491: Railtype Label Check

```nfo
9491 * 9  07 00 04 0E "3RDR" 55
          │  │  │  │  └────┴── Value: "3RDR", skip 55 sprites
          │  │  │  └── Condition: 0E = label is defined
          │  │  └── Size: 4 bytes
          │  └── Variable: 00 (special: railtype label)
          └── Action 7
```

Wait—the 55 is NOT the number of sprites to skip. Looking at the NFO comments, 55 is the **label** to jump to (Action 10 label 55). Condition `0E` with a following Action 10 creates a jump chain.

### The Availability Chain Pattern

```nfo
9491 * 9  07 00 04 0E "3RDR" 55   // If 3RDR exists, goto label 55
9492 * 9  07 00 04 0E "3RDC" 55   // If 3RDC exists, goto label 55
... (28 more checks)
9521 * 9  07 00 04 0E "SUAZ" 55   // If SUAZ exists, goto label 55
9522 * 7  00 00 01 01 79 06 00    // Reached if nothing matched: hide vehicle
9523 * 2  10 55                    // Label 55: success (vehicle available)
```

If ANY label exists, execution jumps to label 55, skipping the "hide vehicle" action.

## GRFID Checks: 89 25 / 8A 25

The `89 25` and `8A 25` patterns are VarAction2 checks for wagon compatibility and livery selection. See [GRFID-TRAP.md](GRFID-TRAP.md) for the full explanation, history, and byte breakdown.

## Callback Chains: Following the Flow

### Type JB Power Determination

1. Entry point: Action 3 links vehicle 0x79 to callbacks
2. At runtime, power callback is invoked
3. Callback 0x37 checks Variable 4A
4. If in 3rd rail range → returns electric power data
5. Otherwise → returns diesel power data

```
Vehicle 0x79 (Type JB)
       │
       ▼
   Callback CC (main entry)
       │
       ▼
   Callback 37 (power check)
       │
   ┌───┴───┐
   │       │
   ▼       ▼
0x02-0x20  Default
(3rd rail) (others)
   │       │
   ▼       ▼
Electric  Diesel
```

### Catenary Detection Chain

For vehicles like Eurostar that need full speed on catenary:

```
Speed callback
       │
       ▼
   Callback 11 (catenary check)
       │
   ┌───┴───┬───────┬───────┬───────┬─────────────────┐
   │       │       │       │       │                 │
   ▼       ▼       ▼       ▼       ▼                 ▼
  0x01    0x03    0x05    0x07   0x17-0x2A        Default
 (ELRL)  (3RDC)  (CLOW)  (CMED) (SAAZ-SUAE)     (no cat)
   │       │       │       │       │                 │
   └───────┴───────┴───────┴───────┘                 │
                   │                                 │
                   ▼                                 ▼
            Full speed                        Reduced speed
```

## The GRF Structure Overview

### ukrs2.nfo Layout

```
Sprites 0-31:     Metadata, Action 14, version info
Sprite 32:        Action 8 - GRFID "MCX" 00, name, description
Sprites 33-418:   Various setup, cargo definitions
Sprite 419:       Rail translation table (43 entries)
Sprites 420-9440: Vehicle graphics, basic callbacks
Sprites 9441-9523: Type JB (Class 73) - power detection, availability
Sprites 10092-10093: Catenary/3rd rail detection callbacks
Sprites 10094-~14700: More vehicles, including Class 92, A-Train
```

### ukrs2-addon.nfo Layout

```
Sprites 0-37:     Metadata, version check
Sprites 38-39:    Dependency check (requires main set)
Sprite 40:        Action 8 - GRFID "MCX" 01
Sprites 41+:      Additional vehicles (Eurostar, etc.)
```

## Modification Recipes

### Add New 3rd Rail Label "NEWR"

1. **Translation table** (sprite 419):
   - Change `2B` → `2C`
   - Change `178` → `182`
   - Add `"NEWR"` after `"SUAE"`
   - New index: 0x2B

2. **Type JB power** (sprite 9441):
   - If 0x2B > 0x20, change `02 20` → `02 2B`

3. **Availability chain**:
   - Add before sprite 9522: `07 00 04 0E "NEWR" 55`

### Add New Catenary Label "NEWC"

1. **Translation table** (sprite 419):
   - Add label, note index (e.g., 0x2B)

2. **Catenary detection** (sprite 10092):
   - If contiguous with 0x2A: change `17 2A` → `17 2B`
   - If not contiguous: add new range, increment range count, adjust size

### Change GRFID

See [GRFID-TRAP.md](GRFID-TRAP.md) for the full procedure and history.

## Debugging Tips

### Verify Translation Table

Count entries manually:
```bash
grep -c "// [0-9A-Fa-f]" ukrs2.nfo  # Near sprite 419
```

### Test Power Detection

In OpenTTD debug console:
```
newgrf_debug vehicle <id>
```

### Find All Railtype Checks

```bash
grep -n "4A 00 FF" ukrs2.nfo          # Variable 4A checks
grep -n "89 25\|8A 25" ukrs2.nfo      # GRFID checks
grep -n "07 00 04 0E" ukrs2.nfo       # Railtype label checks
```

## Summary: The Four Key Mechanisms

1. **Translation Table** (Sprite 419): Maps labels → indexes
2. **VarAction2 Power** (Sprite 9441): Range check on Variable 4A
3. **Action 7 Availability** (Sprites 9491-9523): Hide if no 3rd rail
4. **GRFID Compatibility** (89 25 / 8A 25): Ensure wagons match

All four must be updated together for full compatibility with new track sets.
