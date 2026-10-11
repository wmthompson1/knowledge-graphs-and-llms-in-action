// Check that ontology + instance data are present
MATCH (n) RETURN count(n) AS totalNodes;

// List labels in the graph
CALL db.labels() YIELD label RETURN label ORDER BY label;

// View suppliers and risk categories
MATCH (s:Supplier) RETURN s LIMIT 20;

// View work orders and their lifecycle stages
MATCH (wo:WorkOrder) RETURN wo LIMIT 20;

// View nonconformances and related defects
MATCH (nc:Nonconformance)-[r]->(target)
RETURN type(r) AS relType, labels(nc) AS fromLabel, labels(target) AS toLabel, nc, target
LIMIT 50;

// Quick quality summary (severity/status are relationships to nodes, not properties)
MATCH (nc:Nonconformance)
OPTIONAL MATCH (nc)-[:severity]->(sev)
OPTIONAL MATCH (nc)-[:status]->(st)
RETURN sev.uri AS severity, st.uri AS status, count(nc) AS nonconformances
ORDER BY nonconformances DESC;

// Inspect a specific work center / schedule slot relationship
MATCH (slot:ScheduleSlot)-[r]->(wc)
RETURN type(r) AS relType, slot, wc LIMIT 20;
