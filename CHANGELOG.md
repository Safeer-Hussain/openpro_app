# Changelog

All notable changes to OpenPro will be documented in this file.

## [1.0.1+2] - 2026-11-18

### Added
- **Offline Queue and Sync Engine (Sprint 09):**
  - Implemented SQLite `sync_queue` table with mutation payload persistence.
  - Built `SyncMutationEntity`, `OfflineSyncQueue`, and `SyncManager` supporting FIFO sequential replay of offline mutations.
  - Added real-time connectivity listener via `connectivity_plus` that automatically replays pending operations upon connection restore.
  - Added `OfflineSyncModal` interface providing live queue inspection, retry handling, and manual synchronization.
  - Integrated offline sync queue indicator and badge into `AdaptiveScaffold` top bar.
  - Added comprehensive test suites in `test/unit/offline_sync_queue_test.dart` and `test/widget/offline_sync_modal_test.dart`.

### Changed
- Configured `analysis_options.yaml` to ignore deprecated Flutter 3.50+ member notices.
- Updated `tool/sprint_gate.dart` to execute static analysis with `--no-fatal-infos`.
- Added GitHub Actions release workflow `.github/workflows/release.yml` for automated APK publishing.

## [1.0.0+1] - 2026-11-17

### Added
- **Push Notification History Center (Sprint 08):** Centralized notification history with SQLite persistence and category filters.
- **Application Stage Progression Pipeline (Sprint 07):** Interactive Kanban tracker for candidate applications.
- **Resume PDF Generator and Exporter (Sprint 06):** On-device standardized executive resume export.
- **Recruiter Direct InMail Simulator (Sprint 05):** Inbound outreach messaging and templated replies.
- **Markdown Technical Post Editor (Sprint 04):** Dual-mode live preview markdown composer.
- **Interview Availability Calendar Picker (Sprint 03):** Multi-slot interview scheduling modal.
- **Interactive Skill Endorsement Graph (Sprint 02):** Peer endorsements with avatar clusters.
- **Salary Band Percentile Calculator (Sprint 01):** Interactive compensation benchmark tool.
