# GRFID Trap: Why You Can't Change the GRF ID

## The Problem

You might think changing the GRF ID would be a simple way to create a new version of UKRS2. **Don't do it.** Several internal mechanisms depend on the exact GRF ID.

The current GRF ID is: `"MCX" 00` (hex: `4D 43 58 00`)

## Why the GRF ID Matters

### 1. A-Train/MU Wagon Compatibility

Multiple unit trains (like the A-Train, Eurostars, and other EMUs) check the GRF ID of attached wagons to determine if they're allowed.

The check uses Variable 0x25 (GRFID of wagon):
```nfo
// Check wagon compatibility
02 00 A2 89 25 00 "����" 01 A2 00 "MCX" 00 "MCX" 00 E5 80
           │      │          │  │  │       │
           │      │          │  │  │       └── GRF ID to compare: "MCX\0"
           │      │          │  │  └── If matches: result A2
           │      │          │  └── GRF ID to compare
           │      │          └── Number of ranges
           │      └── Mask
           └── Variable 0x25: GRFID of attached vehicle
```

If you change the GRF ID, these checks fail, and wagons become "incompatible" with their locomotives.

### 2. Coach Livery Graphics

Coaches use the GRF ID to determine which graphics callback to use. Variable 0x25 with operator 0x8A checks the front vehicle's GRF ID:

```nfo
02 00 50 8A 25 00 "����" 01 50 00 "MCX" 00 "MCX" 01 20 00
```

This allows coaches to use different liveries based on which locomotive is pulling them.

### 3. Saved Games

Existing saved games reference vehicles by GRF ID. Changing the ID would:
- Break saved games
- Cause vehicles to disappear
- Potentially corrupt game state

## Magic Numbers to Search For

To find all GRFID-dependent code, search for these patterns:

| Pattern | Meaning |
|---------|---------|
| `89 25` | VarAction2 checking GRFID with condition 89 |
| `8A 25` | VarAction2 checking GRFID with condition 8A (self) |
| `"MCX"` | Direct references to the GRF ID |

### Current References in ukrs2.nfo

```bash
grep -n "89 25\|8A 25" ukrs2.nfo
```

Common locations:
- Lines around 624, 644, 779 (early coach checks)
- Lines 10407, 11299, etc. (wagon compatibility for MUs)
- Lines 14039, etc. (A-Train wagon checks)

## Safe Changes

You CAN change:
- GRF name (in Action 8)
- GRF description (in Action 8)
- Version number (in Action 14)
- URL, author info, etc.

You CANNOT safely change:
- The 4-byte GRF ID (`"MCX" 00`)

## If You Absolutely Must Fork

If you need to create an independent fork with a different GRF ID:

1. **Change the GRF ID** in Action 8:
   ```nfo
   // Original
   08 08 "MCX" 00 "UK Railway Set..."
   // Fork
   08 08 "NEW" 00 "UK Railway Set Fork..."
   ```

2. **Update ALL internal GRFID checks** (dozens of places):
   ```nfo
   // Change every occurrence of "MCX" 00 to "NEW" 00
   ```

3. **Document that it's incompatible** with the original

4. **Expect saved games to break**

5. **Test all MU trains** to ensure wagon compatibility still works

## Add-on Set Dependency

The add-on set (`ukrs2-addon.nfo`) checks for the main set's GRF ID:

```nfo
// Check if UKRS2 main set is active
38 * 9  07 88 04 \7G "MCX" 00 01
```

If you change the main set's GRF ID, the add-on will refuse to load.

## NARS Compatibility Check

UKRS2 also checks for the North American Renewal Set (NARS) GRF ID:

```nfo
// Check if NARS is/will be active
07 88 04 \7GG 44 44 03 02 BB
```

This is to handle conflicts between the two sets. The NARS GRF ID is `44 44 03 02`.

## Summary

The GRF ID is deeply embedded in the wagon compatibility system. Changing it would require:
- Updating dozens of VarAction2 checks
- Breaking saved game compatibility
- Breaking add-on set compatibility
- Extensive testing of all MU trains

Unless you're creating a completely independent fork and accept these consequences, **do not change the GRF ID**.
