# Rail Translation Table

## What It Is

The rail translation table maps railtype labels (like "RAIL", "ELRL", "3RDR") to GRF-local indexes (0x00, 0x01, 0x02, etc.). This allows the GRF to reference track types by index rather than by label.

**Technical Details:**
- Action 0, Feature 08 (Global Settings), Property 12
- Location in ukrs2.nfo: Sprite 419 (around line 726)
- Current count: 43 entries (0x2B)

## Format

```nfo
00 08 01 [count] 00 12 [labels...]
│  │  │  │       │  │   └── Each label is 4 bytes (e.g., "RAIL")
│  │  │  │       │  └── Property 12: railtype translation table
│  │  │  │       └── ID (ignored for global settings)
│  │  │  └── Number of entries
│  │  └── Number of properties to change
│  └── Feature 08: global settings
└── Action 0
```

## Current Index Map

### Basic Tracks (0x00 - 0x03)

| Index | Label | Description |
|-------|-------|-------------|
| 0x00 | `RAIL` | Plain rail (unpowered/diesel) |
| 0x01 | `ELRL` | Catenary (legacy) |
| 0x02 | `3RDR` | 3rd rail (legacy, primary) |
| 0x03 | `3RDC` | 3rd rail + catenary (legacy) |

### Non-Standard 3rd Rail (0x04 - 0x0C)

| Index | Label | Description |
|-------|-------|-------------|
| 0x04 | `3LOW` | Low-speed 3rd rail |
| 0x05 | `CLOW` | Low-speed 3rd rail + catenary |
| 0x06 | `3MED` | Medium-speed 3rd rail |
| 0x07 | `CMED` | Medium-speed 3rd rail + catenary |
| 0x08 | `MTRO` | Metro |
| 0x09 | `MTRC` | Metro + catenary |
| 0x0A | `MTRS` | Metro (subterranean) |
| 0x0B | `MTRU` | Metro (urban) |
| 0x0C | `MTRT` | Metro (tunnel) |

### Standardized 3rd Rail (0x0D - 0x16)

| Index | Label | Description |
|-------|-------|-------------|
| 0x0D | `SAA3` | Speed A, Any axle, 3rd rail |
| 0x0E | `SBA3` | Speed B, Any axle, 3rd rail |
| 0x0F | `SCA3` | Speed C, Any axle, 3rd rail |
| 0x10 | `SDA3` | Speed D, Any axle, 3rd rail |
| 0x11 | `SEA3` | Speed E, Any axle, 3rd rail |
| 0x12 | `SFA3` | Speed F, Any axle, 3rd rail |
| 0x13 | `SGA3` | Speed G, Any axle, 3rd rail |
| 0x14 | `SHA3` | Speed H, Any axle, 3rd rail |
| 0x15 | `SSA3` | Subterranean, Any axle, 3rd rail |
| 0x16 | `SUA3` | Urban, Any axle, 3rd rail |

### Standardized 3rd Rail + Catenary (0x17 - 0x20)

| Index | Label | Description |
|-------|-------|-------------|
| 0x17 | `SAAZ` | Speed A, Any axle, 3rd + catenary |
| 0x18 | `SBAZ` | Speed B, Any axle, 3rd + catenary |
| 0x19 | `SCAZ` | Speed C, Any axle, 3rd + catenary |
| 0x1A | `SDAZ` | Speed D, Any axle, 3rd + catenary |
| 0x1B | `SEAZ` | Speed E, Any axle, 3rd + catenary |
| 0x1C | `SFAZ` | Speed F, Any axle, 3rd + catenary |
| 0x1D | `SGAZ` | Speed G, Any axle, 3rd + catenary |
| 0x1E | `SHAZ` | Speed H, Any axle, 3rd + catenary |
| 0x1F | `SSAZ` | Subterranean, Any axle, 3rd + catenary |
| 0x20 | `SUAZ` | Urban, Any axle, 3rd + catenary |

### Standardized Catenary Only (0x21 - 0x2A)

| Index | Label | Description |
|-------|-------|-------------|
| 0x21 | `SAAE` | Speed A, Any axle, Electric catenary |
| 0x22 | `SBAE` | Speed B, Any axle, Electric catenary |
| 0x23 | `SCAE` | Speed C, Any axle, Electric catenary |
| 0x24 | `SDAE` | Speed D, Any axle, Electric catenary |
| 0x25 | `SEAE` | Speed E, Any axle, Electric catenary |
| 0x26 | `SFAE` | Speed F, Any axle, Electric catenary |
| 0x27 | `SGAE` | Speed G, Any axle, Electric catenary |
| 0x28 | `SHAE` | Speed H, Any axle, Electric catenary |
| 0x29 | `SSAE` | Subterranean, Any axle, Electric catenary |
| 0x2A | `SUAE` | Urban, Any axle, Electric catenary |

## Index Range Summary

These ranges are used in VarAction2 checks:

| Track Type | Index Range | Notes |
|------------|-------------|-------|
| 3rd rail available | 0x02 - 0x20 | Contiguous range |
| Catenary available | 0x01, 0x03, 0x05, 0x07, 0x17 - 0x2A | Non-contiguous! |

**Important**: Catenary detection requires 5 separate ranges because the indexes are not contiguous.

## How to Add New Labels

1. **Increment the count byte** (currently 0x2B = 43)
2. **Add the new label at the end** (4 characters, e.g., "NEWR")
3. **Note the new index** (next index after 0x2A would be 0x2B)
4. **Update VarAction2 ranges** if the new track type provides power
5. **Update Action 07 chains** if vehicles should be available when this track exists

### Example: Adding "NEWR" as a new 3rd rail type

```nfo
// Before: count = 0x2B (43 entries)
419 * 178 00 08 01 2B 00 12 "RAIL" "ELRL" ...

// After: count = 0x2C (44 entries)
419 * 182 00 08 01 2C 00 12 "RAIL" "ELRL" ... "NEWR"
//    ↑ size increases by 4 bytes (new label)
//                   ↑ count increases by 1
```

Then update VarAction2 for 3rd rail detection:
```nfo
// Before: range 02-20
02 00 37 81 4A 00 FF 01 37 00 02 20 47 00

// After: range 02-2B (if NEWR provides 3rd rail power)
02 00 37 81 4A 00 FF 01 37 00 02 2B 47 00
//                               ↑↑ new max
```

## Why This Matters

Variable 4A returns the **index** from this table, not the label itself. So when checking "is 3rd rail available?", the code checks if the index is in range 0x02-0x20.

If a track set uses a label not in this table, the index won't match, and power detection fails. This is why UKRS2 needed updates to support the Standardized Railtype Scheme.

See also: [VARACTION2-CALLBACKS.md](VARACTION2-CALLBACKS.md)
