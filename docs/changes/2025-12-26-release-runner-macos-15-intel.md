# Change Log Entry

## Version
- N/A (CI config change)

## Date
- 2025-12-26

## Summary
- Fix GitHub Actions release workflow: migrate x86_64 build runner from retired `macos-13` to supported `macos-15-intel`.

## Approved By
- Human: 批准实现 (2025-12-26)

## Notes
- Scope: `.github/workflows/release.yml` only.
- Rationale: GitHub Actions has retired macOS 13 runner images, causing the x86_64 release build job to fail before execution.
- Rollback: switch the runner label back to a supported Intel runner if GitHub changes labels again (e.g. `macos-15-intel` -> another supported Intel label).
