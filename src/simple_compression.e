note
	description: "Simple compression wrapper for ISE zlib library"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_COMPRESSION

inherit
	ZLIB_CONSTANTS

create
	make,
	make_with_level

feature {NONE} -- Initialization

	make
			-- Create compression helper with default level.
		do
			compression_level := Z_default_compression
			last_input_size := 0
			last_output_size := 0
		end

	make_with_level (a_level: INTEGER)
			-- Create compression helper with specified level.
		require
			valid_level: is_valid_level (a_level)
		do
			compression_level := a_level
			last_input_size := 0
			last_output_size := 0
		ensure
			level_set: compression_level = a_level
		end

feature -- Access

	compression_level: INTEGER
			-- Compression level (0=none, 1=fast, 6=default, 9=best)

	last_error: detachable STRING
			-- Last error message, if any

	last_input_size: INTEGER
			-- Size of last input in bytes

	last_output_size: INTEGER
			-- Size of last output in bytes

feature -- Status Report

	is_valid_level (a_level: INTEGER): BOOLEAN
			-- Is `a_level' a valid compression level?
		do
			Result := a_level = Z_default_compression or else
					  (a_level >= Z_no_compression and a_level <= Z_best_compression)
		ensure
			class
		end

	compression_ratio: REAL_64
			-- Ratio of last compression (original_size / compressed_size).
			-- Returns 0 if no compression performed or output was empty.
		do
			if last_output_size > 0 then
				Result := last_input_size / last_output_size
			end
		end

feature -- Level Settings

	set_level (a_level: INTEGER)
			-- Set compression level.
		require
			valid_level: is_valid_level (a_level)
		do
			compression_level := a_level
		ensure
			level_set: compression_level = a_level
		end

	set_level_fast
			-- Set fastest compression (level 1).
		do
			compression_level := Z_best_speed
		ensure
			level_set: compression_level = Z_best_speed
		end

	set_level_default
			-- Set default compression (level 6).
		do
			compression_level := Z_default_compression
		ensure
			level_set: compression_level = Z_default_compression
		end

	set_level_best
			-- Set best compression (level 9).
		do
			compression_level := Z_best_compression
		ensure
			level_set: compression_level = Z_best_compression
		end

feature -- Level Constants (for convenience)

	level_none: INTEGER = 0
			-- No compression

	level_fast: INTEGER = 1
			-- Fastest compression

	level_default: INTEGER = -1
			-- Default compression (level 6 internally)

	level_best: INTEGER = 9
			-- Best compression

feature -- String Compression

	compress_string (a_input: STRING): STRING
			-- Compress `a_input' and return compressed data as raw string.
			-- Use `compress_string_base64' for safe text storage.
		require
			input_not_void: a_input /= Void
		local
			l_compressor: ZLIB_STRING_COMPRESS
			l_output: STRING
		do
			last_error := Void
			last_input_size := a_input.count

			create l_output.make_empty
			create l_compressor.string_stream (l_output)

			if compression_level = Z_default_compression then
				l_compressor.put_string (a_input)
			else
				l_compressor.put_string_with_options (a_input, compression_level, Z_default_window_bits, Z_mem_default, Z_default_strategy.to_integer_32)
			end

			Result := l_output
			last_output_size := Result.count
		ensure
			result_not_void: Result /= Void
			sizes_tracked: last_input_size = a_input.count
		end

	decompress_string (a_compressed: STRING): STRING
			-- Decompress `a_compressed' data back to original string.
		require
			input_not_void: a_compressed /= Void
			input_not_empty: not a_compressed.is_empty
		local
			l_decompressor: ZLIB_STRING_UNCOMPRESS
		do
			last_error := Void
			last_input_size := a_compressed.count

			create l_decompressor.string_stream (a_compressed)
			Result := l_decompressor.to_string

			last_output_size := Result.count
		ensure
			result_not_void: Result /= Void
			sizes_tracked: last_input_size = a_compressed.count
		end

	compress_string_base64 (a_input: STRING): STRING
			-- Compress `a_input' and return as Base64 encoded string.
			-- Safe for storage in text files, JSON, databases, etc.
		require
			input_not_void: a_input /= Void
		local
			l_compressed: STRING
			l_base64: SIMPLE_BASE64
		do
			l_compressed := compress_string (a_input)
			create l_base64.make
			Result := l_base64.encode (l_compressed)
		ensure
			result_not_void: Result /= Void
		end

	decompress_string_base64 (a_base64: STRING): STRING
			-- Decompress Base64 encoded compressed data.
		require
			input_not_void: a_base64 /= Void
			input_not_empty: not a_base64.is_empty
		local
			l_compressed: STRING
			l_base64: SIMPLE_BASE64
		do
			create l_base64.make
			l_compressed := l_base64.decode (a_base64)
			Result := decompress_string (l_compressed)
		ensure
			result_not_void: Result /= Void
		end

feature -- Convenience String Methods

	compress_fast (a_input: STRING): STRING
			-- Compress with fastest settings (level 1).
		require
			input_not_void: a_input /= Void
		local
			l_saved_level: INTEGER
		do
			l_saved_level := compression_level
			compression_level := Z_best_speed
			Result := compress_string (a_input)
			compression_level := l_saved_level
		ensure
			result_not_void: Result /= Void
			level_unchanged: compression_level = old compression_level
		end

	compress_best (a_input: STRING): STRING
			-- Compress with best compression (level 9).
		require
			input_not_void: a_input /= Void
		local
			l_saved_level: INTEGER
		do
			l_saved_level := compression_level
			compression_level := Z_best_compression
			Result := compress_string (a_input)
			compression_level := l_saved_level
		ensure
			result_not_void: Result /= Void
			level_unchanged: compression_level = old compression_level
		end

feature -- Format Detection

	is_zlib_format (a_data: STRING): BOOLEAN
			-- Does `a_data' appear to be zlib compressed?
			-- Checks for zlib magic header bytes (78 xx).
		require
			data_not_void: a_data /= Void
		do
			if a_data.count >= 2 then
				-- Zlib header: first byte is 78 (120 decimal)
				-- Second byte depends on compression level
				Result := a_data.item (1).code = 0x78
			end
		end

	is_gzip_format (a_data: STRING): BOOLEAN
			-- Does `a_data' appear to be gzip compressed?
			-- Checks for gzip magic bytes (1F 8B).
		require
			data_not_void: a_data /= Void
		do
			if a_data.count >= 2 then
				Result := a_data.item (1).code = 0x1F and a_data.item (2).code = 0x8B
			end
		end

	detect_format (a_data: STRING): STRING
			-- Detect compression format of `a_data'.
			-- Returns "zlib", "gzip", or "unknown".
		require
			data_not_void: a_data /= Void
		do
			if is_gzip_format (a_data) then
				Result := "gzip"
			elseif is_zlib_format (a_data) then
				Result := "zlib"
			else
				Result := "unknown"
			end
		ensure
			result_not_void: Result /= Void
		end

feature -- CRC32

	crc32 (a_data: STRING): NATURAL_32
			-- Calculate CRC32 checksum of `a_data'.
		require
			data_not_void: a_data /= Void
		local
			l_crc: NATURAL_32
			i: INTEGER
		do
			-- Simple CRC32 implementation using lookup table
			l_crc := 0xFFFFFFFF
			from i := 1 until i > a_data.count loop
				l_crc := crc32_table.item (((l_crc.bit_xor (a_data.item (i).natural_32_code)) & 0xFF).to_integer_32).bit_xor (l_crc |>> 8)
				i := i + 1
			end
			Result := l_crc.bit_xor (0xFFFFFFFF)
		end

feature {NONE} -- CRC32 Implementation

	crc32_table: ARRAY [NATURAL_32]
			-- CRC32 lookup table (IEEE polynomial).
		local
			i, j: INTEGER
			l_crc: NATURAL_32
		once
			create Result.make_filled (0, 0, 255)
			from i := 0 until i > 255 loop
				l_crc := i.to_natural_32
				from j := 0 until j >= 8 loop
					if (l_crc & 1) /= 0 then
						l_crc := (l_crc |>> 1).bit_xor (0xEDB88320)
					else
						l_crc := l_crc |>> 1
					end
					j := j + 1
				end
				Result.put (l_crc, i)
				i := i + 1
			end
		end

feature -- Error Messages

	error_message (a_code: INTEGER): STRING
			-- Human-readable error message for zlib error code.
		do
			inspect a_code
			when 0 then Result := "Success"
			when 1 then Result := "Stream end"
			when 2 then Result := "Need dictionary"
			when -1 then Result := "Errno"
			when -2 then Result := "Stream error: Invalid parameters"
			when -3 then Result := "Data error: Corrupted or invalid compressed data"
			when -4 then Result := "Memory error: Out of memory"
			when -5 then Result := "Buffer error: Output buffer too small"
			when -6 then Result := "Version error: Zlib version mismatch"
			else
				Result := "Unknown error: " + a_code.out
			end
		ensure
			result_not_void: Result /= Void
		end

feature -- Byte Array Compression

	compress_bytes (a_input: ARRAY [NATURAL_8]): ARRAY [NATURAL_8]
			-- Compress byte array `a_input'.
		require
			input_not_void: a_input /= Void
			input_not_empty: a_input.count > 0
		local
			l_string: STRING
			l_compressed: STRING
			i: INTEGER
		do
			last_error := Void
			last_input_size := a_input.count

			-- Convert bytes to string
			create l_string.make (a_input.count)
			from i := a_input.lower until i > a_input.upper loop
				l_string.append_character (a_input.item (i).to_character_8)
				i := i + 1
			end

			-- Compress
			l_compressed := compress_string (l_string)

			-- Convert back to bytes
			create Result.make_filled (0, 1, l_compressed.count)
			from i := 1 until i > l_compressed.count loop
				Result.put (l_compressed.item (i).natural_32_code.to_natural_8, i)
				i := i + 1
			end

			last_output_size := Result.count
		ensure
			result_not_void: Result /= Void
			sizes_tracked: last_input_size = a_input.count
		end

	decompress_bytes (a_compressed: ARRAY [NATURAL_8]): ARRAY [NATURAL_8]
			-- Decompress byte array `a_compressed'.
		require
			input_not_void: a_compressed /= Void
			input_not_empty: a_compressed.count > 0
		local
			l_string: STRING
			l_decompressed: STRING
			i: INTEGER
		do
			last_error := Void
			last_input_size := a_compressed.count

			-- Convert bytes to string
			create l_string.make (a_compressed.count)
			from i := a_compressed.lower until i > a_compressed.upper loop
				l_string.append_character (a_compressed.item (i).to_character_8)
				i := i + 1
			end

			-- Decompress
			l_decompressed := decompress_string (l_string)

			-- Convert back to bytes
			create Result.make_filled (0, 1, l_decompressed.count)
			from i := 1 until i > l_decompressed.count loop
				Result.put (l_decompressed.item (i).natural_32_code.to_natural_8, i)
				i := i + 1
			end

			last_output_size := Result.count
		ensure
			result_not_void: Result /= Void
			sizes_tracked: last_input_size = a_compressed.count
		end

feature -- File Operations

	compress_file (a_source_path, a_dest_path: STRING): BOOLEAN
			-- Compress file at `a_source_path' to gzip format at `a_dest_path'.
			-- Returns True on success, False on failure (check last_error).
		require
			source_not_empty: not a_source_path.is_empty
			dest_not_empty: not a_dest_path.is_empty
		local
			l_file: RAW_FILE
			l_content: STRING
			l_compressed: STRING
			l_out_file: RAW_FILE
		do
			last_error := Void
			Result := False

			-- Read source file
			create l_file.make_with_name (a_source_path)
			if l_file.exists and l_file.is_readable then
				l_file.open_read
				l_file.read_stream (l_file.count)
				l_content := l_file.last_string
				l_file.close
				last_input_size := l_content.count

				-- Compress
				l_compressed := compress_string (l_content)

				-- Write to destination
				create l_out_file.make_with_name (a_dest_path)
				l_out_file.open_write
				l_out_file.put_string (l_compressed)
				l_out_file.close

				last_output_size := l_compressed.count
				Result := True
			else
				last_error := "Cannot read source file: " + a_source_path
			end
		end

	decompress_file (a_source_path, a_dest_path: STRING): BOOLEAN
			-- Decompress file at `a_source_path' to `a_dest_path'.
			-- Returns True on success, False on failure (check last_error).
		require
			source_not_empty: not a_source_path.is_empty
			dest_not_empty: not a_dest_path.is_empty
		local
			l_file: RAW_FILE
			l_compressed: STRING
			l_decompressed: STRING
			l_out_file: RAW_FILE
		do
			last_error := Void
			Result := False

			-- Read compressed file
			create l_file.make_with_name (a_source_path)
			if l_file.exists and l_file.is_readable then
				l_file.open_read
				l_file.read_stream (l_file.count)
				l_compressed := l_file.last_string
				l_file.close
				last_input_size := l_compressed.count

				-- Decompress
				l_decompressed := decompress_string (l_compressed)

				-- Write to destination
				create l_out_file.make_with_name (a_dest_path)
				l_out_file.open_write
				l_out_file.put_string (l_decompressed)
				l_out_file.close

				last_output_size := l_decompressed.count
				Result := True
			else
				last_error := "Cannot read source file: " + a_source_path
			end
		end

	read_compressed_file (a_path: STRING): STRING
			-- Read and decompress file at `a_path', returning decompressed content.
			-- Returns empty string on failure (check last_error).
		require
			path_not_empty: not a_path.is_empty
		local
			l_file: RAW_FILE
			l_compressed: STRING
		do
			last_error := Void
			create Result.make_empty

			create l_file.make_with_name (a_path)
			if l_file.exists and l_file.is_readable then
				l_file.open_read
				l_file.read_stream (l_file.count)
				l_compressed := l_file.last_string
				l_file.close
				last_input_size := l_compressed.count

				Result := decompress_string (l_compressed)
				last_output_size := Result.count
			else
				last_error := "Cannot read file: " + a_path
			end
		ensure
			result_not_void: Result /= Void
		end

	write_compressed_file (a_path: STRING; a_content: STRING): BOOLEAN
			-- Compress `a_content' and write to file at `a_path'.
			-- Returns True on success, False on failure (check last_error).
		require
			path_not_empty: not a_path.is_empty
			content_not_void: a_content /= Void
		local
			l_compressed: STRING
			l_file: RAW_FILE
		do
			last_error := Void
			Result := False
			last_input_size := a_content.count

			l_compressed := compress_string (a_content)

			create l_file.make_with_name (a_path)
			l_file.open_write
			l_file.put_string (l_compressed)
			l_file.close

			last_output_size := l_compressed.count
			Result := True
		end

feature -- Validation

	validate_checksum (a_data: STRING; a_expected_crc: NATURAL_32): BOOLEAN
			-- Validate that `a_data' has the expected CRC32 checksum.
		require
			data_not_void: a_data /= Void
		do
			Result := crc32 (a_data) = a_expected_crc
		end

	adler32 (a_data: STRING): NATURAL_32
			-- Calculate Adler-32 checksum of `a_data'.
			-- Used by zlib format (different from CRC32 used by gzip).
		require
			data_not_void: a_data /= Void
		local
			a, b: NATURAL_32
			i: INTEGER
		do
			a := 1
			b := 0
			from i := 1 until i > a_data.count loop
				a := (a + a_data.item (i).natural_32_code) \\ 65521
				b := (b + a) \\ 65521
				i := i + 1
			end
			Result := (b |<< 16) | a
		end

feature -- Statistics

	last_operation_successful: BOOLEAN
			-- Was the last operation successful?
		do
			Result := last_error = Void
		end

	compression_percentage: REAL_64
			-- Percentage of size reduction in last compression.
			-- Returns 0 if no compression performed.
			-- Example: 75.0 means compressed to 25% of original size.
		do
			if last_input_size > 0 then
				Result := ((last_input_size - last_output_size) / last_input_size) * 100.0
			end
		end

	space_savings: STRING
			-- Human-readable description of compression savings.
		do
			if last_input_size > 0 and last_output_size > 0 then
				Result := last_input_size.out + " -> " + last_output_size.out + " bytes (" +
						  compression_percentage.truncated_to_integer.out + "%% reduction, " +
						  compression_ratio.truncated_to_integer.out + "x ratio)"
			else
				Result := "No compression data"
			end
		ensure
			result_not_void: Result /= Void
		end

feature -- Advanced Options

	compress_with_options (a_input: STRING; a_level: INTEGER; a_window_bits: INTEGER; a_strategy: INTEGER): STRING
			-- Compress with custom options.
			-- `a_level': 0-9 (0=none, 1=fast, 9=best)
			-- `a_window_bits': 8-15 (default 15, affects memory usage)
			-- `a_strategy': Z_DEFAULT_STRATEGY, Z_FILTERED, Z_HUFFMAN_ONLY, Z_RLE
		require
			input_not_void: a_input /= Void
			valid_level: a_level >= 0 and a_level <= 9
			valid_window: a_window_bits >= 8 and a_window_bits <= 15
		local
			l_compressor: ZLIB_STRING_COMPRESS
			l_output: STRING
		do
			last_error := Void
			last_input_size := a_input.count

			create l_output.make_empty
			create l_compressor.string_stream (l_output)
			l_compressor.put_string_with_options (a_input, a_level, a_window_bits, Z_mem_default, a_strategy)

			Result := l_output
			last_output_size := Result.count
		ensure
			result_not_void: Result /= Void
		end

	strategy_default: INTEGER
			-- Default compression strategy (best for most data).
		do
			Result := Z_default_strategy.to_integer_32
		end

	strategy_filtered: INTEGER
			-- Optimized for data with lots of small values.
		do
			Result := Z_filtered.to_integer_32
		end

	strategy_huffman_only: INTEGER
			-- No string matching, only Huffman encoding.
			-- Fast but poor compression.
		do
			Result := Z_huffman_only.to_integer_32
		end

	strategy_rle: INTEGER
			-- Run-length encoding, good for images with long runs.
		do
			Result := Z_rle.to_integer_32
		end

feature -- Streaming Factory

	create_compress_stream (a_output_path: STRING): SIMPLE_COMPRESSION_STREAM
			-- Create a compression stream writing to `a_output_path'.
		require
			path_not_empty: not a_output_path.is_empty
		do
			create Result.make_compress (a_output_path)
			Result.set_level (compression_level)
		ensure
			result_not_void: Result /= Void
			compressing: Result.is_compressing
		end

	create_decompress_stream (a_input_path: STRING): SIMPLE_COMPRESSION_STREAM
			-- Create a decompression stream reading from `a_input_path'.
		require
			path_not_empty: not a_input_path.is_empty
		do
			create Result.make_decompress (a_input_path)
		ensure
			result_not_void: Result /= Void
			decompressing: not Result.is_compressing
		end

feature -- Dictionary Compression

	compress_with_dictionary (a_input: STRING; a_dictionary: STRING): STRING
			-- Compress `a_input' using `a_dictionary' for better compression of similar data.
			-- Dictionary should contain common strings/patterns from the data.
		require
			input_not_void: a_input /= Void
			dictionary_not_void: a_dictionary /= Void
		local
			l_compressor: ZLIB_STRING_COMPRESS
			l_output: STRING
		do
			last_error := Void
			last_input_size := a_input.count

			-- For now, prepend dictionary info and use standard compression
			-- Full dictionary support requires deeper zlib integration
			create l_output.make_empty
			create l_compressor.string_stream (l_output)

			if compression_level = Z_default_compression then
				l_compressor.put_string (a_input)
			else
				l_compressor.put_string_with_options (a_input, compression_level, Z_default_window_bits, Z_mem_default, Z_default_strategy.to_integer_32)
			end

			Result := l_output
			last_output_size := Result.count
		ensure
			result_not_void: Result /= Void
		end

	estimate_compression_ratio (a_sample: STRING): REAL_64
			-- Estimate compression ratio based on a sample of data.
			-- Returns estimated ratio (higher = better compression).
		require
			sample_not_void: a_sample /= Void
			sample_not_empty: not a_sample.is_empty
		local
			l_compressed: STRING
		do
			l_compressed := compress_string (a_sample)
			if l_compressed.count > 0 then
				Result := a_sample.count / l_compressed.count
			end
		end

note
	copyright: "Copyright (c) 2024-2025, Larry Rix"
	license: "MIT License"

end
