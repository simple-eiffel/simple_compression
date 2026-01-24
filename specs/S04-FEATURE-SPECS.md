# S04 - Feature Specifications: simple_compression

**Status:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23

---

## 1. Compression Levels

| Level | Constant | Speed | Ratio | Use Case |
|-------|----------|-------|-------|----------|
| 0 | level_none | Fastest | None | Testing, already compressed |
| 1 | level_fast | Fast | Low | Real-time, streaming |
| 6 | level_default (-1) | Balanced | Good | General purpose |
| 9 | level_best | Slow | Best | Archives, storage |

---

## 2. String Compression Features

### compress_string

| Attribute | Value |
|-----------|-------|
| Signature | `compress_string (a_input: STRING): STRING` |
| Purpose | Compress string to raw zlib format |
| Algorithm | Use ZLIB_STRING_COMPRESS, apply compression_level |
| Return | Raw compressed bytes as STRING |
| Side Effects | Updates last_input_size, last_output_size |

### decompress_string

| Attribute | Value |
|-----------|-------|
| Signature | `decompress_string (a_compressed: STRING): STRING` |
| Purpose | Decompress zlib data to original string |
| Algorithm | Use ZLIB_STRING_UNCOMPRESS |
| Return | Original uncompressed string |
| Side Effects | Updates last_input_size, last_output_size |

### compress_string_base64

| Attribute | Value |
|-----------|-------|
| Signature | `compress_string_base64 (a_input: STRING): STRING` |
| Purpose | Compress and encode for text storage |
| Algorithm | 1. compress_string; 2. Base64 encode |
| Return | Base64 encoded compressed data |
| Use Case | JSON, databases, text files |

### decompress_string_base64

| Attribute | Value |
|-----------|-------|
| Signature | `decompress_string_base64 (a_base64: STRING): STRING` |
| Purpose | Decode and decompress Base64 data |
| Algorithm | 1. Base64 decode; 2. decompress_string |
| Return | Original uncompressed string |

---

## 3. File Operations

### compress_file

| Attribute | Value |
|-----------|-------|
| Signature | `compress_file (a_source_path, a_dest_path: STRING): BOOLEAN` |
| Purpose | Compress file to zlib format |
| Algorithm | 1. Read source; 2. compress_string; 3. Write dest |
| Return | True on success, False on failure |
| Error | last_error set on failure |

### decompress_file

| Attribute | Value |
|-----------|-------|
| Signature | `decompress_file (a_source_path, a_dest_path: STRING): BOOLEAN` |
| Purpose | Decompress zlib file |
| Algorithm | 1. Read source; 2. decompress_string; 3. Write dest |
| Return | True on success, False on failure |
| Error | last_error set on failure |

### read_compressed_file

| Attribute | Value |
|-----------|-------|
| Signature | `read_compressed_file (a_path: STRING): STRING` |
| Purpose | Read and decompress file in one call |
| Return | Decompressed content (empty on error) |

### write_compressed_file

| Attribute | Value |
|-----------|-------|
| Signature | `write_compressed_file (a_path: STRING; a_content: STRING): BOOLEAN` |
| Purpose | Compress and write file in one call |
| Return | True on success |

---

## 4. Format Detection

### is_zlib_format

| Attribute | Value |
|-----------|-------|
| Signature | `is_zlib_format (a_data: STRING): BOOLEAN` |
| Purpose | Check for zlib magic bytes |
| Algorithm | First byte = 0x78 (120 decimal) |
| Note | Second byte varies by compression level |

### is_gzip_format

| Attribute | Value |
|-----------|-------|
| Signature | `is_gzip_format (a_data: STRING): BOOLEAN` |
| Purpose | Check for gzip magic bytes |
| Algorithm | First two bytes = 0x1F 0x8B |

### detect_format

| Attribute | Value |
|-----------|-------|
| Signature | `detect_format (a_data: STRING): STRING` |
| Purpose | Identify compression format |
| Return | "zlib", "gzip", or "unknown" |

---

## 5. Checksum Features

### crc32

| Attribute | Value |
|-----------|-------|
| Signature | `crc32 (a_data: STRING): NATURAL_32` |
| Purpose | Calculate CRC32 checksum |
| Algorithm | IEEE CRC32 polynomial (0xEDB88320) |
| Use Case | Gzip format, data integrity |

### adler32

| Attribute | Value |
|-----------|-------|
| Signature | `adler32 (a_data: STRING): NATURAL_32` |
| Purpose | Calculate Adler-32 checksum |
| Algorithm | Standard Adler-32 (faster than CRC32) |
| Use Case | Zlib format verification |

### validate_checksum

| Attribute | Value |
|-----------|-------|
| Signature | `validate_checksum (a_data: STRING; a_expected_crc: NATURAL_32): BOOLEAN` |
| Purpose | Verify data integrity |
| Return | True if CRC32 matches expected |

---

## 6. Statistics Features

### compression_ratio

| Attribute | Value |
|-----------|-------|
| Signature | `compression_ratio: REAL_64` |
| Purpose | Input/output size ratio |
| Calculation | last_input_size / last_output_size |
| Example | 3.0 means compressed to 1/3 of original |

### compression_percentage

| Attribute | Value |
|-----------|-------|
| Signature | `compression_percentage: REAL_64` |
| Purpose | Percentage size reduction |
| Calculation | ((input - output) / input) * 100 |
| Example | 75.0 means 75% smaller |

### space_savings

| Attribute | Value |
|-----------|-------|
| Signature | `space_savings: STRING` |
| Purpose | Human-readable summary |
| Example | "10000 -> 2500 bytes (75% reduction, 4x ratio)" |

---

## 7. Error Handling

### Error Codes

| Code | Constant | Message |
|------|----------|---------|
| 0 | Z_OK | Success |
| 1 | Z_STREAM_END | Stream end |
| 2 | Z_NEED_DICT | Need dictionary |
| -1 | Z_ERRNO | Errno |
| -2 | Z_STREAM_ERROR | Invalid parameters |
| -3 | Z_DATA_ERROR | Corrupted data |
| -4 | Z_MEM_ERROR | Out of memory |
| -5 | Z_BUF_ERROR | Buffer too small |
| -6 | Z_VERSION_ERROR | Version mismatch |

### error_message

| Attribute | Value |
|-----------|-------|
| Signature | `error_message (a_code: INTEGER): STRING` |
| Purpose | Convert error code to message |
| Return | Human-readable error description |
