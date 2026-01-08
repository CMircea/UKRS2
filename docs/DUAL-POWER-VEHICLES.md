# Dual-Power Vehicles

This document lists all vehicles in UKRS2 that have railtype-dependent behavior.

## Type JB - BR Class 73 (Electro-Diesel)

### Basic Info
- **Vehicle ID**: 0x79
- **Type**: Electro-diesel locomotive
- **Real-world**: BR Class 73, capable of running on 3rd rail electric or diesel power

### Behavior
- **On 3rd rail**: 1420 hp, 177 kN tractive effort, spark effects
- **Diesel fallback**: 600 hp, 160 kN tractive effort, exhaust effects
- **Availability**: Hidden if no 3rd rail track types exist

### Code Locations (ukrs2.nfo)
| Sprite | Line | Purpose |
|--------|------|---------|
| 9441 | ~9962 | VarAction2 power callback (Variable 4A check) |
| 9466 | ~9987 | Secondary power callback reference |
| 9468 | ~9989 | Action 3: links callbacks to vehicle 0x79 |
| 9469 | ~9990 | Action 4: vehicle name "BR Type JB (Electro-Diesel)" |
| 9470-9474 | ~9991-9995 | Action 0: vehicle properties |
| 9491-9521 | ~10012-10042 | Action 7 availability chain (all 3rd rail labels) |
| 9522 | ~10043 | Action 0: hide vehicle if no 3rd rail |
| 9523 | ~10044 | Action 10: label 55 (success jump target) |

### 3rd Rail Detection Logic
```
IF current_railtype_index in [0x02-0x20]:
    use_electric_power()
ELSE:
    use_diesel_power()
```

---

## GEC-Alstom Eurostar (Electric) — Add-on Set

### Basic Info
- **Vehicle ID**: 0xFF 0x2B 0x01 (extended ID in ukrs2-addon.nfo)
- **Type**: High-speed electric multiple unit
- **Real-world**: Eurostar, runs on both 3rd rail (750V DC) and overhead catenary (25kV AC)

### Behavior
- **On catenary**: 186 mph, 16400 hp
- **On 3rd rail**: 110 mph, 4600 hp
- **Track preference**: Prefers 3RDC (3rd rail + catenary combined)

### Code Locations (ukrs2-addon.nfo)
| Sprite | Line | Purpose |
|--------|------|---------|
| 3120 | ~3325 | VarAction2 speed callback (Variable 4A catenary check) |
| 3130 | ~3337 | Secondary speed callback |
| 3136 | ~3343 | Action 4: vehicle name "GEC-Alstom Eurostar (Electric)" |

### Catenary Detection Logic (for speed)
```
IF current_railtype_index in [0x01, 0x03, 0x05, 0x07, 0x17-0x2A]:
    use_high_speed()  // catenary available
ELSE:
    use_low_speed()   // 3rd rail only
```

---

## Hitachi A-Train (Electric)

### Basic Info
- **Vehicle ID**: 0x69
- **Type**: Electric multiple unit
- **Real-world**: Modern UK EMU, dual-voltage capable

### Behavior
- **On catenary**: 155 mph
- **On 3rd rail**: 100 mph

### Code Locations (ukrs2.nfo)
| Sprite | Line | Purpose |
|--------|------|---------|
| 13999 | ~14556 | VarAction2 speed callback (Variable 4A catenary check) |
| 14039 | ~14598 | Wagon compatibility check (GRFID) |
| 14053 | ~14612 | Action 4: vehicle name "Hitachi A-Train (Electric)" |
| 14054-14057 | ~14613-14616 | Action 0: vehicle properties |
| 14058 | ~14617 | Action 7: track type check |

### Speed Callback Logic
Same catenary detection as Eurostar - 5 disjoint ranges.

---

## Brush Class 92 (Electric)

### Basic Info
- **Vehicle ID**: 0x62
- **Type**: Dual-voltage electric freight locomotive
- **Real-world**: Class 92, operates on 750V DC 3rd rail and 25kV AC catenary

### Behavior
- **On catenary**: 6700 hp
- **On 3rd rail**: 5360 hp
- **Designed for**: Channel Tunnel freight

### Code Locations (ukrs2.nfo)
| Sprite | Line | Purpose |
|--------|------|---------|
| 10092 | ~10616 | VarAction2 catenary detection (5 ranges) |
| 10093 | ~10617 | VarAction2 3rd rail detection (5 ranges) |
| 10122-10131 | ~10646-10655 | Power callbacks |
| 10156 | ~10680 | Action 4: vehicle name "Brush Class 92 (Electric)" |
| 10157-10161 | ~10681-10685 | Action 0: vehicle properties |
| 10162 | ~10686 | Action 7: track type check (3RDC) |

### Dual Detection Logic
The Class 92 checks for BOTH 3rd rail AND catenary separately:
```
catenary_available = check_catenary_indexes()
third_rail_available = check_third_rail_indexes()

power = calculate_power(catenary_available, third_rail_available)
```

---

## Bidwell Tripworker (Electric)

### Basic Info
- **Type**: Electric multiple unit
- **Real-world**: Dual-voltage EMU

### Behavior
- Dual-voltage: operates on both 3rd rail and catenary

---

## ABB Class 325 (Electric)

### Basic Info
- **Type**: Electric multiple unit (mail/parcels)
- **Real-world**: Class 325, dual-voltage postal EMU

### Behavior
- Dual-voltage: operates on both 3rd rail and catenary

---

## Electrostar (Electric)

### Basic Info
- **Type**: Electric multiple unit
- **Real-world**: Bombardier Electrostar family, dual-voltage variants

### Behavior
- Dual-voltage: operates on both 3rd rail and catenary

---

## BREL Class 313 (Electric) — Add-on Set

### Basic Info
- **Type**: Electric multiple unit
- **Real-world**: Class 313, dual-voltage suburban EMU

### Behavior
- Dual-voltage: operates on both 3rd rail and catenary

---

## Summary Table

| Vehicle | Set | Catenary | 3rd Rail | Varies |
|---------|-----|----------|----------|--------|
| Type JB (Class 73) | Main | — | 1420 hp / 177 kN | Power + TE + Effects (diesel: 600 hp / 160 kN) |
| Brush Class 92 | Main | 6700 hp | 5360 hp | Power |
| Hitachi A-Train | Main | 155 mph | 100 mph | Speed |
| Bidwell Tripworker | Main | ✓ | ✓ | — |
| ABB Class 325 | Main | ✓ | ✓ | — |
| Electrostar | Main | ✓ | ✓ | — |
| BREL Class 313 | Add-on | ✓ | ✓ | — |
| GEC-Alstom Eurostar | Add-on | 186 mph / 16400 hp | 110 mph / 4600 hp | Speed + Power |

---

## Common Patterns

### 3rd Rail Index Range
All 3rd rail checks use range **0x02 - 0x20**, which covers:
- Legacy: 3RDR, 3RDC
- Non-standard: 3LOW, 3MED, MTRO, etc.
- Standardized: SAA3 through SUA3, SAAZ through SUAZ

### Catenary Index Ranges
Catenary checks require **5 disjoint ranges**:
- 0x01-0x01: ELRL (legacy)
- 0x03-0x03: 3RDC (legacy combined)
- 0x05-0x05: CLOW (non-standard)
- 0x07-0x07: CMED (non-standard)
- 0x17-0x2A: SAAZ through SUAE (standardized)

This is because catenary track indexes are not contiguous in the translation table.

---

## Maintenance

For instructions on updating these vehicles to support new track types, see [FIXING-RAILTYPE-COMPATIBILITY.md](FIXING-RAILTYPE-COMPATIBILITY.md).
