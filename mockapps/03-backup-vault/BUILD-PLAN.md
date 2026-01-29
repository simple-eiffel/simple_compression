# BackupVault - Build Plan

## Phase Overview

| Phase | Deliverable | Effort | Dependencies |
|-------|-------------|--------|--------------|
| Phase 1 | MVP CLI | 6 days | simple_compression, simple_cli, simple_file, simple_hash |
| Phase 2 | Full CLI | 7 days | Phase 1 + simple_encryption, simple_sql, simple_config |
| Phase 3 | Polish | 5 days | Phase 2 + simple_logger, simple_datetime |

---

## Phase 1: MVP

### Objective

Deliver a working CLI that can backup and restore files with compression and basic deduplication. This proves the core concept of content-addressable backup storage.

### Deliverables

1. **BACKUP_VAULT_CLI** - Main CLI entry point with basic commands
2. **BACKUP_ENGINE** - Core backup/restore logic
3. **CHUNK_STORE** - Content-addressable chunk storage
4. **DEDUPLICATION_ENGINE** - Hash-based deduplication
5. **Basic commands:** backup, restore, list, verify

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T1.1 | Create project structure | ECF compiles, directories created |
| T1.2 | Design vault structure | Chunk storage layout documented |
| T1.3 | Implement CHUNK_STORE | Store and retrieve chunks by hash |
| T1.4 | Implement DEDUPLICATION_ENGINE | Content-based chunking |
| T1.5 | Implement BACKUP_ENGINE | Create backups with manifests |
| T1.6 | Implement backup command | `backup-vault backup /path --vault /vault` works |
| T1.7 | Implement restore command | `backup-vault restore --vault /vault --to /dest` works |
| T1.8 | Implement list command | Shows backup history |
| T1.9 | Implement verify command | Checks all chunks exist and are valid |
| T1.10 | Add progress display | Shows files processed, bytes, ratio |
| T1.11 | Write Phase 1 tests | All tests pass |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Backup directory | 100MB directory | Vault created with chunks |
| Restore backup | Vault | Exact original files |
| Roundtrip test | Any directory | restore(backup(x)) == x |
| Incremental backup | Modified directory | Only new chunks stored |
| Deduplication | Files with duplicates | Significant space savings |
| List backups | Vault with backups | List of backups shown |
| Verify valid | Valid vault | "Vault OK" |
| Verify corrupt | Missing chunk | Error with details |

### Phase 1 Vault Layout

```
vault/
+-- chunks/
|   +-- ab/
|   |   +-- cdef1234...  # Compressed chunk
|   +-- 12/
|       +-- 3456fedc...
+-- manifests/
|   +-- 2026-01-24.json   # Unencrypted manifest (Phase 1)
+-- index.json            # Simple index file (Phase 1)
```

---

## Phase 2: Full Implementation

### Objective

Add encryption, catalog database, retention policies, and configuration support. This enables secure, managed backups for production use.

### Deliverables

1. **ENCRYPTION_ENGINE** - AES-256-GCM encryption
2. **BACKUP_CATALOG** - SQLite-based catalog
3. **RETENTION_POLICY** - Configurable retention
4. **FILE_SCANNER** - Exclude patterns, change detection
5. **Commands:** prune, config, key

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T2.1 | Implement ENCRYPTION_ENGINE | AES-256-GCM encryption works |
| T2.2 | Add key derivation | PBKDF2 with configurable iterations |
| T2.3 | Encrypt chunks | All chunks encrypted before storage |
| T2.4 | Encrypt manifests | Manifests encrypted |
| T2.5 | Implement BACKUP_CATALOG | SQLite catalog with full schema |
| T2.6 | Migrate from index.json | Upgrade path from Phase 1 |
| T2.7 | Implement RETENTION_POLICY | keep-daily, keep-weekly, etc. |
| T2.8 | Implement prune command | Apply retention, remove old |
| T2.9 | Add exclude patterns | --exclude "*.tmp" works |
| T2.10 | Add configuration file | Load YAML config |
| T2.11 | Implement key command | Generate, export, import keys |
| T2.12 | Write Phase 2 tests | All tests pass |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Encrypted backup | With password | Encrypted chunks |
| Encrypted restore | With password | Correct decryption |
| Wrong password | Bad password | Clear error, no data leak |
| Key file backup | With key file | Works without password |
| Retention prune | 30-day policy | Old backups removed |
| Chunk cleanup | Pruned backup | Unreferenced chunks deleted |
| Exclude patterns | *.tmp exclusion | Temp files not backed up |
| Config loading | YAML config | Settings applied |

### Phase 2 Security Model

```
Password/Key File
       |
       v
   PBKDF2 (100K iterations)
       |
       v
   Derived Key (256 bits)
       |
       +------+-------+
       |              |
       v              v
   Chunk Key      Manifest Key
   (per-chunk IV)  (per-manifest IV)
```

---

## Phase 3: Production Polish

### Objective

Add comprehensive logging, statistics, error recovery, and production hardening.

### Deliverables

1. **BACKUP_LOGGER** - Audit logging
2. **BACKUP_STATS** - Detailed statistics
3. **Error recovery** - Resume interrupted backups
4. **Documentation** - README, man page, deployment guide

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T3.1 | Implement BACKUP_LOGGER | All operations logged |
| T3.2 | Add JSON output | --json flag for all commands |
| T3.3 | Implement resume | Resume interrupted backup |
| T3.4 | Add backup verification | --verify after backup |
| T3.5 | Implement stats command | Detailed vault statistics |
| T3.6 | Harden error handling | All errors caught, clear messages |
| T3.7 | Add bandwidth limiting | --limit-rate flag |
| T3.8 | Performance optimization | Parallel chunking |
| T3.9 | Write README.md | Installation, usage, examples |
| T3.10 | Create automation examples | Cron, Task Scheduler |
| T3.11 | Final test suite | 100% critical path coverage |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Audit logging | Any operation | Log entry created |
| JSON output | --json flag | Valid JSON output |
| Resume backup | Interrupted backup | Continues from last chunk |
| Post-backup verify | --verify flag | Verification runs |
| Stats display | stats command | Detailed statistics |
| Large backup | 100GB | Completes successfully |
| Parallel chunking | Many files | Faster than sequential |
| Bandwidth limit | --limit-rate 10M | Stays under limit |

---

## ECF Target Structure

```xml
<!-- Library target (reusable logic) -->
<target name="backup_vault_lib">
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
    <library name="simple_encryption" location="$SIMPLE_EIFFEL\simple_encryption\simple_encryption.ecf"/>
    <library name="simple_hash" location="$SIMPLE_EIFFEL\simple_hash\simple_hash.ecf"/>
    <library name="simple_file" location="$SIMPLE_EIFFEL\simple_file\simple_file.ecf"/>
    <library name="simple_sql" location="$SIMPLE_EIFFEL\simple_sql\simple_sql.ecf"/>
    <library name="simple_config" location="$SIMPLE_EIFFEL\simple_config\simple_config.ecf"/>
    <library name="simple_datetime" location="$SIMPLE_EIFFEL\simple_datetime\simple_datetime.ecf"/>
    <library name="simple_logger" location="$SIMPLE_EIFFEL\simple_logger\simple_logger.ecf"/>
    <library name="base" location="$ISE_LIBRARY\library\base\base.ecf"/>
    <library name="time" location="$ISE_LIBRARY\library\time\time.ecf"/>
</target>

<!-- CLI executable target -->
<target name="backup_vault_cli" extends="backup_vault_lib">
    <root class="BACKUP_VAULT_CLI" feature="make"/>
    <setting name="console_application" value="true"/>
    <library name="simple_cli" location="$SIMPLE_EIFFEL\simple_cli\simple_cli.ecf"/>
    <cluster name="cli" location=".\src\cli\"/>
</target>

<!-- Test target -->
<target name="backup_vault_tests" extends="backup_vault_lib">
    <root class="TEST_APP" feature="make"/>
    <library name="simple_testing" location="$SIMPLE_EIFFEL\simple_testing\simple_testing.ecf"/>
    <cluster name="testing" location=".\testing\"/>
</target>
```

---

## Build Commands

```bash
# Phase 1: Compile MVP CLI
/d/prod/ec.sh -batch -config backup_vault.ecf -target backup_vault_cli -c_compile

# Run tests
/d/prod/ec.sh -batch -config backup_vault.ecf -target backup_vault_tests -c_compile
./EIFGENs/backup_vault_tests/W_code/backup_vault.exe

# Finalized build for release
/d/prod/ec.sh -batch -config backup_vault.ecf -target backup_vault_cli -finalize -c_compile
```

---

## Success Criteria

| Criterion | Measure | Target |
|-----------|---------|--------|
| Compiles | Zero errors | 100% |
| Tests pass | All tests | 100% |
| CLI works | All commands | Functional |
| Deduplication | Space savings | 40%+ on incremental |
| Encryption | Security audit | AES-256-GCM compliant |
| Integrity | Roundtrip test | 100% data preserved |
| Performance | Throughput | 50+ MB/s |
| Documentation | README complete | Yes |

---

## Directory Structure

```
backup_vault/
+-- backup_vault.ecf
+-- README.md
+-- CHANGELOG.md
+-- LICENSE
+-- src/
|   +-- backup_vault_cli.e
|   +-- backup_engine.e
|   +-- restore_engine.e
|   +-- deduplication_engine.e
|   +-- encryption_engine.e
|   +-- chunk_store.e
|   +-- backup_catalog.e
|   +-- file_scanner.e
|   +-- manifest.e
|   +-- retention_policy.e
|   +-- backup_stats.e
|   +-- cli/
|       +-- cli_commands.e
+-- testing/
|   +-- test_app.e
|   +-- lib_tests.e
|   +-- test_deduplication.e
|   +-- test_encryption.e
|   +-- test_backup_restore.e
|   +-- test_retention.e
+-- examples/
|   +-- basic-config.yaml
|   +-- server-backup.yaml
|   +-- scripts/
|   |   +-- daily-backup.bat
|   |   +-- daily-backup.sh
|   +-- scheduled/
|       +-- windows-task.xml
|       +-- cron.d-backup
+-- docs/
    +-- index.html
    +-- security.md
    +-- configuration.md
    +-- automation.md
```

---

## Automation Examples

### Windows Task Scheduler

```xml
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <Triggers>
    <CalendarTrigger>
      <StartBoundary>2026-01-01T02:00:00</StartBoundary>
      <ScheduleByDay><DaysInterval>1</DaysInterval></ScheduleByDay>
    </CalendarTrigger>
  </Triggers>
  <Actions>
    <Exec>
      <Command>backup-vault.exe</Command>
      <Arguments>backup C:\Users --vault D:\Backups\vault --config C:\backup-config.yaml</Arguments>
    </Exec>
  </Actions>
</Task>
```

### Linux Cron

```bash
# /etc/cron.d/backup-vault
# Daily backup at 2 AM
0 2 * * * root /usr/local/bin/backup-vault backup /home --vault /backup/vault --config /etc/backup-vault.yaml >> /var/log/backup-vault.log 2>&1
# Weekly prune
0 3 * * 0 root /usr/local/bin/backup-vault prune --vault /backup/vault
```

### PowerShell Script

```powershell
# daily-backup.ps1
$ErrorActionPreference = "Stop"

$vault = "D:\Backups\vault"
$source = "C:\Users"
$password = Get-Content "C:\secure\backup-password.txt"

backup-vault backup $source --vault $vault --password-file "C:\secure\backup-password.txt" --verify

if ($LASTEXITCODE -ne 0) {
    Send-MailMessage -To "admin@company.com" -Subject "Backup Failed" -Body "Backup failed with exit code $LASTEXITCODE"
    exit 1
}
```
