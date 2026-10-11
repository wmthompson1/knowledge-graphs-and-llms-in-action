// Parameters let file connectors and agents write external context without becoming ERP authorities.
// $documents rows: sourceKey, externalDocumentId, uri, contentHash, ownerSourceKey.
UNWIND $documents AS row
MERGE (document:Document {sourceKey: row.sourceKey})
SET document += apoc.map.clean({
  externalDocumentId: row.externalDocumentId,
  uri: row.uri,
  contentHash: row.contentHash,
  sourceSystem: row.sourceSystem
}, [], [null])
WITH document, row
MATCH (owner {sourceKey: row.ownerSourceKey})
WHERE owner:WorkOrder OR owner:Part OR owner:Operation
MERGE (owner)-[:HAS_DOCUMENT]->(document);

// $agentRun: sourceKey, agentName, startedAt, contextSourceKeys, producedDocumentSourceKeys.
MERGE (run:AgentRun {sourceKey: $agentRun.sourceKey})
SET run.agentName = $agentRun.agentName,
    run.startedAt = datetime($agentRun.startedAt)
WITH run
UNWIND $agentRun.contextSourceKeys AS contextKey
MATCH (context {sourceKey: contextKey})
MERGE (run)-[:USED_CONTEXT]->(context)
WITH DISTINCT run
UNWIND $agentRun.producedDocumentSourceKeys AS documentKey
MATCH (document:Document {sourceKey: documentKey})
MERGE (run)-[:PRODUCED_DOCUMENT]->(document);
