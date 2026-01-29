# BackupVault - Technical Design

## Architecture

### Component Overview

```
+-------------------------------------------------------------+
|                        BackupVault                           |
+-------------------------------------------------------------+
|  CLI Interface Layer                                         |
|    - Argument parsing (simple_cli)                           |
|    - Command routing                                         |
|    - Progress display                                        |
|    - Output formatting                                       |
+-------------------------------------------------------------+
|  Backup Engine                                               |
|    - File discovery and filtering                            |
|    - Change detection (hash-based)                           |
|    - Deduplication logic                                     |
|    - Compression orchestration                               |
+-------------------------------------------------------------+
|  Security Layer                                              |
|    - Key derivation (PBKDF2)                                 |
|    - AES-256 encryption                                      |
|    - Secure key storage                                      |
+-------------------------------------------------------------+
|  Catalog Manager                                             |
|    - Backup history                                          |
|    - File manifests                                          |
|    - Deduplication index                                     |
+-------------------------------------------------------------+
|  Integration Layer                                           |
|    - simple_compression (compression)                        |
|    - simple_encryption (encryption)                          |
|    - simple_hash (deduplication)                             |
|    - simple_file (file operations)                           |
|    - simple_sql (catalog storage)                            |
+-------------------------------------------------------------+
```

### Class Design

| Class | Responsibility | Key Features |
|-------|----------------|--------------|
| `BACKUP_VAULT_CLI` | Command-line interface | parse_args, execute, show_progress |
| `BACKUP_ENGINE` | Core backup orchestration | backup, restore, verify, prune |
| `DEDUPLICATION_ENGINE` | Content-based deduplication | chunk, hash, dedupe |
| `ENCRYPTION_ENGINE` | Secure encryption | encrypt, decrypt, derive_key |
| `BACKUP_CATALOG` | Backup history and manifests | save, load, query |
| `FILE_SCANNER` | File discovery | scan, filter, detect_changes |
| `CHUNK_STORE` | Deduplicated chunk storage | store, retrieve, exists |
| `MANIFEST` | Backup file manifest | add_file, get_file, serialize |
| `BACKUP_STATS` | Statistics tracking | files, bytes, dedup_ratio |
| `RESTORE_ENGINE` | Restore operations | restore_full, restore_file, verify |

### Command Structure

```bash
backup-vault <command> [options] [arguments]

Commands:
  backup      Create a backup of files/directories
  restore     Restore files from backup
  verify      Verify backup integrity
  list        List backups and contents
  prune       Remove old backups per retention policy
  mount       Mount backup as virtual filesystem (future)
  config      Manage configuration
  key         Key management (generate, export, import)

Global Options:
  --config FILE       Configuration file
  --vault PATH        Vault storage location
  --password          Prompt for encryption password
  --password-file F   Read password from file
  --key-file FILE     Use key file for encryption
  --verbose           Verbose output
  --quiet             Suppress non-error output
  --json              Output in JSON format
  --help              Show help

Backup Options:
  --name NAME         Backup name/tag
  --exclude PATTERN   Exclude files matching pattern
  --include PATTERN   Include only files matching pattern
  --compression LEVEL Compression level (fast|default|best)
  --no-encryption     Skip encryption (not recommended)
  --verify            Verify after backup

Restore Options:
  --to PATH           Restore destination
  --point NAME        Restore from specific backup point
  --overwrite         Overwrite existing files
  --preserve          Preserve original permissions/timestamps

Examples:
  backup-vault backup /home/user/documents --vault /backup/vault
  backup-vault restore /home/user/documents --vault /backup/vault --to /restore
  backup-vault list --vault /backup/vault --json
  backup-vault verify --vault /backup/vault
  backup-vault prune --vault /backup/vault --keep-daily 7 --keep-weekly 4
```

### Data Flow

```
Source Files         Backup Engine              Vault Storage
+------------+      +------------------+        +----------------+
| Directory  |      | File Scanner     |        | chunks/        |
| Tree       | ---> | Change Detection | -----> |   ab/cdef...   |
|            |      | Chunking         |        |   12/3456...   |
+------------+      | Deduplication    |        | manifests/     |
                    | Compression      |        |   2026-01-24   |
                    | Encryption       |        | catalog.db     |
                    +------------------+        +----------------+
                           |
                           v
                    +--------------+
                    | Catalog DB   |
                    | (SQLite)     |
                    +--------------+
```

### Vault Structure

```
vault/
+-- config.json           # Vault configuration
+-- catalog.db            # SQLite backup catalog (encrypted)
+-- chunks/               # Deduplicated data chunks
|   +-- ab/              # First 2 chars of hash
|   |   +-- cdef1234...  # Compressed, encrypted chunk
|   |   +-- 5678abcd...
|   +-- 12/
|       +-- 3456fedc...
+-- manifests/            # Backup manifests
|   +-- 2026-01-24T10-30-00.manifest.enc
|   +-- 2026-01-23T10-30-00.manifest.enc
+-- keys/                 # Key files (if using key-based encryption)
    +-- master.key.enc    # Encrypted master key
```

### Chunk Format

```
+--------------------------------------------------+
| Chunk Header (32 bytes)                          |
|   - Magic: "BVCK"                                |
|   - Version: uint16                              |
|   - Flags: uint16 (compressed, encrypted)        |
|   - Original size: uint32                        |
|   - Compressed size: uint32                      |
|   - Hash: SHA-256 (32 bytes of remaining 16)     |
+--------------------------------------------------+
| Encrypted Payload                                |
|   - IV (16 bytes)                                |
|   - Compressed data (variable)                   |
|   - Auth tag (16 bytes, if AEAD)                 |
+--------------------------------------------------+
```

### Manifest Format (JSON, then encrypted)

```json
{
  "version": 1,
  "created": "2026-01-24T10:30:00Z",
  "name": "daily-backup",
  "source": "/home/user/documents",
  "host": "workstation-1",
  "stats": {
    "files": 1234,
    "directories": 56,
    "total_bytes": 1073741824,
    "stored_bytes": 268435456,
    "dedup_ratio": 0.75,
    "new_chunks": 45,
    "reused_chunks": 678
  },
  "files": [
    {
      "path": "project/README.md",
      "size": 4096,
      "modified": "2026-01-20T15:30:00Z",
      "mode": 0644,
      "chunks": ["ab/cdef1234...", "12/3456fedc..."]
    }
  ]
}
```

### Configuration Schema

```yaml
# backup-vault.yaml
version: "1.0"

vault:
  path: /backup/vault

encryption:
  enabled: true
  algorithm: aes-256-gcm
  key_derivation: pbkdf2
  iterations: 100000

compression:
  level: default  # fast|default|best
  min_size: 64    # Don't compress chunks smaller than 64 bytes

deduplication:
  enabled: true
  chunk_size: 64KB
  algorithm: sha256

retention:
  keep_daily: 7
  keep_weekly: 4
  keep_monthly: 12
  keep_yearly: 5

exclude:
  - "*.tmp"
  - "*.log"
  - ".git/"
  - "node_modules/"
  - "__pycache__/"

notifications:
  on_success: false
  on_failure: true
  email: admin@example.com
```

### Error Handling

| Error Type | Handling | User Message |
|------------|----------|--------------|
| Vault not found | Fail with init suggestion | "Vault not found at {path}. Run 'backup-vault init' first." |
| Invalid password | Fail with retry option | "Invalid password. Decryption failed." |
| Source not found | Skip with warning | "Source not found: {path}. Skipping." |
| Disk full | Fail with space info | "Insufficient space. Need {needed}, have {available}." |
| Corrupt chunk | Fail with recovery info | "Chunk corrupted: {hash}. Backup may be incomplete." |
| Verification failure | Fail with details | "Verification failed for {file}. Expected {hash}, got {actual}." |
| Permission denied | Skip or fail (configurable) | "Cannot read {path}: Permission denied." |

## GUI/TUI Future Path

**CLI foundation enables:**

1. **Backup Browser (TUI)**
   - ncurses-based vault browser
   - Navigate backup history
   - Select files for restore
   - Real-time backup progress

2. **Backup Manager (GUI)**
   - Schedule configuration
   - Storage analytics
   - Multi-vault management
   - Built on same BACKUP_ENGINE

3. **Shared Components**
   - `BACKUP_ENGINE` - Same engine for all interfaces
   - `RESTORE_ENGINE` - Same restore for CLI/TUI/GUI
   - `BACKUP_CATALOG` - Same catalog format
   - Encryption and deduplication shared

4. **Migration Path**
   - CLI users can transition to GUI without re-configuring vaults
   - Same vault format across all interfaces
   - Backups created in GUI restorable via CLI
