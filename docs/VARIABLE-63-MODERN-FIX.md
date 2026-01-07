# Variable 63: Modern Fix for Railtype Compatibility

## Overview

Variable 63 was added in OpenTTD 1.11 (released 2021) as a better way to check railtype compatibility. Instead of enumerating every possible track type label, you can ask "would a vehicle of type X be powered on this tile?"

**Important**: UKRS2 v1.06 was released in 2010, ONE YEAR before OpenTTD 1.11. The original code uses Variable 4A because Variable 63 didn't exist yet.

## Variable 63: Track Type Test

### What It Does

Variable 63 answers the question: "Would a vehicle that requires railtype X be able to operate on the current tile?"

### Parameters

The variable takes a parameter specifying which railtype to test:
```
Variable 63, Parameter = railtype index from translation table
```

### Result Flags

The result is a bitmask:

| Bit | Meaning |
|-----|---------|
| 0 | Track type is known to the game |
| 1 | Track type is compatible (vehicle can travel on this tile) |
| 2 | Track type is **powered** (vehicle would have power) |
| 3 | Track type is identical (exact match) |

For power detection, you typically check bit 2.

## Why Variable 63 is Better

### Old Approach (Variable 4A)
- Returns the current tile's railtype **index** from your translation table
- You must enumerate every possible label in your table
- You must maintain complex range checks in VarAction2
- Breaks when track sets add labels you don't have

### New Approach (Variable 63)
- The game handles all railtype equivalence internally
- You only need to ask about the power sources you care about
- Immune to other track sets changing their labels
- Future-proof: automatically works with new track sets

## Simplified Translation Table

With Variable 63, you only need to define the railtypes you want to test for:

```nml
railtypetable {
    RAIL,   // Baseline (unpowered)
    ELRL,   // Catenary
    SAA3,   // 3rd rail (modern standardized)
    _3RDR   // 3rd rail (legacy) - note underscore prefix for labels starting with numbers
}
```

That's **4 entries** instead of **43 entries**!

## Example: Class 73 Power Callback

### Current UKRS2 Approach (Variable 4A)
```nfo
// Check if railtype index is in range 0x02-0x20 (any 3rd rail)
02 00 37 81 4A 00 FF 01 37 00 02 20 47 00
```
Requires maintaining 43 entries in translation table and updating ranges.

### Modern Approach (Variable 63)
```nml
switch(FEAT_TRAINS, SELF, sw_class73_power,
       tile_powers_railtype(SAA3) || tile_powers_railtype(_3RDR)) {
    1: return 1600;  // Electric power (kW)
    0: return 600;   // Diesel power (kW)
}
```
Just test two railtypes and let the game handle equivalence.

## Why You Need BOTH SAA3 and 3RDR

Legacy track sets (pre-2015) don't know about the Standardized Railtype Scheme. They use:
- `3RDR` for 3rd rail
- `3RDC` for 3rd rail + catenary

Modern track sets use:
- `SAA3` for standard 3rd rail
- `SAAZ` for 3rd rail + catenary

By testing for BOTH, you cover:
- Legacy track sets (respond to `3RDR`)
- Modern track sets (respond to `SAA3`)

The game handles the equivalence within each scheme, but can't bridge the gap between schemes.

## NML Functions

| Function | Description |
|----------|-------------|
| `tile_powers_railtype(X)` | Returns 1 if vehicle type X would be powered |
| `tile_supports_railtype(X)` | Returns 1 if vehicle type X could travel here |
| `tile_is_railtype(X)` | Returns 1 if exact match (stricter) |

For power detection, use `tile_powers_railtype()`.

## Example: Full NML Conversion

```nml
// Translation table - only 4 entries needed!
railtypetable {
    RAIL,   // Index 0: baseline
    ELRL,   // Index 1: catenary
    SAA3,   // Index 2: 3rd rail (standardized)
    _3RDR   // Index 3: 3rd rail (legacy)
}

// Class 73 power callback
switch(FEAT_TRAINS, SELF, sw_class73_power_check,
       tile_powers_railtype(SAA3) || tile_powers_railtype(_3RDR)) {
    1: return 1600;  // Electric: 1600 kW
    0: return 600;   // Diesel: 600 kW
}

// Catenary detection (for dual-voltage trains)
switch(FEAT_TRAINS, SELF, sw_catenary_check,
       tile_powers_railtype(ELRL)) {
    1: return HIGH_SPEED;   // Full speed on catenary
    0: return LOW_SPEED;    // Reduced speed on 3rd rail
}
```

## Migration Path

To convert UKRS2 to use Variable 63:

1. **Convert to NML** (recommended) or rewrite VarAction2 chains
2. **Simplify translation table** to just the types you test for
3. **Replace all Variable 4A checks** with `tile_powers_railtype()` calls
4. **Test both legacy and modern labels** for backwards compatibility
5. **Remove complex range calculations**

## Compatibility Notes

- Variable 63 requires OpenTTD 1.11 or later
- Won't work in TTDPatch
- Won't work in older OpenTTD versions

If you need to support older versions, you could use Action 7/9 to detect the game version and use different code paths:
```nfo
// If OpenTTD >= 1.11, use Variable 63 code
// Else, use Variable 4A code (legacy)
```

## References

- [VarAction2/Vehicles - Variable 63](https://newgrf-specs.tt-wiki.net/wiki/VariationalAction2/Vehicles)
- [NML:Vehicles - tile_powers_railtype](https://newgrf-specs.tt-wiki.net/wiki/NML:Vehicles#Vehicle_variables)
- [Standardized Railtype Scheme](https://newgrf-specs.tt-wiki.net/wiki/Standardized_Railtype_Scheme)
