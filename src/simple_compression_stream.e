note
	description: "Streaming compression for large data sets"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_COMPRESSION_STREAM

inherit
	ZLIB_CONSTANTS

create
	make_compress,
	make_decompress

feature {NONE} -- Initialization

	make_compress (a_output_path: STRING)
			-- Create compressing stream writing to `a_output_path'.
		require
			path_not_empty: not a_output_path.is_empty
		do
			output_path := a_output_path
			is_compressing := True
			compression_level := Z_default_compression
			create output_buffer.make_empty
			total_input := 0
			total_output := 0
			is_open := True
		ensure
			compressing: is_compressing
			open: is_open
		end

	make_decompress (a_input_path: STRING)
			-- Create decompressing stream reading from `a_input_path'.
		require
			path_not_empty: not a_input_path.is_empty
		do
			input_path := a_input_path
			is_compressing := False
			create output_buffer.make_empty
			total_input := 0
			total_output := 0
			is_open := True
		ensure
			decompressing: not is_compressing
			open: is_open
		end

feature -- Access

	is_compressing: BOOLEAN
			-- Is this a compression stream?

	is_open: BOOLEAN
			-- Is the stream open?

	total_input: INTEGER
			-- Total bytes written/read

	total_output: INTEGER
			-- Total bytes output

	compression_level: INTEGER
			-- Compression level (for compress mode)

	last_error: detachable STRING
			-- Last error message

feature -- Configuration

	set_level (a_level: INTEGER)
			-- Set compression level.
		require
			compressing: is_compressing
			valid_level: a_level = Z_default_compression or else
						 (a_level >= Z_no_compression and a_level <= Z_best_compression)
		do
			compression_level := a_level
		ensure
			level_set: compression_level = a_level
		end

feature -- Operations

	write (a_data: STRING)
			-- Write data to compression stream.
		require
			compressing: is_compressing
			open: is_open
			data_not_void: a_data /= Void
		do
			output_buffer.append (a_data)
			total_input := total_input + a_data.count
		ensure
			input_tracked: total_input = old total_input + a_data.count
		end

	write_bytes (a_data: ARRAY [NATURAL_8])
			-- Write byte array to compression stream.
		require
			compressing: is_compressing
			open: is_open
			data_not_void: a_data /= Void
		local
			i: INTEGER
		do
			from i := a_data.lower until i > a_data.upper loop
				output_buffer.append_character (a_data.item (i).to_character_8)
				i := i + 1
			end
			total_input := total_input + a_data.count
		ensure
			input_tracked: total_input = old total_input + a_data.count
		end

	close
			-- Close the stream, finalize compression/decompression.
		require
			open: is_open
		local
			l_compressor: ZLIB_STRING_COMPRESS
			l_decompressor: ZLIB_STRING_UNCOMPRESS
			l_compressed: STRING
			l_file: RAW_FILE
			l_input_file: RAW_FILE
		do
			if is_compressing then
				-- Compress accumulated data
				create l_compressed.make_empty
				create l_compressor.string_stream (l_compressed)
				if compression_level = Z_default_compression then
					l_compressor.put_string (output_buffer)
				else
					l_compressor.put_string_with_options (output_buffer, compression_level, Z_default_window_bits, Z_mem_default, Z_default_strategy.to_integer_32)
				end

				-- Write to file
				if attached output_path as op then
					create l_file.make_with_name (op)
					l_file.open_write
					l_file.put_string (l_compressed)
					l_file.close
					total_output := l_compressed.count
				end
			else
				-- Read and decompress
				if attached input_path as ip then
					create l_input_file.make_with_name (ip)
					if l_input_file.exists then
						l_input_file.open_read
						l_input_file.read_stream (l_input_file.count)
						total_input := l_input_file.last_string.count
						create l_decompressor.string_stream (l_input_file.last_string)
						output_buffer := l_decompressor.to_string
						total_output := output_buffer.count
						l_input_file.close
					else
						last_error := "File not found: " + ip
					end
				end
			end

			is_open := False
		ensure
			closed: not is_open
		end

	read_all: STRING
			-- Read all decompressed data (call after close for decompress mode).
		require
			not_compressing: not is_compressing
		do
			if not is_open then
				Result := output_buffer
			else
				create Result.make_empty
			end
		ensure
			result_not_void: Result /= Void
		end

	read_chunk (a_size: INTEGER): STRING
			-- Read up to `a_size' bytes from decompressed data.
		require
			not_compressing: not is_compressing
			positive_size: a_size > 0
		do
			if not is_open and output_buffer.count > 0 then
				if a_size >= output_buffer.count then
					Result := output_buffer.twin
					output_buffer.wipe_out
				else
					Result := output_buffer.substring (1, a_size)
					output_buffer := output_buffer.substring (a_size + 1, output_buffer.count)
				end
			else
				create Result.make_empty
			end
		ensure
			result_not_void: Result /= Void
		end

feature -- Statistics

	compression_ratio: REAL_64
			-- Compression ratio (input / output).
		do
			if total_output > 0 then
				Result := total_input / total_output
			end
		end

feature {NONE} -- Implementation

	output_path: detachable STRING
			-- Output file path (compress mode)

	input_path: detachable STRING
			-- Input file path (decompress mode)

	output_buffer: STRING
			-- Buffer for accumulated data

invariant
	buffer_not_void: output_buffer /= Void

note
	copyright: "Copyright (c) 2024-2025, Larry Rix"
	license: "MIT License"

end
