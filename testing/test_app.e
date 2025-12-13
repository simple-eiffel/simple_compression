note
	description: "Test application for SIMPLE_COMPRESSION"
	author: "Larry Rix"

class
	TEST_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Run the tests.
		do
			create tests
			print ("Running SIMPLE_COMPRESSION tests...%N%N")

			passed := 0
			failed := 0

			run_test (agent tests.test_compress_decompress_basic, "test_compress_decompress_basic")
			run_test (agent tests.test_compress_decompress_empty, "test_compress_decompress_empty")
			run_test (agent tests.test_compress_fast_best, "test_compress_fast_best")
			run_test (agent tests.test_compression_ratio, "test_compression_ratio")
			run_test (agent tests.test_base64_encoding, "test_base64_encoding")
			run_test (agent tests.test_format_detection, "test_format_detection")
			run_test (agent tests.test_crc32, "test_crc32")
			run_test (agent tests.test_level_settings, "test_level_settings")
			run_test (agent tests.test_large_text, "test_large_text")
			run_test (agent tests.test_binary_data, "test_binary_data")
			run_test (agent tests.test_byte_array_compression, "test_byte_array_compression")
			run_test (agent tests.test_file_compression, "test_file_compression")
			run_test (agent tests.test_adler32, "test_adler32")
			run_test (agent tests.test_statistics, "test_statistics")
			run_test (agent tests.test_streaming_compression, "test_streaming_compression")
			run_test (agent tests.test_advanced_options, "test_advanced_options")
			run_test (agent tests.test_compression_estimation, "test_compression_estimation")

			print ("%N========================%N")
			print ("Results: " + passed.out + " passed, " + failed.out + " failed%N")

			if failed > 0 then
				print ("TESTS FAILED%N")
			else
				print ("ALL TESTS PASSED%N")
			end
		end

feature {NONE} -- Implementation

	tests: LIB_TESTS

	passed: INTEGER
	failed: INTEGER

	run_test (a_test: PROCEDURE; a_name: STRING)
			-- Run a single test and update counters.
		local
			l_retried: BOOLEAN
		do
			if not l_retried then
				a_test.call (Void)
				print ("  PASS: " + a_name + "%N")
				passed := passed + 1
			end
		rescue
			print ("  FAIL: " + a_name + "%N")
			failed := failed + 1
			l_retried := True
			retry
		end

end
