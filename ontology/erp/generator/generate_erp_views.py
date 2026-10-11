"""Emit schema-only classes for relations seen in query SQL but absent from the DDL.

Reads schema/unknown-views.csv (rows with include=yes; edit the CSV to curate) and writes
schema/erp-views.ttl. Columns are those referenced in queries, so they are a lower bound;
datatypes are unknown and left undeclared. No data is read.
"""
import csv
import re
from pathlib import Path

HERE = Path(__file__).resolve().parent.parent / "schema"
NS = "http://example.com/erp#"


def pascal(name):
    return "".join(p[:1].upper() + p[1:].lower() for p in re.split(r"[_\W]+", name) if p)


def main():
    existing = set(re.findall(r"^erp:(\w+) a owl:Class", (HERE / "erp-schema.ttl").read_text(), re.M))
    rows = [r for r in csv.DictReader((HERE / "unknown-views.csv").open()) if r["include"].strip().lower() == "yes"]
    out = [f"@prefix erp: <{NS}> .", "@prefix owl: <http://www.w3.org/2002/07/owl#> .",
           "@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .", "",
           "# Inferred from query SQL (not DDL): classes and the columns the queries reference.", "",
           "erp:inferredFromQuery a owl:AnnotationProperty .", ""]
    used = set(existing)
    for r in rows:
        cls = pascal(r["name"]) or "Unnamed"
        while cls in used:
            cls += "View"
        used.add(cls)
        out += [f"erp:{cls} a owl:Class ;", f'  rdfs:label "{pascal(r["name"])}" ;',
                f'  rdfs:comment "Referenced in query SQL ({r["uses"]} uses; {r["folders"]}); no DDL." ;',
                "  erp:inferredFromQuery true .", ""]
        seen = set()
        for col in filter(None, r["columns"].split(";")):
            prop = cls[:1].lower() + cls[1:] + "_" + pascal(col)[:1].lower() + pascal(col)[1:]
            if prop in seen:
                continue
            seen.add(prop)
            out += [f"erp:{prop} a owl:DatatypeProperty ;", f"  rdfs:domain erp:{cls} ;",
                    f'  rdfs:label "{prop}" ;', "  erp:inferredFromQuery true .", ""]
    (HERE / "erp-views.ttl").write_text("\n".join(out))
    print(f"wrote {len(rows)} classes -> {HERE / 'erp-views.ttl'}")


if __name__ == "__main__":
    main()
