import subprocess
import sys
from pathlib import Path

CH03 = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(CH03 / "scripts"))
import check_sql_coverage as c  # noqa: E402

POC = CH03.parent.parent / "ontology" / "erp" / "ontop-ontology-poc"


def kinds(sql, known=(), views=()):
    tables, ctes = c.refs_in_batch(sql)
    return {n: c.classify(s, n, ctes, set(views), set(known)) for s, n in tables}


def test_cte_and_temp_and_system():
    sql = "WITH base AS (SELECT * FROM dbo.PART) SELECT * FROM base JOIN #t ON 1=1 JOIN sys.objects o ON 1=1"
    k = kinds(sql, known={"part"})
    assert k == {"part": "table", "base": "cte", "#t": "temp", "objects": "system"}


def test_four_part_linked_server_name():
    k = kinds("SELECT * FROM [sql-lab-2].live.dbo.WORK_ORDER w", known={"workorder"})
    assert k == {"work_order": "table"}


def test_use_statement_is_ignored_and_go_splits():
    batches = c.split_batches("USE [LIVE]\nGO\nSELECT * FROM dbo.PART\nGO\n")
    assert len(batches) == 1 and "PART" in batches[0]


def test_fallback_regex_on_unparseable_batch():
    tables, ctes = c.refs_in_batch("IF OBJECT_ID('x') IS NULL BEGIN SELECT * FROM dbo.PART p JOIN LIVE..CUSTOMER c ON 1=1 END")
    assert {n for _, n in tables} >= {"part", "customer"}


def test_generate_mapping_defaults_resolve_and_are_current():
    r = subprocess.run([sys.executable, "generate_mapping.py", "--all", "--check"],
                       cwd=POC, capture_output=True, text=True)
    assert r.returncode == 0, r.stdout + r.stderr
