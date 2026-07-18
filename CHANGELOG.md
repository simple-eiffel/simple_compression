# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `crc32` and `adler32` now bind zlib's native C functions (cross-platform via the
  ISE zlib dependency) instead of pure-Eiffel loops — resolving the Eiffel Users
  request for a zlib-backed CRC-32/ISO-HDLC checksum.
- Pure-Eiffel `crc32_native` / `adler32_native` retained as portable reference
  implementations and as the DbC oracle: `crc32`/`adler32` carry an
  `agrees_with_reference` postcondition asserting the zlib result equals the
  independent reference on every call in a contracted build (differential verification).
- Adversarial checksum tests: zlib-vs-reference agreement across all lengths 0–512,
  all 256 byte values, embedded nulls, and a 1 MB block; plus published CRC-32 and
  Adler-32 known-answer vectors. SCOOP consumer integration gate.

### Changed
- Post-session update 2025-12-08 20:52
- Remove EIFGENs from git tracking
- Post-session update 2025-12-08 20:45
- Post-session update 2025-12-08 20:16
- Add Phase 2 & 3 enhancements: streaming, advanced options, fluent builders, interceptors, cookies
- first commit

## [1.0.0] - 2025-12-08

### Added
- Initial release
- Core functionality implemented
- Test suite with comprehensive coverage
- Documentation and examples

[Unreleased]: https://github.com/simple-eiffel/simple_compression/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/simple-eiffel/simple_compression/releases/tag/v1.0.0
