# S02 - Class Catalog: simple_compression

**Status:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23

---

## 1. Class Hierarchy

```
ZLIB_CONSTANTS (ISE library)
     |
     v
SIMPLE_COMPRESSION (facade)
     |
     +-- creates --> SIMPLE_COMPRESSION_STREAM

ZLIB_CONSTANTS (ISE library)
     |
     v
SIMPLE_COMPRESSION_STREAM (streaming)
```

## 2. Class Descriptions

### SIMPLE_COMPRESSION (Facade)

| Attribute | Value |
|-----------|-------|
| Role | Main entry point for compression |
| Responsibility | Wrap ISE zlib with simple API |
| Creatable | Yes (via `make`, `make_with_level`) |
| Inherits | ZLIB_CONSTANTS |

**Key Responsibilities:**
- Compress/decompress strings
- Compress/decompress byte arrays
- Compress/decompress files
- Format detection (zlib, gzip)
- Checksum calculation (CRC32, Adler-32)
- Statistics tracking
- Stream creation

### SIMPLE_COMPRESSION_STREAM

| Attribute | Value |
|-----------|-------|
| Role | Streaming compression for large data |
| Responsibility | Incremental write, finalize on close |
| Creatable | Yes (via `make_compress`, `make_decompress`) |
| Inherits | ZLIB_CONSTANTS |

**Key Responsibilities:**
- Buffer incoming data
- Compress on close
- Track statistics

## 3. Feature Groupings

### SIMPLE_COMPRESSION Features

| Category | Features |
|----------|----------|
| Access | compression_level, last_error, last_input_size, last_output_size |
| Status Report | is_valid_level, compression_ratio |
| Level Settings | set_level, set_level_fast, set_level_default, set_level_best |
| Level Constants | level_none, level_fast, level_default, level_best |
| String Compression | compress_string, decompress_string, compress_string_base64, decompress_string_base64 |
| Convenience | compress_fast, compress_best |
| Format Detection | is_zlib_format, is_gzip_format, detect_format |
| Checksums | crc32, adler32, validate_checksum |
| Error Messages | error_message |
| Byte Compression | compress_bytes, decompress_bytes |
| File Operations | compress_file, decompress_file, read_compressed_file, write_compressed_file |
| Statistics | last_operation_successful, compression_percentage, space_savings |
| Advanced | compress_with_options, strategy_* constants |
| Streaming | create_compress_stream, create_decompress_stream |
| Dictionary | compress_with_dictionary, estimate_compression_ratio |

### SIMPLE_COMPRESSION_STREAM Features

| Category | Features |
|----------|----------|
| Access | is_compressing, is_open, total_input, total_output, compression_level, last_error |
| Configuration | set_level |
| Operations | write, write_bytes, close, read_all, read_chunk |
| Statistics | compression_ratio |

## 4. Visibility Matrix

| Class | SIMPLE_COMPRESSION | SIMPLE_COMPRESSION_STREAM |
|-------|-------------------|---------------------------|
| SIMPLE_COMPRESSION | - | Creates |
| SIMPLE_COMPRESSION_STREAM | - | - |

## 5. ISE Zlib Integration

### Classes Used

| ISE Class | Purpose |
|-----------|---------|
| ZLIB_CONSTANTS | Compression level constants |
| ZLIB_STRING_COMPRESS | String compression |
| ZLIB_STRING_UNCOMPRESS | String decompression |

### Constants Inherited

| Constant | Value | Purpose |
|----------|-------|---------|
| Z_no_compression | 0 | No compression |
| Z_best_speed | 1 | Fastest compression |
| Z_default_compression | -1 | Default (level 6) |
| Z_best_compression | 9 | Best compression |
| Z_default_window_bits | 15 | Default window size |
| Z_default_strategy | 0 | Default strategy |
| Z_filtered | 1 | Filtered strategy |
| Z_huffman_only | 2 | Huffman only |
| Z_rle | 3 | Run-length encoding |
