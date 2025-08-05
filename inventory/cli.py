"""Command-line utilities for the inventory database."""

from __future__ import annotations

import os
import shutil
import subprocess
import tempfile
from pathlib import Path
from typing import Iterable


def run_sql_file(conn_str: str, sql_file: str | Path) -> None:
    """Execute a SQL file using ``psql``.

    Parameters
    ----------
    conn_str:
        Database connection string understood by ``psql``.
    sql_file:
        Path to the SQL file to execute.

    Raises
    ------
    RuntimeError
        If ``psql`` is not available or execution fails.
    """

    if shutil.which("psql") is None:
        raise RuntimeError("psql executable not found in PATH")

    try:
        subprocess.run(["psql", conn_str, "-f", str(sql_file)], check=True)
    except subprocess.CalledProcessError as exc:  # pragma: no cover - defensive
        msg = f"Failed to execute {sql_file}: {exc}"
        raise RuntimeError(msg) from exc


def run_migrations(
    conn_str: str, directory: str | Path = "db/migrations", to: str | None = None
) -> None:
    """Run migration scripts in order.

    Parameters
    ----------
    conn_str:
        Connection string for the target database.
    directory:
        Directory containing migration ``.sql`` files.
    to:
        Optional filename of the last migration to run.

    Raises
    ------
    RuntimeError
        If a migration fails.
    """

    paths: list[Path] = sorted(Path(directory).glob("*.sql"))
    if to:
        paths = [p for p in paths if p.name <= to]

    for path in paths:
        run_sql_file(conn_str, path)


def run_seeds(
    conn_str: str, directory: str | Path = "db/seeds", to: str | None = None
) -> None:
    """Execute seed scripts to populate reference data.

    Parameters
    ----------
    conn_str:
        Database connection string.
    directory:
        Directory containing seed ``.sql`` files.
    to:
        Optional filename of the last seed to run.

    Raises
    ------
    RuntimeError
        If a seed script fails.
    """

    paths: list[Path] = sorted(Path(directory).glob("*.sql"))
    if to:
        paths = [p for p in paths if p.name <= to]

    for path in paths:
        run_sql_file(conn_str, path)


def run_rollbacks(
    conn_str: str, directory: str | Path = "db/migrations", to: str | None = None
) -> None:
    """Execute migration rollbacks in reverse order.

    This parses the commented ``Down`` sections at the end of each migration
    script and runs them using ``psql``. Migrations are processed from newest to
    oldest and stop once ``to`` is reached.

    Parameters
    ----------
    conn_str:
        Database connection string.
    directory:
        Directory containing migration ``.sql`` files.
    to:
        Optional filename of the last rollback to execute (inclusive).
    """

    paths: list[Path] = sorted(Path(directory).glob("*.sql"), reverse=True)
    for path in paths:
        down_lines: list[str] = []
        capture: bool = False
        for line in path.read_text().splitlines():
            stripped = line.lstrip()
            if stripped.lower().startswith("-- down"):
                capture = True
                continue
            if capture and stripped.startswith("--"):
                down_lines.append(stripped[2:].lstrip())
        if down_lines:
            with tempfile.NamedTemporaryFile("w", delete=False) as tmp:
                tmp.write("\n".join(down_lines))
                tmp_path: str = tmp.name

            try:
                run_sql_file(conn_str, tmp_path)
            finally:
                os.unlink(tmp_path)

        if to and path.name == to:
            break


def main(args: Iterable[str] | None = None) -> None:
    """Entry point for the ``inventory-cli`` console script.

    The CLI provides subcommands to run migrations and seed scripts. It
    gracefully handles missing ``psql`` or failed scripts and allows running up
    to a specific file if desired.

    Args:
        args: Optional command-line arguments for testing purposes.
    """

    from argparse import ArgumentParser

    parser = ArgumentParser(description="Manage inventory database")
    parser.add_argument("conn", help="Database connection string for psql")

    sub = parser.add_subparsers(dest="cmd", required=False)

    mig = sub.add_parser("migrate", help="Run database migrations")
    mig.add_argument("--to", help="Run migrations up to this file (inclusive)")

    seed = sub.add_parser("seed", help="Run seed scripts")
    seed.add_argument("--to", help="Run seeds up to this file (inclusive)")

    roll = sub.add_parser("rollback", help="Run migration rollbacks")
    roll.add_argument("--to", help="Rollback down to this file (inclusive)")

    sub.add_parser("all", help="Run migrations and seeds (default)")

    parsed = parser.parse_args(list(args) if args is not None else None)

    cmd = parsed.cmd or "all"
    if cmd == "migrate":
        run_migrations(parsed.conn, to=getattr(parsed, "to", None))
    elif cmd == "seed":
        run_seeds(parsed.conn, to=getattr(parsed, "to", None))
    elif cmd == "rollback":
        run_rollbacks(parsed.conn, to=getattr(parsed, "to", None))
    else:
        run_migrations(parsed.conn)
        run_seeds(parsed.conn)


if __name__ == "__main__":
    main()
