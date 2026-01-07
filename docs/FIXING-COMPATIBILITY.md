# Fixing Railtype Compatibility Issues

This is a step-by-step guide for fixing railtype compatibility problems in UKRS2.

## Symptoms of Compatibility Issues

- Electro-diesels (Type JB) stay in diesel mode on 3rd rail track
- Eurostar/A-Train runs at reduced speed on catenary track
- Class 92 doesn't switch power modes correctly
- Vehicles hidden from purchase menu when they should be available

## Diagnostic Steps

### 1. Identify the Track Set

Find out which track set is causing the problem:
- Check the NewGRF list in the game
- Look at the track labels used by the track set
- Common modern track sets use standardized labels (SAAE, SAA3, etc.)

### 2. Check if Labels are in Translation Table

Search `ukrs2.nfo` for the track set's labels:
```bash
grep -i "XXXX" ukrs2.nfo  # Replace XXXX with the label
```

If not found, the label needs to be added to the translation table.

### 3. Verify Index Ranges

If the label IS in the table but still not working:
1. Find the label's index in the translation table
2. Check if that index falls within the VarAction2 range checks

---

## Legacy Approach: Using Variable 4A (Current UKRS2)

### Step 1: Add Label to Translation Table

Location: Sprite 419 (~line 726 in ukrs2.nfo)

```nfo
// Before: 43 entries (0x2B)
419 * 178 00 08 01 2B 00 12
    "RAIL"  // 0x00
    "ELRL"  // 0x01
    ...
    "SUAE"  // 0x2A

// After: 44 entries (0x2C)
419 * 182 00 08 01 2C 00 12
    "RAIL"  // 0x00
    "ELRL"  // 0x01
    ...
    "SUAE"  // 0x2A
    "NEWR"  // 0x2B (new entry)
```

**Important**:
- Increment the count byte (2B → 2C)
- Increment the sprite size (178 → 182, +4 bytes for new label)
- Add new label at the END (to avoid changing existing indexes)
- Note the new index (0x2B in this example)

### Step 2: Update VarAction2 Ranges

#### For 3rd Rail Track Types

If the new track provides 3rd rail power, update Type JB callback:

Location: Sprite 9441 (~line 9962)

```nfo
// Before: range 0x02-0x20
9441 * 14 02 00 37 81 4A 00 FF 01 37 00 02 20 47 00
                                          ↑↑ max

// After: range 0x02-0x2B (assuming new label is 3rd rail)
9441 * 14 02 00 37 81 4A 00 FF 01 37 00 02 2B 47 00
                                          ↑↑ new max
```

#### For Catenary Track Types

If the new track provides catenary power, you need to add a new range OR extend the last range.

Location: Sprite 10092 (~line 10616)

**If extending existing range** (new index is 0x2B, contiguous with 0x2A):
```nfo
// Before: last range 0x17-0x2A
01 00 17 2A

// After: last range 0x17-0x2B
01 00 17 2B
```

**If adding new disjoint range** (new index is e.g., 0x30, not contiguous):
```nfo
// Before: 5 ranges
10092 * 30 02 00 11 81 4A 00 FF 05 01 00 01 01 ...
                              ↑↑ 5 ranges

// After: 6 ranges
10092 * 34 02 00 11 81 4A 00 FF 06 01 00 01 01 ... 01 00 30 30
                        ↑↑↑↑↑↑ ↑↑                  └──────────┘
                        size+4  6 ranges            new range
```

### Step 3: Update Action 7 Availability Chains

For 3rd rail vehicles (Type JB), add the new label to the availability check:

Location: Before sprite 9522 (~line 10043)

```nfo
// Add new check before the "hide vehicle" sprite
9521.5 * 9 07 00 04 0E "NEWR" 55  // If NEWR defined, jump to label 55
```

Alternatively, add it at any position before sprite 9522.

### Step 4: Compile and Test

```bash
cd /path/to/UKRS2
grfcodec -e ukrs2.grf ukrs2.nfo
grfcodec -e ukrs2-addon.grf ukrs2-addon.nfo
```

If grfcodec reports errors:
- Check sprite sizes match actual content
- Verify byte counts are correct
- Ensure no bytes were accidentally deleted

### Step 5: Test In-Game

1. Load OpenTTD with the new GRF
2. Place the new track type
3. Purchase Type JB locomotive
4. Verify it switches to electric power on the track
5. Test other affected vehicles (Eurostar, A-Train, Class 92)

---

## Modern Approach: Using Variable 63 (OpenTTD 1.11+)

### Step 1: Convert to NML or Rewrite VarAction2

The Variable 63 approach requires significant restructuring.

### Step 2: Simplify Translation Table

Only include the types you explicitly test for:
```nml
railtypetable {
    RAIL,   // Baseline
    ELRL,   // Catenary
    SAA3,   // 3rd rail (standardized)
    _3RDR   // 3rd rail (legacy)
}
```

### Step 3: Replace Variable 4A with tile_powers_railtype()

**Before (Variable 4A)**:
```nfo
// Check index range 0x02-0x20 for 3rd rail
02 00 37 81 4A 00 FF 01 37 00 02 20 47 00
```

**After (Variable 63 / NML)**:
```nml
switch(FEAT_TRAINS, SELF, sw_class73_power,
       tile_powers_railtype(SAA3) || tile_powers_railtype(_3RDR)) {
    1: return ELECTRIC_POWER;
    0: return DIESEL_POWER;
}
```

### Step 4: Check Both Legacy and Modern Labels

Always test for BOTH standardized (SAA3) and legacy (3RDR) labels:
```nml
// 3rd rail: test both
tile_powers_railtype(SAA3) || tile_powers_railtype(_3RDR)

// Catenary: just ELRL is usually sufficient
tile_powers_railtype(ELRL)
```

### Step 5: Remove Complex Range Calculations

No more maintaining 5-range catenary checks or 30-entry translation tables.

---

## Quick Reference: What to Update

| Change Type | Files to Modify |
|-------------|-----------------|
| New 3rd rail label | Translation table, Type JB power callback, Type JB availability chain |
| New catenary label | Translation table, Eurostar/A-Train/Class 92 speed callbacks |
| New combined label | All of the above |

| Sprite | Purpose | Location |
|--------|---------|----------|
| 419 | Translation table | ~line 726 |
| 9441 | Type JB 3rd rail check | ~line 9962 |
| 9491-9521 | Type JB availability | ~lines 10012-10042 |
| 10092 | Catenary detection | ~line 10616 |
| 10093 | 3rd rail detection (Class 92) | ~line 10617 |

---

## Common Mistakes

### 1. Forgetting to Update Sprite Size
When adding bytes to a sprite, update the size field:
```nfo
419 * 178 ...  // Before: 178 bytes
419 * 182 ...  // After: 182 bytes (+4 for new label)
```

### 2. Using Wrong Byte Order
NFO uses little-endian. `37 00` means 0x0037, not 0x3700.

### 3. Forgetting to Increment Range Count
When adding a new range to VarAction2:
```nfo
05 ...  // Before: 5 ranges
06 ...  // After: 6 ranges
```

### 4. Adding Label in Wrong Position
Always add new labels at the END of the translation table to avoid changing existing indexes.

### 5. Missing Action 7 Check
If you add a new 3rd rail label, also add it to the availability chain or Type JB won't appear when only that track type exists.

---

## Testing Checklist

- [ ] GRF compiles without errors
- [ ] Type JB appears in purchase menu with new track type
- [ ] Type JB switches to electric power on new track
- [ ] Eurostar/A-Train speed is correct on new track
- [ ] Class 92 power switching works on new track
- [ ] No regression with existing track types
- [ ] Saved games still load correctly
