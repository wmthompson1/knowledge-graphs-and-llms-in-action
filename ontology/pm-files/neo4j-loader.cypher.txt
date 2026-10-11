// Neo4j Ontology Loader for create-context-graph
// Requires: n10s plugin installed and configured

// OPTIONAL: Clear existing graph
CALL n10s.graphconfig.init();
MATCH (n) DETACH DELETE n;

// 1. Load source manufacturing ontology
CALL n10s.rdf.import.fetch(
  "file:///ontology/mfg/manufacturing.ttl",
  "Turtle"
);

// 2. Load source quality ontology
CALL n10s.rdf.import.fetch(
  "file:///ontology/mfg/quality.ttl",
  "Turtle"
);

// 3. Load unified manufacturing + quality ontology
CALL n10s.rdf.import.fetch(
  "file:///ontology/mfg/mfg-unified.ttl",
  "Turtle"
);

// 4. Load SALT_KG ontology skeleton
CALL n10s.rdf.import.fetch(
  "file:///ontology/saltkg/saltkg.ttl",
  "Turtle"
);

// 5. Load SALT_KG → SALT unified bindings
CALL n10s.rdf.import.fetch(
  "file:///ontology/saltkg/saltkg-bindings.ttl",
  "Turtle"
);

// 6. Load SALT_KG → Deloitte SAP ontology bindings
CALL n10s.rdf.import.fetch(
  "file:///ontology/saltkg/saltkg-sap.ttl",
  "Turtle"
);

// Done
RETURN "Ontology import complete.";
