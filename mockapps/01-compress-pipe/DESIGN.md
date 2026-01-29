# CompressPipe - Technical Design

## Architecture

### Component Overview

```
+-------------------------------------------------------------+
|                      CompressPipe                            |
+-------------------------------------------------------------+
|  CLI Interface Layer                                         |
|    - Argument parsing (simple_cli)                           |
|    - Command routing                                         |
|    - Output formatting (text, JSON, CSV)                     |
+-------------------------------------------------------------+
|  Pipeline Engine                                             |
|    - Configuration loading (simple_config)                   |
|    - Stage orchestration                                     |
|    - Data flow management                                    |
+-------------------------------------------------------------+
|  Processing Stages                                           |
|    - Source readers (file, stdin, directory)                 |
|    - Transformers (compress, decompress, convert)            |
|    - Destination writers (file, stdout, multi-target)        |
+-------------------------------------------------------------+
|  Integration Layer                                           |
|    - simple_compression (core compression)                   |
|    - simple_json (JSON transform)                            |
|    - simple_csv (CSV transform)                              |
|    - simple_file (file operations)                           |
|    - simple_logger (operation logging)                       |
+-------------------------------------------------------------+
```

### Class Design

| Class | Responsibility | Key Features |
|-------|----------------|--------------|
| `COMPRESS_PIPE_CLI` | Command-line interface | parse_args, execute, format_output |
| `PIPELINE_ENGINE` | Pipeline orchestration | load_config, run, get_stats |
| `PIPELINE_CONFIG` | Configuration management | load_yaml, load_json, validate |
| `PIPELINE_STAGE` | Abstract stage interface | process, get_stats |
| `SOURCE_STAGE` | Data input | read_file, read_stdin, read_directory |
| `COMPRESS_STAGE` | Compression processing | compress, decompress, set_level |
| `TRANSFORM_STAGE` | Format conversion | csv_to_json, json_to_csv |
| `DESTINATION_STAGE` | Data output | write_file, write_stdout, multi_write |
| `PIPELINE_STATS` | Statistics tracking | bytes_in, bytes_out, ratio, duration |
| `PIPELINE_LOGGER` | Audit logging | log_start, log_complete, log_error |

### Command Structure

```bash
compress-pipe <command> [options] [arguments]

Commands:
  run         Execute a pipeline from configuration file
  compress    Quick compress file(s) with default settings
  decompress  Quick decompress file(s)
  convert     Convert between formats (CSV/JSON) with optional compression
  stats       Show statistics from previous runs
  validate    Validate pipeline configuration file
  init        Create example pipeline configuration

Global Options:
  --config FILE       Pipeline configuration file (YAML or JSON)
  --output FORMAT     Output format: text|json|csv (default: text)
  --level LEVEL       Compression level: 1-9 or fast|default|best
  --verbose           Verbose output with timing info
  --quiet             Suppress non-error output
  --log FILE          Write log to file
  --help              Show help

Examples:
  compress-pipe compress input.csv -o output.csv.gz --level best
  compress-pipe run --config pipeline.yaml
  compress-pipe convert input.csv --to json --compress -o output.json.gz
```

### Data Flow

```
Input Sources          Processing Stages           Output Destinations
+------------+         +------------------+        +----------------+
| File       |         | Decompress       |        | File           |
| stdin      | ------> | Transform        | -----> | stdout         |
| Directory  |         | Compress         |        | Multi-target   |
| Glob       |         | Filter           |        | Archive        |
+------------+         +------------------+        +----------------+
                              |
                              v
                       +--------------+
                       | Statistics   |
                       | Logging      |
                       | Checksum     |
                       +--------------+
```

### Configuration Schema

```yaml
# pipeline.yaml - CompressPipe Configuration
version: "1.0"
name: "daily-log-compression"
description: "Compress and archive daily log files"

source:
  type: directory
  path: /var/log/app
  pattern: "*.log"
  recursive: false

stages:
  - name: compress
    type: compress
    level: best
    format: gzip

  - name: checksum
    type: checksum
    algorithm: crc32

destination:
  type: file
  path: /archive/logs/{date}/{filename}.gz
  create_dirs: true

options:
  parallel: 4
  on_error: continue  # continue|stop|retry
  cleanup_source: false

logging:
  level: info
  file: /var/log/compress-pipe.log
  format: json

stats:
  enabled: true
  file: /var/lib/compress-pipe/stats.db
```

```json
{
  "compress-pipe": {
    "version": "1.0",
    "default_level": "default",
    "default_format": "gzip",
    "stats_retention_days": 30
  }
}
```

### Error Handling

| Error Type | Handling | User Message |
|------------|----------|--------------|
| Config not found | Fail with suggestion | "Configuration file not found: {path}. Use 'compress-pipe init' to create example." |
| Invalid config | Fail with details | "Invalid configuration at line {n}: {reason}" |
| Source not found | Skip or fail (configurable) | "Source not found: {path}. Skipping." |
| Compression error | Retry or fail | "Compression failed for {file}: {reason}" |
| Destination error | Fail with suggestion | "Cannot write to {path}: {reason}. Check permissions." |
| Out of memory | Fail gracefully | "Insufficient memory for {file}. Consider streaming mode." |
| Checksum mismatch | Fail with details | "Checksum verification failed for {file}. Data may be corrupted." |

## GUI/TUI Future Path

**CLI foundation enables:**

1. **Pipeline Designer (GUI)**
   - Visual drag-and-drop stage configuration
   - Real-time pipeline preview
   - Shared command structure with CLI

2. **Pipeline Monitor (TUI)**
   - Real-time processing visualization
   - Job queue management
   - Statistics dashboard

3. **Shared Components**
   - `PIPELINE_ENGINE` - Same engine for all interfaces
   - `PIPELINE_CONFIG` - Same configuration format
   - `PIPELINE_STATS` - Same statistics tracking
   - Business logic completely separated from UI

4. **Migration Path**
   - CLI users can transition to GUI without relearning
   - Configuration files work across all interfaces
   - Same compression behavior regardless of interface
