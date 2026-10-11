// Requires APOC Extended, a DuckDB JDBC driver in Neo4j's plugins directory,
// and a supplied $sqlmeshJdbcUrl parameter such as jdbc:duckdb:C:/path/Utilities/SQLMesh/db.db.

// Nodes
CALL apoc.load.jdbc($sqlmeshJdbcUrl, 'SELECT * FROM staging.graph_parts') YIELD row
MERGE (node:Part {sourceKey: row.source_key})
SET node += apoc.map.clean({
  partId: row.part_id, description: row.description, stockUm: row.stock_um,
  fabricated: row.fabricated, purchased: row.purchased,
  toolOrFixture: row.tool_or_fixture, commodityCode: row.commodity_code,
  status: row.status, sourceSystem: row.source_system
}, [], [null]);

CALL apoc.load.jdbc($sqlmeshJdbcUrl, 'SELECT * FROM staging.graph_work_orders') YIELD row
MERGE (node:WorkOrder {sourceKey: row.source_key})
SET node += apoc.map.clean({
  workOrderType: row.work_order_type, baseId: row.base_id, lotId: row.lot_id,
  splitId: row.split_id, subId: row.sub_id, partId: row.part_id,
  desiredQuantity: row.desired_qty, desiredReleaseDate: row.desired_rls_date,
  status: row.status, siteId: row.site_id, udfDocumentKey: row.udf_document_key,
  sourceSystem: row.source_system
}, [], [null]);

CALL apoc.periodic.iterate(
  "CALL apoc.load.jdbc($url, 'SELECT * FROM staging.graph_operations') YIELD row RETURN row",
  "MERGE (node:Operation {sourceKey: row.source_key})
   SET node += apoc.map.clean({
     sequenceNumber: row.sequence_no, resourceId: row.resource_id,
     operationType: row.operation_type, setupHours: row.setup_hrs,
     runHours: row.run_hrs, actualSetupHours: row.act_setup_hrs,
     actualRunHours: row.act_run_hrs, status: row.status, siteId: row.site_id,
     scheduledCapacityUsage: row.sched_capacity_usage, sourceSystem: row.source_system
   }, [], [null])",
  {batchSize: 10000, parallel: false, retries: 1, params: {url: $sqlmeshJdbcUrl}}
) YIELD batches, total, failedBatches, errorMessages
RETURN 'Operation' AS entity, batches, total, failedBatches, errorMessages;

CALL apoc.load.jdbc($sqlmeshJdbcUrl, 'SELECT * FROM staging.graph_requirements') YIELD row
MERGE (node:Requirement {sourceKey: row.source_key})
SET node += apoc.map.clean({
  operationSequenceNumber: row.operation_seq_no, pieceNumber: row.piece_no,
  partId: row.part_id, status: row.status, quantityPer: row.qty_per,
  quantityPerType: row.qty_per_type, fixedQuantity: row.fixed_qty,
  calculatedQuantity: row.calc_qty, usageUnitOfMeasure: row.usage_um,
  siteId: row.site_id, sourceSystem: row.source_system
}, [], [null]);

CALL apoc.load.jdbc($sqlmeshJdbcUrl, 'SELECT * FROM staging.graph_resources') YIELD row
MERGE (node:ShopResource {sourceKey: row.source_key})
SET node += apoc.map.clean({
  resourceId: row.resource_id, description: row.description,
  resourceType: row.resource_type, shift1CapacityHours: row.shift_1_capacity,
  shift2CapacityHours: row.shift_2_capacity, shift3CapacityHours: row.shift_3_capacity,
  efficiencyFactor: row.efficiency_factor, monitorLoad: row.monitor_load,
  departmentId: row.department_id, status: row.status, sourceSystem: row.source_system
}, [], [null]);

CALL apoc.load.jdbc($sqlmeshJdbcUrl, 'SELECT * FROM staging.graph_resource_capacities') YIELD row
MERGE (node:ResourceCapacity {sourceKey: row.source_key})
SET node += apoc.map.clean({
  siteId: row.site_id, resourceId: row.resource_id,
  shift1CapacityHours: row.shift_1_capacity, shift2CapacityHours: row.shift_2_capacity,
  shift3CapacityHours: row.shift_3_capacity, efficiencyFactor: row.efficiency_factor,
  monitorLoad: row.monitor_load, departmentId: row.department_id,
  status: row.status, sourceSystem: row.source_system
}, [], [null]);

CALL apoc.periodic.iterate(
  "CALL apoc.load.jdbc($url, 'SELECT * FROM staging.graph_udfs') YIELD row RETURN row",
  "MERGE (node:UserDefinedField {sourceKey: row.source_key})
   SET node += apoc.map.clean({
     programId: row.program_id, fieldId: row.field_id, documentKey: row.document_key,
     fieldName: row.field_name, dataTypeCode: row.data_type_code,
     isRequired: row.is_required, stringValue: row.string_value,
     numberValue: row.number_value, booleanValue: row.boolean_value,
     dateValue: row.date_value, sourceSystem: row.source_system
   }, [], [null])",
  {batchSize: 10000, parallel: false, retries: 1, params: {url: $sqlmeshJdbcUrl}}
) YIELD batches, total, failedBatches, errorMessages
RETURN 'UserDefinedField' AS entity, batches, total, failedBatches, errorMessages;

CALL apoc.load.jdbc($sqlmeshJdbcUrl, 'SELECT * FROM staging.graph_udf_definitions') YIELD row
MERGE (node:UserDefinedFieldDefinition {sourceKey: row.source_key})
SET node += apoc.map.clean({
  programId: row.program_id, fieldId: row.field_id, fieldName: row.field_name,
  dataTypeCode: row.data_type_code, displayFormat: row.display_format,
  isRequired: row.is_required, sourceSystem: row.source_system
}, [], [null]);

CALL apoc.periodic.iterate(
  "CALL apoc.load.jdbc($url, 'SELECT u.source_key AS udf_key, d.source_key AS definition_key FROM staging.graph_udfs u JOIN staging.graph_udf_definitions d ON d.program_id = u.program_id AND d.field_id = u.field_id') YIELD row RETURN row",
  "MATCH (udf:UserDefinedField {sourceKey: row.udf_key})
   MATCH (definition:UserDefinedFieldDefinition {sourceKey: row.definition_key})
   MERGE (udf)-[:HAS_DEFINITION]->(definition)",
  {batchSize: 10000, parallel: false, retries: 1, params: {url: $sqlmeshJdbcUrl}}
) YIELD batches, total, failedBatches, errorMessages
RETURN 'HAS_DEFINITION' AS entity, batches, total, failedBatches, errorMessages;

// Certified ERP relationships
CALL apoc.load.jdbc($sqlmeshJdbcUrl, 'SELECT source_key, part_key FROM staging.graph_work_orders WHERE part_id IS NOT NULL') YIELD row
MATCH (workOrder:WorkOrder {sourceKey: row.source_key})
MATCH (part:Part {sourceKey: row.part_key})
MERGE (workOrder)-[:PRODUCES_PART]->(part);

CALL apoc.periodic.iterate(
  "CALL apoc.load.jdbc($url, 'SELECT source_key, work_order_key, resource_key FROM staging.graph_operations') YIELD row RETURN row",
  "MATCH (operation:Operation {sourceKey: row.source_key})
   MATCH (workOrder:WorkOrder {sourceKey: row.work_order_key})
   MERGE (workOrder)-[:HAS_OPERATION]->(operation)
   WITH operation, row
   OPTIONAL MATCH (resource:ShopResource {sourceKey: row.resource_key})
   FOREACH (_ IN CASE WHEN resource IS NULL THEN [] ELSE [1] END |
     MERGE (operation)-[:USES_RESOURCE]->(resource)
   )",
  {batchSize: 10000, parallel: false, retries: 1, params: {url: $sqlmeshJdbcUrl}}
) YIELD batches, total, failedBatches, errorMessages
RETURN 'Operation relationships' AS entity, batches, total, failedBatches, errorMessages;

CALL apoc.load.jdbc($sqlmeshJdbcUrl, 'SELECT * FROM staging.graph_requirements') YIELD row
MATCH (requirement:Requirement {sourceKey: row.source_key})
MATCH (workOrder:WorkOrder {sourceKey: row.work_order_key})
MERGE (workOrder)-[:HAS_REQUIREMENT]->(requirement)
WITH requirement, row
OPTIONAL MATCH (operation:Operation {sourceKey: row.operation_key})
OPTIONAL MATCH (part:Part {sourceKey: row.part_key})
OPTIONAL MATCH (subordinate:WorkOrder {sourceKey: row.subordinate_work_order_key})
FOREACH (_ IN CASE WHEN operation IS NULL THEN [] ELSE [1] END |
  MERGE (requirement)-[:REQUIRED_AT_OPERATION]->(operation)
)
FOREACH (_ IN CASE WHEN part IS NULL THEN [] ELSE [1] END |
  MERGE (requirement)-[:REQUIRES_PART]->(part)
)
FOREACH (_ IN CASE WHEN subordinate IS NULL THEN [] ELSE [1] END |
  MERGE (requirement)-[:FULFILLED_BY_SUBORDINATE_WORK_ORDER]->(subordinate)
);

CALL apoc.load.jdbc($sqlmeshJdbcUrl, 'SELECT source_key, resource_key FROM staging.graph_resource_capacities') YIELD row
MATCH (capacity:ResourceCapacity {sourceKey: row.source_key})
MATCH (resource:ShopResource {sourceKey: row.resource_key})
MERGE (resource)-[:HAS_CAPACITY]->(capacity);

// The first polymorphic UDF attachment: Work Order Maintenance.
CALL apoc.periodic.iterate(
  "CALL apoc.load.jdbc($url, 'SELECT u.source_key AS udf_key, w.source_key AS owner_key FROM staging.graph_udfs u JOIN staging.graph_work_orders w ON w.udf_document_key = u.document_key WHERE u.program_id = \\'VMMFGWIN_WO\\'') YIELD row RETURN row",
  "MATCH (workOrder:WorkOrder {sourceKey: row.owner_key})
   MATCH (udf:UserDefinedField {sourceKey: row.udf_key})
   MERGE (workOrder)-[:HAS_UDF]->(udf)",
  {batchSize: 10000, parallel: false, retries: 1, params: {url: $sqlmeshJdbcUrl}}
) YIELD batches, total, failedBatches, errorMessages
RETURN 'WorkOrder HAS_UDF' AS entity, batches, total, failedBatches, errorMessages;

// Part Maintenance uses PART.ID directly as USER_DEF_FIELDS.DOCUMENT_ID.
CALL apoc.periodic.iterate(
  "CALL apoc.load.jdbc($url, 'SELECT u.source_key AS udf_key, p.source_key AS owner_key FROM staging.graph_udfs u JOIN staging.graph_parts p ON p.part_id = u.document_key WHERE u.program_id = \\'VMPRTMNT\\'') YIELD row RETURN row",
  "MATCH (part:Part {sourceKey: row.owner_key})
   MATCH (udf:UserDefinedField {sourceKey: row.udf_key})
   MERGE (part)-[:HAS_UDF]->(udf)",
  {batchSize: 10000, parallel: false, retries: 1, params: {url: $sqlmeshJdbcUrl}}
) YIELD batches, total, failedBatches, errorMessages
RETURN 'Part HAS_UDF' AS entity, batches, total, failedBatches, errorMessages;

// Materialized transitive BOM paths. Path is part of relationship identity because a component can occur by multiple routes.
CALL apoc.load.jdbc($sqlmeshJdbcUrl, 'SELECT * FROM staging.graph_bom_explosion') YIELD row
MATCH (root:Part {sourceKey: row.root_part_key})
MATCH (component:Part {sourceKey: row.component_part_key})
MERGE (root)-[relationship:HAS_BOM_COMPONENT {bomPath: row.bom_path}]->(component)
SET relationship.bomDepth = row.bom_depth,
    relationship.cumulativeQuantity = row.cumulative_quantity;
