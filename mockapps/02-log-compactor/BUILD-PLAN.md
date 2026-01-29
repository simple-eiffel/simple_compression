# LogCompactor - Build Plan

## Phase Overview

| Phase | Deliverable | Effort | Dependencies |
|-------|-------------|--------|--------------|
| Phase 1 | MVP CLI | 5 days | simple_compression, simple_cli, simple_file, simple_datetime |
| Phase 2 | Full CLI | 6 days | Phase 1 + simple_sql, simple_json, simple_config |
| Phase 3 | Polish | 4 days | Phase 2 + simple_watcher, simple_logger |

---

## Phase 1: MVP

### Objective

Deliver a working CLI that can compress log files into the .logz archive format with basic search capability. This proves the core concept of searchable compressed logs.

### Deliverables

1. **LOG_COMPACTOR_CLI** - Main CLI entry point with basic commands
2. **COMPACTOR_ENGINE** - Core compression with block-based processing
3. **ARCHIVE_MANAGER** - .logz archive format creation and reading
4. **Basic commands:** compact, extract, verify

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T1.1 | Create project structure | ECF compiles, directories created |
| T1.2 | Design .logz archive format | Header, blocks, footer spec documented |
| T1.3 | Implement ARCHIVE_MANAGER | Create and read .logz files |
| T1.4 | Implement COMPACTOR_ENGINE | Block-based compression works |
| T1.5 | Implement compact command | `log-compactor compact input.log -o output.logz` works |
| T1.6 | Implement extract command | `log-compactor extract archive.logz` restores original |
| T1.7 | Implement verify command | Checksum verification works |
| T1.8 | Add compression level support | `--level fast\|default\|best` works |
| T1.9 | Write Phase 1 tests | All tests pass |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Compact log file | 10MB log file | .logz archive ~2MB |
| Extract archive | .logz archive | Exact original content |
| Roundtrip test | Any log file | extract(compact(x)) == x |
| Verify valid | Valid archive | "Archive OK" |
| Verify corrupt | Corrupted archive | Error with details |
| Block boundary | Large file | Correct block splitting |
| Empty file | 0 byte file | Clear error message |
| Binary content | Log with binary | Handled gracefully |

### Phase 1 Archive Format

```
.logz Archive Structure:
+------------------+
| Magic: "LOGZ"    | 4 bytes
| Version: 1       | 2 bytes
| Flags: 0         | 2 bytes
| Original size    | 8 bytes
| Compressed size  | 8 bytes
| Block count      | 4 bytes
| Reserved         | 36 bytes
+------------------+
| Block 1          | Variable
|   - Size (4B)    |
|   - CRC32 (4B)   |
|   - Data         |
+------------------+
| Block 2          |
+------------------+
| ...              |
+------------------+
| Footer CRC32     | 4 bytes
+------------------+
```

---

## Phase 2: Full Implementation

### Objective

Add searchable indexing, retention management, and configuration support. This enables real production use for log management.

### Deliverables

1. **LOG_INDEX** - SQLite-based searchable index
2. **SEARCH_ENGINE** - Pattern and time-range search
3. **RETENTION_POLICY** - Configurable retention and cleanup
4. **LOG_FORMAT_DETECTOR** - Auto-detect log formats
5. **Commands:** search, cleanup, stats, validate, init

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T2.1 | Design index schema | SQLite tables for archives, blocks |
| T2.2 | Implement LOG_INDEX | Index creation and querying |
| T2.3 | Implement SEARCH_ENGINE | Pattern search in compressed archives |
| T2.4 | Add time-range search | `--from` and `--to` date filters |
| T2.5 | Implement LOG_FORMAT_DETECTOR | Auto-detect JSON, syslog, Apache |
| T2.6 | Implement RETENTION_POLICY | Configurable retention periods |
| T2.7 | Implement cleanup command | Apply retention, remove expired |
| T2.8 | Implement stats command | Show compression statistics |
| T2.9 | Add configuration support | Load YAML/JSON config |
| T2.10 | Add directory processing | Compact entire directories |
| T2.11 | Write Phase 2 tests | All tests pass |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Index creation | Compact operation | Index entries created |
| Pattern search | "ERROR" pattern | Matching lines returned |
| Time range search | --last 7d | Only recent entries |
| Format detection | JSON logs | Detected as JSON |
| Format detection | Syslog | Detected as syslog |
| Retention cleanup | 90-day policy | Archives >90 days deleted |
| Stats display | After operations | Compression stats shown |
| Config loading | YAML file | Configuration applied |
| Directory compact | /var/log/app/ | All .log files compacted |

### Phase 2 Search Examples

```bash
# Search for error patterns
log-compactor search "ERROR.*timeout" --archive /archive/logs

# Search with time range
log-compactor search "connection refused" --from 2026-01-01 --to 2026-01-15

# Search last N days
log-compactor search "OutOfMemory" --last 7d

# Search specific service (JSON logs)
log-compactor search --field service=api --field level=ERROR

# Show matching files only
log-compactor search "CRITICAL" --files-only
```

---

## Phase 3: Production Polish

### Objective

Add watch mode for continuous compression, comprehensive logging, and production hardening.

### Deliverables

1. **WATCH_SERVICE** - Continuous log monitoring and compression
2. **COMPACTOR_LOGGER** - Audit logging
3. **Error handling** - Comprehensive recovery
4. **Documentation** - README, man page, deployment guide

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T3.1 | Implement WATCH_SERVICE | Monitor directories for rotation |
| T3.2 | Add rotation detection | Detect when logs rotate |
| T3.3 | Implement continuous mode | `--daemon` flag for service mode |
| T3.4 | Add audit logging | All operations logged |
| T3.5 | Harden error handling | All errors caught, recovery attempted |
| T3.6 | Add graceful shutdown | SIGTERM handling |
| T3.7 | Performance optimization | Profile and optimize hot paths |
| T3.8 | Write README.md | Installation, usage, configuration |
| T3.9 | Create deployment examples | Systemd service, Docker |
| T3.10 | Final test suite | 100% critical path coverage |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Watch mode start | Directory path | Monitoring active |
| Rotation detection | Log rotates | Old log compacted |
| New file handling | New .log file | Eventually compacted |
| Daemon mode | --daemon flag | Runs as background service |
| Graceful shutdown | SIGTERM | Clean exit, no corruption |
| Audit logging | Any operation | Log entry created |
| Error recovery | Disk full during compact | Partial work cleaned up |
| Large file | 10GB log | Completes with streaming |

---

## ECF Target Structure

```xml
<!-- Library target (reusable logic) -->
<target name="log_compactor_lib">
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
    <library name="simple_file" location="$SIMPLE_EIFFEL\simple_file\simple_file.ecf"/>
    <library name="simple_datetime" location="$SIMPLE_EIFFEL\simple_datetime\simple_datetime.ecf"/>
    <library name="simple_sql" location="$SIMPLE_EIFFEL\simple_sql\simple_sql.ecf"/>
    <library name="simple_json" location="$SIMPLE_EIFFEL\simple_json\simple_json.ecf"/>
    <library name="simple_config" location="$SIMPLE_EIFFEL\simple_config\simple_config.ecf"/>
    <library name="base" location="$ISE_LIBRARY\library\base\base.ecf"/>
    <library name="time" location="$ISE_LIBRARY\library\time\time.ecf"/>
</target>

<!-- CLI executable target -->
<target name="log_compactor_cli" extends="log_compactor_lib">
    <root class="LOG_COMPACTOR_CLI" feature="make"/>
    <setting name="console_application" value="true"/>
    <library name="simple_cli" location="$SIMPLE_EIFFEL\simple_cli\simple_cli.ecf"/>
    <cluster name="cli" location=".\src\cli\"/>
</target>

<!-- Test target -->
<target name="log_compactor_tests" extends="log_compactor_lib">
    <root class="TEST_APP" feature="make"/>
    <library name="simple_testing" location="$SIMPLE_EIFFEL\simple_testing\simple_testing.ecf"/>
    <cluster name="testing" location=".\testing\"/>
</target>
```

---

## Build Commands

```bash
# Phase 1: Compile MVP CLI
/d/prod/ec.sh -batch -config log_compactor.ecf -target log_compactor_cli -c_compile

# Run tests
/d/prod/ec.sh -batch -config log_compactor.ecf -target log_compactor_tests -c_compile
./EIFGENs/log_compactor_tests/W_code/log_compactor.exe

# Finalized build for release
/d/prod/ec.sh -batch -config log_compactor.ecf -target log_compactor_cli -finalize -c_compile
```

---

## Success Criteria

| Criterion | Measure | Target |
|-----------|---------|--------|
| Compiles | Zero errors | 100% |
| Tests pass | All tests | 100% |
| CLI works | All commands | Functional |
| Compression | Ratio on logs | 70%+ reduction |
| Search speed | Time to first result | <5s for 1GB archive |
| Integrity | Roundtrip verification | 100% data preserved |
| Documentation | README complete | Yes |

---

## Directory Structure

```
log_compactor/
+-- log_compactor.ecf
+-- README.md
+-- CHANGELOG.md
+-- LICENSE
+-- src/
|   +-- log_compactor_cli.e
|   +-- compactor_engine.e
|   +-- archive_manager.e
|   +-- log_index.e
|   +-- search_engine.e
|   +-- retention_policy.e
|   +-- watch_service.e
|   +-- log_format_detector.e
|   +-- compactor_stats.e
|   +-- cli/
|       +-- cli_commands.e
+-- testing/
|   +-- test_app.e
|   +-- lib_tests.e
|   +-- test_archive_format.e
|   +-- test_compression.e
|   +-- test_search.e
|   +-- test_retention.e
+-- examples/
|   +-- basic-config.yaml
|   +-- enterprise-config.yaml
|   +-- systemd/
|   |   +-- log-compactor.service
|   +-- docker/
|       +-- Dockerfile
+-- docs/
    +-- index.html
    +-- archive-format.md
    +-- configuration.md
    +-- deployment.md
```

---

## Deployment Examples

### Systemd Service

```ini
# /etc/systemd/system/log-compactor.service
[Unit]
Description=LogCompactor - Log compression service
After=network.target

[Service]
Type=simple
User=logcompactor
ExecStart=/usr/local/bin/log-compactor watch --config /etc/log-compactor/config.yaml
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### Cron Job (Batch Mode)

```bash
# /etc/cron.d/log-compactor
# Compact logs daily at 2 AM
0 2 * * * root /usr/local/bin/log-compactor compact /var/log/app --archive /archive/logs --retention 90
# Cleanup expired archives weekly
0 3 * * 0 root /usr/local/bin/log-compactor cleanup --archive /archive/logs
```

### Docker

```dockerfile
FROM alpine:3.19
RUN apk add --no-cache libc6-compat
COPY log-compactor /usr/local/bin/
VOLUME ["/logs", "/archive", "/config"]
ENTRYPOINT ["/usr/local/bin/log-compactor"]
CMD ["watch", "--config", "/config/config.yaml"]
```
