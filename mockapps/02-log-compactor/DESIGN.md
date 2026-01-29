# LogCompactor - Technical Design

## Architecture

### Component Overview

```
+-------------------------------------------------------------+
|                       LogCompactor                           |
+-------------------------------------------------------------+
|  CLI Interface Layer                                         |
|    - Argument parsing (simple_cli)                           |
|    - Command routing                                         |
|    - Output formatting (text, JSON)                          |
+-------------------------------------------------------------+
|  Compactor Engine                                            |
|    - Log format detection                                    |
|    - Compression strategy selection                          |
|    - Index generation                                        |
|    - Retention policy enforcement                            |
+-------------------------------------------------------------+
|  Watch Service                                               |
|    - File system monitoring (simple_watcher)                 |
|    - Rotation detection                                      |
|    - Continuous compression                                  |
+-------------------------------------------------------------+
|  Search Engine                                               |
|    - Index lookup                                            |
|    - Compressed block decompression                          |
|    - Result filtering                                        |
+-------------------------------------------------------------+
|  Integration Layer                                           |
|    - simple_compression (core compression)                   |
|    - simple_file (file operations)                           |
|    - simple_datetime (timestamp handling)                    |
|    - simple_sql (index storage)                              |
|    - simple_json (structured log handling)                   |
|    - simple_watcher (file monitoring)                        |
+-------------------------------------------------------------+
```

### Class Design

| Class | Responsibility | Key Features |
|-------|----------------|--------------|
| `LOG_COMPACTOR_CLI` | Command-line interface | parse_args, execute, format_output |
| `COMPACTOR_ENGINE` | Core compression orchestration | compact, search, rotate, cleanup |
| `LOG_FORMAT_DETECTOR` | Identify log format | detect_json, detect_syslog, detect_apache |
| `COMPRESSION_STRATEGY` | Optimize compression | select_level, select_block_size |
| `LOG_INDEX` | Searchable index | build_index, search, save, load |
| `RETENTION_POLICY` | Retention management | apply_policy, cleanup_expired |
| `WATCH_SERVICE` | Continuous monitoring | start, stop, on_rotate |
| `SEARCH_ENGINE` | Search in compressed | search_pattern, search_time_range |
| `COMPACTOR_STATS` | Statistics tracking | compression_ratio, files_processed |
| `ARCHIVE_MANAGER` | Archive file handling | create, verify, extract |

### Command Structure

```bash
log-compactor <command> [options] [arguments]

Commands:
  compact     Compress log files with indexing
  search      Search in compressed archives
  watch       Monitor and compress logs continuously
  rotate      Rotate and compress current logs
  cleanup     Apply retention policy, remove expired archives
  stats       Show compression and storage statistics
  verify      Verify archive integrity
  extract     Extract logs from archive

Global Options:
  --config FILE       Configuration file
  --log-dir PATH      Log directory to process
  --archive-dir PATH  Archive destination
  --retention DAYS    Retention period in days
  --format FORMAT     Output format: text|json
  --verbose           Verbose output
  --quiet             Suppress non-error output
  --help              Show help

Examples:
  log-compactor compact /var/log/app --archive /archive/logs
  log-compactor search "ERROR.*timeout" --archive /archive/logs --last 7d
  log-compactor watch /var/log/app --archive /archive/logs --retention 90
  log-compactor cleanup --retention 30 --archive /archive/logs
```

### Data Flow

```
Log Sources              Compactor Engine              Archives
+------------+          +------------------+          +----------------+
| /var/log   |          | Format Detection |          | .logz archives |
| app/*.log  | -------> | Block Splitting  | -------> | with embedded  |
| rotated    |          | Compression      |          | index metadata |
+------------+          | Index Generation |          +----------------+
                        +------------------+                  |
                               |                              |
                               v                              v
                        +--------------+              +--------------+
                        | Index DB     |              | Search       |
                        | (SQLite)     | <----------- | Engine       |
                        +--------------+              +--------------+
```

### Archive Format (.logz)

```
+--------------------------------------------------+
| LOGZ Header (64 bytes)                           |
|   - Magic: "LOGZ" (4 bytes)                      |
|   - Version: uint16                              |
|   - Flags: uint16                                |
|   - Original size: uint64                        |
|   - Compressed size: uint64                      |
|   - Block count: uint32                          |
|   - Index offset: uint64                         |
|   - Checksum: uint32 (CRC32)                     |
+--------------------------------------------------+
| Block 1 (compressed)                             |
|   - Block header (timestamp range, line count)   |
|   - Compressed log lines                         |
+--------------------------------------------------+
| Block 2 (compressed)                             |
+--------------------------------------------------+
| ...                                              |
+--------------------------------------------------+
| Block N (compressed)                             |
+--------------------------------------------------+
| Index Section                                    |
|   - Block offsets                                |
|   - Timestamp ranges per block                   |
|   - Line number mappings                         |
+--------------------------------------------------+
| Footer                                           |
|   - Total checksum                               |
+--------------------------------------------------+
```

### Configuration Schema

```yaml
# log-compactor.yaml
version: "1.0"

sources:
  - name: app-logs
    path: /var/log/app
    pattern: "*.log"
    format: auto  # auto|json|syslog|apache|custom
    watch: true

archive:
  path: /archive/logs
  naming: "{source}/{date}/{filename}.logz"
  block_size: 64KB  # Compression block size

compression:
  level: best  # fast|default|best
  min_size: 1KB  # Don't compress files smaller than this

retention:
  default: 90  # days
  policies:
    - pattern: "error*.log"
      days: 365
    - pattern: "access*.log"
      days: 30

index:
  enabled: true
  db_path: /var/lib/log-compactor/index.db
  fields:  # Fields to index (for structured logs)
    - timestamp
    - level
    - service

watch:
  enabled: true
  interval: 60  # seconds
  rotate_trigger: size  # size|time|pattern
  rotate_size: 100MB

logging:
  file: /var/log/log-compactor.log
  level: info
```

### Error Handling

| Error Type | Handling | User Message |
|------------|----------|--------------|
| Source not found | Skip with warning | "Source not found: {path}. Skipping." |
| Permission denied | Fail with suggestion | "Cannot read {path}: Permission denied. Run with elevated privileges." |
| Archive exists | Warn and skip or overwrite | "Archive exists: {path}. Use --force to overwrite." |
| Compression failed | Retry then fail | "Compression failed for {file}: {reason}" |
| Index corruption | Rebuild | "Index corrupted. Rebuilding from archives..." |
| Disk full | Fail with cleanup suggestion | "Disk full. Run 'log-compactor cleanup' to free space." |
| Checksum mismatch | Fail with recovery suggestion | "Archive verification failed: {file}. Data may be corrupted." |

## GUI/TUI Future Path

**CLI foundation enables:**

1. **Log Browser (TUI)**
   - ncurses-based archive browser
   - Real-time search with highlighting
   - Time-range navigation
   - Same search engine as CLI

2. **Dashboard (Web GUI)**
   - Compression statistics visualization
   - Storage trending graphs
   - Retention policy management
   - Built on same COMPACTOR_ENGINE

3. **Shared Components**
   - `COMPACTOR_ENGINE` - Same engine for all interfaces
   - `SEARCH_ENGINE` - Same search for CLI/TUI/GUI
   - `ARCHIVE_MANAGER` - Same archive format
   - Statistics and logging shared

4. **Migration Path**
   - CLI commands map directly to GUI actions
   - Configuration files work across interfaces
   - Search syntax identical in all modes
