# S01 - Project Inventory: simple_compression

**Status:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23
**Library Version:** 1.0.0

---

## 1. Project Identity

| Attribute | Value |
|-----------|-------|
| Name | simple_compression |
| Purpose | Data compression wrapper for ISE zlib library |
| Domain | Data Compression |
| Facade Class | SIMPLE_COMPRESSION |
| ECF File | simple_compression.ecf |

## 2. File Inventory

### Source Files (src/)

| File | Class | Purpose |
|------|-------|---------|
| simple_compression.e | SIMPLE_COMPRESSION | Main facade - compress/decompress strings, bytes, files |
| simple_compression_stream.e | SIMPLE_COMPRESSION_STREAM | Streaming compression for large data |

### Test Files (testing/)

| File | Purpose |
|------|---------|
| test_app.e | Test application entry point |
| lib_tests.e | Library test suite |
| test_set_base.e | Base test set class |

## 3. Dependencies

### ISE Libraries

| Library | Purpose |
|---------|---------|
| base | Core Eiffel classes |
| zlib | ISE zlib wrapper (ZLIB_STRING_COMPRESS, etc.) |

### simple_* Libraries

| Library | Purpose |
|---------|---------|
| simple_base64 | Base64 encoding for compressed data |

### External Dependencies

| Dependency | Type | Purpose |
|------------|------|---------|
| zlibwapi.dll | Windows DLL | Zlib implementation |
| libz.so | Linux SO | Zlib implementation |

## 4. Platform Requirements

| Requirement | Value |
|-------------|-------|
| OS | Windows, Linux (with zlib) |
| Architecture | x64 |
| Compiler | EiffelStudio 25.02+ |
| External | zlib library |

## 5. Documentation Assets

| File | Status |
|------|--------|
| README.md | Present |
| CHANGELOG.md | Present |
| research/SIMPLE_COMPRESSION_RESEARCH.md | Present (comprehensive) |
| docs/index.html | Present |

## 6. Known Limitations

1. Zlib library must be installed/deployed
2. No streaming decompression (only compression)
3. No gzip file format (header/footer) - raw zlib only
4. Dictionary compression not fully implemented
5. No compression bomb protection
