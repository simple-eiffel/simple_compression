# S06 - Boundaries: simple_compression

**Status:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23

---

## 1. External Boundaries

### ISE Zlib Integration

```
simple_compression
     |
     v
+-------------------+
| SIMPLE_COMPRESSION|
+-------------------+
     |
     | wraps
     v
+-------------------+
| ISE zlib library  |
| - ZLIB_CONSTANTS  |
| - ZLIB_STRING_*   |
+-------------------+
     |
     | calls
     v
+-------------------+
| zlib native lib   |
| - zlibwapi.dll    |
| - libz.so         |
+-------------------+
```

### File System Integration

```
Application
     |
     | compress_file / decompress_file
     v
SIMPLE_COMPRESSION
     |
     | RAW_FILE
     v
File System
```

### Base64 Integration

```
SIMPLE_COMPRESSION
     |
     | compress_string_base64
     v
SIMPLE_BASE64
     |
     v
Base64 encoded string
```

---

## 2. Internal Module Boundaries

### Facade Pattern

```
Client Code
     |
     v
+-------------------+
| SIMPLE_COMPRESSION|  <-- Facade
+-------------------+
     |
     +-- String ops (uses ZLIB_STRING_COMPRESS/UNCOMPRESS)
     |
     +-- Byte ops (converts to/from strings)
     |
     +-- File ops (uses RAW_FILE + string ops)
     |
     +-- Stream factory (creates SIMPLE_COMPRESSION_STREAM)
```

### Stream Separation

```
SIMPLE_COMPRESSION (stateless operations)
     |
     | create_compress_stream / create_decompress_stream
     v
SIMPLE_COMPRESSION_STREAM (stateful operations)
```

---

## 3. Data Flow Boundaries

### Compression Flow

```
String input
     | compress_string
     v
Convert to internal format
     |
     v
ZLIB_STRING_COMPRESS.put_string
     |
     v
Compressed output STRING
```

### Decompression Flow

```
Compressed STRING
     |
     v
ZLIB_STRING_UNCOMPRESS.string_stream
     |
     v
to_string
     |
     v
Original STRING
```

### Byte Array Flow

```
ARRAY [NATURAL_8]
     |
     | Convert to STRING (byte-by-byte)
     v
compress_string
     |
     v
Compressed STRING
     |
     | Convert to ARRAY [NATURAL_8]
     v
ARRAY [NATURAL_8]
```

### File Flow

```
Source file path
     |
     | RAW_FILE.read_stream
     v
File content STRING
     |
     | compress_string
     v
Compressed STRING
     |
     | RAW_FILE.put_string
     v
Destination file
```

---

## 4. Error Boundaries

### Error Sources

| Source | Detection | Recovery |
|--------|-----------|----------|
| File not found | RAW_FILE.exists | Return False, set last_error |
| Invalid compressed data | ZLIB exception | Return empty, set last_error |
| Out of memory | ZLIB Z_MEM_ERROR | Exception |
| Buffer overflow | Handled by ISE | Automatic resizing |

### Error Propagation

```
ZLIB error code
     |
     v
error_message(code)
     |
     v
last_error := message
     |
     v
Return False / empty
     |
     v
Client checks last_error
```

---

## 5. Output Boundaries

### Compressed Data Format

| Format | Header | Checksum |
|--------|--------|----------|
| Raw zlib | 78 xx | Adler-32 (4 bytes) |
| Gzip | 1F 8B ... | CRC32 (4 bytes) |

### Base64 Output

```
Raw compressed bytes
     |
     v
Base64 encoding
     |
     v
Safe ASCII string (A-Za-z0-9+/=)
```

---

## 6. Scope Boundaries

### In Scope

- Zlib format compression/decompression
- String data handling
- Byte array handling
- File compression/decompression
- Format detection (zlib, gzip)
- CRC32 and Adler-32 checksums
- Compression statistics
- Streaming compression
- Compression level control
- Window bits and strategy options

### Out of Scope

- Gzip file format (with headers/trailer)
- Tar/archive support
- Password protection/encryption
- Multi-file archives
- Compression bomb protection
- Memory-mapped file support
- Async/SCOOP compression
- Progress callbacks

### Integration Points

| Feature | External Library |
|---------|-----------------|
| Encryption | simple_encryption |
| Archives | simple_archive |
| JSON compression | simple_json + this |
| HTTP compression | simple_http + this |

---

## 7. API Boundaries

### Public API

All features in SIMPLE_COMPRESSION are public and intended for client use.

### Internal Details

| Detail | Exposure |
|--------|----------|
| crc32_table | Private (once function) |
| ISE zlib classes | Private (implementation detail) |
| Buffer management | Automatic (hidden) |

---

## 8. Platform Boundaries

### Windows Specific

| Aspect | Handling |
|--------|----------|
| DLL location | Must be in PATH or app directory |
| Path separators | Handled by RAW_FILE |
| Unicode paths | Via READABLE_STRING_GENERAL |

### Linux Specific

| Aspect | Handling |
|--------|----------|
| Shared library | Must be installed (apt install zlib1g) |
| File permissions | Standard Unix permissions |
