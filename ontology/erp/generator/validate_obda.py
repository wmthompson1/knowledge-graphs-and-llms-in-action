"""Validate schema/erp-obda.obda with Ontop against an empty H2 database built from the DDL (no data).

Needs a JRE (JAVA_HOME or `java` on PATH), the Ontop CLI (ONTOP_HOME, default ~/tools/ontop) and its jdbc/h2.jar.
Usage: python validate_obda.py [--keep]
"""
import argparse
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

from generate_erp_ontology_from_ddl import XSD, parse

HERE = Path(__file__).resolve().parent
ERP = HERE.parent
ONTOP_HOME = Path(os.environ.get("ONTOP_HOME", Path.home() / "tools" / "ontop"))
H2_TYPES = {"nchar": "VARCHAR", "nvarchar": "VARCHAR", "char": "VARCHAR", "varchar": "VARCHAR", "text": "VARCHAR",
            "ntext": "VARCHAR", "uniqueidentifier": "VARCHAR", "xml": "VARCHAR", "sql_variant": "VARCHAR",
            "datetime": "TIMESTAMP", "datetime2": "TIMESTAMP", "smalldatetime": "TIMESTAMP",
            "datetimeoffset": "TIMESTAMP", "money": "DECIMAL(19,4)", "smallmoney": "DECIMAL(10,4)",
            "decimal": "DECIMAL(38,8)", "numeric": "DECIMAL(38,8)", "float": "DOUBLE PRECISION", "real": "REAL",
            "bit": "BOOLEAN", "tinyint": "SMALLINT", "smallint": "SMALLINT", "int": "INTEGER", "bigint": "BIGINT",
            "date": "DATE", "time": "TIME", "image": "VARBINARY", "binary": "VARBINARY",
            "varbinary": "VARBINARY", "timestamp": "VARBINARY"}


def h2_script(tables):
    stmts = [f"CREATE SCHEMA IF NOT EXISTS {s}" for s in sorted({t['schema'] for t in tables.values()})]
    for t in tables.values():
        cols = ", ".join(f"{c} {H2_TYPES.get(ty, 'VARCHAR')}" for c, ty in t["columns"])
        pk = f", PRIMARY KEY ({', '.join(t['pk'])})" if t["pk"] else ""
        stmts.append(f"CREATE TABLE {t['schema']}.{t['name']} ({cols}{pk})")
    return ";\n".join(stmts) + ";\n"


def run(cmd, env):
    return subprocess.run(cmd, env=env, capture_output=True, text=True)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--keep", action="store_true", help="keep the generated H2 files")
    a = ap.parse_args()
    env = dict(os.environ)
    if "JAVA_HOME" not in env and not any(Path(p, "java").exists() for p in env["PATH"].split(":")):
        jres = sorted((Path.home() / "tools").glob("jdk-*"))
        if jres:
            env["JAVA_HOME"] = str(jres[-1])
    h2 = ONTOP_HOME / "jdbc" / "h2.jar"
    java = Path(env.get("JAVA_HOME", "")) / "bin" / "java" if "JAVA_HOME" in env else Path("java")
    if not h2.exists():
        sys.exit(f"Missing {h2}")

    tables = parse(ERP / "ddl")
    work = Path(tempfile.mkdtemp(prefix="erp_obda_"))
    # Reserved words appear as T-SQL column names; make H2 treat them as identifiers.
    non_kw = sorted({c.upper() for t in tables.values() for c, _ in t["columns"]} | {t["name"].upper() for t in tables.values()})
    url = f"jdbc:h2:file:{work}/erp;NON_KEYWORDS={','.join(non_kw)}"
    (work / "schema.sql").write_text(h2_script(tables))
    r = run([str(java), "-cp", str(h2), "org.h2.tools.RunScript", "-url", url, "-user", "sa", "-script", str(work / "schema.sql")], env)
    if r.returncode:
        sys.exit("Building the H2 schema failed:\n" + (r.stderr or r.stdout)[-3000:])
    print(f"Built empty H2 schema with {len(tables)} tables")

    props = work / "erp.properties"
    props.write_text(f"jdbc.url={url}\njdbc.driver=org.h2.Driver\njdbc.user=sa\njdbc.password=\n")
    r = run([str(ONTOP_HOME / "ontop"), "validate", "-t", str(ERP / "schema" / "erp-schema.ttl"),
             "-m", str(ERP / "schema" / "erp-obda.obda"), "-p", str(props)], env)
    out = (r.stdout + r.stderr)
    print(out[-6000:])
    print("VALID" if r.returncode == 0 else f"INVALID (exit {r.returncode})")
    if not a.keep:
        for f in work.iterdir():
            f.unlink()
        work.rmdir()
    return r.returncode


if __name__ == "__main__":
    sys.exit(main())
