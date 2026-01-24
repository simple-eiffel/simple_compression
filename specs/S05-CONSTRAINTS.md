# S05 - Constraints: simple_compression

**Status:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23

---

## 1. Compression Level Constraints

| Level | Value | Valid |
|-------|-------|-------|
| Z_no_compression | 0 | Yes |
| Z_best_speed | 1 | Yes |
| Levels 2-8 | 2-8 | Yes |
| Z_best_compression | 9 | Yes |
| Z_default_compression | -1 | Yes |
| Other | < -1 or > 9 | No |

### Validation

```eiffel
is_valid_level (a_level: INTEGER): BOOLEAN
    Result := a_level = Z_default_compression or else
              (a_level >= Z_no_compression and a_level <= Z_best_compression)
```

---

## 2. Input Constraints

### String Input

| Constraint | Requirement |
|------------|-------------|
| Not Void | a_input /= Void |
| For decompression | Not empty |

### Byte Array Input

| Constraint | Requirement |
|------------|-------------|
| Not Void | a_input /= Void |
| Not empty | a_input.count > 0 |

### File Path Input

| Constraint | Requirement |
|------------|-------------|
| Not empty | not a_path.is_empty |
| For compression | File must exist and be readable |
| For decompression | File must contain valid compressed data |

---

## 3. Output Constraints

### Compression Output

| Constraint | Description |
|------------|-------------|
| Never Void | Result /= Void |
| May be larger | Incompressible data can expand |
| Maximum expansion | ~0.015% for DEFLATE |

### Decompression Output

| Constraint | Description |
|------------|-------------|
| Never Void | Result /= Void |
| May be empty | On error, returns empty string |
| Size unbounded | No protection against compression bombs |

---

## 4. Format Detection Constraints

### Zlib Format

| Byte | Value | Meaning |
|------|-------|---------|
| 0 | 0x78 | CMF (CM=8, CINFO=7) |
| 1 | Varies | FLG (level-dependent) |

| Level | Second Byte |
|-------|-------------|
| 1 (fast) | 0x01 or 0x5E |
| 6 (default) | 0x9C |
| 9 (best) | 0xDA |

### Gzip Format

| Bytes | Value | Meaning |
|-------|-------|---------|
| 0-1 | 0x1F 0x8B | Magic number |
| 2 | 0x08 | Compression method (DEFLATE) |

---

## 5. Window Bits Constraints

| Value | Description |
|-------|-------------|
| 8 | Minimum window size |
| 15 | Maximum window size (default) |
| < 8 | Invalid |
| > 15 | Invalid |

### Memory Usage

| Window Bits | Window Size | Memory |
|-------------|-------------|--------|
| 8 | 256 bytes | Low |
| 10 | 1 KB | Low |
| 12 | 4 KB | Medium |
| 15 | 32 KB | Default |

---

## 6. Strategy Constraints

| Strategy | Constant | Use Case |
|----------|----------|----------|
| Default | Z_default_strategy | General data |
| Filtered | Z_filtered | Data with lots of small values |
| Huffman Only | Z_huffman_only | Fast, poor compression |
| RLE | Z_rle | Images with long runs |

---

## 7. Streaming Constraints

### Compression Stream

| Constraint | Description |
|------------|-------------|
| Write before close | Data accumulated in buffer |
| Close finalizes | Compression happens on close |
| Single close | Cannot close twice |

### Decompression Stream

| Constraint | Description |
|------------|-------------|
| Close before read | Decompression happens on close |
| Read after close | Returns decompressed data |

### State Machine

```
[Created] --write--> [Writing] --close--> [Closed]
                         |
                         +--write--> [Writing]
```

---

## 8. Thread Safety

| Component | Thread Safety |
|-----------|---------------|
| SIMPLE_COMPRESSION | Not thread-safe |
| SIMPLE_COMPRESSION_STREAM | Not thread-safe |
| Shared state | last_input_size, last_output_size |

**Recommendation:** Create separate instances per thread.

---

## 9. External Dependency Constraints

### Windows

| Dependency | Location |
|------------|----------|
| zlibwapi.dll | Application directory or PATH |

### Linux

| Dependency | Location |
|------------|----------|
| libz.so | System library path |

### Missing Library Error

If zlib is not available:
- Operations may crash
- No graceful error handling
- last_error may not be set
