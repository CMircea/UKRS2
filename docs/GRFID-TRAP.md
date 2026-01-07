# GRFID Trap: The Hard Way

## The Problem

The GRF ID was changed from PikkaBird's original to `"MCX" 00` for the community bugfix fork. This broke A-Train wagon compatibility until the `89 25` / `8A 25` checks were also updated.

**Don't change it AGAIN** unless you're prepared to find and update all the GRFID-dependent checks.

## History

**Forum thread**: [UKRS2 - tt-forums.net](https://www.tt-forums.net/viewtopic.php?t=45637&start=1060) (pages 54-56)

```
PikkaBird's original: "DD" 10 00 (or similar)
         ↓
CMircea changes it to "MCX" 00 for the bugfix fork
         ↓
A-Train wagons break - won't accept High-Speed Carriages
         ↓
PikkaBird tells CMircea the magic numbers...
         ↓
CMircea: *fixes wagon compatibility*
         ↓
It works!
```

### The Forum Post That Saved the Day

> **PikkaBird** » 21 Feb 2018 11:08
>
> Oops, yeah, the MUs all check the GRFID as part of the allowed wagon check. **BAD FEATURES, eh?**
>
> The magical number to check for is "89 25" to find these sprites; if you update the GRFID there too it should fix the issue. A bunch of coach liveries also use ID checks for graphics and/or property callbacks in certain consists. "8A 25" will get you those sprites.
>
> Are you getting the feeling this is more trouble than it's worth yet?

PikkaBird knew exactly what needed fixing - he wrote the original code. The "89 25" and "8A 25" patterns are the key to finding all the GRFID-dependent checks.

## Understanding the Magic Numbers

The `89 25` and `8A 25` patterns are VarAction2 checks that read the GRFID of related vehicles.

### Breaking Down the Bytes

```
89 25
│  └── Variable 25 (0x25): GRFID of the vehicle
└── VarAction2 type 89: access "related object" variables
```

**VarAction2 Types** (see [VarAction2 specs](https://newgrf-specs.tt-wiki.net/wiki/VariationalAction2)):
- `81` = access variables of current vehicle
- `82` = access variables of lead vehicle in consist
- `89` = access variables of "related object" (for articulated parts, this is the leading part)
- `8A` = access variables of "related object" with different scope

**Variable 25** (see [VarAction2/Vehicles](https://newgrf-specs.tt-wiki.net/wiki/VariationalAction2/Vehicles)):
- Returns the GRFID of the vehicle being checked
- Used to verify wagons belong to the same GRF as the locomotive

### MU Wagon Compatibility (`89 25`)

Multiple unit trains check the GRF ID of attached wagons to ensure they're from UKRS2, not some random wagon #38 from another GRF:

```nfo
// Check wagon compatibility
02 00 A2 89 25 00 "····" 01 A2 00 "MCX" 00 "MCX" 00 E5 80
         ↑↑ ↑↑                     ↑↑↑↑↑↑↑  ↑↑↑↑↑↑↑
         │  │                      │        └── GRFID value to compare
         │  │                      └── GRFID value to compare
         │  └── Variable 25: GRFID
         └── Type 89: related object
```

If the GRFID in Action 8 doesn't match the GRFIDs in these checks, wagons become "incompatible" with their locomotives.

### Coach Livery Graphics (`8A 25`)

Coaches check the front vehicle's GRF ID for livery selection:

```nfo
02 00 50 8A 25 00 "····" 01 50 00 "MCX" 00 "MCX" 01 20 00
         ↑↑ ↑↑
         │  └── Variable 25: GRFID
         └── Type 8A: related object (different scope)
```

## Finding All GRFID Checks

| Pattern | Meaning | Spec Reference |
|---------|---------|----------------|
| `89 25` | Related object's GRFID | [VarAction2](https://newgrf-specs.tt-wiki.net/wiki/VariationalAction2) |
| `8A 25` | Related object's GRFID (alt scope) | [VarAction2](https://newgrf-specs.tt-wiki.net/wiki/VariationalAction2) |

To find them all (as PikkaBird said):
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

The add-on set checks for the main set's GRF ID using Action 7:

```nfo
// Check if UKRS2 main set is active
38 * 9  07 88 04 \7G "MCX" 00 01
            ↑↑
            └── Variable 88: check if GRFID is active
```

See [Action 7](https://newgrf-specs.tt-wiki.net/wiki/Action7) for the condition codes.

If you change the main set's GRF ID, update this too or the add-on won't load.

## Lesson Learned

It's possible to change the GRFID. It's just tedious. As PikkaBird said: **"BAD FEATURES, eh?"**

The `89 25` and `8A 25` patterns are your friends for finding what needs updating.

## References

- [UKRS2 Forum Thread](https://www.tt-forums.net/viewtopic.php?t=45637&start=1060) - The original discussion (pages 54-56)
- [VarAction2](https://newgrf-specs.tt-wiki.net/wiki/VariationalAction2) - Type bytes (81, 82, 89, 8A, etc.)
- [VarAction2/Vehicles](https://newgrf-specs.tt-wiki.net/wiki/VariationalAction2/Vehicles) - Variable 25 (GRFID)
- [Action 7](https://newgrf-specs.tt-wiki.net/wiki/Action7) - Variable 88 (GRFID active check)
