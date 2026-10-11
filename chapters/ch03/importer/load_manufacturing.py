"""Load the manufacturing ontology + instance data into Neo4j via n10s and fail loudly on any problem."""
import configparser
import os
import sys

from neo4j import GraphDatabase

FILES = ["manufacturing", "quality", "mfg-unified", "manufacturing-instances"]
URI_PREFIX = os.environ.get("ONTOLOGY_URI_PREFIX", "file:///ontology/mfg/")
DATABASE = os.environ.get("NEO4J_DATABASE", "neo4j")


def main() -> int:
    cfg = configparser.ConfigParser()
    cfg.read(os.path.join(os.path.dirname(__file__), "..", "..", "..", "config.ini"))
    c = cfg["neo4j"]
    driver = GraphDatabase.driver(c["uri"], auth=(c["user"], c["password"]))
    failed = False
    with driver.session(database=DATABASE) as s:
        if not s.run("SHOW PROCEDURES YIELD name WHERE name = 'n10s.graphconfig.init' RETURN name").data():
            print("ERROR: Neosemantics (n10s) is not installed in this Neo4j instance.")
            return 1
        s.run("CREATE CONSTRAINT n10s_unique_uri IF NOT EXISTS FOR (r:Resource) REQUIRE r.uri IS UNIQUE").consume()
        if not s.run("MATCH (g:_GraphConfig) RETURN g").data():
            s.run("CALL n10s.graphconfig.init({handleVocabUris: 'IGNORE', handleMultival: 'ARRAY'})").consume()
        for name in FILES:
            rec = s.run("CALL n10s.rdf.import.fetch($url, 'Turtle') "
                        "YIELD terminationStatus, triplesLoaded, extraInfo RETURN *",
                        url=f"{URI_PREFIX}{name}.ttl").single()
            ok = rec["terminationStatus"] == "OK" and rec["triplesLoaded"] > 0
            print(f"{'OK  ' if ok else 'FAIL'} {name}.ttl: status={rec['terminationStatus']} "
                  f"triples={rec['triplesLoaded']} {rec['extraInfo']}")
            failed |= not ok
        total = s.run("MATCH (n:Resource) RETURN count(n) AS c").single()["c"]
        print(f"Resource nodes in '{DATABASE}': {total}")
        failed |= total == 0
    driver.close()
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
