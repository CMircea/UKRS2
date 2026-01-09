# UKRS2 Technical Documentation

This documentation explains the internal mechanics of the UK Railway Set (UKRS2), specifically focused on railtype compatibility and how trains detect and respond to different track types.

## Overview

UKRS2 is a NewGRF for OpenTTD/TTDPatch that provides UK railway vehicles. Several vehicles in this set are "dual-mode" - they can operate on multiple track types with different performance characteristics:

- **Electro-diesels**: Run on diesel power by default, upgrade to electric power on 3rd rail track
- **Dual-voltage electrics**: Adjust speed based on whether overhead catenary or 3rd rail power is available

This requires complex detection logic to determine what track type the train is currently on.

## Historical Context

PikkaBird released UKRS2 v1.05 in January 2013. CMircea forked it in February 2018 as "UKRS2 - Community Bugfixes" to fix compatibility with modern track sets, releasing v1.06 in September 2020.

The fork happened after PikkaBird provided guidance on the [tt-forums thread](https://www.tt-forums.net/viewtopic.php?t=45637) (pages 54-56). For the full timeline and technical history, see [FIXING-RAILTYPE-COMPATIBILITY.md](FIXING-RAILTYPE-COMPATIBILITY.md).

## Documentation Files

### Core Concepts

| File | Description |
|------|-------------|
| [RAIL-TRANSLATION-TABLE.md](RAIL-TRANSLATION-TABLE.md) | How railtype labels are mapped to GRF-local indexes |
| [STANDARDIZED-RAILTYPE-SCHEME.md](STANDARDIZED-RAILTYPE-SCHEME.md) | The modern 4-character label format for railtypes |
| [VARACTION2-CALLBACKS.md](VARACTION2-CALLBACKS.md) | How trains dynamically switch power/speed at runtime |
| [ACTION-07-AVAILABILITY.md](ACTION-07-AVAILABILITY.md) | How vehicles are hidden when required track types are unavailable |

### Specific Implementations

| File | Description |
|------|-------------|
| [DUAL-POWER-VEHICLES.md](DUAL-POWER-VEHICLES.md) | List of vehicles with railtype-dependent behavior |
| [GRFID-TRAP.md](GRFID-TRAP.md) | The GRFID change history and 89 25 / 8A 25 patterns |
| [NFO-DECOMPILATION-ARTIFACTS.md](NFO-DECOMPILATION-ARTIFACTS.md) | grfcodec quirks (trailing 'U' in label checks) |

### Maintenance Guides

| File | Description |
|------|-------------|
| [FIXING-RAILTYPE-COMPATIBILITY.md](FIXING-RAILTYPE-COMPATIBILITY.md) | Step-by-step guide to fix railtype compatibility issues (includes history and NFO byte-level reference) |
| [VARIABLE-63-MODERN-FIX.md](VARIABLE-63-MODERN-FIX.md) | Modern approach using Variable 63 (OpenTTD 1.11+) |

## Quick Reference

### Key Sprite Numbers (ukrs2.nfo)

| Sprite | Purpose |
|--------|---------|
| 419 | Rail translation table definition (43 entries) |
| 9441 | Type JB (Class 73) VarAction2 power callback |
| 9491-9522 | Type JB Action 07 availability chain |
| 10092-10093 | Catenary detection VarAction2 (multi-range) |
| 10156 | Class 92 definition |
| 14053 | A-Train definition |

### Magic Variables

| Variable | Purpose |
|----------|---------|
| 0x4A | Current railtype index (deprecated but used in UKRS2) |
| 0x63 | Railtype compatibility test (modern, OpenTTD 1.11+) |

## External References

- [NewGRF Specs](https://newgrf-specs.tt-wiki.net/wiki/Main_Page)
- [Action 0 Trains](https://newgrf-specs.tt-wiki.net/wiki/Action0/Vehicles/Trains)
- [Action 0 Railtypes](https://newgrf-specs.tt-wiki.net/wiki/Action0/Railtypes)
- [VarAction2](https://newgrf-specs.tt-wiki.net/wiki/VariationalAction2)
- [VarAction2 Vehicles](https://newgrf-specs.tt-wiki.net/wiki/VariationalAction2/Vehicles)
- [Action 7](https://newgrf-specs.tt-wiki.net/wiki/Action7)
- [Standardized Railtype Scheme](https://newgrf-specs.tt-wiki.net/wiki/Standardized_Railtype_Scheme)
