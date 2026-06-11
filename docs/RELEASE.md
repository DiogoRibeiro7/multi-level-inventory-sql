# Release Guide

This repository uses a lightweight semantic-versioning workflow.

## Versioning Policy

- Tags use the format `vMAJOR.MINOR.PATCH`.
- `MAJOR` changes only for incompatible schema or workflow changes.
- `MINOR` changes for new features, migrations, views, functions, tests, and
  operational tooling.
- `PATCH` changes for backward-compatible fixes and documentation-only updates
  that should be tracked in a release.

## Current Release State

- Latest documented release: `0.3.0`
- Current development target: `0.4.0`
- Current package metadata version: `0.4.0`

The `Unreleased` section in `CHANGELOG.md` is the source of truth for work
that will ship in the next tag.

## Release Checklist

1. Confirm the working tree is clean and CI is green.
2. Review `CHANGELOG.md` and move completed `Unreleased` entries into a new
   versioned section with the release date.
3. Verify `pyproject.toml` matches the version being released.
4. Run the project validation path:
   `pytest -q` and the PostgreSQL integration/pgTAP suite.
5. Create an annotated tag such as:
   `git tag -a v0.4.0 -m "Release v0.4.0"`
6. Push the branch and tags:
   `git push && git push --tags`

## After a Release

After tagging a release:

1. Create a fresh `Unreleased` section if needed.
2. Bump `pyproject.toml` to the next intended development version when the next
   milestone starts.
3. Record any post-release fixes in `CHANGELOG.md` under `Unreleased`.
