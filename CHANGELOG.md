# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]
### Added
- Typed BOM relationships so finished products and intermediaries can reference lower-level components
- Recursive `bom_explosion` output across intermediary and raw-material levels
- Reporting indexes for stock transaction date and product lookups

### Fixed
- Deploy `create_production_run` through the migration path used by the CLI
- Reject stock transactions that reference missing products
- Validate production runs require a positive quantity and a valid BOM

## [0.3.0] - 2025-07-06
### Added
- Docker Compose configuration for integration testing
- pgTAP test validating `bom_explosion`

## [0.2.0] - 2025-07-05
### Added
- Recursive `bom_explosion` function
- Backup and restore scripts
- Entity relationship diagram documentation

### Changed
- Roadmap marked with completed items

## [0.1.0] - 2025-07-04
### Added
- Initial schema migrations
- Seed data and production run procedure
- Poetry-based CLI and CI workflow
