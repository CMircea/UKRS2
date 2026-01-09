# Standardized Railtype Scheme

## Overview

The Standardized Railtype Scheme is a naming convention for railtype labels that allows different track sets to be compatible with each other. It was introduced around 2015 to solve the problem of different track sets using different labels for similar track types.

**Reference**: https://newgrf-specs.tt-wiki.net/wiki/Standardized_Railtype_Scheme

## Label Format

Labels are 4 characters: `[Gauge][Speed][Axle][Power]`

### Position 1: Gauge
| Code | Meaning |
|------|---------|
| S | Standard gauge |
| N | Narrow gauge |
| D | Dual gauge (or "any" gauge) |

### Position 2: Speed Class
| Code | Speed Limit |
|------|-------------|
| A | All speeds (no limit) |
| B | Very high speed (300+ km/h) |
| C | High speed (200-300 km/h) |
| D | Medium-high (160-200 km/h) |
| E | Medium (120-160 km/h) |
| F | Low-medium (90-120 km/h) |
| G | Low (60-90 km/h) |
| H | Very low (<60 km/h) |
| S | Subterranean (metro, underground) |
| U | Urban (light rail, tram) |

### Position 3: Axle Weight
| Code | Meaning |
|------|---------|
| A | Any (no restriction) |
| B | Heavy |
| C | Medium |
| D | Light |

### Position 4: Power Type
| Code | Meaning |
|------|---------|
| N | None (unpowered) |
| E | Electric (catenary) |
| 3 | 3rd rail |
| Z | Both catenary and 3rd rail |
| D | Diesel |

## Examples

| Label | Meaning |
|-------|---------|
| `SAAN` | Standard gauge, Any speed, Any axle, No power |
| `SAAE` | Standard gauge, Any speed, Any axle, Electric catenary |
| `SAA3` | Standard gauge, Any speed, Any axle, 3rd rail |
| `SAAZ` | Standard gauge, Any speed, Any axle, Both 3rd rail + catenary |
| `SDAE` | Standard gauge, Speed D (160-200 km/h), Any axle, Electric |
| `NAAE` | Narrow gauge, Any speed, Any axle, Electric |
| `SSAE` | Standard gauge, Subterranean, Any axle, Electric |
| `SUAZ` | Standard gauge, Urban, Any axle, 3rd rail + catenary |

## Fallback Mechanism

Track types can declare "fallback" types using Property 1D. If a vehicle requires a track type that doesn't exist, the game will try the fallback.

Example fallback chain:
```
SDAE → SAAE → ELRL → RAIL
(fast electric → any electric → legacy electric → plain rail)
```

**Important**: VarAction2 does NOT use fallbacks! When checking the current track type with Variable 4A, you get the exact label, not any fallback. This is why UKRS2 must enumerate all possible labels.

## Why UKRS2 Needs So Many Labels

UKRS2 was originally written for legacy labels:
- `RAIL` - Plain rail
- `ELRL` - Electric catenary
- `3RDR` - 3rd rail
- `3RDC` - 3rd rail + catenary

When the Standardized Scheme was introduced, UKRS2 needed to recognize all the new labels (`SAA3`, `SAAE`, `SAAZ`, etc.) to properly detect track power at runtime.

The translation table in UKRS2 now has 43 entries to cover:
- 4 legacy labels
- 9 non-standard legacy labels (metro, etc.)
- 30 standardized labels

## Legacy vs Modern Track Sets

| Era | Labels Used |
|-----|-------------|
| Pre-2015 | `RAIL`, `ELRL`, `3RDR`, `3RDC` |
| Post-2015 | Standardized (`SAAE`, `SAA3`, etc.) |

Modern track sets typically define fallbacks so that vehicles using legacy labels still work. But for VarAction2 power detection, you must explicitly check for both legacy AND standardized labels.

## UKRS2 Index Mapping

| Label Type | Index Range |
|------------|-------------|
| Legacy 3rd rail | 0x02-0x03 |
| Non-standard 3rd rail | 0x04-0x0C |
| Standardized 3rd rail | 0x0D-0x16 |
| Standardized 3rd+catenary | 0x17-0x20 |
| Legacy catenary | 0x01 |
| Legacy 3rd+catenary | 0x03 |
| Standardized catenary | 0x21-0x2A |

See also: [RAIL-TRANSLATION-TABLE.md](RAIL-TRANSLATION-TABLE.md)
