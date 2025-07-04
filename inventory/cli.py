"""Command-line utilities for the inventory database."""
from pathlib import Path
import subprocess
from typing import Iterable


def run_sql_file(conn_str: str, sql_file: str) -> None:
    """Execute a SQL file using psql.

    Args:
        conn_str: Database connection string understood by ``psql``.
        sql_file: Path to the SQL file to execute.

    Raises:
        subprocess.CalledProcessError: If ``psql`` exits with an error.
    """
    # Execute the SQL file with psql and raise if it fails
    subprocess.run(["psql", conn_str, "-f", sql_file], check=True)


def run_migrations(conn_str: str, directory: str = "db/migrations") -> None:
    """Run all migration scripts in order.

    Args:
        conn_str: Connection string for the target database.
        directory: Directory containing migration ``.sql`` files.

    Raises:
        subprocess.CalledProcessError: If a migration fails.
    """
    # Iterate over migration files alphabetically for deterministic execution
    paths = sorted(Path(directory).glob("*.sql"))
    for path in paths:
        run_sql_file(conn_str, str(path))


def run_seeds(conn_str: str, directory: str = "db/seeds") -> None:
    """Execute seed scripts to populate reference data.

    Args:
        conn_str: Database connection string.
        directory: Directory containing seed ``.sql`` files.

    Raises:
        subprocess.CalledProcessError: If a seed script fails.
    """
    # Similar to migrations, run seed files alphabetically
    paths = sorted(Path(directory).glob("*.sql"))
    for path in paths:
        run_sql_file(conn_str, str(path))


def main(args: Iterable[str] | None = None) -> None:
    """Entry point for the ``inventory-cli`` console script.

    This simple CLI assumes ``psql`` is installed and available in ``PATH``.
    It runs migrations and seeds against the database provided via connection
    string.

    Args:
        args: Optional iterable of command-line arguments. Only the first
            positional argument is interpreted as the connection string.
    """
    from argparse import ArgumentParser

    parser = ArgumentParser(description="Manage inventory database")
    parser.add_argument("conn", help="Database connection string for psql")
    parsed = parser.parse_args(list(args) if args is not None else None)

    # Run migrations and then seeds in sequence
    run_migrations(parsed.conn)
    run_seeds(parsed.conn)


if __name__ == "__main__":
    main()
