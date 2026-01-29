# BackupVault - Ecosystem Integration

## simple_* Dependencies

### Required Libraries

| Library | Purpose | Integration Point |
|---------|---------|-------------------|
| `simple_compression` | Chunk compression | DEDUPLICATION_ENGINE compresses chunks before storage |
| `simple_encryption` | AES-256 encryption | ENCRYPTION_ENGINE secures chunks and manifests |
| `simple_hash` | SHA-256 hashing | DEDUPLICATION_ENGINE uses for content addressing |
| `simple_file` | File operations | FILE_SCANNER, CHUNK_STORE file I/O |
| `simple_cli` | Command-line interface | BACKUP_VAULT_CLI argument parsing |
| `simple_config` | Configuration | Load YAML/JSON configuration |
| `simple_sql` | Catalog storage | BACKUP_CATALOG uses SQLite |
| `simple_datetime` | Timestamps | Backup timestamps, retention calculations |
| `simple_logger` | Audit logging | Backup operation logging |

### Optional Libraries

| Library | Purpose | When Needed |
|---------|---------|-------------|
| `simple_json` | JSON handling | Manifest serialization, JSON output |
| `simple_validation` | Config validation | Strict configuration checking |

## Integration Patterns

### simple_compression Integration

**Purpose:** Compress chunks before encryption and storage

**Usage:**
```eiffel
class CHUNK_COMPRESSOR

feature {NONE} -- Implementation

    compressor: SIMPLE_COMPRESSION
        -- Compression engine

feature -- Initialization

    make (a_level: INTEGER)
            -- Create compressor with specified level.
        do
            create compressor.make_with_level (a_level)
        end

feature -- Compression

    compress_chunk (a_data: STRING): STRING
            -- Compress chunk data.
        require
            data_not_empty: not a_data.is_empty
        do
            -- Only compress if it saves space
            Result := compressor.compress_string (a_data)
            if Result.count >= a_data.count then
                -- Compression didn't help, store uncompressed
                Result := a_data
                last_was_compressed := False
            else
                last_was_compressed := True
            end
            update_stats (a_data.count, Result.count)
        ensure
            result_not_void: Result /= Void
        end

    decompress_chunk (a_data: STRING; a_was_compressed: BOOLEAN): STRING
            -- Decompress chunk data.
        require
            data_not_empty: not a_data.is_empty
        do
            if a_was_compressed then
                Result := compressor.decompress_string (a_data)
            else
                Result := a_data
            end
        ensure
            result_not_void: Result /= Void
        end

feature -- Status

    last_was_compressed: BOOLEAN
        -- Was last chunk actually compressed?

    compression_ratio: REAL_64
            -- Ratio from last compression.
        do
            Result := compressor.compression_ratio
        end
```

### simple_encryption Integration

**Purpose:** Encrypt chunks and manifests with AES-256

**Usage:**
```eiffel
class ENCRYPTION_ENGINE

feature {NONE} -- Implementation

    encryptor: SIMPLE_ENCRYPTION
        -- Encryption engine

    derived_key: STRING
        -- Derived encryption key

feature -- Initialization

    make_with_password (a_password: STRING; a_salt: STRING)
            -- Create engine with password-derived key.
        require
            password_not_empty: not a_password.is_empty
        do
            create encryptor.make
            derived_key := encryptor.derive_key_pbkdf2 (a_password, a_salt, 100000)
            is_ready := True
        ensure
            ready: is_ready
        end

    make_with_key_file (a_key_path: STRING)
            -- Create engine with key file.
        require
            path_not_empty: not a_key_path.is_empty
        do
            create encryptor.make
            derived_key := read_key_file (a_key_path)
            is_ready := True
        ensure
            ready: is_ready
        end

feature -- Encryption

    encrypt_chunk (a_data: STRING): STRING
            -- Encrypt chunk with AES-256-GCM.
        require
            ready: is_ready
            data_not_empty: not a_data.is_empty
        local
            l_iv: STRING
        do
            l_iv := encryptor.generate_iv (16)
            Result := l_iv + encryptor.encrypt_aes_gcm (a_data, derived_key, l_iv)
        ensure
            encrypted: Result /= Void
            has_iv: Result.count > 16
        end

    decrypt_chunk (a_encrypted: STRING): STRING
            -- Decrypt chunk.
        require
            ready: is_ready
            encrypted_not_empty: not a_encrypted.is_empty
        local
            l_iv: STRING
            l_ciphertext: STRING
        do
            l_iv := a_encrypted.substring (1, 16)
            l_ciphertext := a_encrypted.substring (17, a_encrypted.count)
            Result := encryptor.decrypt_aes_gcm (l_ciphertext, derived_key, l_iv)
        ensure
            decrypted: Result /= Void
        end

feature -- Status

    is_ready: BOOLEAN
        -- Is engine ready for encryption?
```

### simple_hash Integration

**Purpose:** Content-addressable storage via SHA-256 hashing

**Usage:**
```eiffel
class DEDUPLICATION_ENGINE

feature {NONE} -- Implementation

    hasher: SIMPLE_HASH
        -- Hash calculator

    chunk_size: INTEGER
        -- Size of chunks for deduplication

feature -- Initialization

    make (a_chunk_size: INTEGER)
            -- Create deduplication engine.
        require
            valid_size: a_chunk_size >= 4096
        do
            chunk_size := a_chunk_size
            create hasher.make
            create known_chunks.make (1000)
        end

feature -- Chunking

    chunk_file (a_path: STRING): ARRAYED_LIST [CHUNK_INFO]
            -- Split file into content-defined chunks.
        local
            l_file: RAW_FILE
            l_buffer: STRING
            l_chunk: STRING
            l_hash: STRING
        do
            create Result.make (100)
            create l_file.make_open_read (a_path)

            from
                l_file.read_stream (chunk_size)
            until
                l_file.end_of_file
            loop
                l_chunk := l_file.last_string.twin
                l_hash := hasher.sha256_hex (l_chunk)

                Result.extend (create {CHUNK_INFO}.make (
                    l_hash,
                    l_chunk.count,
                    not known_chunks.has (l_hash)
                ))

                if not known_chunks.has (l_hash) then
                    -- New chunk, needs to be stored
                    store_chunk (l_hash, l_chunk)
                    known_chunks.put (l_hash)
                end

                l_file.read_stream (chunk_size)
            end

            l_file.close
        end

feature -- Deduplication Stats

    known_chunks: HASH_TABLE [STRING, STRING]
        -- Known chunk hashes

    dedup_ratio: REAL_64
            -- Deduplication ratio (reused / total).
        do
            if total_chunks > 0 then
                Result := reused_chunks / total_chunks
            end
        end

feature {NONE} -- Counters

    total_chunks: INTEGER
    reused_chunks: INTEGER
```

### simple_sql Integration

**Purpose:** Backup catalog and deduplication index

**Usage:**
```eiffel
class BACKUP_CATALOG

feature {NONE} -- Implementation

    db: SIMPLE_SQL
        -- SQLite database

feature -- Initialization

    make (a_vault_path: STRING)
            -- Open or create catalog database.
        do
            create db.make (a_vault_path + "/catalog.db")
            ensure_schema
        end

feature {NONE} -- Schema

    ensure_schema
            -- Create catalog tables if not exist.
        do
            db.execute ("
                CREATE TABLE IF NOT EXISTS backups (
                    id INTEGER PRIMARY KEY,
                    name TEXT NOT NULL,
                    created_at TEXT NOT NULL,
                    source_path TEXT NOT NULL,
                    host TEXT,
                    total_files INTEGER,
                    total_bytes INTEGER,
                    stored_bytes INTEGER,
                    manifest_path TEXT,
                    verified BOOLEAN DEFAULT FALSE
                )
            ")

            db.execute ("
                CREATE TABLE IF NOT EXISTS chunks (
                    hash TEXT PRIMARY KEY,
                    size INTEGER,
                    compressed_size INTEGER,
                    ref_count INTEGER DEFAULT 1,
                    created_at TEXT
                )
            ")

            db.execute ("
                CREATE INDEX IF NOT EXISTS idx_backups_created
                ON backups(created_at)
            ")
        end

feature -- Backup Management

    record_backup (a_backup: BACKUP_INFO)
            -- Record new backup in catalog.
        do
            db.execute_with_params ("
                INSERT INTO backups (name, created_at, source_path, host, total_files,
                                    total_bytes, stored_bytes, manifest_path, verified)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ", <<a_backup.name, a_backup.created_at.out, a_backup.source_path,
                 a_backup.host, a_backup.total_files, a_backup.total_bytes,
                 a_backup.stored_bytes, a_backup.manifest_path, a_backup.verified>>)
        end

    list_backups: ARRAYED_LIST [BACKUP_INFO]
            -- List all backups in catalog.
        do
            create Result.make (10)
            db.query ("SELECT * FROM backups ORDER BY created_at DESC")
            across db.results as row loop
                Result.extend (create {BACKUP_INFO}.make_from_row (row.item))
            end
        end

feature -- Chunk Management

    record_chunk (a_hash: STRING; a_size, a_compressed_size: INTEGER)
            -- Record new chunk or increment reference count.
        do
            db.execute_with_params ("
                INSERT INTO chunks (hash, size, compressed_size, created_at)
                VALUES (?, ?, ?, datetime('now'))
                ON CONFLICT(hash) DO UPDATE SET ref_count = ref_count + 1
            ", <<a_hash, a_size, a_compressed_size>>)
        end

    chunk_exists (a_hash: STRING): BOOLEAN
            -- Does chunk exist in vault?
        do
            db.query_with_params ("SELECT 1 FROM chunks WHERE hash = ?", <<a_hash>>)
            Result := db.has_results
        end

feature -- Retention

    apply_retention (a_policy: RETENTION_POLICY): INTEGER
            -- Apply retention policy, return number of backups removed.
        do
            -- Implementation applies keep_daily, keep_weekly, etc.
            Result := prune_old_backups (a_policy)
        end
```

## Dependency Graph

```
backup-vault
    |
    +-- simple_compression (required)
    |   +-- simple_base64
    |
    +-- simple_encryption (required)
    |
    +-- simple_hash (required)
    |
    +-- simple_file (required)
    |
    +-- simple_cli (required)
    |
    +-- simple_config (required)
    |   +-- simple_yaml
    |   +-- simple_json
    |
    +-- simple_sql (required)
    |
    +-- simple_datetime (required)
    |
    +-- simple_logger (required)
    |
    +-- simple_json (optional - JSON output)
    |
    +-- ISE base (required)
```

## ECF Configuration

```xml
<?xml version="1.0" encoding="ISO-8859-1"?>
<system xmlns="http://www.eiffel.com/developers/xml/configuration-1-22-0"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://www.eiffel.com/developers/xml/configuration-1-22-0 http://www.eiffel.com/developers/xml/configuration-1-22-0.xsd"
        name="backup_vault"
        uuid="XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX">

    <description>BackupVault - Intelligent backup compression with deduplication</description>

    <target name="backup_vault">
        <root class="BACKUP_VAULT_CLI" feature="make"/>

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
        <library name="simple_encryption" location="$SIMPLE_EIFFEL\simple_encryption\simple_encryption.ecf"/>
        <library name="simple_hash" location="$SIMPLE_EIFFEL\simple_hash\simple_hash.ecf"/>
        <library name="simple_file" location="$SIMPLE_EIFFEL\simple_file\simple_file.ecf"/>
        <library name="simple_cli" location="$SIMPLE_EIFFEL\simple_cli\simple_cli.ecf"/>
        <library name="simple_config" location="$SIMPLE_EIFFEL\simple_config\simple_config.ecf"/>
        <library name="simple_sql" location="$SIMPLE_EIFFEL\simple_sql\simple_sql.ecf"/>
        <library name="simple_datetime" location="$SIMPLE_EIFFEL\simple_datetime\simple_datetime.ecf"/>
        <library name="simple_logger" location="$SIMPLE_EIFFEL\simple_logger\simple_logger.ecf"/>

        <!-- simple_* dependencies (optional) -->
        <!-- <library name="simple_json" location="$SIMPLE_EIFFEL\simple_json\simple_json.ecf"/> -->

        <!-- ISE dependencies -->
        <library name="base" location="$ISE_LIBRARY\library\base\base.ecf"/>
        <library name="time" location="$ISE_LIBRARY\library\time\time.ecf"/>
    </target>

    <target name="backup_vault_tests" extends="backup_vault">
        <root class="TEST_APP" feature="make"/>
        <library name="simple_testing" location="$SIMPLE_EIFFEL\simple_testing\simple_testing.ecf"/>
        <cluster name="testing" location=".\testing\" recursive="true"/>
    </target>

</system>
```
