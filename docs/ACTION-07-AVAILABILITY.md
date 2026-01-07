# Action 07 Availability Checks

## Purpose

Action 07 is used at GRF load time to conditionally skip sprites. UKRS2 uses it to:
1. Hide vehicles from the purchase menu if their required track type doesn't exist
2. Implement if-else-if logic for track type selection

## Format

```nfo
07 [var] [size] [condition] [value...] [skip]
│   │     │      │          │           └── Number of sprites to skip (or label)
│   │     │      │          └── Value to compare against
│   │     │      └── Comparison condition
│   │     └── Size of value in bytes
│   └── Variable to check
└── Action 7
```

### Condition 0E: Skip if Railtype Defined

This is the most common condition used for vehicle availability:

```nfo
07 00 04 0E "XXXX" [skip]
│  │  │  │  │       └── Sprites to skip if railtype IS defined
│  │  │  │  └── 4-character railtype label
│  │  │  └── Condition: 0E = "skip if railtype defined"
│  │  └── Size: 4 bytes (label length)
│  └── Variable: ignored for condition 0E
└── Action 7
```

## Type JB (Class 73) Availability Chain

The Class 73 electro-diesel should only be available if at least one 3rd rail track type exists. The implementation checks each possible label and jumps to a "success" label if any is defined.

**Location**: Sprites 9491-9523 (ukrs2.nfo)

### Logic Flow

```
Check 3RDR → if defined, jump to label 55 (available)
Check 3RDC → if defined, jump to label 55 (available)
Check 3LOW → if defined, jump to label 55 (available)
... (continue for all 3rd rail labels)
Check SUAZ → if defined, jump to label 55 (available)

// If we reach here, no 3rd rail track exists
Set Property 06 = 0x00 (hide vehicle)

Label 55: // Success - vehicle is available
```

### Actual Code

```nfo
9491 * 9  07 00 04 0E "3RDR" 55  // If 3RDR defined, jump to label 55
9492 * 9  07 00 04 0E "3RDC" 55  // If 3RDC defined, jump to label 55
9493 * 9  07 00 04 0E "3LOW" 55  // If 3LOW defined, jump to label 55
9494 * 9  07 00 04 0E "CLOW" 55  // If CLOW defined, jump to label 55
9495 * 9  07 00 04 0E "3MED" 55  // If 3MED defined, jump to label 55
9496 * 9  07 00 04 0E "CMED" 55  // If CMED defined, jump to label 55
9497 * 9  07 00 04 0E "MTRO" 55  // If MTRO defined, jump to label 55
9498 * 9  07 00 04 0E "MTRC" 55  // If MTRC defined, jump to label 55
9499 * 9  07 00 04 0E "MTRS" 55  // If MTRS defined, jump to label 55
9500 * 9  07 00 04 0E "MTRU" 55  // If MTRU defined, jump to label 55
9501 * 9  07 00 04 0E "MTRT" 55  // If MTRT defined, jump to label 55
9502 * 9  07 00 04 0E "SAA3" 55  // If SAA3 defined, jump to label 55
9503 * 9  07 00 04 0E "SBA3" 55  // ... and so on for all standardized labels
9504 * 9  07 00 04 0E "SCA3" 55
9505 * 9  07 00 04 0E "SDA3" 55
9506 * 9  07 00 04 0E "SEA3" 55
9507 * 9  07 00 04 0E "SFA3" 55
9508 * 9  07 00 04 0E "SGA3" 55
9509 * 9  07 00 04 0E "SHA3" 55
9510 * 9  07 00 04 0E "SSA3" 55
9511 * 9  07 00 04 0E "SUA3" 55
9512 * 9  07 00 04 0E "SAAZ" 55
9513 * 9  07 00 04 0E "SBAZ" 55
9514 * 9  07 00 04 0E "SCAZ" 55
9515 * 9  07 00 04 0E "SDAZ" 55
9516 * 9  07 00 04 0E "SEAZ" 55
9517 * 9  07 00 04 0E "SFAZ" 55
9518 * 9  07 00 04 0E "SGAZ" 55
9519 * 9  07 00 04 0E "SHAZ" 55
9520 * 9  07 00 04 0E "SSAZ" 55
9521 * 9  07 00 04 0E "SUAZ" 55

9522 * 7  00 00 01 01 79 06 00   // Hide vehicle: Property 06 = 0x00
//        │  │  │  │  │  │  └── Value: 0x00 (hidden from all climates)
//        │  │  │  │  │  └── Property 06: climate availability
//        │  │  │  │  └── Vehicle ID: 0x79 (Type JB)
//        │  │  │  └── Number of vehicles: 1
//        │  │  └── Number of properties: 1
//        │  └── Feature 00: trains
//        └── Action 0

9523 * 2  10 55                  // Label 55: skip point (vehicle available)
//        │  └── Label ID: 55 (0x37)
//        └── Action 10: define label
```

## The "U" Artifact

When viewing decompiled code, you might see things like:
```
"3RDRU"
```

This is NOT a 5-character label! The `U` (byte 0x55) is actually the jump target:
```
"3RDR" 55
│      └── Jump target: label 55 (0x55 = 85 decimal, or label ID)
└── 4-character label
```

This is a common source of confusion when reading NFO files.

## Property 06: Climate Availability

```nfo
00 00 01 01 [id] 06 [value]
```

| Value | Meaning |
|-------|---------|
| 0x00 | Hidden (no climates) |
| 0x0F | All climates (temperate, arctic, tropical, toyland) |
| 0x01 | Temperate only |
| 0x02 | Arctic only |
| etc. | Bitmask of climates |

## Adding New Labels

To support a new 3rd rail track type label:

1. Add the label to the translation table (see [RAIL-TRANSLATION-TABLE.md](RAIL-TRANSLATION-TABLE.md))
2. Add a new Action 07 check in the availability chain:
   ```nfo
   07 00 04 0E "NEWR" 55
   ```
3. Position it before the "hide vehicle" sprite (9522)

## Alternative: Using Action 09

Action 09 is similar to Action 07 but continues loading regardless of condition outcome. It's used for in-game version checks rather than load-time decisions.

See also: [VARACTION2-CALLBACKS.md](VARACTION2-CALLBACKS.md) for runtime checks
