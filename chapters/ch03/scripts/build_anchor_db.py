"""Build librarian/anchors.db: the read-only anchor DB the terminology stager scores candidate terms against.

Perspectives come from the knowledge-base topic folders; categories come from the manufacturing ontology
classes and the ERP topology (tables). The certified SQLite metadata of the original project is not part of
this repo, so these anchors are derived, not SME-certified: treat them as the book's reference vocabulary.
"""
import json
import re
import sqlite3
from pathlib import Path

import rdflib
from rdflib.namespace import OWL, RDF, RDFS

CH3 = Path(__file__).resolve().parent.parent
ROOT = CH3.parent.parent
KB = CH3 / "librarian" / "my-mrp-kb"
OUT = CH3 / "librarian" / "anchors.db"

PERSPECTIVES = {
    "core_framework": ("Knowledge loop framework, deterministic semantic architecture and MRP terminology", "Architect", "governance semantics"),
    "capacity_planning": ("Finite capacity, work centers, schedule slots, load and remaining capacity", "Planner", "capacity utilization"),
    "customer_order_demand": ("Customer orders, demand, forecast and order promising", "Planner", "demand fulfillment"),
    "shop_floor_routing": ("Shop floor work, routings, operations and work orders", "Production Supervisor", "routing and execution"),
    "inventory_transactions": ("Receiving, issuing, adjusting and returning inventory", "Inventory Control", "inventory accuracy"),
    "supplier_rating": ("Supplier on-time delivery, quality score and risk category", "Supply Chain", "supplier performance"),
    "three_way_match": ("Purchase order, receiver and invoice matching and accruals", "Finance", "invoice accuracy"),
}


def main():
    cats = {}
    for f in (ROOT / "ontology" / "mfg").glob("*.ttl"):
        if f.name == "manufacturing-instances.ttl":
            continue
        g = rdflib.Graph().parse(f, format="turtle")
        for c in set(g.subjects(RDF.type, OWL.Class)) | set(g.subjects(RDF.type, RDFS.Class)):
            name = re.split(r"[#/]", str(c))[-1]
            desc = " ".join(str(o) for o in g.objects(c, RDFS.comment)) or " ".join(str(o) for o in g.objects(c, RDFS.label))
            cats.setdefault(name, desc)
    topo = ROOT / "ontology" / "erp" / "schema" / "erp-topology.json"
    if topo.exists():
        for n in json.loads(topo.read_text())["nodes"]:
            cats.setdefault(n["id"], f"ERP table {n['table']}")
    OUT.unlink(missing_ok=True)
    db = sqlite3.connect(OUT)
    db.execute("CREATE TABLE schema_perspectives (perspective_name TEXT PRIMARY KEY, description TEXT, stakeholder_role TEXT, priority_focus TEXT)")
    db.execute("CREATE TABLE schema_entity_categories (category_name TEXT PRIMARY KEY, description TEXT)")
    folders = {re.sub(r"^\d+-", "", d.name).replace("-", "_") for d in KB.iterdir() if d.is_dir()}
    db.executemany("INSERT INTO schema_perspectives VALUES (?,?,?,?)",
                   [(k, *v) for k, v in PERSPECTIVES.items() if k in folders or not folders])
    db.executemany("INSERT INTO schema_entity_categories VALUES (?,?)", sorted(cats.items()))
    db.commit()
    print(f"{OUT}: {db.execute('select count(*) from schema_perspectives').fetchone()[0]} perspectives, "
          f"{len(cats)} categories")


if __name__ == "__main__":
    main()
