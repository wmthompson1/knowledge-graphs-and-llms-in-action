"""Generate a schema-only ERP ontology layer (TTL + Ontop OBDA + topology JSON) from the T-SQL DDL in ../ddl.

No data is read or written: only table/column/key metadata is used.
Usage: python generate_erp_ontology_from_ddl.py [--ddl DIR] [--out DIR]
"""
import argparse
import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
NS = "http://example.com/erp#"

XSD = {
    "bit": "boolean", "tinyint": "integer", "smallint": "integer", "int": "integer", "bigint": "integer",
    "decimal": "decimal", "numeric": "decimal", "money": "decimal", "smallmoney": "decimal",
    "float": "double", "real": "float",
    "date": "date", "datetime": "dateTime", "datetime2": "dateTime", "smalldatetime": "dateTime",
    "datetimeoffset": "dateTime", "time": "time",
    "varbinary": "hexBinary", "binary": "hexBinary", "image": "hexBinary", "timestamp": "hexBinary",
}

CREATE_RE = re.compile(r"CREATE\s+TABLE\s+\[?(\w+)\]?\.\[?(\w+)\]?\s*\((.*?)\n\)", re.I | re.S)
COL_RE = re.compile(r"^\s*\[(\w+)\]\s+\[?(\w+)\]?", re.M)
ALTER_RE = re.compile(r"ALTER\s+TABLE\s+\[?(\w+)\]?\.\[?(\w+)\]?\s+ADD\s+CONSTRAINT\s+\[?\w+\]?\s+(.*?);", re.I | re.S)
PK_RE = re.compile(r"PRIMARY\s+KEY\s*(?:CLUSTERED|NONCLUSTERED)?\s*\(([^)]*)\)", re.I)
FK_RE = re.compile(r"FOREIGN\s+KEY\s*\(([^)]*)\)\s*REFERENCES\s+\[?(\w+)\]?\.\[?(\w+)\]?\s*\(([^)]*)\)", re.I)


def cols(s):
    return [c.strip().strip("[]") for c in s.split(",") if c.strip()]


def pascal(name):
    return "".join(p[:1].upper() + p[1:].lower() for p in re.split(r"[_\W]+", name) if p)


def camel(name):
    p = pascal(name)
    return p[:1].lower() + p[1:]


# T-SQL reserved words that occur as column names; they must be quoted in the OBDA source query.
RESERVED = {"ADD", "ALL", "ALTER", "AND", "ANY", "AS", "ASC", "BETWEEN", "BY", "CASE", "CHECK", "COLUMN", "CONSTRAINT",
            "CREATE", "CROSS", "CURRENT", "DEFAULT", "DELETE", "DESC", "DISTINCT", "DROP", "ELSE", "END", "EXISTS",
            "FOR", "FOREIGN", "FROM", "FULL", "GROUP", "HAVING", "IN", "INDEX", "INNER", "INSERT", "INTO", "IS",
            "JOIN", "KEY", "LEFT", "LIKE", "NOT", "NULL", "OF", "ON", "OR", "ORDER", "OUTER", "PRIMARY", "PUBLIC",
            "REFERENCES", "RIGHT", "SELECT", "SET", "TABLE", "THEN", "TO", "UNION", "UNIQUE", "UPDATE", "USER",
            "VALUES", "VIEW", "WHEN", "WHERE", "WITH", "VALUE", "YEAR", "MONTH", "DAY", "HOUR", "MINUTE", "SECOND",
            "INTERVAL", "LIMIT", "OFFSET", "ROW", "ROWS", "SYSTEM_USER"}


def lower_first(n):
    return n[:1].lower() + n[1:]


def parse(ddl_dir):
    tables = {}
    for f in sorted(ddl_dir.glob("*.sql")):
        text = f.read_text(encoding="utf-8-sig", errors="replace")
        for m in CREATE_RE.finditer(text):
            schema, name, body = m.groups()
            columns = [(c, t.lower()) for c, t in COL_RE.findall(body)]
            tables[(schema, name)] = {"schema": schema, "name": name, "columns": columns, "pk": [], "fks": [], "file": f.name}
        for m in ALTER_RE.finditer(text):
            schema, name, clause = m.groups()
            t = tables.get((schema, name))
            if not t:
                continue
            if (pk := PK_RE.search(clause)):
                t["pk"] = cols(pk.group(1))
            if (fk := FK_RE.search(clause)):
                t["fks"].append({"cols": cols(fk.group(1)), "ref": (fk.group(2), fk.group(3)), "ref_cols": cols(fk.group(4))})
    return tables


def class_names(tables):
    """dbo tables get a bare PascalCase name; other schemas are prefixed to avoid collisions."""
    names, used = {}, {}
    for key, t in sorted(tables.items()):
        n = pascal(t["name"]) if t["schema"].lower() == "dbo" else pascal(t["schema"]) + pascal(t["name"])
        if n in used:  # e.g. TL_RM21925 vs TL_RM_21925: keep the raw table name for the later one
            n = t["name"] if t["name"] not in used else pascal(t["schema"]) + t["name"]
        used[n] = key
        names[key] = n
    return names


def build(tables):
    names = class_names(tables)
    ttl = [f"@prefix erp: <{NS}> .", "@prefix owl: <http://www.w3.org/2002/07/owl#> .",
           "@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .",
           "@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .",
           "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .", "",
           "<http://example.com/erp> a owl:Ontology ; rdfs:label \"ERP schema ontology (generated from DDL, no data)\" .", ""]
    obda = ["[PrefixDeclaration]", f":\t{NS}", "xsd:\thttp://www.w3.org/2001/XMLSchema#", "rdfs:\thttp://www.w3.org/2000/01/rdf-schema#", "",
            "[MappingDeclaration] @collection [[", ""]
    nodes, edges, skipped, warnings = [], [], [], []

    def template(key, colnames):
        return f":{names[key]}/" + "/".join("{%s}" % c for c in colnames)

    for key, t in sorted(tables.items()):
        cls, schema, tname = names[key], t["schema"], t["name"]
        ttl += [f"erp:{cls} a owl:Class ;", f"  rdfs:label \"{pascal(tname)}\" ;",
                f"  rdfs:comment \"Generated from {schema}.{tname}\" .", ""]
        nodes.append({"id": cls, "label": cls, "table": f"{schema}.{tname}", "columns": len(t["columns"]), "mapped": bool(t["pk"])})
        pcols = {}
        for col, typ in t["columns"]:
            prop = f"{lower_first(cls)}_{camel(col)}"
            pcols[col] = prop
            ttl += [f"erp:{prop} a owl:DatatypeProperty ;", f"  rdfs:domain erp:{cls} ;",
                    f"  rdfs:range xsd:{XSD.get(typ, 'string')} ;", f"  rdfs:label \"{col}\" .", ""]
        for fk in t["fks"]:
            tgt = tables.get(fk["ref"])
            if tgt is None:
                warnings.append(f"{schema}.{tname}: FK to unknown table {'.'.join(fk['ref'])}")
                continue
            prop = f"{lower_first(cls)}_{lower_first(names[fk['ref']])}"
            if len(fk["cols"]) > 1 or prop in pcols.values() or any(e["label"] == prop and e["from"] == cls for e in edges):
                prop += "_" + "_".join(camel(c) for c in fk["cols"])
            while prop in pcols.values():
                prop += "Ref"
            fk["prop"] = prop
            ttl += [f"erp:{prop} a owl:ObjectProperty ;", f"  rdfs:domain erp:{cls} ;",
                    f"  rdfs:range erp:{names[fk['ref']]} ;", f"  rdfs:label \"{prop}\" .", ""]
            edges.append({"from": cls, "to": names[fk["ref"]], "label": prop, "columns": fk["cols"]})
        if not t["pk"]:
            skipped.append(f"{schema}.{tname}")
            continue
        targets = [f"{template(key, t['pk'])} a :{cls}"]
        for col, typ in t["columns"]:
            targets.append(f":{pcols[col]} {{{col}}}^^xsd:{XSD.get(typ, 'string')}")
        for fk in t["fks"]:
            tgt = tables.get(fk["ref"])
            if tgt is None or "prop" not in fk or not tgt["pk"] or set(fk["ref_cols"]) != set(tgt["pk"]):
                if tgt is not None and "prop" in fk:
                    warnings.append(f"{schema}.{tname}: FK {fk['prop']} does not reference target PK; no object mapping")
                continue
            by_ref = dict(zip(fk["ref_cols"], fk["cols"]))
            targets.append(f":{fk['prop']} {template(fk['ref'], [by_ref[c] for c in tgt['pk']])}")
        selected = list(dict.fromkeys(t["pk"] + [c for c, _ in t["columns"]] + [c for f in t["fks"] for c in f["cols"]]))
        select_list = ", ".join(f'"{c}"' if c.upper() in RESERVED else c for c in selected)
        obda += [f"mappingId\tM_{cls}", "target\t\t" + " ;\n\t\t\t".join(targets) + " .",
                 f"source\t\tSELECT {select_list} FROM {schema}.{tname}", ""]
    obda.append("]]")
    topo = {"nodes": nodes, "edges": edges}
    return "\n".join(ttl) + "\n", "\n".join(obda) + "\n", topo, skipped, warnings


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ddl", type=Path, default=HERE.parent / "ddl")
    ap.add_argument("--out", type=Path, default=HERE.parent / "schema")
    a = ap.parse_args()
    tables = parse(a.ddl)
    if not tables:
        sys.exit(f"No CREATE TABLE statements found in {a.ddl}")
    ttl, obda, topo, skipped, warnings = build(tables)
    a.out.mkdir(parents=True, exist_ok=True)
    (a.out / "erp-schema.ttl").write_text(ttl, encoding="utf-8")
    (a.out / "erp-obda.obda").write_text(obda, encoding="utf-8")
    (a.out / "erp-topology.json").write_text(json.dumps(topo, indent=2), encoding="utf-8")
    print(f"{len(tables)} tables, {len(topo['edges'])} foreign-key edges -> {a.out}")
    print(f"{len(skipped)} tables without a primary key were left out of the OBDA mappings")
    for w in warnings[:20]:
        print("WARN", w)
    if len(warnings) > 20:
        print(f"... {len(warnings) - 20} more warnings")


if __name__ == "__main__":
    main()
