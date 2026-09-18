"""Command-line utilities for the inventory database."""

from __future__ import annotations

from pathlib import Path
import shutil
import subprocess
from typing import Iterable


def run_sql_file(conn_str: str, sql_file: str) -> None:
    """Execute a SQL file using ``psql`` and fail on the first SQL error.

    Args:
        conn_str: Database connection string understood by ``psql``.
        sql_file: Path to the SQL file to execute.

    Raises:
        RuntimeError: If ``psql`` is not available or execution fails.
    """

    if shutil.which("psql") is None:
        raise RuntimeError("psql executable not found in PATH")

    command = [
        "psql",
        conn_str,
        "-v",
        "ON_ERROR_STOP=1",
        "-f",
        sql_file,
    ]

    try:
        subprocess.run(command, check=True)
    except subprocess.CalledProcessError as exc:
        msg = f"Failed to execute {sql_file}: {exc}"
        raise RuntimeError(msg) from exc


def run_migrations(
    conn_str: str, directory: str = "db/migrations", to: str | None = None
) -> None:
    """Run migration scripts in order.

    Args:
        conn_str: Connection string for the target database.
        directory: Directory containing migration ``.sql`` files.
        to: Optional filename of the last migration to run.

    Raises:
        RuntimeError: If a migration fails.
    """

    paths = sorted(Path(directory).glob("*.sql"))
    if to:
        paths = [p for p in paths if p.name <= to]

    for path in paths:
        run_sql_file(conn_str, str(path))


def run_seeds(
    conn_str: str, directory: str = "db/seeds", to: str | None = None
) -> None:
    """Execute seed scripts to populate reference data.

    Args:
        conn_str: Database connection string.
        directory: Directory containing seed ``.sql`` files.
        to: Optional filename of the last seed to run.

    Raises:
        RuntimeError: If a seed script fails.
    """

    paths = sorted(Path(directory).glob("*.sql"))
    if to:
        paths = [p for p in paths if p.name <= to]

    for path in paths:
        run_sql_file(conn_str, str(path))


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

    sub.add_parser("all", help="Run migrations and seeds (default)")

    parsed = parser.parse_args(list(args) if args is not None else None)

    cmd = parsed.cmd or "all"
    if cmd == "migrate":
        run_migrations(parsed.conn, to=getattr(parsed, "to", None))
    elif cmd == "seed":
        run_seeds(parsed.conn, to=getattr(parsed, "to", None))
    else:
        run_migrations(parsed.conn)
        run_seeds(parsed.conn)


if __name__ == "__main__":
    main()
