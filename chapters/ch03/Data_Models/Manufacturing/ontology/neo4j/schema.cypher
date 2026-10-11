// Neo4j 5+ constraints for the manufacturing ontology.
CREATE CONSTRAINT part_source_key IF NOT EXISTS
FOR (node:Part) REQUIRE node.sourceKey IS UNIQUE;

CREATE CONSTRAINT work_order_source_key IF NOT EXISTS
FOR (node:WorkOrder) REQUIRE node.sourceKey IS UNIQUE;

CREATE CONSTRAINT operation_source_key IF NOT EXISTS
FOR (node:Operation) REQUIRE node.sourceKey IS UNIQUE;

CREATE CONSTRAINT requirement_source_key IF NOT EXISTS
FOR (node:Requirement) REQUIRE node.sourceKey IS UNIQUE;

CREATE CONSTRAINT resource_source_key IF NOT EXISTS
FOR (node:ShopResource) REQUIRE node.sourceKey IS UNIQUE;

CREATE CONSTRAINT capacity_source_key IF NOT EXISTS
FOR (node:ResourceCapacity) REQUIRE node.sourceKey IS UNIQUE;

CREATE CONSTRAINT udf_source_key IF NOT EXISTS
FOR (node:UserDefinedField) REQUIRE node.sourceKey IS UNIQUE;

CREATE CONSTRAINT udf_definition_source_key IF NOT EXISTS
FOR (node:UserDefinedFieldDefinition) REQUIRE node.sourceKey IS UNIQUE;

CREATE CONSTRAINT document_source_key IF NOT EXISTS
FOR (node:Document) REQUIRE node.sourceKey IS UNIQUE;

CREATE CONSTRAINT agent_run_source_key IF NOT EXISTS
FOR (node:AgentRun) REQUIRE node.sourceKey IS UNIQUE;

CREATE INDEX part_id IF NOT EXISTS FOR (node:Part) ON (node.partId);
CREATE INDEX work_order_document_key IF NOT EXISTS FOR (node:WorkOrder) ON (node.udfDocumentKey);
CREATE INDEX udf_document_key IF NOT EXISTS FOR (node:UserDefinedField) ON (node.documentKey);
CREATE INDEX udf_program_field IF NOT EXISTS FOR (node:UserDefinedField) ON (node.programId, node.fieldId);
CREATE INDEX udf_definition_program_field IF NOT EXISTS FOR (node:UserDefinedFieldDefinition) ON (node.programId, node.fieldId);
CREATE INDEX resource_id IF NOT EXISTS FOR (node:ShopResource) ON (node.resourceId);
CREATE INDEX document_external_id IF NOT EXISTS FOR (node:Document) ON (node.externalDocumentId);
