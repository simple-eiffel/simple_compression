# S07 - Specification Summary: simple_compression

**Status:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23

---

## 1. Library Overview

**simple_compression** is a data compression library for Eiffel, wrapping the ISE zlib library with a simple, safe API for compressing strings, byte arrays, and files.

### Key Capabilities

| Capability | Description |
|------------|-------------|
| String Compression | Compress/decompress STRING data |
| Byte Array | Compress/decompress ARRAY [NATURAL_8] |
| File Operations | Compress/decompress files |
| Base64 Integration | Safe text storage of compressed data |
| Format Detection | Identify zlib vs gzip format |
| Checksums | CRC32 and Adler-32 calculation |
| Statistics | Compression ratio and space savings |
| Streaming | Incremental compression for large data |
| Levels | 0 (none) to 9 (best) compression |

---

## 2. Architecture Summary

### Component Count

| Component | Count |
|-----------|-------|
| Classes | 2 |
| Public Features | 40+ |
| Preconditions | 47 |
| Postconditions | 40 |
| Class Invariants | 1 |

### Design Patterns

| Pattern | Application |
|---------|-------------|
| Facade | SIMPLE_COMPRESSION hides ISE zlib complexity |
| Factory | Stream creation via facade |
| Wrapper | Thin wrapper over ISE classes |

---

## 3. API Quick Reference

### Basic Usage

```eiffel
compression: SIMPLE_COMPRESSION
create compression.make

-- Compress string
compressed := compression.compress_string ("Hello, World!")
decompressed := compression.decompress_string (compressed)

-- Compress with Base64 (for text storage)
base64 := compression.compress_string_base64 (data)
original := compression.decompress_string_base64 (base64)

-- Compress file
if compression.compress_file ("input.txt", "input.txt.z") then
    print ("Compressed successfully%N")
    print (compression.space_savings)
end
```

### Level Selection

```eiffel
-- Fast compression
compression.set_level_fast
compressed := compression.compress_string (data)

-- Best compression
compression.set_level_best
compressed := compression.compress_string (data)

-- Custom level
compression.set_level (5)

-- One-off fast/best without changing default
fast := compression.compress_fast (data)
best := compression.compress_best (data)
```

### Format Detection

```eiffel
if compression.is_zlib_format (data) then
    decompressed := compression.decompress_string (data)
elseif compression.is_gzip_format (data) then
    -- Note: gzip decompression not fully supported
end

format := compression.detect_format (data)  -- "zlib", "gzip", or "unknown"
```

### Checksums

```eiffel
crc := compression.crc32 (data)
adler := compression.adler32 (data)

if compression.validate_checksum (data, expected_crc) then
    -- Data integrity verified
end
```

### Streaming

```eiffel
stream := compression.create_compress_stream ("output.z")
stream.write ("chunk 1...")
stream.write ("chunk 2...")
stream.close
print ("Ratio: " + stream.compression_ratio.out)
```

---

## 4. Constraint Summary

### Compression Levels

| Level | Constant | Description |
|-------|----------|-------------|
| 0 | level_none | No compression |
| 1 | level_fast | Fastest |
| -1 | level_default | Default (6) |
| 9 | level_best | Best compression |

### Format Magic Bytes

| Format | Bytes |
|--------|-------|
| Zlib | 78 xx |
| Gzip | 1F 8B |

---

## 5. Dependencies

### Required

| Dependency | Purpose |
|------------|---------|
| ISE base library | Core Eiffel classes |
| ISE zlib library | Compression implementation |
| simple_base64 | Base64 encoding |
| zlib native | Platform-specific DLL/SO |

---

## 6. Platform Support

| Platform | Status | Requirement |
|----------|--------|-------------|
| Windows | Supported | zlibwapi.dll |
| Linux | Supported | libz.so (apt install zlib1g) |
| macOS | Likely | libz.dylib |

---

## 7. Performance Characteristics

| Operation | Complexity | Notes |
|-----------|------------|-------|
| Compression | O(n) | n = input size |
| Decompression | O(n) | n = compressed size |
| CRC32 | O(n) | n = data size |
| Format detection | O(1) | Checks first 2 bytes |

### Compression Ratios

| Data Type | Expected Ratio |
|-----------|----------------|
| English text | 2.5x - 3x |
| Source code | 3x - 4x |
| Random/binary | 1x (no compression) |
| Already compressed | < 1x (slight expansion) |

---

## 8. Completeness Assessment

### Implemented Features

- [x] String compression/decompression
- [x] Byte array compression/decompression
- [x] File compression/decompression
- [x] Base64 encoding
- [x] Compression levels
- [x] Format detection
- [x] CRC32 checksum
- [x] Adler-32 checksum
- [x] Compression statistics
- [x] Streaming compression
- [x] Advanced options (window bits, strategy)
- [x] Error messages

### Not Implemented (Future)

- [ ] Full gzip format support (headers/trailer)
- [ ] Streaming decompression
- [ ] Compression bomb protection
- [ ] Progress callbacks
- [ ] Async/SCOOP support
- [ ] Dictionary presets

---

## 9. Usage Recommendations

### Best Practices

1. **Use Base64** for text storage (JSON, databases)
2. **Check format** before decompressing unknown data
3. **Use streaming** for large files (> 100MB)
4. **Validate checksums** for critical data
5. **Handle errors** via last_error check

### Common Pitfalls

| Pitfall | Solution |
|---------|----------|
| Missing zlib DLL | Deploy with application |
| Decompression fails | Check format, validate checksum |
| Memory issues | Use streaming for large data |
| Level unchanged | compress_fast/best restore level |
