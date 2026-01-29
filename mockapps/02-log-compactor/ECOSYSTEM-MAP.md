# LogCompactor - Ecosystem Integration

## simple_* Dependencies

### Required Libraries

| Library | Purpose | Integration Point |
|---------|---------|-------------------|
| `simple_compression` | Core compression engine | COMPACTOR_ENGINE uses for all compression/decompression |
| `simple_file` | File operations | SOURCE handling, archive writing, rotation |
| `simple_datetime` | Timestamp parsing/formatting | Log timestamp extraction, archive naming |
| `simple_cli` | Command-line interface | LOG_COMPACTOR_CLI argument parsing |
| `simple_config` | Configuration management | Load YAML/JSON config files |
| `simple_sql` | Index storage | LOG_INDEX uses SQLite for searchable index |
| `simple_json` | JSON log parsing | LOG_FORMAT_DETECTOR for structured logs |

### Optional Libraries

| Library | Purpose | When Needed |
|---------|---------|-------------|
| `simple_watcher` | File system monitoring | Watch mode for continuous compression |
| `simple_logger` | Operation logging | Audit trail and debugging |
| `simple_hash` | Extended checksums | SHA-256 verification for compliance |
| `simple_validation` | Config validation | Strict configuration checking |

## Integration Patterns

### simple_compression Integration

**Purpose:** Provides block-based compression with configurable levels

**Usage:**
```eiffel
class COMPACTOR_ENGINE

feature {NONE} -- Implementation

    compressor: SIMPLE_COMPRESSION
        -- Core compression engine

    stream: SIMPLE_COMPRESSION_STREAM
        -- Streaming compression for large files

feature -- Initialization

    make (a_config: COMPACTOR_CONFIG)
            -- Create compactor with configuration.
        do
            create compressor.make
            set_compression_level (a_config.compression_level)
        end

feature -- Compression

    compress_block (a_block: STRING): STRING
            -- Compress a log block.
        require
            block_not_empty: not a_block.is_empty
        do
            Result := compressor.compress_string (a_block)
            update_stats (a_block.count, Result.count)
        ensure
            compressed: Result /= Void
        end

    compress_file_streaming (a_source, a_dest: STRING)
            -- Compress large file using streaming.
        local
            l_source_file: RAW_FILE
            l_chunk: STRING
        do
            stream := compressor.create_compress_stream (a_dest)
            create l_source_file.make_open_read (a_source)

            from
                l_source_file.read_stream (block_size)
            until
                l_source_file.end_of_file
            loop
                l_chunk := l_source_file.last_string
                stream.write (l_chunk)
                l_source_file.read_stream (block_size)
            end

            stream.close
            l_source_file.close
        end

feature -- Decompression (for search)

    decompress_block (a_compressed: STRING): STRING
            -- Decompress a single block for search.
        require
            compressed_not_empty: not a_compressed.is_empty
        do
            Result := compressor.decompress_string (a_compressed)
        ensure
            decompressed: Result /= Void
        end

feature -- Statistics

    compression_ratio: REAL_64
            -- Overall compression ratio.
        do
            Result := compressor.compression_ratio
        end
```

**Data flow:**
```
Log file -> Split into blocks -> COMPACTOR_ENGINE.compress_block -> Archive
                                           |
                                           v
                                    Track: block_offset, timestamp_range
                                           |
                                           v
                                    LOG_INDEX (SQLite)
```

### simple_datetime Integration

**Purpose:** Parse and format timestamps for log analysis and archive naming

**Usage:**
```eiffel
class LOG_TIMESTAMP_PARSER

feature {NONE} -- Implementation

    datetime: SIMPLE_DATETIME
        -- Datetime handler

feature -- Parsing

    parse_log_timestamp (a_line: STRING): detachable DATE_TIME
            -- Extract timestamp from log line.
        local
            l_patterns: ARRAYED_LIST [STRING]
        do
            create datetime.make_now

            -- Try common log timestamp formats
            l_patterns := <<
                "yyyy-MM-dd HH:mm:ss",      -- ISO format
                "dd/MMM/yyyy:HH:mm:ss",     -- Apache format
                "MMM dd HH:mm:ss",          -- Syslog format
                "yyyy-MM-dd'T'HH:mm:ss"     -- ISO 8601
            >>

            across l_patterns as pattern until Result /= Void loop
                Result := datetime.parse (a_line.substring (1, 30), pattern.item)
            end
        end

    format_archive_path (a_template: STRING; a_timestamp: DATE_TIME): STRING
            -- Format archive path with timestamp.
        do
            create datetime.make_from_date_time (a_timestamp)
            Result := a_template.twin
            Result.replace_substring_all ("{date}", datetime.format ("yyyy-MM-dd"))
            Result.replace_substring_all ("{year}", datetime.format ("yyyy"))
            Result.replace_substring_all ("{month}", datetime.format ("MM"))
            Result.replace_substring_all ("{day}", datetime.format ("dd"))
        end

feature -- Time Range Queries

    is_in_range (a_timestamp: DATE_TIME; a_start, a_end: DATE_TIME): BOOLEAN
            -- Is timestamp within range?
        do
            Result := a_timestamp >= a_start and a_timestamp <= a_end
        end
```

### simple_sql Integration

**Purpose:** Store searchable index for compressed log archives

**Usage:**
```eiffel
class LOG_INDEX

feature {NONE} -- Implementation

    db: SIMPLE_SQL
        -- SQLite database for index

feature -- Initialization

    make (a_db_path: STRING)
            -- Create or open index database.
        do
            create db.make (a_db_path)
            ensure_schema
        end

feature {NONE} -- Schema

    ensure_schema
            -- Create index tables if not exist.
        do
            db.execute ("
                CREATE TABLE IF NOT EXISTS archives (
                    id INTEGER PRIMARY KEY,
                    path TEXT NOT NULL,
                    source_path TEXT NOT NULL,
                    created_at TEXT NOT NULL,
                    original_size INTEGER,
                    compressed_size INTEGER,
                    block_count INTEGER
                )
            ")

            db.execute ("
                CREATE TABLE IF NOT EXISTS blocks (
                    id INTEGER PRIMARY KEY,
                    archive_id INTEGER,
                    block_number INTEGER,
                    offset INTEGER,
                    size INTEGER,
                    timestamp_start TEXT,
                    timestamp_end TEXT,
                    line_count INTEGER,
                    FOREIGN KEY (archive_id) REFERENCES archives(id)
                )
            ")

            db.execute ("
                CREATE INDEX IF NOT EXISTS idx_blocks_timestamp
                ON blocks(timestamp_start, timestamp_end)
            ")
        end

feature -- Indexing

    index_archive (a_archive: ARCHIVE_METADATA)
            -- Add archive to index.
        local
            l_archive_id: INTEGER
        do
            db.execute_with_params ("
                INSERT INTO archives (path, source_path, created_at, original_size, compressed_size, block_count)
                VALUES (?, ?, ?, ?, ?, ?)
            ", <<a_archive.path, a_archive.source_path, a_archive.created_at.out,
                 a_archive.original_size, a_archive.compressed_size, a_archive.block_count>>)

            l_archive_id := db.last_insert_id

            across a_archive.blocks as block loop
                index_block (l_archive_id, block.item)
            end
        end

feature -- Search

    find_blocks_in_range (a_start, a_end: DATE_TIME): ARRAYED_LIST [BLOCK_LOCATION]
            -- Find all blocks containing timestamps in range.
        do
            create Result.make (10)
            db.query_with_params ("
                SELECT a.path, b.block_number, b.offset, b.size
                FROM blocks b
                JOIN archives a ON b.archive_id = a.id
                WHERE b.timestamp_end >= ? AND b.timestamp_start <= ?
                ORDER BY b.timestamp_start
            ", <<a_start.out, a_end.out>>)

            across db.results as row loop
                Result.extend (create {BLOCK_LOCATION}.make (
                    row.item.string ("path"),
                    row.item.integer ("block_number"),
                    row.item.integer ("offset"),
                    row.item.integer ("size")
                ))
            end
        end
```

### simple_watcher Integration

**Purpose:** Monitor log directories for continuous compression

**Usage:**
```eiffel
class WATCH_SERVICE

feature {NONE} -- Implementation

    watcher: SIMPLE_WATCHER
        -- File system watcher

    compactor: COMPACTOR_ENGINE
        -- Compactor for processing

feature -- Initialization

    make (a_config: WATCH_CONFIG; a_compactor: COMPACTOR_ENGINE)
            -- Create watch service.
        do
            compactor := a_compactor
            create watcher.make (a_config.watch_path)
            watcher.on_modify (agent handle_file_change)
            watcher.on_create (agent handle_new_file)
        end

feature -- Service Control

    start
            -- Start watching for log changes.
        do
            watcher.start
            is_running := True
        end

    stop
            -- Stop watching.
        do
            watcher.stop
            is_running := False
        end

feature {NONE} -- Event Handlers

    handle_file_change (a_path: STRING)
            -- Handle modified file (potential rotation).
        do
            if is_rotation_complete (a_path) then
                compactor.compact_file (a_path)
            end
        end

    handle_new_file (a_path: STRING)
            -- Handle new file (rotated log).
        do
            if matches_log_pattern (a_path) then
                -- Wait for file to stabilize, then compact
                schedule_compact (a_path, settle_delay)
            end
        end

    is_rotation_complete (a_path: STRING): BOOLEAN
            -- Check if log rotation is complete.
        do
            -- Rotated logs typically have date suffix or .1, .2, etc.
            Result := a_path.has_substring (".1") or
                      a_path.has_substring (".log.") or
                      not a_path.ends_with (".log")
        end
```

## Dependency Graph

```
log-compactor
    |
    +-- simple_compression (required)
    |   +-- simple_base64
    |
    +-- simple_file (required)
    |
    +-- simple_datetime (required)
    |
    +-- simple_cli (required)
    |
    +-- simple_config (required)
    |   +-- simple_yaml
    |   +-- simple_json
    |
    +-- simple_sql (required)
    |
    +-- simple_json (required)
    |
    +-- simple_watcher (optional - watch mode)
    |
    +-- simple_logger (optional - audit logging)
    |
    +-- simple_hash (optional - SHA-256 verification)
    |
    +-- ISE base (required)
```

## ECF Configuration

```xml
<?xml version="1.0" encoding="ISO-8859-1"?>
<system xmlns="http://www.eiffel.com/developers/xml/configuration-1-22-0"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://www.eiffel.com/developers/xml/configuration-1-22-0 http://www.eiffel.com/developers/xml/configuration-1-22-0.xsd"
        name="log_compactor"
        uuid="XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX">

    <description>LogCompactor - High-performance log compression and archival</description>

    <target name="log_compactor">
        <root class="LOG_COMPACTOR_CLI" feature="make"/>

        <option warning="warning" syntax="provisional" manifest_array_type="mismatch_warning">
            <assertions precondition="true" postcondition="true" check="true" invariant="true"/>
        </option>

        <setting name="console_application" value="true"/>
        <setting name="concurrency" value="none"/>

        <capability>
            <concurrency support="none"/>
            <void_safety support="all"/>
        </capability>

        <!-- Application source -->
        <cluster name="src" location=".\src\" recursive="true"/>

        <!-- simple_* dependencies (required) -->
        <library name="simple_compression" location="$SIMPLE_EIFFEL\simple_compression\simple_compression.ecf"/>
        <library name="simple_file" location="$SIMPLE_EIFFEL\simple_file\simple_file.ecf"/>
        <library name="simple_datetime" location="$SIMPLE_EIFFEL\simple_datetime\simple_datetime.ecf"/>
        <library name="simple_cli" location="$SIMPLE_EIFFEL\simple_cli\simple_cli.ecf"/>
        <library name="simple_config" location="$SIMPLE_EIFFEL\simple_config\simple_config.ecf"/>
        <library name="simple_sql" location="$SIMPLE_EIFFEL\simple_sql\simple_sql.ecf"/>
        <library name="simple_json" location="$SIMPLE_EIFFEL\simple_json\simple_json.ecf"/>

        <!-- simple_* dependencies (optional - uncomment as needed) -->
        <!-- <library name="simple_watcher" location="$SIMPLE_EIFFEL\simple_watcher\simple_watcher.ecf"/> -->
        <!-- <library name="simple_logger" location="$SIMPLE_EIFFEL\simple_logger\simple_logger.ecf"/> -->
        <!-- <library name="simple_hash" location="$SIMPLE_EIFFEL\simple_hash\simple_hash.ecf"/> -->

        <!-- ISE dependencies -->
        <library name="base" location="$ISE_LIBRARY\library\base\base.ecf"/>
        <library name="time" location="$ISE_LIBRARY\library\time\time.ecf"/>
    </target>

    <target name="log_compactor_tests" extends="log_compactor">
        <root class="TEST_APP" feature="make"/>
        <library name="simple_testing" location="$SIMPLE_EIFFEL\simple_testing\simple_testing.ecf"/>
        <cluster name="testing" location=".\testing\" recursive="true"/>
    </target>

</system>
```
