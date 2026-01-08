# Variable 63: Modern Fix for Railtype Compatibility

## Overview

Variable 63 was added in OpenTTD 1.11 (released 2021) as a better way to check railtype compatibility. Instead of enumerating every possible track type label, you ask the game "would a vehicle of type X be powered on this tile?"

**Important**: PikkaBird's UKRS2 v1.05 was released in 2013. CMircea's community bugfix fork (v1.06) was released in Sept 2020. Variable 63 was added to OpenTTD 1.11 in 2021. The original code uses Variable 4A because Variable 63 didn't exist during UKRS2's active development.

## How Variable 63 Works

**Spec Reference**: [VarAction2/Vehicles](https://newgrf-specs.tt-wiki.net/wiki/VariationalAction2/Vehicles)

When you call `tile_powers_railtype(X)`:
1. Game looks at the **current tile's railtype**
2. Game checks that railtype's **Property 0F (powered_railtype_list)**
3. If X is in that list (or equals the railtype), returns powered

The **track set** determines what's powered, not the train set. This means well-behaved track sets that declare legacy labels in their powered_railtype_list will work automatically.

### Result Flags

| Bit | Value | Meaning |
|-----|-------|---------|
| 0 | 0x01 | Track type is known to the game |
| 1 | 0x02 | Track type is compatible (vehicle can travel) |
| 2 | 0x04 | Track type is **powered** |
| 3 | 0x08 | Track type is identical (exact match) |

For power detection, check bit 2 (mask with 0x04).

## Minimal Translation Table

With Variable 63, you only need the base labels you want to test:

```nml
railtypetable {
    RAIL,   // 0 - baseline unpowered
    ELRL,   // 1 - catenary (THE universal catenary label)
    SAA3,   // 2 - 3rd rail (standardized scheme)
    _3RDR,  // 3 - 3rd rail (legacy/pb_trax)
}
```

**4 entries vs 43!**

No need to include dual-power labels (SAAZ, 3RDC) - dual-power tracks declare the base labels (SAA3, 3RDR, ELRL) in their `powered_railtype_list`, so checking base labels covers them.

## Detection Logic

### Class 73 (Electro-Diesel) - 3rd Rail Power

Diesel by default, electric on any 3rd rail:

```nml
switch(FEAT_TRAINS, SELF, sw_class73_power,
       tile_powers_railtype(SAA3) || tile_powers_railtype(_3RDR)) {
    1: return 1600;  // Electric - any 3rd rail detected
    0: return 600;   // Diesel fallback
}
```

### Eurostar/A-Train - Dual-Voltage Speed

Dual-voltage EMUs that run on either 3rd rail or catenary. Speed depends on power source (3rd rail = 750V DC limited, catenary = 25kV AC full power):

```nml
switch(FEAT_TRAINS, SELF, sw_eurostar_speed,
       tile_powers_railtype(ELRL)) {
    1: return 186;   // Catenary - full speed (25kV AC)
    0: return 100;   // 3rd rail only - voltage limited (750V DC)
}
```

Note: The vehicle must already be on compatible track (3rd rail or catenary). This callback determines speed mode, not availability.

### Class 92 - Dual-Voltage Power

Dual-voltage freight locomotive, runs on either 3rd rail or catenary:

```nml
switch(FEAT_TRAINS, SELF, sw_class92_power,
       tile_powers_railtype(ELRL) ||
       tile_powers_railtype(SAA3) || tile_powers_railtype(_3RDR)) {
    1: return 5000;  // Electric mode (either power source)
    0: return 0;     // No electric power available
}
```

For differentiated power by voltage system, check catenary first:

```nml
switch(FEAT_TRAINS, SELF, sw_class92_power_detailed,
       tile_powers_railtype(ELRL)) {
    1: return 5000;  // Catenary - full power (25kV AC)
    0: sw_class92_check_3rd_rail;  // Check 3rd rail
}

switch(FEAT_TRAINS, SELF, sw_class92_check_3rd_rail,
       tile_powers_railtype(SAA3) || tile_powers_railtype(_3RDR)) {
    1: return 4000;  // 3rd rail - reduced power (750V DC)
    0: return 0;     // No electric power
}
```

## Why This Works

### Key Insight: Track Sets Declare Compatibility

Well-behaved track sets declare legacy labels in their `powered_railtype_list`:

**NuTracks SBA3:**
```nml
powered_railtype_list: ["3RDR", "3LOW", "3MED", "SAA3", "SAB3", "SBA3", ...];
```

**U&ReRMM 2 SAA3:**
```nml
powered_railtype_list: ["3RDR", "SAA3", ...];
```

So `tile_powers_railtype(_3RDR)` on a modern SAA3/SBA3 track returns POWERED because the track set explicitly declares 3RDR compatibility.

### Dual-Power Tracks

Tracks like 3RDC and SAAZ provide both 3rd rail AND catenary. They declare both base labels:
- `tile_powers_railtype(ELRL)` → POWERED (catenary available)
- `tile_powers_railtype(_3RDR)` or `tile_powers_railtype(SAA3)` → POWERED (3rd rail available)

No need to check SAAZ or 3RDC directly.

## Coverage Matrix

| Track Set | 3rd Rail Label | Catenary Label | Class 73 | Eurostar | Class 92 |
|-----------|---------------|----------------|----------|----------|----------|
| pb_trax (legacy) | 3RDR | ELRL | ✓ | ✓ | ✓ |
| Metro Track Set | SAA3 | via SAAZ | ✓ | ✓ | ✓ |
| NuTracks 2 | SAA3+3RDR | SAAE+ELRL | ✓ | ✓ | ✓ |
| U&ReRMM 2 | SAA3+3RDR | SAAE+ELRL | ✓ | ✓ | ✓ |

## NFO Implementation

Variable 63 is a 60+x variable requiring a parameter. In NFO, use advanced VarAction2 chaining:

### Single Railtype Check

```nfo
// Check if 3RDR (index 3) is powered
02 00 [set-id] 89
   7B                   // Variable 7B = constant
   20                   // shift-num with add/div
   FF FF                // AND mask
   00 00                // add 0
   01 00                // divide by 1
   03 00                // constant: 0x0003 (3RDR index)
   0C                   // store and use as parameter
   63                   // Variable 63
   00                   // shift 0
   04                   // AND mask 0x04 (bit 2 = powered)
   01                   // 1 range
   01 00 04 04          // result 1 if powered (value = 0x04)
   00 00                // result 0 if not
```

### Multiple Railtype Check (OR)

```nfo
// Check SAA3 (index 2)
02 00 [id-saa3] 89
   7B 20 FF FF 00 00 01 00 02 00 0C 63 00 04
   01  01 00 04 04  00 00

// Check 3RDR (index 3)
02 00 [id-3rdr] 89
   7B 20 FF FF 00 00 01 00 03 00 0C 63 00 04
   01  01 00 04 04  00 00

// Combine with OR
02 00 [id-main] 81
   7E [id-saa3] 00 FF    // call SAA3 check
   0D                     // OR
   7E [id-3rdr] 00 FF    // call 3RDR check
   01
   [electric-cb] 01 01   // if result >= 1
   [diesel-cb]           // else
```

**Spec Reference**: [VarAction2 Advanced](https://newgrf-specs.tt-wiki.net/wiki/VarAction2Advanced)

## Version Check

Variable 63 requires OpenTTD 1.11+. For backwards compatibility:

```nfo
// Check OpenTTD version >= 1.11
09 9A 04 05 00 00 00 1B [skip-to-var4a-code]
// Variable 63 code here...

// Label for Variable 4A fallback
10 [label]
// Variable 4A code here (legacy approach)
```

**Spec Reference**: [Action 9](https://newgrf-specs.tt-wiki.net/wiki/Action9)

## Comparison: Variable 4A vs Variable 63

| Aspect | Variable 4A (current) | Variable 63 (modern) |
|--------|----------------------|---------------------|
| Translation table | 43 entries | 4 entries |
| Catenary check | 5 disjoint ranges | 1 check (ELRL) |
| 3rd rail check | 1 range (0x02-0x20) | 2 checks (SAA3 \|\| 3RDR) |
| Future-proof | Must add new labels | Automatic if track sets follow scheme |
| Min OpenTTD | Any | 1.11+ |

## References

- [VarAction2/Vehicles](https://newgrf-specs.tt-wiki.net/wiki/VariationalAction2/Vehicles) - Variable 63 definition
- [VarAction2 Advanced](https://newgrf-specs.tt-wiki.net/wiki/VarAction2Advanced) - Parameter passing for 60+x variables
- [Action0/Railtypes](https://newgrf-specs.tt-wiki.net/wiki/Action0/Railtypes) - Property 0F (powered_railtype_list)
- [Action 9](https://newgrf-specs.tt-wiki.net/wiki/Action9) - Version checking
- [Guide to Railtypes](https://newgrf-specs.tt-wiki.net/wiki/Guide_to_railtypes) - tile_powers_railtype examples
- [Standardized Railtype Scheme](https://newgrf-specs.tt-wiki.net/wiki/Standardized_Railtype_Scheme)
