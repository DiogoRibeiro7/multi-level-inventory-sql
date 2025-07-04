from pathlib import Path
import sys

# Allow tests to import the package without installation
sys.path.append(str(Path(__file__).resolve().parents[1]))

from unittest import mock

from inventory import cli


def test_run_sql_file_invokes_psql():
    with mock.patch("subprocess.run") as run:
        cli.run_sql_file("db", "file.sql")
        run.assert_called_with(["psql", "db", "-f", "file.sql"], check=True)


def test_run_migrations_order(tmp_path):
    (tmp_path / "002.sql").write_text("")
    (tmp_path / "001.sql").write_text("")
    (tmp_path / "003.sql").write_text("")
    with mock.patch("inventory.cli.run_sql_file") as run_sql:
        cli.run_migrations("db", str(tmp_path))
        assert run_sql.call_count == 3
        assert run_sql.call_args_list[0].args[1].endswith("001.sql")
        assert run_sql.call_args_list[1].args[1].endswith("002.sql")
        assert run_sql.call_args_list[2].args[1].endswith("003.sql")
