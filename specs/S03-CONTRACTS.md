# S03 - Contracts: simple_compression

**Status:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23

---

## 1. SIMPLE_COMPRESSION Contracts

### Creation Contracts

```eiffel
make_with_level (a_level: INTEGER)
    require
        valid_level: is_valid_level (a_level)
    ensure
        level_set: compression_level = a_level
```

### Level Setting Contracts

```eiffel
set_level (a_level: INTEGER)
    require
        valid_level: is_valid_level (a_level)
    ensure
        level_set: compression_level = a_level

set_level_fast
    ensure
        level_set: compression_level = Z_best_speed

set_level_default
    ensure
        level_set: compression_level = Z_default_compression

set_level_best
    ensure
        level_set: compression_level = Z_best_compression

is_valid_level (a_level: INTEGER): BOOLEAN
    ensure
        class
```

### String Compression Contracts

```eiffel
compress_string (a_input: STRING): STRING
    require
        input_not_void: a_input /= Void
    ensure
        result_not_void: Result /= Void
        sizes_tracked: last_input_size = a_input.count

decompress_string (a_compressed: STRING): STRING
    require
        input_not_void: a_compressed /= Void
        input_not_empty: not a_compressed.is_empty
    ensure
        result_not_void: Result /= Void
        sizes_tracked: last_input_size = a_compressed.count

compress_string_base64 (a_input: STRING): STRING
    require
        input_not_void: a_input /= Void
    ensure
        result_not_void: Result /= Void

decompress_string_base64 (a_base64: STRING): STRING
    require
        input_not_void: a_base64 /= Void
        input_not_empty: not a_base64.is_empty
    ensure
        result_not_void: Result /= Void
```

### Convenience Method Contracts

```eiffel
compress_fast (a_input: STRING): STRING
    require
        input_not_void: a_input /= Void
    ensure
        result_not_void: Result /= Void
        level_unchanged: compression_level = old compression_level

compress_best (a_input: STRING): STRING
    require
        input_not_void: a_input /= Void
    ensure
        result_not_void: Result /= Void
        level_unchanged: compression_level = old compression_level
```

### Format Detection Contracts

```eiffel
is_zlib_format (a_data: STRING): BOOLEAN
    require
        data_not_void: a_data /= Void

is_gzip_format (a_data: STRING): BOOLEAN
    require
        data_not_void: a_data /= Void

detect_format (a_data: STRING): STRING
    require
        data_not_void: a_data /= Void
    ensure
        result_not_void: Result /= Void
```

### Checksum Contracts

```eiffel
crc32 (a_data: STRING): NATURAL_32
    require
        data_not_void: a_data /= Void

adler32 (a_data: STRING): NATURAL_32
    require
        data_not_void: a_data /= Void

validate_checksum (a_data: STRING; a_expected_crc: NATURAL_32): BOOLEAN
    require
        data_not_void: a_data /= Void
```

### Byte Compression Contracts

```eiffel
compress_bytes (a_input: ARRAY [NATURAL_8]): ARRAY [NATURAL_8]
    require
        input_not_void: a_input /= Void
        input_not_empty: a_input.count > 0
    ensure
        result_not_void: Result /= Void
        sizes_tracked: last_input_size = a_input.count

decompress_bytes (a_compressed: ARRAY [NATURAL_8]): ARRAY [NATURAL_8]
    require
        input_not_void: a_compressed /= Void
        input_not_empty: a_compressed.count > 0
    ensure
        result_not_void: Result /= Void
        sizes_tracked: last_input_size = a_compressed.count
```

### File Operation Contracts

```eiffel
compress_file (a_source_path, a_dest_path: STRING): BOOLEAN
    require
        source_not_empty: not a_source_path.is_empty
        dest_not_empty: not a_dest_path.is_empty

decompress_file (a_source_path, a_dest_path: STRING): BOOLEAN
    require
        source_not_empty: not a_source_path.is_empty
        dest_not_empty: not a_dest_path.is_empty

read_compressed_file (a_path: STRING): STRING
    require
        path_not_empty: not a_path.is_empty
    ensure
        result_not_void: Result /= Void

write_compressed_file (a_path: STRING; a_content: STRING): BOOLEAN
    require
        path_not_empty: not a_path.is_empty
        content_not_void: a_content /= Void
```

### Advanced Contracts

```eiffel
compress_with_options (a_input: STRING; a_level: INTEGER; a_window_bits: INTEGER; a_strategy: INTEGER): STRING
    require
        input_not_void: a_input /= Void
        valid_level: a_level >= 0 and a_level <= 9
        valid_window: a_window_bits >= 8 and a_window_bits <= 15
    ensure
        result_not_void: Result /= Void
```

### Streaming Factory Contracts

```eiffel
create_compress_stream (a_output_path: STRING): SIMPLE_COMPRESSION_STREAM
    require
        path_not_empty: not a_output_path.is_empty
    ensure
        result_not_void: Result /= Void
        compressing: Result.is_compressing

create_decompress_stream (a_input_path: STRING): SIMPLE_COMPRESSION_STREAM
    require
        path_not_empty: not a_input_path.is_empty
    ensure
        result_not_void: Result /= Void
        decompressing: not Result.is_compressing
```

### Dictionary Contracts

```eiffel
compress_with_dictionary (a_input: STRING; a_dictionary: STRING): STRING
    require
        input_not_void: a_input /= Void
        dictionary_not_void: a_dictionary /= Void
    ensure
        result_not_void: Result /= Void

estimate_compression_ratio (a_sample: STRING): REAL_64
    require
        sample_not_void: a_sample /= Void
        sample_not_empty: not a_sample.is_empty
```

### Statistics Contracts

```eiffel
space_savings: STRING
    ensure
        result_not_void: Result /= Void

error_message (a_code: INTEGER): STRING
    ensure
        result_not_void: Result /= Void
```

---

## 2. SIMPLE_COMPRESSION_STREAM Contracts

```eiffel
make_compress (a_output_path: STRING)
    require
        path_not_empty: not a_output_path.is_empty
    ensure
        compressing: is_compressing
        open: is_open

make_decompress (a_input_path: STRING)
    require
        path_not_empty: not a_input_path.is_empty
    ensure
        decompressing: not is_compressing
        open: is_open

set_level (a_level: INTEGER)
    require
        compressing: is_compressing
        valid_level: a_level = Z_default_compression or else
                    (a_level >= Z_no_compression and a_level <= Z_best_compression)
    ensure
        level_set: compression_level = a_level

write (a_data: STRING)
    require
        compressing: is_compressing
        open: is_open
        data_not_void: a_data /= Void
    ensure
        input_tracked: total_input = old total_input + a_data.count

write_bytes (a_data: ARRAY [NATURAL_8])
    require
        compressing: is_compressing
        open: is_open
        data_not_void: a_data /= Void
    ensure
        input_tracked: total_input = old total_input + a_data.count

close
    require
        open: is_open
    ensure
        closed: not is_open

read_all: STRING
    require
        not_compressing: not is_compressing
    ensure
        result_not_void: Result /= Void

read_chunk (a_size: INTEGER): STRING
    require
        not_compressing: not is_compressing
        positive_size: a_size > 0
    ensure
        result_not_void: Result /= Void
```

### Class Invariant

```eiffel
invariant
    buffer_not_void: output_buffer /= Void
```

---

## 3. Contract Summary

| Class | Preconditions | Postconditions | Invariants |
|-------|---------------|----------------|------------|
| SIMPLE_COMPRESSION | 35 | 30 | 0 |
| SIMPLE_COMPRESSION_STREAM | 12 | 10 | 1 |
| **Total** | **47** | **40** | **1** |
