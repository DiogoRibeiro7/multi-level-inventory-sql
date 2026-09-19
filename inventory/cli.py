"""Command-line utilities for the inventory database."""

from __future__ import annotations

from hashlib import sha256
from pathlib import Path
import shutil
import subprocess
from typing import Iterable, Literal, Mapping, TypeAlias

ScriptKind: TypeAlias = Literal["migration", "seed"]

_HISTORY_TABLE = "inventory_script_history"
_VALID_SCRIPT_KINDS: frozenset[str] = frozenset({"migration", "seed"})


def _require_psql() -> None:
    """Raise if the PostgreSQL client is unavailable."""

    if shutil.which("psql") is None:
        raise RuntimeError("psql executable not found in PATH")


def _run_psql(
    conn_str: str,
    sql: str,
    *,
    variables: Mapping[str, str] | None = None,
) -> str:
    """Execute SQL with psql and return stripped stdout.

    Args:
        conn_str: Database connection string understood by psql.
        sql: SQL statement to execute.
        variables: Optional psql variables exposed through -v.

    Returns:
        Standard output emitted by psql with surrounding whitespace removed.

    Raises:
        RuntimeError: If psql is unavailable or the command fails.
    """

    _require_psql()

    command = [
        "psql",
        conn_str,
        "-X",
        "-q",
        "-t",
        "-A",
        "-v",
        "ON_ERROR_STOP=1",
    ]

    for name, value in (variables or {}).items():
        command.extend(["-v", f"{name}={value}"])

    command.extend(["-f", "-"])

    try:
        result = subprocess.run(
            command,
            check=True,
            capture_output=True,
            text=True,
            input=sql,
        )
    except subprocess.CalledProcessError as exc:
        msg = f"Failed to execute PostgreSQL command: {exc}"
        raise RuntimeError(msg) from exc

    return result.stdout.strip()


def run_sql_file(conn_str: str, sql_file: str) -> None:
    """Execute a SQL file using psql and fail on the first SQL error.

    The -X flag prevents a user-level .psqlrc from changing migration behavior.

    Args:
        conn_str: Database connection string understood by psql.
        sql_file: Path to the SQL file to execute.

    Raises:
        RuntimeError: If psql is not available or execution fails.
    """

    _require_psql()

    command = [
        "psql",
        conn_str,
        "-X",
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


def _ensure_history_table(conn_str: str) -> None:
    """Create the internal migration ledger if it does not yet exist."""

    sql = f"""
    CREATE TABLE IF NOT EXISTS {_HISTORY_TABLE} (
        script_type TEXT NOT NULL
            CHECK (script_type IN ('migration', 'seed')),
        script_name TEXT NOT NULL,
        checksum TEXT NOT NULL,
        applied_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
        PRIMARY KEY (script_type, script_name)
    );
    """
    _run_psql(conn_str, sql)


def _validate_script_kind(script_kind: ScriptKind) -> None:
    """Validate an internal script kind before using it in SQL."""

    if script_kind not in _VALID_SCRIPT_KINDS:
        raise ValueError(f"Unsupported script kind: {script_kind}")


def _load_script_history(
    conn_str: str,
    script_kind: ScriptKind,
) -> dict[str, str]:
    """Return applied script names mapped to their recorded checksums."""

    _validate_script_kind(script_kind)

    output = _run_psql(
        conn_str,
        f"""
        SELECT script_name || E'\\t' || checksum
        FROM {_HISTORY_TABLE}
        WHERE script_type = :'script_type'
        ORDER BY script_name;
        """,
        variables={"script_type": script_kind},
    )

    history: dict[str, str] = {}
    for line in output.splitlines():
        if not line:
            continue
        name, checksum = line.split("\t", maxsplit=1)
        history[name] = checksum

    return history


def _record_script(
    conn_str: str,
    script_kind: ScriptKind,
    script_name: str,
    checksum: str,
) -> None:
    """Record a successfully applied or explicitly baselined SQL script."""

    _validate_script_kind(script_kind)

    _run_psql(
        conn_str,
        f"""
        INSERT INTO {_HISTORY_TABLE} (
            script_type,
            script_name,
            checksum
        )
        VALUES (
            :'script_type',
            :'script_name',
            :'checksum'
        );
        """,
        variables={
            "script_type": script_kind,
            "script_name": script_name,
            "checksum": checksum,
        },
    )


def _script_checksum(path: Path) -> str:
    """Return the SHA-256 checksum of one SQL script."""

    return sha256(path.read_bytes()).hexdigest()


def _script_paths(directory: str, to: str | None = None) -> list[Path]:
    """Return SQL scripts in deterministic filename order."""

    paths = sorted(Path(directory).glob("*.sql"))
    if to is not None:
        paths = [path for path in paths if path.name <= to]
    return paths


def _run_tracked_scripts(
    conn_str: str,
    directory: str,
    script_kind: ScriptKind,
    to: str | None = None,
) -> None:
    """Apply pending SQL scripts and persist their checksums."""

    _ensure_history_table(conn_str)
    history = _load_script_history(conn_str, script_kind)

    for path in _script_paths(directory, to):
        checksum = _script_checksum(path)
        recorded_checksum = history.get(path.name)

        if recorded_checksum is not None:
            if recorded_checksum != checksum:
                raise RuntimeError(
                    f"Applied {script_kind} checksum mismatch for {path.name}"
                )
            continue

        run_sql_file(conn_str, str(path))
        _record_script(conn_str, script_kind, path.name, checksum)


def run_migrations(
    conn_str: str,
    directory: str = "db/migrations",
    to: str | None = None,
) -> None:
    """Apply pending migration scripts in filename order.

    Already-applied migrations are skipped. If the contents of an applied
    migration change, execution stops with a checksum mismatch.

    Args:
        conn_str: Connection string for the target database.
        directory: Directory containing migration .sql files.
        to: Optional filename of the last migration to consider.
    """

    _run_tracked_scripts(conn_str, directory, "migration", to)


def run_seeds(
    conn_str: str,
    directory: str = "db/seeds",
    to: str | None = None,
) -> None:
    """Apply pending seed scripts in filename order.

    Args:
        conn_str: Database connection string.
        directory: Directory containing seed .sql files.
        to: Optional filename of the last seed to consider.
    """

    _run_tracked_scripts(conn_str, directory, "seed", to)


def _baseline_scripts(
    conn_str: str,
    directory: str,
    script_kind: ScriptKind,
) -> None:
    """Record existing scripts without executing them."""

    _ensure_history_table(conn_str)
    history = _load_script_history(conn_str, script_kind)

    for path in _script_paths(directory):
        checksum = _script_checksum(path)
        recorded_checksum = history.get(path.name)

        if recorded_checksum is not None:
            if recorded_checksum != checksum:
                raise RuntimeError(
                    f"Applied {script_kind} checksum mismatch for {path.name}"
                )
            continue

        _record_script(conn_str, script_kind, path.name, checksum)


def baseline_database(
    conn_str: str,
    migration_directory: str = "db/migrations",
    seed_directory: str = "db/seeds",
) -> None:
    """Record the current migrations and seeds without executing them.

    Use this only when adopting migration tracking for a database that was
    already initialized by an earlier version of this project.

    Args:
        conn_str: Connection string for the existing target database.
        migration_directory: Directory containing migration scripts.
        seed_directory: Directory containing seed scripts.
    """

    _baseline_scripts(conn_str, migration_directory, "migration")
    _baseline_scripts(conn_str, seed_directory, "seed")


def main(args: Iterable[str] | None = None) -> None:
    """Entry point for the inventory-cli console script.

    Args:
        args: Optional command-line arguments for testing purposes.
    """

    from argparse import ArgumentParser

    parser = ArgumentParser(description="Manage inventory database")
    parser.add_argument("conn", help="Database connection string for psql")

    sub = parser.add_subparsers(dest="cmd", required=False)

    mig = sub.add_parser("migrate", help="Apply pending database migrations")
    mig.add_argument("--to", help="Consider migrations up to this file")

    seed = sub.add_parser("seed", help="Apply pending seed scripts")
    seed.add_argument("--to", help="Consider seeds up to this file")

    sub.add_parser("all", help="Apply pending migrations and seeds (default)")
    sub.add_parser(
        "baseline",
        help="Record existing migrations and seeds without executing them",
    )

    parsed = parser.parse_args(list(args) if args is not None else None)

    cmd = parsed.cmd or "all"
    if cmd == "migrate":
        run_migrations(parsed.conn, to=getattr(parsed, "to", None))
    elif cmd == "seed":
        run_seeds(parsed.conn, to=getattr(parsed, "to", None))
    elif cmd == "baseline":
        baseline_database(parsed.conn)
    else:
        run_migrations(parsed.conn)
        run_seeds(parsed.conn)


if __name__ == "__main__":
    main()
