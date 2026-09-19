from hashlib import sha256
from pathlib import Path
import subprocess
import sys
from unittest import mock

import pytest

# Allow tests to import the package without installation
sys.path.append(str(Path(__file__).resolve().parents[1]))

from inventory import cli


def test_run_sql_file_invokes_psql() -> None:
    with mock.patch("shutil.which", return_value="psql"), mock.patch(
        "subprocess.run"
    ) as run:
        cli.run_sql_file("db", "file.sql")
        run.assert_called_once_with(
            [
                "psql",
                "db",
                "-X",
                "-v",
                "ON_ERROR_STOP=1",
                "-f",
                "file.sql",
            ],
            check=True,
        )


def test_run_sql_file_raises_on_psql_failure() -> None:
    failure = subprocess.CalledProcessError(
        returncode=3,
        cmd=["psql", "db", "-X", "-v", "ON_ERROR_STOP=1", "-f", "file.sql"],
    )

    with mock.patch("shutil.which", return_value="psql"), mock.patch(
        "subprocess.run", side_effect=failure
    ), pytest.raises(RuntimeError, match="Failed to execute file.sql"):
        cli.run_sql_file("db", "file.sql")


def test_run_psql_uses_stdin_for_variable_expansion() -> None:
    completed = subprocess.CompletedProcess(
        args=[],
        returncode=0,
        stdout="001.sql\tchecksum\n",
        stderr="",
    )

    with mock.patch("shutil.which", return_value="psql"), mock.patch(
        "subprocess.run",
        return_value=completed,
    ) as run:
        output = cli._run_psql(
            "db",
            "SELECT :'script_type';",
            variables={"script_type": "migration"},
        )

    run.assert_called_once_with(
        [
            "psql",
            "db",
            "-X",
            "-q",
            "-t",
            "-A",
            "-v",
            "ON_ERROR_STOP=1",
            "-v",
            "script_type=migration",
            "-f",
            "-",
        ],
        check=True,
        capture_output=True,
        text=True,
        input="SELECT :'script_type';",
    )
    assert output == "001.sql\tchecksum"


def test_run_migrations_applies_pending_scripts_in_order(tmp_path: Path) -> None:
    (tmp_path / "002.sql").write_text("SELECT 2;")
    (tmp_path / "001.sql").write_text("SELECT 1;")
    (tmp_path / "003.sql").write_text("SELECT 3;")

    with (
        mock.patch("inventory.cli._ensure_history_table"),
        mock.patch("inventory.cli._load_script_history", return_value={}),
        mock.patch("inventory.cli.run_sql_file") as run_sql,
        mock.patch("inventory.cli._record_script") as record,
    ):
        cli.run_migrations("db", str(tmp_path))

    assert [Path(call.args[1]).name for call in run_sql.call_args_list] == [
        "001.sql",
        "002.sql",
        "003.sql",
    ]
    assert [call.args[2] for call in record.call_args_list] == [
        "001.sql",
        "002.sql",
        "003.sql",
    ]


def test_run_migrations_skips_applied_script(tmp_path: Path) -> None:
    script = tmp_path / "001.sql"
    script.write_text("SELECT 1;")
    checksum = sha256(script.read_bytes()).hexdigest()

    with (
        mock.patch("inventory.cli._ensure_history_table"),
        mock.patch(
            "inventory.cli._load_script_history",
            return_value={"001.sql": checksum},
        ),
        mock.patch("inventory.cli.run_sql_file") as run_sql,
        mock.patch("inventory.cli._record_script") as record,
    ):
        cli.run_migrations("db", str(tmp_path))

    run_sql.assert_not_called()
    record.assert_not_called()


def test_run_migrations_rejects_checksum_drift(tmp_path: Path) -> None:
    script = tmp_path / "001.sql"
    script.write_text("SELECT 1;")

    with (
        mock.patch("inventory.cli._ensure_history_table"),
        mock.patch(
            "inventory.cli._load_script_history",
            return_value={"001.sql": "old-checksum"},
        ),
        pytest.raises(RuntimeError, match="checksum mismatch"),
    ):
        cli.run_migrations("db", str(tmp_path))


def test_baseline_records_scripts_without_executing(tmp_path: Path) -> None:
    migration_dir = tmp_path / "migrations"
    seed_dir = tmp_path / "seeds"
    migration_dir.mkdir()
    seed_dir.mkdir()
    (migration_dir / "001.sql").write_text("SELECT 1;")
    (seed_dir / "001.sql").write_text("SELECT 2;")

    with (
        mock.patch("inventory.cli._ensure_history_table"),
        mock.patch("inventory.cli._load_script_history", return_value={}),
        mock.patch("inventory.cli._record_script") as record,
        mock.patch("inventory.cli.run_sql_file") as run_sql,
    ):
        cli.baseline_database(
            "db",
            str(migration_dir),
            str(seed_dir),
        )

    run_sql.assert_not_called()
    assert [call.args[1] for call in record.call_args_list] == [
        "migration",
        "seed",
    ]


def test_main_runs_all_by_default() -> None:
    with mock.patch("inventory.cli.run_migrations") as mig, mock.patch(
        "inventory.cli.run_seeds"
    ) as seed:
        cli.main(["db"])
        mig.assert_called_once_with("db")
        seed.assert_called_once_with("db")


def test_main_migrate_only() -> None:
    with mock.patch("inventory.cli.run_migrations") as mig, mock.patch(
        "inventory.cli.run_seeds"
    ) as seed:
        cli.main(["db", "migrate", "--to", "001.sql"])
        mig.assert_called_once_with("db", to="001.sql")
        seed.assert_not_called()


def test_main_seed_only() -> None:
    with mock.patch("inventory.cli.run_migrations") as mig, mock.patch(
        "inventory.cli.run_seeds"
    ) as seed:
        cli.main(["db", "seed", "--to", "002.sql"])
        seed.assert_called_once_with("db", to="002.sql")
        mig.assert_not_called()


def test_main_baseline() -> None:
    with mock.patch("inventory.cli.baseline_database") as baseline:
        cli.main(["db", "baseline"])
        baseline.assert_called_once_with("db")
