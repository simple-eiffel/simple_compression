note
	description: "Test application for SIMPLE_COMPRESSION"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	COMPRESSION_TEST_APP

inherit
	TEST_SET_BASE
		redefine
			on_prepare
		end

create
	make

feature {NONE} -- Initialization

	make
			-- Run the tests.
		do
			default_create
			print ("Running SIMPLE_COMPRESSION tests...%N%N")

			test_compress_decompress_basic
			test_compress_decompress_empty
			test_compress_fast_best
			test_compression_ratio
			test_base64_encoding
			test_format_detection
			test_crc32
			test_level_settings
			test_large_text
			test_binary_data
			test_byte_array_compression
			test_file_compression
			test_adler32
			test_statistics
			test_streaming_compression
			test_advanced_options
			test_compression_estimation

			print ("%N=== All tests passed ===%N")
		end

	on_prepare
			-- Prepare for tests.
		do
		end

feature -- Tests

	test_compress_decompress_basic
			-- Test basic compression and decompression.
		local
			comp: SIMPLE_COMPRESSION
			original, compressed, decompressed: STRING
		do
			print ("test_compress_decompress_basic: ")

			create comp.make
			original := "Hello, World! This is a test of the compression library."

			compressed := comp.compress_string (original)
			assert_true ("compressed not empty", not compressed.is_empty)
			-- Compressed should be smaller for repetitive text
			-- (though very small strings may not compress well)

			decompressed := comp.decompress_string (compressed)
			assert_equal ("round trip", original, decompressed)

			print ("OK%N")
		end

	test_compress_decompress_empty
			-- Test compression of empty-ish content.
		local
			comp: SIMPLE_COMPRESSION
			original, compressed, decompressed: STRING
		do
			print ("test_compress_decompress_empty: ")

			create comp.make
			original := "x"  -- Single character

			compressed := comp.compress_string (original)
			assert_true ("compressed not empty", not compressed.is_empty)

			decompressed := comp.decompress_string (compressed)
			assert_equal ("single char round trip", original, decompressed)

			print ("OK%N")
		end

	test_compress_fast_best
			-- Test fast vs best compression.
		local
			comp: SIMPLE_COMPRESSION
			original, fast_compressed, best_compressed: STRING
		do
			print ("test_compress_fast_best: ")

			create comp.make
			-- Use repetitive text that compresses well
			original := create_repetitive_text (500)

			fast_compressed := comp.compress_fast (original)
			best_compressed := comp.compress_best (original)

			assert_true ("fast not empty", not fast_compressed.is_empty)
			assert_true ("best not empty", not best_compressed.is_empty)
			-- Best compression should typically be smaller or equal
			assert_true ("best <= fast", best_compressed.count <= fast_compressed.count + 10)

			-- Both should decompress correctly
			assert_equal ("fast round trip", original, comp.decompress_string (fast_compressed))
			assert_equal ("best round trip", original, comp.decompress_string (best_compressed))

			print ("OK%N")
		end

	test_compression_ratio
			-- Test compression ratio tracking.
		local
			comp: SIMPLE_COMPRESSION
			original, compressed: STRING
		do
			print ("test_compression_ratio: ")

			create comp.make
			original := create_repetitive_text (1000)

			compressed := comp.compress_string (original)

			assert_integers_equal ("input size tracked", original.count, comp.last_input_size)
			assert_integers_equal ("output size tracked", compressed.count, comp.last_output_size)
			assert_true ("ratio positive", comp.compression_ratio > 0)
			-- Repetitive text should compress well
			assert_true ("good compression", comp.compression_ratio > 1.5)

			print ("OK (ratio: " + comp.compression_ratio.out + ")%N")
		end

	test_base64_encoding
			-- Test Base64 encoded compression.
		local
			comp: SIMPLE_COMPRESSION
			original, encoded, decoded: STRING
		do
			print ("test_base64_encoding: ")

			create comp.make
			original := "Test string for Base64 compression encoding."

			encoded := comp.compress_string_base64 (original)
			assert_true ("encoded is printable", is_printable (encoded))

			decoded := comp.decompress_string_base64 (encoded)
			assert_equal ("base64 round trip", original, decoded)

			print ("OK%N")
		end

	test_format_detection
			-- Test compression format detection.
		local
			comp: SIMPLE_COMPRESSION
			compressed: STRING
		do
			print ("test_format_detection: ")

			create comp.make
			compressed := comp.compress_string ("Test data")

			assert_true ("detects zlib", comp.is_zlib_format (compressed))
			assert_false ("not gzip", comp.is_gzip_format (compressed))
			assert_equal ("format is zlib", "zlib", comp.detect_format (compressed))

			-- Test non-compressed data
			assert_false ("random not zlib", comp.is_zlib_format ("random data"))
			assert_equal ("unknown format", "unknown", comp.detect_format ("random"))

			print ("OK%N")
		end

	test_crc32
			-- Test CRC32 checksum calculation.
		local
			comp: SIMPLE_COMPRESSION
			crc1, crc2: NATURAL_32
		do
			print ("test_crc32: ")

			create comp.make

			-- Same data should produce same CRC
			crc1 := comp.crc32 ("Hello")
			crc2 := comp.crc32 ("Hello")
			assert_true ("same data same crc", crc1 = crc2)

			-- Different data should produce different CRC
			crc2 := comp.crc32 ("World")
			assert_true ("different data different crc", crc1 /= crc2)

			-- Known test vector: CRC32("123456789") = 0xCBF43926
			crc1 := comp.crc32 ("123456789")
			assert_true ("known vector", crc1 = 0xCBF43926)

			print ("OK%N")
		end

	test_level_settings
			-- Test compression level settings.
		local
			comp: SIMPLE_COMPRESSION
		do
			print ("test_level_settings: ")

			create comp.make
			assert_integers_equal ("default level", -1, comp.compression_level)

			comp.set_level_fast
			assert_integers_equal ("fast level", 1, comp.compression_level)

			comp.set_level_best
			assert_integers_equal ("best level", 9, comp.compression_level)

			comp.set_level_default
			assert_integers_equal ("default level again", -1, comp.compression_level)

			comp.set_level (5)
			assert_integers_equal ("custom level", 5, comp.compression_level)

			-- Test level constants
			assert_integers_equal ("level_none", 0, comp.level_none)
			assert_integers_equal ("level_fast", 1, comp.level_fast)
			assert_integers_equal ("level_best", 9, comp.level_best)

			print ("OK%N")
		end

	test_large_text
			-- Test compression of larger text.
		local
			comp: SIMPLE_COMPRESSION
			original, compressed, decompressed: STRING
		do
			print ("test_large_text: ")

			create comp.make
			original := create_repetitive_text (10000)

			compressed := comp.compress_string (original)
			assert_true ("compressed smaller", compressed.count < original.count)

			decompressed := comp.decompress_string (compressed)
			assert_equal ("large text round trip", original, decompressed)

			print ("OK (compressed " + original.count.out + " to " + compressed.count.out + " bytes)%N")
		end

	test_binary_data
			-- Test compression of binary-like data.
		local
			comp: SIMPLE_COMPRESSION
			original, compressed, decompressed: STRING
			i: INTEGER
		do
			print ("test_binary_data: ")

			create comp.make
			create original.make (256)
			-- Create string with all byte values
			from i := 0 until i > 255 loop
				original.append_character (i.to_character_8)
				i := i + 1
			end

			compressed := comp.compress_string (original)
			assert_true ("binary compressed", not compressed.is_empty)

			decompressed := comp.decompress_string (compressed)
			assert_integers_equal ("binary length preserved", original.count, decompressed.count)
			assert_true ("binary content preserved", original.same_string (decompressed))

			print ("OK%N")
		end

feature {NONE} -- Helpers

	create_repetitive_text (a_length: INTEGER): STRING
			-- Create repetitive text of approximately `a_length' characters.
		local
			l_phrase: STRING
		do
			l_phrase := "The quick brown fox jumps over the lazy dog. "
			create Result.make (a_length)
			from until Result.count >= a_length loop
				Result.append (l_phrase)
			end
			Result := Result.substring (1, a_length)
		end

	is_printable (s: STRING): BOOLEAN
			-- Does `s' contain only printable ASCII characters?
		local
			i: INTEGER
			c: INTEGER
		do
			Result := True
			from i := 1 until i > s.count or not Result loop
				c := s.item (i).code
				Result := (c >= 32 and c <= 126) or c = 10 or c = 13
				i := i + 1
			end
		end

	temp_file_path (a_prefix: STRING): STRING
			-- Generate temp file path for testing.
		local
			l_env: EXECUTION_ENVIRONMENT
		do
			create l_env
			if attached l_env.temporary_directory_path as tmp then
				Result := tmp.out + "/" + a_prefix + "_test.tmp"
			else
				Result := a_prefix + "_test.tmp"
			end
		end

feature -- Phase 2 Tests

	test_byte_array_compression
			-- Test byte array compression/decompression.
		local
			comp: SIMPLE_COMPRESSION
			input: ARRAY [NATURAL_8]
			compressed, decompressed: ARRAY [NATURAL_8]
			i: INTEGER
		do
			print ("test_byte_array_compression: ")

			create comp.make

			-- Create test data
			create input.make_filled (0, 1, 100)
			from i := 1 until i > 100 loop
				input.put ((i \\ 10).to_natural_8, i)
				i := i + 1
			end

			-- Compress
			compressed := comp.compress_bytes (input)
			assert_true ("bytes compressed", compressed.count > 0)

			-- Decompress
			decompressed := comp.decompress_bytes (compressed)
			assert_integers_equal ("byte count restored", input.count, decompressed.count)

			-- Verify content
			from i := 1 until i > input.count loop
				assert_integers_equal ("byte " + i.out, input.item (i).to_integer_32, decompressed.item (i).to_integer_32)
				i := i + 1
			end

			print ("OK%N")
		end

	test_file_compression
			-- Test file compression operations.
		local
			comp: SIMPLE_COMPRESSION
			src_path, comp_path, dest_path: STRING
			original, restored: STRING
			l_file: RAW_FILE
		do
			print ("test_file_compression: ")

			create comp.make

			-- Create temp paths
			src_path := temp_file_path ("compress_src")
			comp_path := temp_file_path ("compress_out")
			dest_path := temp_file_path ("compress_dest")

			-- Create source file
			original := create_repetitive_text (500)
			create l_file.make_with_name (src_path)
			l_file.open_write
			l_file.put_string (original)
			l_file.close

			-- Test compress_file
			assert_true ("compress succeeded", comp.compress_file (src_path, comp_path))
			assert_true ("compressed file exists", (create {RAW_FILE}.make_with_name (comp_path)).exists)

			-- Test decompress_file
			assert_true ("decompress succeeded", comp.decompress_file (comp_path, dest_path))

			-- Verify content
			create l_file.make_with_name (dest_path)
			l_file.open_read
			l_file.read_stream (l_file.count)
			restored := l_file.last_string
			l_file.close

			assert_equal ("file round trip", original, restored)

			-- Test write_compressed_file and read_compressed_file
			assert_true ("write compressed", comp.write_compressed_file (comp_path, "Quick test"))
			restored := comp.read_compressed_file (comp_path)
			assert_equal ("read compressed", "Quick test", restored)

			-- Cleanup
			create l_file.make_with_name (src_path)
			if l_file.exists then l_file.delete end
			create l_file.make_with_name (comp_path)
			if l_file.exists then l_file.delete end
			create l_file.make_with_name (dest_path)
			if l_file.exists then l_file.delete end

			print ("OK%N")
		end

	test_adler32
			-- Test Adler-32 checksum calculation.
		local
			comp: SIMPLE_COMPRESSION
			a1, a2: NATURAL_32
		do
			print ("test_adler32: ")

			create comp.make

			-- Same data should produce same checksum
			a1 := comp.adler32 ("Hello")
			a2 := comp.adler32 ("Hello")
			assert_true ("same data same adler", a1 = a2)

			-- Different data should produce different checksum
			a2 := comp.adler32 ("World")
			assert_true ("different data different adler", a1 /= a2)

			-- Known test vector: adler32("Wikipedia") = 0x11E60398
			a1 := comp.adler32 ("Wikipedia")
			assert_true ("known adler vector", a1 = 0x11E60398)

			print ("OK%N")
		end

	test_statistics
			-- Test compression statistics.
		local
			comp: SIMPLE_COMPRESSION
			original, compressed: STRING
		do
			print ("test_statistics: ")

			create comp.make
			original := create_repetitive_text (1000)
			compressed := comp.compress_string (original)

			-- Test last_operation_successful
			assert_true ("operation successful", comp.last_operation_successful)

			-- Test compression_percentage
			assert_true ("percentage positive", comp.compression_percentage > 0)
			assert_true ("percentage < 100", comp.compression_percentage < 100)

			-- Test space_savings
			assert_true ("savings not empty", not comp.space_savings.is_empty)
			assert_true ("savings contains bytes", comp.space_savings.has_substring ("bytes"))

			-- Test validate_checksum
			assert_true ("checksum valid", comp.validate_checksum ("123456789", 0xCBF43926))
			assert_false ("checksum invalid", comp.validate_checksum ("123456789", 0x12345678))

			print ("OK (" + comp.space_savings + ")%N")
		end

feature -- Phase 3 Tests

	test_streaming_compression
			-- Test streaming compression for large data.
		local
			comp: SIMPLE_COMPRESSION
			stream: SIMPLE_COMPRESSION_STREAM
			original, restored: STRING
			out_path: STRING
			l_file: RAW_FILE
		do
			print ("test_streaming_compression: ")

			create comp.make

			-- Create test paths
			out_path := temp_file_path ("stream_out")

			-- Test compression stream
			stream := comp.create_compress_stream (out_path)
			assert_true ("stream created", stream /= Void)
			assert_true ("stream open", stream.is_open)
			assert_true ("is compressing", stream.is_compressing)

			-- Write data in chunks
			original := create_repetitive_text (1000)
			stream.write (original.substring (1, 500))
			stream.write (original.substring (501, 1000))
			stream.close

			assert_false ("stream closed", stream.is_open)
			assert_true ("input tracked", stream.total_input > 0)
			assert_true ("output tracked", stream.total_output > 0)

			-- Verify file was created
			create l_file.make_with_name (out_path)
			assert_true ("compressed file exists", l_file.exists)

			-- Test decompression stream
			stream := comp.create_decompress_stream (out_path)
			assert_true ("decompress stream created", stream /= Void)
			assert_false ("is decompressing", stream.is_compressing)

			stream.close
			restored := stream.read_all

			assert_equal ("streaming round trip", original, restored)

			-- Cleanup
			create l_file.make_with_name (out_path)
			if l_file.exists then l_file.delete end

			print ("OK%N")
		end

	test_advanced_options
			-- Test advanced compression options.
		local
			comp: SIMPLE_COMPRESSION
			original, compressed, decompressed: STRING
		do
			print ("test_advanced_options: ")

			create comp.make
			original := create_repetitive_text (500)

			-- Test with default strategy
			compressed := comp.compress_with_options (original, 6, 15, comp.strategy_default)
			assert_true ("default strategy works", not compressed.is_empty)
			decompressed := comp.decompress_string (compressed)
			assert_equal ("default strategy round trip", original, decompressed)

			-- Test with filtered strategy (good for data with patterns)
			compressed := comp.compress_with_options (original, 6, 15, comp.strategy_filtered)
			assert_true ("filtered strategy works", not compressed.is_empty)
			decompressed := comp.decompress_string (compressed)
			assert_equal ("filtered strategy round trip", original, decompressed)

			-- Test with huffman only strategy
			compressed := comp.compress_with_options (original, 6, 15, comp.strategy_huffman_only)
			assert_true ("huffman strategy works", not compressed.is_empty)
			decompressed := comp.decompress_string (compressed)
			assert_equal ("huffman strategy round trip", original, decompressed)

			-- Test strategy constants
			assert_integers_equal ("strategy_default", 0, comp.strategy_default)
			assert_integers_equal ("strategy_filtered", 1, comp.strategy_filtered)
			assert_integers_equal ("strategy_huffman_only", 2, comp.strategy_huffman_only)
			assert_integers_equal ("strategy_rle", 3, comp.strategy_rle)

			print ("OK%N")
		end

	test_compression_estimation
			-- Test compression ratio estimation.
		local
			comp: SIMPLE_COMPRESSION
			repetitive, random: STRING
			est_rep, est_rand: REAL_64
			i: INTEGER
		do
			print ("test_compression_estimation: ")

			create comp.make

			-- Repetitive text should estimate high compression
			repetitive := create_repetitive_text (500)
			est_rep := comp.estimate_compression_ratio (repetitive)
			assert_true ("repetitive estimate > 1", est_rep > 1.0)

			-- More random data should estimate lower compression
			create random.make (256)
			from i := 0 until i > 255 loop
				random.append_character (i.to_character_8)
				i := i + 1
			end
			est_rand := comp.estimate_compression_ratio (random)
			assert_true ("random estimate positive", est_rand > 0)

			-- Repetitive should estimate higher than random
			assert_true ("repetitive > random", est_rep > est_rand)

			print ("OK (repetitive: " + est_rep.out + ", random: " + est_rand.out + ")%N")
		end

note
	copyright: "Copyright (c) 2024-2025, Larry Rix"
	license: "MIT License"

end
