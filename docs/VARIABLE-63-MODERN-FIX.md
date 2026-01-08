# Variable 63: Modern Fix for Railtype Compatibility

## Overview

Variable 63 was added in OpenTTD 1.11 (released 2021) as a better way to check railtype compatibility. Instead of enumerating every possible track type label, you can ask "would a vehicle of type X be powered on this tile?"

**Important**: PikkaBird's UKRS2 v1.05 was released in 2013. CMircea's community bugfix fork (v1.06) was released in Sept 2020. Variable 63 was added to OpenTTD 1.11 in 2021. The original code uses Variable 4A because Variable 63 didn't exist during UKRS2's active development.

## Variable 63: Track Type Test

**Spec Reference**: [VarAction2/Vehicles](https://newgrf-specs.tt-wiki.net/wiki/VariationalAction2/Vehicles)

### What It Does

Variable 63 answers the question: "Would a vehicle that requires railtype X be able to operate on the current tile?"

### Parameter

Variable 63 is a **60+x variable** - it requires a parameter specifying which railtype to test. The parameter is the railtype index from your translation table.

### Result Flags

The result is a bitmask:

| Bit | Value | Meaning |
|-----|-------|---------|
| 0 | 0x01 | Track type is known to the game |
| 1 | 0x02 | Track type is compatible (vehicle can travel on this tile) |
| 2 | 0x04 | Track type is **powered** (vehicle would have power) |
| 3 | 0x08 | Track type is identical (exact match) |

For power detection, check bit 2 (mask with 0x04).

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

```nfo
// Before: 43 entries (0x2B)
419 * 178 00 08 01 2B 00 12 "RAIL" "ELRL" "3RDR" ... "SUAE"

// After: 4 entries (0x04)
419 * 22 00 08 01 04 00 12 "RAIL" "ELRL" "SAA3" "3RDR"
//                ↑↑                      ↑↑↑↑↑  ↑↑↑↑↑
//              4 entries            Index 0x02  Index 0x03
```

That's **4 entries** instead of **43 entries**!

## NFO Implementation

### The Challenge: 60+x Variables Need Parameters

Variable 63 is in the 60-7F range, meaning it takes a parameter. In NFO VarAction2, this parameter comes from the **accumulated value** in the calculation chain.

**Spec Reference**: [VarAction2 Advanced Format](https://newgrf-specs.tt-wiki.net/wiki/VarAction2Advanced)

### Method 1: Advanced VarAction2 with Chained Operations

To check if railtype index 0x02 (SAA3) is powered:

```nfo
// Advanced VarAction2: load constant, then check Variable 63
02 00 [set-id] 89
   7B                   // Variable 7B = read constant from following bytes
   20                   // shift-num: bit 5 set = add/div/mod follows
   FF FF                // AND mask: 0xFFFF
   00 00                // add: 0
   01 00                // divide: 1 (no-op)
   02 00                // constant value: 0x0002 (SAA3 index)
   0C                   // operation: 0x0C = "use as parameter for next var"
   63                   // Variable 63 (parameter = accumulated value = 0x02)
   00                   // shift: 0
   04                   // AND mask: 0x04 (bit 2 = powered)
   01                   // 1 range
   [result-lo] [result-hi] 04 04    // if masked value = 0x04 (powered)
   [default-lo] [default-hi]        // if not powered
```

**Byte breakdown**:
- `89` = type: advanced format, byte-sized, related object scope
- `7B` = Variable 7B (literal constant)
- `20 FF FF 00 00 01 00 02 00` = load constant 0x0002
- `0C` = store result and use as parameter for next variable
- `63 00 04` = Variable 63, shift 0, mask 0x04 (bit 2)

### Method 2: Check Multiple Railtypes with OR

To check SAA3 OR 3RDR (for backwards compatibility):

```nfo
// Check SAA3 (index 0x02)
02 00 [set-id-A] 89
   7B 20 FF FF 00 00 01 00 02 00   // load 0x0002
   0C                               // use as param
   63 00 04                         // var 63, mask bit 2
   01
   01 00 04 04                      // result 1 if powered
   00 00                            // result 0 if not

// Check 3RDR (index 0x03)
02 00 [set-id-B] 89
   7B 20 FF FF 00 00 01 00 03 00   // load 0x0003
   0C
   63 00 04
   01
   01 00 04 04
   00 00

// Combine: return electric if either is powered
02 00 [set-id-main] 81
   7E [set-id-A] 00 FF             // call set-id-A
   0D                               // OR with next
   7E [set-id-B] 00 FF             // call set-id-B
   01
   [electric-cb] 01 01             // if result >= 1, electric
   [diesel-cb]                      // else diesel
```

### Comparison: Variable 4A vs Variable 63

**Variable 4A (current UKRS2)**:
```nfo
// Simple but requires 43-entry translation table and range maintenance
9441 * 14  02 00 37 81 4A 00 FF 01 37 00 02 20 47 00
//         Check range 0x02-0x20, return 0x37 (electric) or 0x47 (diesel)
```

**Variable 63**:
```nfo
// More complex per-check, but only needs 4-entry translation table
// and automatically handles equivalence
```

## NML Implementation (Recommended)

NML abstracts away the complexity of 60+x variables:

```nml
// Translation table - only 4 entries needed
railtypetable {
    RAIL,   // Index 0: baseline
    ELRL,   // Index 1: catenary
    SAA3,   // Index 2: 3rd rail (standardized)
    _3RDR   // Index 3: 3rd rail (legacy)
}

// Class 73 power callback - clean and readable
switch(FEAT_TRAINS, SELF, sw_class73_power_check,
       tile_powers_railtype(SAA3) || tile_powers_railtype(_3RDR)) {
    1: return 1600;  // Electric: 1600 kW
    0: return 600;   // Diesel: 600 kW
}

// Catenary detection (for dual-voltage trains)
switch(FEAT_TRAINS, SELF, sw_catenary_check,
       tile_powers_railtype(ELRL)) {
    1: return HIGH_SPEED;
    0: return LOW_SPEED;
}
```

**NML Functions**:

| Function | Description |
|----------|-------------|
| `tile_powers_railtype(X)` | Returns 1 if vehicle type X would be powered |
| `tile_supports_railtype(X)` | Returns 1 if vehicle type X could travel here |
| `tile_is_railtype(X)` | Returns 1 if exact match (stricter) |

## Why You Need BOTH SAA3 and 3RDR

Legacy track sets (pre-2015) don't know about the Standardized Railtype Scheme:
- `3RDR` for 3rd rail
- `3RDC` for 3rd rail + catenary

Modern track sets use:
- `SAA3` for standard 3rd rail
- `SAAZ` for 3rd rail + catenary

The game handles equivalence **within** each scheme, but can't bridge between schemes. Test both for full compatibility.

## Migration Path

1. **Choose approach**: NML (recommended) or raw NFO
2. **Simplify translation table**: 4 entries instead of 43
3. **Replace Variable 4A checks**: Use Variable 63 with appropriate parameters
4. **Test both legacy and modern labels**: SAA3 + 3RDR for 3rd rail, ELRL for catenary
5. **Add version check**: Fall back to Variable 4A for OpenTTD < 1.11

### Version Check (Action 9)

```nfo
// Check OpenTTD version >= 1.11 (version 0x1B000000)
09 9A 04 05 00 00 00 1B [skip]
// If older, skip Variable 63 code and use Variable 4A fallback
```

**Spec Reference**: [Action 9](https://newgrf-specs.tt-wiki.net/wiki/Action9)

## Compatibility Notes

- Variable 63 requires **OpenTTD 1.11** or later
- Won't work in TTDPatch
- Won't work in older OpenTTD versions
- Consider dual code paths if backwards compatibility needed

## References

- [VarAction2/Vehicles](https://newgrf-specs.tt-wiki.net/wiki/VariationalAction2/Vehicles) - Variable 63 definition
- [VarAction2 Advanced](https://newgrf-specs.tt-wiki.net/wiki/VarAction2Advanced) - Chained operations format
- [Action 9](https://newgrf-specs.tt-wiki.net/wiki/Action9) - Version checking
- [NML:Vehicles](https://newgrf-specs.tt-wiki.net/wiki/NML:Vehicles#Vehicle_variables) - tile_powers_railtype
- [Standardized Railtype Scheme](https://newgrf-specs.tt-wiki.net/wiki/Standardized_Railtype_Scheme)
