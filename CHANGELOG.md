# Changelog

All notable changes to this project will be documented in this file.

## [1.1.0] - 2025-12-23
### Changed
- Added log buffer caps and payload truncation to prevent freezes/crashes with very large responses.
- Safer UI rendering with truncated previews for oversized payloads.
- Compact logging to reduce memory and CPU usage while preserving copy/export.

## [1.0.0] - 2024-01-XX

### Added
- Initial release
- Network request/response logging with Dio interceptor
- Beautiful UI screen for viewing logs
- Search and filter functionality
- Statistics dashboard (total, requests, responses, errors)
- JSON tree viewer with expandable/collapsible nodes
- FormData viewer
- Copy to clipboard functionality
- Color-coded logs
- FloatingActionButton helper widget

