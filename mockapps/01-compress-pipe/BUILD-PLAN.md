# CompressPipe - Build Plan

## Phase Overview

| Phase | Deliverable | Effort | Dependencies |
|-------|-------------|--------|--------------|
| Phase 1 | MVP CLI | 5 days | simple_compression, simple_cli, simple_file |
| Phase 2 | Full CLI | 5 days | Phase 1 + simple_config, simple_json, simple_csv |
| Phase 3 | Polish | 3 days | Phase 2 + simple_logger, simple_sql |

---

## Phase 1: MVP

### Objective

Deliver a working CLI that can compress and decompress individual files with configurable compression levels. This proves the core concept and provides immediate utility.

### Deliverables

1. **COMPRESS_PIPE_CLI** - Main CLI entry point with basic commands
2. **SIMPLE_COMPRESSOR** - Wrapper around simple_compression for file operations
3. **Basic commands:** compress, decompress, stats

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T1.1 | Create project structure | ECF compiles, directories created |
| T1.2 | Implement COMPRESS_PIPE_CLI | Parses arguments, routes commands |
| T1.3 | Implement compress command | `compress-pipe compress input.txt -o output.gz` works |
| T1.4 | Implement decompress command | `compress-pipe decompress input.gz -o output.txt` works |
| T1.5 | Add compression level support | `--level fast\|default\|best` works |
| T1.6 | Implement stats display | Shows compression ratio, sizes |
| T1.7 | Add glob pattern support | `compress-pipe compress *.log -o archive/` works |
| T1.8 | Write Phase 1 tests | All tests pass |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Compress text file | 10KB text file | Compressed file ~3KB, ratio ~3x |
| Decompress file | Compressed file | Exact original content |
| Roundtrip test | Any file | decompress(compress(x)) == x |
| Level fast | Large file | Faster but larger output |
| Level best | Large file | Slower but smaller output |
| Stats output | After compression | Shows input size, output size, ratio |
| Glob compress | *.log pattern | All matching files compressed |
| Missing file | Non-existent path | Clear error message |

### Phase 1 Class Skeleton

```eiffel
class COMPRESS_PIPE_CLI

create
    make

feature -- Execution

    make
            -- Application entry point.
        do
            parse_arguments
            execute_command
        end

feature {NONE} -- Commands

    do_compress
            -- Execute compress command.
        require
            has_input: not input_path.is_empty
        do
            -- Implementation
        ensure
            output_created: output_exists
        end

    do_decompress
            -- Execute decompress command.
        require
            has_input: not input_path.is_empty
            input_exists: file_exists (input_path)
        do
            -- Implementation
        end

    do_stats
            -- Display compression statistics.
        do
            -- Implementation
        end

feature -- Access

    input_path: STRING
    output_path: STRING
    compression_level: INTEGER

end
```

---

## Phase 2: Full Implementation

### Objective

Add pipeline configuration support, format transformation, and multi-stage processing. This enables real data engineering workflows.

### Deliverables

1. **PIPELINE_ENGINE** - Configuration-driven pipeline execution
2. **PIPELINE_CONFIG** - YAML/JSON configuration loading
3. **TRANSFORM_STAGE** - CSV/JSON format conversion
4. **DESTINATION_STAGE** - Multi-target output support
5. **Commands:** run, convert, validate, init

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T2.1 | Implement PIPELINE_CONFIG | Loads YAML and JSON configs |
| T2.2 | Implement PIPELINE_ENGINE | Executes configured stages |
| T2.3 | Implement SOURCE_STAGE | File, directory, stdin sources |
| T2.4 | Implement COMPRESS_STAGE | Compression with configurable level |
| T2.5 | Implement TRANSFORM_STAGE | CSV to JSON, JSON to CSV |
| T2.6 | Implement DESTINATION_STAGE | File, stdout, multi-target |
| T2.7 | Add run command | `compress-pipe run --config pipeline.yaml` works |
| T2.8 | Add convert command | `compress-pipe convert input.csv --to json` works |
| T2.9 | Add validate command | Validates config syntax |
| T2.10 | Add init command | Creates example config file |
| T2.11 | Write Phase 2 tests | All tests pass |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Load YAML config | Valid YAML | Config object populated |
| Load JSON config | Valid JSON | Config object populated |
| Invalid config | Malformed YAML | Clear error message |
| Run pipeline | Directory of logs | All files compressed to destination |
| CSV to JSON | CSV file | Valid JSON array output |
| JSON to CSV | JSON array | Valid CSV with headers |
| Multi-stage | Decompress -> Transform -> Compress | Correct final output |
| validate command | Config file | Reports errors or "Valid" |
| init command | No args | Creates example.yaml in current dir |

### Phase 2 Example Configuration

```yaml
# pipeline.yaml
version: "1.0"
name: "csv-to-compressed-json"

source:
  type: file
  path: data/input.csv

stages:
  - name: csv-to-json
    type: transform
    from: csv
    to: json

  - name: compress
    type: compress
    level: best
    format: gzip

destination:
  type: file
  path: output/data.json.gz
```

---

## Phase 3: Production Polish

### Objective

Add enterprise features: logging, statistics persistence, error handling hardening, and documentation.

### Deliverables

1. **PIPELINE_LOGGER** - Audit logging with configurable levels
2. **PIPELINE_STATS** - Persistent statistics with SQLite
3. **Error handling** - Comprehensive error recovery
4. **Documentation** - README, man page, examples

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T3.1 | Implement PIPELINE_LOGGER | Logs to file in text/JSON format |
| T3.2 | Implement PIPELINE_STATS | Persists stats to SQLite |
| T3.3 | Add stats history command | `compress-pipe stats --history` shows past runs |
| T3.4 | Harden error handling | All errors caught, clear messages |
| T3.5 | Add verbose mode | `--verbose` shows detailed progress |
| T3.6 | Add quiet mode | `--quiet` suppresses non-error output |
| T3.7 | Write README.md | Installation, usage, examples |
| T3.8 | Create example pipelines | 5+ real-world examples |
| T3.9 | Performance testing | Benchmark on large datasets |
| T3.10 | Final test suite | 100% critical path coverage |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Logging enabled | Run with logging config | Log file created with entries |
| JSON log format | log_format: json | Valid JSON log entries |
| Stats persistence | Multiple runs | Stats queryable across runs |
| Verbose mode | --verbose flag | Detailed progress output |
| Quiet mode | --quiet flag | Only errors shown |
| Error recovery | Partial failure | Continues processing, reports errors |
| Large file | 1GB file | Completes in reasonable time |

---

## ECF Target Structure

```xml
<!-- Library target (reusable logic) -->
<target name="compress_pipe_lib">
    <option warning="warning" syntax="provisional">
        <assertions precondition="true" postcondition="true"/>
    </option>
    <capability>
        <void_safety support="all"/>
    </capability>
    <cluster name="src" location=".\src\" recursive="true">
        <file_rule>
            <exclude>/cli$</exclude>
        </file_rule>
    </cluster>
    <!-- Dependencies -->
    <library name="simple_compression" location="$SIMPLE_EIFFEL\simple_compression\simple_compression.ecf"/>
    <library name="simple_config" location="$SIMPLE_EIFFEL\simple_config\simple_config.ecf"/>
    <library name="simple_json" location="$SIMPLE_EIFFEL\simple_json\simple_json.ecf"/>
    <library name="simple_csv" location="$SIMPLE_EIFFEL\simple_csv\simple_csv.ecf"/>
    <library name="simple_file" location="$SIMPLE_EIFFEL\simple_file\simple_file.ecf"/>
    <library name="simple_logger" location="$SIMPLE_EIFFEL\simple_logger\simple_logger.ecf"/>
    <library name="base" location="$ISE_LIBRARY\library\base\base.ecf"/>
</target>

<!-- CLI executable target -->
<target name="compress_pipe_cli" extends="compress_pipe_lib">
    <root class="COMPRESS_PIPE_CLI" feature="make"/>
    <setting name="console_application" value="true"/>
    <library name="simple_cli" location="$SIMPLE_EIFFEL\simple_cli\simple_cli.ecf"/>
    <cluster name="cli" location=".\src\cli\"/>
</target>

<!-- Test target -->
<target name="compress_pipe_tests" extends="compress_pipe_lib">
    <root class="TEST_APP" feature="make"/>
    <library name="simple_testing" location="$SIMPLE_EIFFEL\simple_testing\simple_testing.ecf"/>
    <cluster name="testing" location=".\testing\"/>
</target>
```

---

## Build Commands

```bash
# Phase 1: Compile MVP CLI
/d/prod/ec.sh -batch -config compress_pipe.ecf -target compress_pipe_cli -c_compile

# Run tests
/d/prod/ec.sh -batch -config compress_pipe.ecf -target compress_pipe_tests -c_compile
./EIFGENs/compress_pipe_tests/W_code/compress_pipe.exe

# Finalized build for release
/d/prod/ec.sh -batch -config compress_pipe.ecf -target compress_pipe_cli -finalize -c_compile
```

---

## Success Criteria

| Criterion | Measure | Target |
|-----------|---------|--------|
| Compiles | Zero errors | 100% |
| Tests pass | All tests | 100% |
| CLI works | All commands | Functional |
| Compression | Ratio on text | 50%+ reduction |
| Performance | Throughput | 50+ MB/s |
| Documentation | README complete | Yes |
| Examples | Working pipelines | 5+ |

---

## Directory Structure

```
compress_pipe/
+-- compress_pipe.ecf
+-- README.md
+-- CHANGELOG.md
+-- LICENSE
+-- src/
|   +-- compress_pipe_cli.e
|   +-- pipeline_engine.e
|   +-- pipeline_config.e
|   +-- pipeline_stage.e
|   +-- pipeline_stats.e
|   +-- pipeline_logger.e
|   +-- stages/
|   |   +-- source_stage.e
|   |   +-- compress_stage.e
|   |   +-- transform_stage.e
|   |   +-- destination_stage.e
|   +-- cli/
|       +-- cli_commands.e
+-- testing/
|   +-- test_app.e
|   +-- lib_tests.e
|   +-- test_compress_stage.e
|   +-- test_transform_stage.e
|   +-- test_pipeline_engine.e
+-- examples/
|   +-- log-compression.yaml
|   +-- csv-to-json.yaml
|   +-- backup-rotation.yaml
|   +-- multi-destination.yaml
|   +-- streaming-large-file.yaml
+-- docs/
    +-- index.html
    +-- usage.md
    +-- configuration.md
```
