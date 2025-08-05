"""Tests for the inventory CLI utilities."""

from pathlib import Path
import sys
import pytest
import subprocess

# Allow tests to import the package without installation
sys.path.append(str(Path(__file__).resolve().parents[1]))

from unittest import mock

from inventory import cli


def test_run_sql_file_invokes_psql() -> None:
    with mock.patch("shutil.which", return_value="psql"), mock.patch(
        "subprocess.run"
    ) as run:
        cli.run_sql_file("db", "file.sql")
        run.assert_called_with(["psql", "db", "-f", "file.sql"], check=True)


def test_run_sql_file_missing_psql() -> None:
    with mock.patch("shutil.which", return_value=None):
        with pytest.raises(RuntimeError, match="psql executable not found"):
            cli.run_sql_file("db", "file.sql")


def test_run_sql_file_subprocess_error() -> None:
    with mock.patch("shutil.which", return_value="psql"), mock.patch(
        "subprocess.run",
        side_effect=subprocess.CalledProcessError(1, ["psql"]),
    ):
        with pytest.raises(RuntimeError):
            cli.run_sql_file("db", "file.sql")


def test_run_migrations_order(tmp_path: Path) -> None:
    (tmp_path / "002.sql").write_text("")
    (tmp_path / "001.sql").write_text("")
    (tmp_path / "003.sql").write_text("")
    with mock.patch("inventory.cli.run_sql_file") as run_sql:
        cli.run_migrations("db", tmp_path)
        assert run_sql.call_count == 3
        assert run_sql.call_args_list[0].args[1].name == "001.sql"
        assert run_sql.call_args_list[1].args[1].name == "002.sql"
        assert run_sql.call_args_list[2].args[1].name == "003.sql"


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


def test_run_rollbacks_parses_down(tmp_path: Path) -> None:
    sql = "CREATE TABLE t(id int);\n-- Down\n-- DROP TABLE t;\n"
    (tmp_path / "001.sql").write_text(sql)
    captured: dict[str, str] = {}

    def capture_sql(_conn: str, path: str | Path) -> None:
        captured["content"] = Path(path).read_text()

    with mock.patch("inventory.cli.run_sql_file", side_effect=capture_sql) as run_sql:
        cli.run_rollbacks("db", tmp_path)
        assert run_sql.call_count == 1
        assert captured["content"].strip() == "DROP TABLE t;"


def test_run_rollbacks_handles_lowercase_marker(tmp_path: Path) -> None:
    sql = "CREATE TABLE t(id int);\n-- down\n-- drop table t;\n"
    (tmp_path / "001.sql").write_text(sql)
    captured: dict[str, str] = {}

    def capture_sql(_conn: str, path: str | Path) -> None:
        captured["content"] = Path(path).read_text()

    with mock.patch("inventory.cli.run_sql_file", side_effect=capture_sql):
        cli.run_rollbacks("db", tmp_path)
    assert captured["content"].strip() == "drop table t;"


def test_main_rollback() -> None:
    with mock.patch("inventory.cli.run_rollbacks") as rb:
        cli.main(["db", "rollback", "--to", "001.sql"])
        rb.assert_called_once_with("db", to="001.sql")


def test_run_migrations_respects_to(tmp_path: Path) -> None:
    (tmp_path / "001.sql").write_text("")
    (tmp_path / "002.sql").write_text("")
    (tmp_path / "003.sql").write_text("")
    with mock.patch("inventory.cli.run_sql_file") as run_sql:
        cli.run_migrations("db", tmp_path, to="002.sql")
        assert run_sql.call_count == 2
        assert run_sql.call_args_list[0].args[1].name == "001.sql"
        assert run_sql.call_args_list[1].args[1].name == "002.sql"


def test_run_seeds_respects_to(tmp_path: Path) -> None:
    (tmp_path / "001.sql").write_text("")
    (tmp_path / "002.sql").write_text("")
    (tmp_path / "003.sql").write_text("")
    with mock.patch("inventory.cli.run_sql_file") as run_sql:
        cli.run_seeds("db", tmp_path, to="002.sql")
        assert run_sql.call_count == 2
        assert run_sql.call_args_list[0].args[1].name == "001.sql"
        assert run_sql.call_args_list[1].args[1].name == "002.sql"


def test_run_rollbacks_stops_at_to(tmp_path: Path) -> None:
    (tmp_path / "001.sql").write_text("-- Down\n-- DROP TABLE a;\n")
    (tmp_path / "002.sql").write_text("-- Down\n-- DROP TABLE b;\n")
    (tmp_path / "003.sql").write_text("-- Down\n-- DROP TABLE c;\n")
    captured: list[str] = []

    def capture(_conn: str, path: str | Path) -> None:
        captured.append(Path(path).read_text().strip())

    with mock.patch("inventory.cli.run_sql_file", side_effect=capture) as run_sql:
        cli.run_rollbacks("db", tmp_path, to="002.sql")
        assert run_sql.call_count == 2
        assert captured == ["DROP TABLE c;", "DROP TABLE b;"]


def test_run_rollbacks_skips_when_no_down(tmp_path: Path) -> None:
    (tmp_path / "001.sql").write_text("CREATE TABLE t(id int);")
    with mock.patch("inventory.cli.run_sql_file") as run_sql:
        cli.run_rollbacks("db", tmp_path)
        run_sql.assert_not_called()


def test_run_migrations_propagates_error(tmp_path: Path) -> None:
    (tmp_path / "001.sql").write_text("")
    with mock.patch(
        "inventory.cli.run_sql_file", side_effect=RuntimeError("boom")
    ):
        with pytest.raises(RuntimeError, match="boom"):
            cli.run_migrations("db", tmp_path)


def test_main_propagates_subprocess_error() -> None:
    with mock.patch(
        "inventory.cli.run_migrations", side_effect=RuntimeError("explode")
    ):
        with pytest.raises(RuntimeError, match="explode"):
            cli.main(["db"])
