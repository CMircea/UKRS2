# UKRS2 Technical Documentation

This documentation explains the internal mechanics of the UK Railway Set (UKRS2), specifically focused on railtype compatibility and how trains detect and respond to different track types.

## Overview

UKRS2 is a NewGRF for OpenTTD/TTDPatch that provides UK railway vehicles. Several vehicles in this set are "dual-mode" - they can operate on multiple track types with different performance characteristics:

- **Electro-diesels**: Run on diesel power by default, upgrade to electric power on 3rd rail track
- **Dual-voltage electrics**: Adjust speed based on whether overhead catenary or 3rd rail power is available

This requires complex detection logic to determine what track type the train is currently on.

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
| [AFFECTED-VEHICLES.md](AFFECTED-VEHICLES.md) | List of vehicles with railtype-dependent behavior |
| [GRFID-TRAP.md](GRFID-TRAP.md) | The GRFID change history and 89 25 / 8A 25 patterns |

### Maintenance Guides

| File | Description |
|------|-------------|
| [FIXING-COMPATIBILITY.md](FIXING-COMPATIBILITY.md) | Step-by-step guide to fix railtype compatibility issues |
| [VARIABLE-63-MODERN-FIX.md](VARIABLE-63-MODERN-FIX.md) | Modern approach using Variable 63 (OpenTTD 1.11+) |

### Archaeology (Comprehensive Context)

| File | Description |
|------|-------------|
| [ARCHAEOLOGY-COMPLETE-CONTEXT.md](ARCHAEOLOGY-COMPLETE-CONTEXT.md) | Complete context document for future maintainers |
| [ARCHAEOLOGY-NFO-DEEP-DIVE.md](ARCHAEOLOGY-NFO-DEEP-DIVE.md) | Byte-level NFO structure analysis |

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

### Index Ranges in Translation Table

| Track Type | Index Range |
|------------|-------------|
| Plain rail (unpowered) | 0x00 |
| 3rd rail available | 0x02 - 0x20 |
| Catenary available | 0x01, 0x03, 0x05, 0x07, 0x17 - 0x2A |

### Magic Variables

| Variable | Purpose |
|----------|---------|
| 0x4A | Current railtype index (deprecated but used in UKRS2) |
| 0x63 | Railtype compatibility test (modern, OpenTTD 1.11+) |

## Historical Notes

- PikkaBird released UKRS2 **v1.05** on Jan 2, 2013 (the last official version)
- CMircea forked it in Feb 2018 as "UKRS2 - Community Bugfixes"
- CMircea released **v1.06** on Sept 7, 2020 with full standard railtype support
- Variable 63 was added to OpenTTD in version 1.11 (2021) - too late for UKRS2's architecture
- The original code uses Variable 4A, which requires enumerating all possible railtype labels
- Modern track sets use the Standardized Railtype Scheme, which UKRS2 now supports

## External References

- [NewGRF Specs](https://newgrf-specs.tt-wiki.net/wiki/Main_Page)
- [Action 0 Trains](https://newgrf-specs.tt-wiki.net/wiki/Action0/Vehicles/Trains)
- [Action 0 Railtypes](https://newgrf-specs.tt-wiki.net/wiki/Action0/Railtypes)
- [VarAction2](https://newgrf-specs.tt-wiki.net/wiki/VariationalAction2)
- [VarAction2 Vehicles](https://newgrf-specs.tt-wiki.net/wiki/VariationalAction2/Vehicles)
- [Action 7](https://newgrf-specs.tt-wiki.net/wiki/Action7)
- [Standardized Railtype Scheme](https://newgrf-specs.tt-wiki.net/wiki/Standardized_Railtype_Scheme)
