# GRFID Trap: The Hard Way

## The Problem

The GRF ID was changed from PikkaBird's original to `"MCX" 00` for the community bugfix fork. This broke A-Train wagon compatibility until the `89 25` / `8A 25` checks were also updated.

**Don't change it AGAIN** unless you're prepared to find and update all the GRFID-dependent checks.

## History

```
PikkaBird's original: "DD" 10 00 (or similar)
         ↓
CMircea changes it to "MCX" 00 for the bugfix fork
         ↓
A-Train wagons break - won't accept High-Speed Carriages
         ↓
PikkaBird: "Are you getting the feeling
            this is more trouble than it's worth yet?"
         ↓
CMircea: *figures out the 89 25 / 8A 25 checks*
         ↓
CMircea: *fixes wagon compatibility*
         ↓
It works!
```

## What Breaks When You Change the GRFID

### 1. MU Wagon Compatibility (`89 25`)

Multiple unit trains check the GRF ID of attached wagons:

```nfo
// Check wagon compatibility
02 00 A2 89 25 00 "····" 01 A2 00 "MCX" 00 "MCX" 00 E5 80
                                   ↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑
                                   These must match the Action 8 GRFID
```

If the GRFID in Action 8 doesn't match the GRFIDs in these checks, wagons become "incompatible" with their locomotives.

### 2. Coach Livery Graphics (`8A 25`)

Coaches check the front vehicle's GRF ID for livery selection:

```nfo
02 00 50 8A 25 00 "····" 01 50 00 "MCX" 00 "MCX" 01 20 00
```

## Magic Numbers to Search For

| Pattern | Meaning | Count |
|---------|---------|-------|
| `89 25` | Wagon compatibility checks | ~15 in ukrs2.nfo |
| `8A 25` | Coach livery checks | ~15 in ukrs2.nfo |

To find them all:
```bash
grep -n "89 25\|8A 25" ukrs2.nfo
```

## If You Must Change It Again

1. Change the GRF ID in Action 8 (sprite 32)
2. Search for ALL `89 25` patterns and update the GRFID values
3. Search for ALL `8A 25` patterns and update the GRFID values
4. Update the add-on set's dependency check
5. Test every MU train with its wagons
6. Accept that saved games using the old GRFID will break

## Add-on Set Dependency

The add-on set checks for the main set's GRF ID:

```nfo
// Check if UKRS2 main set is active
38 * 9  07 88 04 \7G "MCX" 00 01
```

If you change the main set's GRF ID, update this too or the add-on won't load.

## Lesson Learned

It's possible to change the GRFID. It's just tedious. The `89 25` and `8A 25` patterns are your friends for finding what needs updating.
