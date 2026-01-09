# VarAction2 Callbacks

## Purpose

VarAction2 (Variational Action 2) is used for runtime decision-making. In UKRS2, it's used to:
- Switch between diesel and electric power based on current track
- Adjust maximum speed based on power source available
- Select appropriate graphics/sounds

## Format

```nfo
02 [feat] [set-id] 8[type] [var] [shift] [mask] [nranges] [ranges...] [default]
```

| Field | Description |
|-------|-------------|
| `02` | Action 2 |
| `feat` | Feature (00 = trains) |
| `set-id` | Callback ID being defined |
| `8[type]` | Variable access type (81, 82, 89, 8A, etc.) |
| `var` | Variable to check |
| `shift` | Bit shift |
| `mask` | Bit mask |
| `nranges` | Number of ranges |
| `ranges` | Range entries: `[result-lo] [result-hi] [min] [max]` |
| `default` | Default callback if no range matches |

## Variable 0x4A: Current Railtype Index

Variable 0x4A returns the **index** of the current track type from the rail translation table.

**Important**: This is not the label itself, but the index. So if "3RDR" is at index 0x02, Variable 0x4A returns 0x02 when on 3RDR track.

### Limitations

- Only returns values for labels in your translation table
- Returns 0 for unknown labels (causing power detection to fail)
- Requires enumerating ALL possible labels upfront

## Power Detection Patterns

### Single-Range Check (3rd Rail)

Type JB (Class 73) checks if the railtype index falls within the 3rd rail range:

```
IF railtype_index >= 0x02 AND railtype_index <= 0x20:
    RETURN electric power callback
ELSE:
    RETURN diesel power callback
```

The range 0x02-0x20 covers all 3rd rail track types in the translation table.

### Multi-Range Check (Catenary)

Catenary track indexes are NOT contiguous, so multiple ranges are needed:

```
IF index == 0x01 (ELRL)        → catenary available
IF index == 0x03 (3RDC)        → catenary available
IF index == 0x05 (CLOW)        → catenary available
IF index == 0x07 (CMED)        → catenary available
IF index >= 0x17 AND <= 0x2A   → catenary available
ELSE                           → no catenary
```

This requires 5 separate ranges in the VarAction2.

## Callback Chaining

Callbacks can reference other callbacks:
- Callback 0x37 might load electric power sprite data
- Callback 0x47 might load diesel power sprite data
- A main callback checks the railtype and branches to 0x37 or 0x47

## Common Issues

### Index Not in Table
If a track set uses a label not in your translation table, Variable 0x4A returns 0. The power check fails and defaults to unpowered.

### Non-Contiguous Indexes
If you need to check for multiple non-contiguous indexes (like catenary), you must use multiple ranges.

### Stale Ranges
If you update the translation table but forget to update VarAction2 ranges, power detection will be wrong for the new entries.

## Byte-Level Details

For detailed byte-by-byte breakdowns of specific sprites (9441, 10092, etc.), see the **NFO Byte-Level Reference** section in [FIXING-RAILTYPE-COMPATIBILITY.md](FIXING-RAILTYPE-COMPATIBILITY.md).

## See Also

- [RAIL-TRANSLATION-TABLE.md](RAIL-TRANSLATION-TABLE.md) - Index definitions
- [VARIABLE-63-MODERN-FIX.md](VARIABLE-63-MODERN-FIX.md) - Modern alternative
- [FIXING-RAILTYPE-COMPATIBILITY.md](FIXING-RAILTYPE-COMPATIBILITY.md) - How to fix compatibility issues
