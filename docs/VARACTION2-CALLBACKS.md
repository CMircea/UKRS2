# VarAction2 Callbacks

## Purpose

VarAction2 (Variational Action 2) is used for runtime decision-making. In UKRS2, it's used to:
- Switch between diesel and electric power based on current track
- Adjust maximum speed based on power source available
- Select appropriate graphics/sounds

## Format

```nfo
02 [feat] [set-id] 8[type] [var] [shift] [mask] [nranges] [ranges...] [default]
│   │      │        │       │     │       │      │         │            └── Default callback if no range matches
│   │      │        │       │     │       │      │         └── Range entries: [result-lo] [result-hi] [min] [max]
│   │      │        │       │     │       │      └── Number of ranges
│   │      │        │       │     │       └── Bit mask to apply
│   │      │        │       │     └── Bit shift
│   │      │        │       └── Variable to check
│   │      │        └── Type: 81 = basic byte, 85 = extended word, etc.
│   │      └── Set ID (callback ID to define)
│   └── Feature (00 = trains)
└── Action 2
```

## Variable 0x4A: Current Railtype Index

Variable 0x4A returns the **index** of the current track type from the rail translation table.

**Important**: This is not the label itself, but the index. So if "3RDR" is at index 0x02, Variable 0x4A returns 0x02 when on 3RDR track.

### Limitations

- Only returns values for labels in your translation table
- Requires enumerating ALL possible labels
- Breaks when track sets add new labels not in your table

## Type JB Power Callback (Single Range)

The Class 73 electro-diesel switches between diesel and electric power:

**Location**: Sprite 9441 (ukrs2.nfo)

```nfo
9441 * 14  02 00 37 81 4A 00 FF 01 37 00 02 20 47 00
           │  │  │  │  │  │  │  │  │  │  │  │  └── Default: callback 0x47 (diesel)
           │  │  │  │  │  │  │  │  │  │  │  └── Range max: 0x20
           │  │  │  │  │  │  │  │  │  │  └── Range min: 0x02
           │  │  │  │  │  │  │  │  └──┴── Result if in range: callback 0x37 (electric)
           │  │  │  │  │  │  │  └── Number of ranges: 1
           │  │  │  │  │  │  └── Mask: 0xFF (full byte)
           │  │  │  │  │  └── Shift: 0
           │  │  │  │  └── Variable: 0x4A (railtype index)
           │  │  │  └── Type: 0x81 (basic)
           │  │  └── Set ID: 0x37
           │  └── Feature: 0x00 (trains)
           └── Action 2
```

### Interpretation

```
IF railtype_index >= 0x02 AND railtype_index <= 0x20:
    RETURN callback 0x37 (electric power)
ELSE:
    RETURN callback 0x47 (diesel power)
```

The range 0x02-0x20 covers all 3rd rail track types in the translation table.

## Catenary Detection (Multi-Range)

Catenary track indexes are NOT contiguous, so multiple ranges are needed:

**Location**: Sprites 10092-10093 (ukrs2.nfo)

```nfo
10092 * 30  02 00 11 81 4A 00 FF 05 01 00 01 01 01 00 03 03 01 00 05 05 01 00 07 07 01 00 17 2A 11 00
            │  │  │  │  │  │  │  │  │     │     │     │     │     │     └── Range 5: 0x17-0x2A → 0x01
            │  │  │  │  │  │  │  │  │     │     │     │     │     └── Range 4: 0x07-0x07 → 0x01
            │  │  │  │  │  │  │  │  │     │     │     │     └── Range 3: 0x05-0x05 → 0x01
            │  │  │  │  │  │  │  │  │     │     │     └── Range 2: 0x03-0x03 → 0x01
            │  │  │  │  │  │  │  │  │     │     └── Range 1: 0x01-0x01 → 0x01
            │  │  │  │  │  │  │  │  │     └── Result: callback 0x01
            │  │  │  │  │  │  │  │  └── Number of ranges: 5
            │  │  │  │  │  │  │  └── Mask: 0xFF
            │  │  │  │  │  │  └── Shift: 0
            │  │  │  │  │  └── Variable: 0x4A
            │  │  │  │  └── Type: 0x81
            │  │  │  └── Set ID: 0x11
            │  │  └── Feature: 0x00
            │  └── Default: callback 0x11 (no catenary)
            └── Action 2
```

### Range Breakdown

| Range | Min | Max | Result | Track Types |
|-------|-----|-----|--------|-------------|
| 1 | 0x01 | 0x01 | 0x01 | ELRL (legacy catenary) |
| 2 | 0x03 | 0x03 | 0x01 | 3RDC (3rd rail + catenary) |
| 3 | 0x05 | 0x05 | 0x01 | CLOW (low-speed + catenary) |
| 4 | 0x07 | 0x07 | 0x01 | CMED (medium-speed + catenary) |
| 5 | 0x17 | 0x2A | 0x01 | SAAZ-SUAE (all standardized catenary) |

### Interpretation

```
IF index == 0x01 (ELRL)        → catenary available
IF index == 0x03 (3RDC)        → catenary available
IF index == 0x05 (CLOW)        → catenary available
IF index == 0x07 (CMED)        → catenary available
IF index >= 0x17 AND <= 0x2A   → catenary available
ELSE                           → no catenary
```

## Callback Chaining

Callbacks can reference other callbacks. For example:
- Callback 0x37 might load electric power sprite data
- Callback 0x47 might load diesel power sprite data
- Callback 0xCC might be the main entry point that calls 0x37 or 0x47

The "turtle all the way down" nature means you may need to trace several callbacks to understand the full behavior.

## Range Entry Format

Each range is 4 bytes:
```
[result-lo] [result-hi] [min] [max]
```

Little-endian byte order means `37 00` = 0x0037, not 0x3700.

## Adding Support for New Labels

When a new track type label needs to be recognized:

1. Add the label to the translation table (get its index)
2. If index extends an existing range, just update the max value:
   ```nfo
   // Before: range 02-20
   37 00 02 20
   // After: range 02-21
   37 00 02 21
   ```
3. If index is isolated, add a new range:
   ```nfo
   // Before: 1 range
   01 37 00 02 20 47 00
   // After: 2 ranges
   02 37 00 02 20 37 00 2B 2B 47 00
   ```
   (increment range count, add new range entry)

## Common Issues

### Index Not in Table
If a track set uses a label not in your translation table, Variable 0x4A returns 0 (or undefined behavior). The power check fails and defaults to unpowered.

### Non-Contiguous Indexes
If you need to check for multiple non-contiguous indexes (like catenary), you must use multiple ranges. A single range only works for contiguous values.

### Stale Ranges
If you update the translation table but forget to update VarAction2 ranges, power detection will be wrong for the new entries.

See also:
- [RAIL-TRANSLATION-TABLE.md](RAIL-TRANSLATION-TABLE.md) - Index definitions
- [VARIABLE-63-MODERN-FIX.md](VARIABLE-63-MODERN-FIX.md) - Modern alternative
