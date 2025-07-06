from pathlib import Path
import sys

# Allow tests to import the package without installation
sys.path.append(str(Path(__file__).resolve().parents[1]))

from unittest import mock

from inventory import cli


def test_run_sql_file_invokes_psql():
    with mock.patch("shutil.which", return_value="psql"), mock.patch(
        "subprocess.run"
    ) as run:
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


def test_main_runs_all_by_default():
    with mock.patch("inventory.cli.run_migrations") as mig, mock.patch(
        "inventory.cli.run_seeds"
    ) as seed:
        cli.main(["db"])
        mig.assert_called_once_with("db")
        seed.assert_called_once_with("db")


def test_main_migrate_only():
    with mock.patch("inventory.cli.run_migrations") as mig, mock.patch(
        "inventory.cli.run_seeds"
    ) as seed:
        cli.main(["db", "migrate", "--to", "001.sql"])
        mig.assert_called_once_with("db", to="001.sql")
        seed.assert_not_called()


def test_main_seed_only():
    with mock.patch("inventory.cli.run_migrations") as mig, mock.patch(
        "inventory.cli.run_seeds"
    ) as seed:
        cli.main(["db", "seed", "--to", "002.sql"])
        seed.assert_called_once_with("db", to="002.sql")
        mig.assert_not_called()
