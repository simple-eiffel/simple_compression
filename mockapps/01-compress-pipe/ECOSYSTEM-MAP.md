# CompressPipe - Ecosystem Integration

## simple_* Dependencies

### Required Libraries

| Library | Purpose | Integration Point |
|---------|---------|-------------------|
| `simple_compression` | Core compression engine | COMPRESS_STAGE uses SIMPLE_COMPRESSION for all compression/decompression |
| `simple_cli` | Command-line argument parsing | COMPRESS_PIPE_CLI uses for argument parsing and help generation |
| `simple_config` | Configuration file handling | PIPELINE_CONFIG uses for YAML/JSON pipeline definitions |
| `simple_file` | File operations | SOURCE_STAGE and DESTINATION_STAGE use for file I/O |
| `simple_json` | JSON transformation | TRANSFORM_STAGE uses for JSON parsing and generation |
| `simple_csv` | CSV transformation | TRANSFORM_STAGE uses for CSV parsing and generation |
| `simple_logger` | Operation logging | PIPELINE_LOGGER uses for audit trail |

### Optional Libraries

| Library | Purpose | When Needed |
|---------|---------|-------------|
| `simple_sql` | Statistics storage | When persistent stats tracking is enabled |
| `simple_datetime` | Timestamp formatting | For filename templates with date patterns |
| `simple_hash` | Extended checksums | When SHA-256/MD5 checksums are requested |
| `simple_watcher` | File watching | For continuous mode (watch directory for changes) |
| `simple_validation` | Config validation | For strict configuration validation |

## Integration Patterns

### simple_compression Integration

**Purpose:** Provides all compression and decompression capabilities

**Usage:**
```eiffel
class COMPRESS_STAGE

inherit
    PIPELINE_STAGE

feature {NONE} -- Implementation

    compressor: SIMPLE_COMPRESSION
        -- Core compression engine

feature -- Initialization

    make (a_level: INTEGER)
            -- Create compression stage with specified level.
        require
            valid_level: a_level >= 0 and a_level <= 9
        do
            create compressor.make_with_level (a_level)
        end

feature -- Processing

    process (a_data: STRING): STRING
            -- Compress input data.
        do
            if is_compressing then
                Result := compressor.compress_string (a_data)
                update_stats (a_data.count, Result.count)
            else
                Result := compressor.decompress_string (a_data)
                update_stats (Result.count, a_data.count)
            end
        end

    process_file (a_source, a_dest: STRING): BOOLEAN
            -- Compress file.
        do
            Result := compressor.compress_file (a_source, a_dest)
            if Result then
                log_compression_stats
            end
        end

feature -- Statistics

    last_ratio: REAL_64
            -- Compression ratio from last operation.
        do
            Result := compressor.compression_ratio
        end

    last_savings: STRING
            -- Human-readable compression savings.
        do
            Result := compressor.space_savings
        end
```

**Data flow:**
```
Input data -> COMPRESS_STAGE.process -> SIMPLE_COMPRESSION.compress_string -> Compressed output
                                     |
                                     v
                              Track stats: ratio, input_size, output_size
```

### simple_cli Integration

**Purpose:** Provides command-line argument parsing and help generation

**Usage:**
```eiffel
class COMPRESS_PIPE_CLI

feature {NONE} -- Implementation

    cli: SIMPLE_CLI
        -- Command-line interface handler

feature -- Initialization

    make
            -- Initialize CLI with commands and options.
        do
            create cli.make ("compress-pipe", "Data pipeline compression tool")

            -- Register commands
            cli.add_command ("run", "Execute pipeline from config", agent do_run)
            cli.add_command ("compress", "Quick compress file(s)", agent do_compress)
            cli.add_command ("decompress", "Quick decompress file(s)", agent do_decompress)
            cli.add_command ("convert", "Convert between formats", agent do_convert)
            cli.add_command ("stats", "Show statistics", agent do_stats)
            cli.add_command ("validate", "Validate configuration", agent do_validate)
            cli.add_command ("init", "Create example config", agent do_init)

            -- Register global options
            cli.add_option ("config", "c", "Pipeline configuration file", True)
            cli.add_option ("output", "o", "Output format (text|json|csv)", True)
            cli.add_option ("level", "l", "Compression level (1-9 or fast|default|best)", True)
            cli.add_flag ("verbose", "v", "Verbose output")
            cli.add_flag ("quiet", "q", "Suppress non-error output")
        end

feature -- Execution

    run
            -- Execute CLI.
        do
            cli.parse_and_execute
        end
```

### simple_config Integration

**Purpose:** Loads and validates pipeline configuration from YAML or JSON files

**Usage:**
```eiffel
class PIPELINE_CONFIG

feature {NONE} -- Implementation

    config: SIMPLE_CONFIG
        -- Configuration handler

feature -- Loading

    load_from_file (a_path: STRING)
            -- Load pipeline configuration from file.
        require
            path_not_empty: not a_path.is_empty
        do
            create config.make
            if a_path.ends_with (".yaml") or a_path.ends_with (".yml") then
                config.load_yaml (a_path)
            else
                config.load_json (a_path)
            end
            parse_pipeline_config
        ensure
            loaded: is_loaded
        end

feature -- Access

    source_config: SOURCE_CONFIG
            -- Configured data source

    stages: ARRAYED_LIST [STAGE_CONFIG]
            -- Configured processing stages

    destination_config: DESTINATION_CONFIG
            -- Configured data destination

feature {NONE} -- Parsing

    parse_pipeline_config
            -- Parse loaded configuration into pipeline components.
        do
            create source_config.make_from_config (config.section ("source"))
            create stages.make (5)
            across config.array ("stages") as stage loop
                stages.extend (create {STAGE_CONFIG}.make_from_config (stage.item))
            end
            create destination_config.make_from_config (config.section ("destination"))
        end
```

### simple_json and simple_csv Integration

**Purpose:** Enable format transformation between JSON and CSV

**Usage:**
```eiffel
class TRANSFORM_STAGE

feature {NONE} -- Implementation

    json_handler: SIMPLE_JSON
    csv_handler: SIMPLE_CSV

feature -- Transformation

    csv_to_json (a_csv: STRING): STRING
            -- Convert CSV data to JSON array.
        local
            l_records: ARRAYED_LIST [HASH_TABLE [STRING, STRING]]
            l_json_array: JSON_ARRAY
        do
            create csv_handler.make
            l_records := csv_handler.parse_with_headers (a_csv)

            create json_handler.make
            create l_json_array.make_empty
            across l_records as rec loop
                l_json_array.add (json_handler.object_from_table (rec.item))
            end

            Result := l_json_array.representation
        end

    json_to_csv (a_json: STRING): STRING
            -- Convert JSON array to CSV.
        local
            l_array: JSON_ARRAY
            l_records: ARRAYED_LIST [HASH_TABLE [STRING, STRING]]
        do
            create json_handler.make
            l_array := json_handler.parse_array (a_json)

            create l_records.make (l_array.count)
            across l_array as item loop
                l_records.extend (json_handler.object_to_table (item.item))
            end

            create csv_handler.make
            Result := csv_handler.generate_with_headers (l_records)
        end
```

### simple_logger Integration

**Purpose:** Provides audit logging for pipeline operations

**Usage:**
```eiffel
class PIPELINE_LOGGER

feature {NONE} -- Implementation

    logger: SIMPLE_LOGGER

feature -- Initialization

    make (a_config: PIPELINE_CONFIG)
            -- Initialize logger from configuration.
        do
            create logger.make (a_config.log_file)
            logger.set_level (a_config.log_level)
            if a_config.log_format.same_string ("json") then
                logger.set_json_format
            end
        end

feature -- Logging

    log_pipeline_start (a_config: PIPELINE_CONFIG)
            -- Log pipeline execution start.
        do
            logger.info ("Pipeline started: " + a_config.name)
            logger.debug ("Source: " + a_config.source_config.path)
            logger.debug ("Stages: " + a_config.stages.count.out)
        end

    log_stage_complete (a_stage: STRING; a_stats: STAGE_STATS)
            -- Log stage completion with statistics.
        do
            logger.info ("Stage complete: " + a_stage +
                        " (in: " + a_stats.bytes_in.out +
                        ", out: " + a_stats.bytes_out.out +
                        ", ratio: " + a_stats.ratio.out + ")")
        end

    log_pipeline_complete (a_stats: PIPELINE_STATS)
            -- Log pipeline completion with summary.
        do
            logger.info ("Pipeline complete: " +
                        a_stats.files_processed.out + " files, " +
                        a_stats.total_savings + " saved")
        end

    log_error (a_stage: STRING; a_error: STRING)
            -- Log error during processing.
        do
            logger.error ("Stage failed: " + a_stage + " - " + a_error)
        end
```

## Dependency Graph

```
compress-pipe
    |
    +-- simple_compression (required)
    |   +-- simple_base64
    |
    +-- simple_cli (required)
    |
    +-- simple_config (required)
    |   +-- simple_yaml (internal)
    |   +-- simple_json (internal)
    |
    +-- simple_file (required)
    |
    +-- simple_json (required)
    |
    +-- simple_csv (required)
    |
    +-- simple_logger (required)
    |
    +-- simple_sql (optional - stats persistence)
    |
    +-- simple_datetime (optional - filename templates)
    |
    +-- simple_hash (optional - extended checksums)
    |
    +-- simple_watcher (optional - watch mode)
    |
    +-- ISE base (required)
```

## ECF Configuration

```xml
<?xml version="1.0" encoding="ISO-8859-1"?>
<system xmlns="http://www.eiffel.com/developers/xml/configuration-1-22-0"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://www.eiffel.com/developers/xml/configuration-1-22-0 http://www.eiffel.com/developers/xml/configuration-1-22-0.xsd"
        name="compress_pipe"
        uuid="XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX">

    <description>CompressPipe - Data pipeline compression tool</description>

    <target name="compress_pipe">
        <root class="COMPRESS_PIPE_CLI" feature="make"/>

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
        <library name="simple_cli" location="$SIMPLE_EIFFEL\simple_cli\simple_cli.ecf"/>
        <library name="simple_config" location="$SIMPLE_EIFFEL\simple_config\simple_config.ecf"/>
        <library name="simple_file" location="$SIMPLE_EIFFEL\simple_file\simple_file.ecf"/>
        <library name="simple_json" location="$SIMPLE_EIFFEL\simple_json\simple_json.ecf"/>
        <library name="simple_csv" location="$SIMPLE_EIFFEL\simple_csv\simple_csv.ecf"/>
        <library name="simple_logger" location="$SIMPLE_EIFFEL\simple_logger\simple_logger.ecf"/>

        <!-- simple_* dependencies (optional - uncomment as needed) -->
        <!-- <library name="simple_sql" location="$SIMPLE_EIFFEL\simple_sql\simple_sql.ecf"/> -->
        <!-- <library name="simple_datetime" location="$SIMPLE_EIFFEL\simple_datetime\simple_datetime.ecf"/> -->
        <!-- <library name="simple_hash" location="$SIMPLE_EIFFEL\simple_hash\simple_hash.ecf"/> -->
        <!-- <library name="simple_watcher" location="$SIMPLE_EIFFEL\simple_watcher\simple_watcher.ecf"/> -->

        <!-- ISE dependencies -->
        <library name="base" location="$ISE_LIBRARY\library\base\base.ecf"/>
    </target>

    <target name="compress_pipe_tests" extends="compress_pipe">
        <root class="TEST_APP" feature="make"/>
        <library name="simple_testing" location="$SIMPLE_EIFFEL\simple_testing\simple_testing.ecf"/>
        <cluster name="testing" location=".\testing\" recursive="true"/>
    </target>

</system>
```
