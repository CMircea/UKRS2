# NFO Decompilation Artifacts

## The Problem

grfcodec converts GRF files to NFO (human-readable) format. When it encounters bytes that happen to be printable ASCII, it displays them as characters - even when they're not meant to be strings.

This can make the decompiled output confusing or misleading.

## The "U" Example

In the Type JB availability chain, you might see:

```nfo
9491 * 9    07 00 04 0E "3RDRU"
```

This looks like a 5-character railtype label, but it's actually:

```nfo
9491 * 9    07 00 04 0E "3RDR" 55
                       ↑↑↑↑↑  ↑↑
                       Label  Jump target (byte 55 = 0x37 = ASCII 'U')
```

The byte `55` (decimal) is the Action 7 jump target (label ID to skip to). grfcodec displays it as 'U' because 0x55 = 85 decimal = ASCII 'U'.

**PikkaBird's explanation** (Feb 20, 2018):
> The "U" is the byte label 55, which grfcodec has **inappropriately converted to an ASCII character**.

## Other Potential Artifacts

Any byte in the printable ASCII range (0x20-0x7E) might be displayed as a character when it's actually:
- A jump target or label ID
- A count or size field
- Part of a numeric value
- A callback ID

Common problematic values:
| Byte (dec) | Byte (hex) | ASCII | Often used as |
|------------|------------|-------|---------------|
| 32 | 0x20 | space | Index/count |
| 48-57 | 0x30-0x39 | 0-9 | Various |
| 55 | 0x37 | 7 | Label ID |
| 65-90 | 0x41-0x5A | A-Z | Various |
| 85 | 0x55 | U | Label ID (55 decimal) |
| 87 | 0x57 | W | Label ID |
| 88 | 0x58 | X | Label ID |

## How to Identify Artifacts

1. **Check the context**: Railtype labels are always exactly 4 characters
2. **Check the Action format**: Action 7 has a specific byte layout - the last byte is usually a jump target
3. **Look at the sprite size**: `9491 * 9` means 9 bytes total - count them to see where strings end
4. **Compare with specs**: Cross-reference with [NewGRF specs](https://newgrf-specs.tt-wiki.net/wiki/Action7) to understand expected byte positions

## The Inline Comments Fix

This is why the inline comments in `ukrs2.nfo` explicitly show the byte breakdown:

```nfo
9491 * 9  07 00 04 0E "3RDR" 55  // If 3RDR defined, jump to label 55 (available)
```

The comment makes it clear that `55` is a jump target, not part of the label.
