"""Create (or reuse) an on-demand semantic slice with a deterministic ID.

ID = sha256(sorted class names + content hashes of the ontology files)[:12], so the
same request over the same ontology always yields the same ID and a cache hit.
"""
import argparse
import hashlib
import json
import sys
from pathlib import Path

import rdflib

sys.path.insert(0, str(Path(__file__).resolve().parent))
from librarian import slice_class  # noqa: E402


def ontology_files(ontology):
    schema = ontology / "erp" / "schema"
    extra = [f for f in [schema / "erp-views.ttl"] if f.exists()]
    return [schema / "erp-schema.ttl", *extra, *sorted((ontology / "mfg").glob("*.ttl"))]


def slice_id(names, files):
    h = hashlib.sha256()
    for n in sorted(set(names)):
        h.update(n.encode())
    for f in files:
        h.update(hashlib.sha256(f.read_bytes()).digest())
    return h.hexdigest()[:12]


def get_slice(names, ontology, out):
    files = ontology_files(ontology)
    for f in files:
        if not f.exists():
            raise SystemExit(f"missing ontology file: {f}")
    sid = slice_id(names, files)
    path = out / "slices" / f"{sid}.json"
    if path.exists():
        return sid, path, True
    g = rdflib.Graph()
    for f in files:
        g.parse(f)
    classes = {n: slice_class(g, n) for n in sorted(set(names))}
    empty = [n for n, t in classes.items() if not t]
    if empty:
        raise SystemExit(f"no classes found: {empty}")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps({"id": sid, "classes": classes,
                                "sources": [str(f) for f in files]}, indent=2))
    return sid, path, False


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("names", nargs="+", help="class names, e.g. WorkOrder Part")
    ap.add_argument("--ontology", type=Path, default=Path("../../ontology"))
    ap.add_argument("--out", type=Path, default=Path("../../kb"))
    a = ap.parse_args()
    sid, path, hit = get_slice(a.names, a.ontology, a.out)
    print(f"slice {sid} ({'cache hit' if hit else 'built'}): {path}")


if __name__ == "__main__":
    main()
