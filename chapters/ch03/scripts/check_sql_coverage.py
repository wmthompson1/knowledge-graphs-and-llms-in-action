"""Check which tables referenced by the ground-truth query SQL exist in the ERP ontology.

Each referenced name is classified: table (in ontology), view (defined by CREATE VIEW in the
SQL corpus), cte, temp, system, or unknown (the real gaps).

Usage: python check_sql_coverage.py [--sql-dir Data_Models] [--topology <erp-topology.json>] [--list KIND]
"""
import argparse
import json
import logging
import re
from collections import Counter, defaultdict
from pathlib import Path

import sqlglot
from sqlglot import exp

logging.getLogger("sqlglot").setLevel(logging.ERROR)
HERE = Path(__file__).resolve().parent.parent

SYSTEM_SCHEMAS = {"sys", "information_schema"}
SYSTEM_NAMES = {"string_split", "sysobjects", "syscolumns", "objects", "columns", "tables", "dual", "values", "inserted", "deleted"}
PART = r"(?:\[[^\]]+\]|[\w#@$]+)"
NAME = r"((?:" + PART + r"?\.){0,3})(" + PART + ")"


def strip_comments(sql):
    sql = re.sub(r"/\*.*?\*/", " ", sql, flags=re.S)
    return re.sub(r"--[^\n]*", " ", sql)


def split_batches(sql):
    sql = re.sub(r"^\s*USE\s+\[?\w+\]?\s*;?\s*$", " ", sql, flags=re.I | re.M)
    return [b for b in re.split(r"^\s*GO\s*$", sql, flags=re.I | re.M) if b.strip()]


def columns_in_batch(batch):
    """Map table name -> columns referenced through that table's alias (parsed statements only)."""
    cols = defaultdict(set)
    try:
        for stmt in sqlglot.parse(batch, read="tsql"):
            if stmt is None or isinstance(stmt, exp.Command):
                continue
            alias = {t.alias_or_name.lower(): t.name.lower() for t in stmt.find_all(exp.Table) if t.name}
            for c in stmt.find_all(exp.Column):
                if c.table and c.name and c.table.lower() in alias:
                    cols[alias[c.table.lower()]].add(c.name.lower())
    except Exception:
        pass
    return cols


def refs_in_batch(batch):
    """Return (tables, ctes) as sets of (schema, name) / names, lowercased."""
    tables, ctes = set(), set()
    try:
        for stmt in sqlglot.parse(batch, read="tsql"):
            if stmt is None or isinstance(stmt, exp.Command):
                raise ValueError("unparsed")
            ctes.update(c.alias.lower() for c in stmt.find_all(exp.CTE))
            for t in stmt.find_all(exp.Table):
                if t.name:
                    ident = t.this
                    is_temp = isinstance(ident, exp.Identifier) and (
                        ident.args.get("temporary") or ident.args.get("global_"))
                    prefix = "#" if is_temp else ""
                    tables.add((t.db.lower(), prefix + t.name.lower()))
        return tables, ctes
    except Exception:
        pass
    tables, ctes = set(), set()
    ctes.update(m.lower() for m in re.findall(r"(?:\bWITH|,)\s*\[?(\w+)\]?\s*(?:\([^)]*\))?\s+AS\s*\(", batch, re.I))
    for m in re.finditer(r"\b(?:FROM|JOIN)\s+" + NAME, batch, re.I):
        prefix = [p.strip("[]").lower() for p in m.group(1).split(".")[:-1]]
        tables.add((prefix[-1] if prefix else "", m.group(2).strip("[]").lower()))
    return tables, ctes


def classify(schema, name, ctes, views, known):
    if name.startswith(("#", "@")) or schema.startswith("#"):
        return "temp"
    if schema in SYSTEM_SCHEMAS or name in SYSTEM_NAMES or name.startswith("sys"):
        return "system"
    if name in ctes:
        return "cte"
    if name.replace("_", "") in known:
        return "table"
    if name in views:
        return "view"
    return "unknown"


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--sql-dir", type=Path, default=HERE / "Data_Models")
    ap.add_argument("--topology", type=Path, default=HERE.parent.parent / "ontology/erp/schema/erp-topology.json")
    ap.add_argument("--csv", type=Path, help="write the unknown names to this CSV (name,include,uses,folders,columns)")
    ap.add_argument("--list", default="unknown", help="kind to list (default unknown)")
    a = ap.parse_args()

    known = {n["id"].lower().replace("_", "") for n in json.loads(a.topology.read_text())["nodes"]}
    texts = {f: strip_comments(f.read_text(errors="ignore")) for f in sorted(a.sql_dir.rglob("*.sql"))}
    views = {m.lower() for t in texts.values()
             for m in re.findall(r"\bCREATE\s+(?:OR\s+ALTER\s+)?VIEW\s+(?:\[?\w+\]?\.)?\[?(\w+)\]?", t, re.I)}

    kinds, where, found_cols = defaultdict(Counter), defaultdict(set), defaultdict(set)
    for f, text in texts.items():
        for batch in split_batches(text):
            tables, ctes = refs_in_batch(batch)
            for t, cs in columns_in_batch(batch).items():
                found_cols[t] |= cs
            for schema, name in tables:
                k = classify(schema, name, ctes, views, known)
                kinds[k][name] += 1
                where[name].add(f.relative_to(a.sql_dir).parts[0])
    if a.csv:
        import csv
        with a.csv.open("w", newline="") as fh:
            w = csv.writer(fh)
            w.writerow(["name", "include", "uses", "folders", "columns"])
            for name, n in kinds["unknown"].most_common():
                w.writerow([name, "yes", n, ";".join(sorted(where[name])), ";".join(sorted(found_cols[name]))])
        print(f"wrote {len(kinds['unknown'])} unknown names -> {a.csv}")
    print(f"{len(texts)} sql files")
    for k in ("table", "view", "cte", "temp", "system", "unknown"):
        print(f"  {k:8} {len(kinds[k])} distinct names")
    print(f"\n{a.list} names (by use):")
    for name, n in kinds[a.list].most_common(25):
        print(f"  {name:40} {n:3}  {','.join(sorted(where[name]))}")


if __name__ == "__main__":
    main()
