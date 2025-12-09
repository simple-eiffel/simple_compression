# SIMPLE_COMPRESSION

Simple compression wrapper for ISE zlib library with string, byte array, and file support.

## Features

- String compression/decompression
- Base64-encoded compression for safe text storage
- Byte array compression
- File compression/decompression
- Configurable compression levels (0-9)
- CRC32 and Adler32 checksums
- Format detection (zlib, gzip)
- Streaming compression for large files
- Compression statistics

## Installation

Add to your ECF file:

```xml
<library name="simple_compression" location="$SIMPLE_COMPRESSION/simple_compression.ecf"/>
```

Set the environment variable:
```
SIMPLE_COMPRESSION=/path/to/simple_compression
```

## Quick Start

```eiffel
local
    comp: SIMPLE_COMPRESSION
    compressed, original: STRING
do
    create comp.make

    -- Compress a string
    compressed := comp.compress_string ("Hello, World!")
    print ("Compressed: " + compressed.count.out + " bytes%N")

    -- Decompress
    original := comp.decompress_string (compressed)

    -- Compress for safe text storage (Base64)
    compressed := comp.compress_string_base64 (original)

    -- Check compression ratio
    print ("Ratio: " + comp.compression_ratio.out + "x%N")
end
```

## API Overview

### SIMPLE_COMPRESSION

| Feature | Description |
|---------|-------------|
| `compress_string` | Compress string to raw bytes |
| `decompress_string` | Decompress back to string |
| `compress_string_base64` | Compress to Base64 (safe for text) |
| `decompress_string_base64` | Decompress from Base64 |
| `compress_bytes` | Compress byte array |
| `decompress_bytes` | Decompress byte array |
| `compress_file` | Compress file to destination |
| `decompress_file` | Decompress file |
| `crc32` | Calculate CRC32 checksum |
| `compression_ratio` | Get last compression ratio |
| `set_level_fast` | Use fastest compression |
| `set_level_best` | Use best compression |

### SIMPLE_COMPRESSION_STREAM

| Feature | Description |
|---------|-------------|
| `make_compress` | Create compression stream |
| `make_decompress` | Create decompression stream |
| `write` | Write data to stream |
| `close` | Finalize and close stream |
| `read_all` | Read decompressed data |

## Documentation

- [API Documentation](https://simple-eiffel.github.io/simple_compression/)

## License

MIT License - see LICENSE file for details.

## Author

Larry Rix
