"""Build a zero-trust KB from ontology structure and synthetic TTL.

Reads ERP schema TTL, manufacturing TTL and synthetic instances only; no ERP rows.
Writes semantic_slices.json and kb_manifest.json to --out.
"""
import argparse
import json
from pathlib import Path

import rdflib
from rdflib import RDF, RDFS, OWL

DEFAULT_SLICES = ["WorkOrder", "Part", "Operation", "Customer"]


def local(uri):
    s = str(uri)
    return s.rsplit("/", 1)[-1].rsplit("#", 1)[-1]


def slice_class(g, name):
    """Triples describing every class named `name` and the properties touching it."""
    classes = {s for s in g.subjects(RDF.type, OWL.Class) if local(s) == name}
    triples = set()
    for c in classes:
        triples.update(g.triples((c, None, None)))
        for p in list(g.subjects(RDFS.domain, c)) + list(g.subjects(RDFS.range, c)):
            triples.update(g.triples((p, None, None)))
    return [
        {"s": str(s), "p": local(p), "o": str(o)} for s, p, o in sorted(triples, key=str)
    ]


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--ontology", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--slices", nargs="*", default=DEFAULT_SLICES)
    a = ap.parse_args()

    sources = [a.ontology / "erp" / "schema" / "erp-schema.ttl"]
    views = a.ontology / "erp" / "schema" / "erp-views.ttl"
    if views.exists():
        sources.append(views)
    sources += sorted((a.ontology / "mfg").glob("*.ttl"))
    g = rdflib.Graph()
    for f in sources:
        if not f.exists():
            raise SystemExit(f"missing ontology file: {f}")
        g.parse(f)

    slices = {n: slice_class(g, n) for n in a.slices}
    empty = [n for n, t in slices.items() if not t]
    if empty:
        raise SystemExit(f"no classes found for slices: {empty}")

    a.out.mkdir(parents=True, exist_ok=True)
    (a.out / "semantic_slices.json").write_text(json.dumps(slices, indent=2))
    manifest = {
        "slices": {n: len(t) for n, t in slices.items()},
        "sources": [str(f) for f in sources],
        "triples_total": len(g),
    }
    (a.out / "kb_manifest.json").write_text(json.dumps(manifest, indent=2))
    print(f"KB built: {a.out} ({len(g)} triples read, slices: {manifest['slices']})")


if __name__ == "__main__":
    main()
