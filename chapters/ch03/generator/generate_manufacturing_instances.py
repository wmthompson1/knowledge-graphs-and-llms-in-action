#!/usr/bin/env python3
"""Generate realistic manufacturing instance data for the MFG ontology."""

from pathlib import Path

OUTPUT_PATH = Path(__file__).resolve().parents[3] / "ontology" / "mfg" / "manufacturing-instances.ttl"

TTL = """@prefix ex: <https://example.com/factory/> .
@prefix mfgm: <https://example.com/mfgm/> .
@prefix mfgq: <https://example.com/mfgq/> .
@prefix owl: <http://www.w3.org/2002/07/owl#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

# Local instance links used by the generated graph.
ex:WorkCenter a owl:Class ; rdfs:label "Work Center"@en .
ex:Batch a owl:Class ; rdfs:label "Batch"@en .

ex:hasPart a owl:ObjectProperty ; rdfs:label "has part"@en .
ex:hasBatch a owl:ObjectProperty ; rdfs:label "has batch"@en .
ex:produces a owl:ObjectProperty ; rdfs:label "produces"@en .
ex:atWorkCenter a owl:ObjectProperty ; rdfs:label "at work center"@en .
ex:assignedTo a owl:ObjectProperty ; rdfs:label "assigned to"@en .
ex:usesEquipment a owl:ObjectProperty ; rdfs:label "uses equipment"@en .

# Suppliers
ex:Supplier-Apex a mfgm:Supplier ;
  rdfs:label "Apex Precision Components"@en ;
  mfgm:hasRiskCategory mfgm:MediumRisk ;
  mfgm:riskScore "7"^^xsd:integer ;
  mfgm:onTimeDeliveryPct "96.5"^^xsd:decimal ;
  mfgm:qualityScore "96.8"^^xsd:decimal ;
  mfgm:complianceStatus "Certified"^^xsd:string .

ex:Supplier-BoreTech a mfgm:Supplier ;
  rdfs:label "BoreTech Machining"@en ;
  mfgm:hasRiskCategory mfgm:HighRisk ;
  mfgm:riskScore "9"^^xsd:integer ;
  mfgm:onTimeDeliveryPct "88.2"^^xsd:decimal ;
  mfgm:qualityScore "92.1"^^xsd:decimal ;
  mfgm:complianceStatus "Limited"^^xsd:string .

ex:Supplier-VectorMfg a mfgm:Supplier ;
  rdfs:label "Vector Manufacturing"@en ;
  mfgm:hasRiskCategory mfgm:LowRisk ;
  mfgm:riskScore "2"^^xsd:integer ;
  mfgm:onTimeDeliveryPct "99.1"^^xsd:decimal ;
  mfgm:qualityScore "98.9"^^xsd:decimal ;
  mfgm:complianceStatus "Approved"^^xsd:string .

# Parts and work orders
ex:Part-PN-204878 a mfgm:Part ;
  rdfs:label "PN-204878 Gearbox Housing"@en .

ex:Part-PN-330104 a mfgm:Part ;
  rdfs:label "PN-330104 Drive Shaft"@en .

ex:WO-45018 a mfgm:WorkOrder ;
  rdfs:label "WO-45018 - Gearbox Housing"@en ;
  mfgm:lifecycleStage "Released"^^xsd:string ;
  ex:hasPart ex:Part-PN-204878 .

ex:WO-45019 a mfgm:WorkOrder ;
  rdfs:label "WO-45019 - Drive Shaft"@en ;
  mfgm:lifecycleStage "InProgress"^^xsd:string ;
  ex:hasPart ex:Part-PN-330104 .

# Schedule and work center state
ex:WorkCenter-Cell-03 a ex:WorkCenter ;
  rdfs:label "Cell 03 - Final Machining"@en .

ex:ScheduleSlot-2026-10-03-A a mfgm:ScheduleSlot ;
  rdfs:label "Shift A Schedule Slot"@en ;
  ex:assignedTo ex:WorkCenter-Cell-03 ;
  mfgm:plannedCapacity "24"^^xsd:integer ;
  mfgm:remainingCapacity "6"^^xsd:integer ;
  mfgm:shiftId "A"^^xsd:string ;
  mfgm:workCenterRole "Machining"^^xsd:string .

ex:ScheduleSlot-2026-10-03-B a mfgm:ScheduleSlot ;
  rdfs:label "Shift B Schedule Slot"@en ;
  ex:assignedTo ex:WorkCenter-Cell-03 ;
  mfgm:plannedCapacity "20"^^xsd:integer ;
  mfgm:remainingCapacity "9"^^xsd:integer ;
  mfgm:shiftId "B"^^xsd:string ;
  mfgm:workCenterRole "Inspection"^^xsd:string .

# Production events
ex:Batch-B-2026-10-03-01 a ex:Batch ;
  rdfs:label "Batch B-2026-10-03-01"@en ;
  ex:hasPart ex:Part-PN-204878 .

ex:ProdEvent-2026-10-03-01 a mfgm:ProductionEvent ;
  rdfs:label "Production event 2026-10-03-01"@en ;
  ex:usesEquipment "CNC-12"^^xsd:string ;
  ex:atWorkCenter ex:WorkCenter-Cell-03 ;
  mfgm:eventType "Machining"^^xsd:string ;
  mfgm:operator "R. Patel"^^xsd:string ;
  mfgm:shift "A"^^xsd:string ;
  mfgm:reasonCode "NormalRun"^^xsd:string ;
  ex:hasBatch ex:Batch-B-2026-10-03-01 .

ex:ProdEvent-2026-10-03-02 a mfgm:ProductionEvent ;
  rdfs:label "Production event 2026-10-03-02"@en ;
  ex:usesEquipment "CMM-04"^^xsd:string ;
  ex:atWorkCenter ex:WorkCenter-Cell-03 ;
  mfgm:eventType "Inspection"^^xsd:string ;
  mfgm:operator "J. Nguyen"^^xsd:string ;
  mfgm:shift "B"^^xsd:string ;
  mfgm:reasonCode "OutOfTolerance"^^xsd:string ;
  ex:hasBatch ex:Batch-B-2026-10-03-01 .

# Quality and nonconformance instances
ex:Defect-SurfaceFinish a mfgq:Defect ;
  rdfs:label "Surface finish out-of-spec"@en .

ex:Defect-HoleConcentricity a mfgq:Defect ;
  rdfs:label "Hole concentricity deviation"@en .

ex:Inspection-9012 a mfgq:Inspection ;
  rdfs:label "Inspection 9012"@en ;
  ex:usesEquipment "CMM-04"^^xsd:string ;
  mfgq:producesMeasurement ex:Measurement-9012-01 .

ex:Measurement-9012-01 a mfgq:Measurement ;
  rdfs:label "Measurement 9012-01"@en ;
  mfgq:measuresCharacteristic ex:Characteristic-Roughness ;
  mfgq:value "0.92"^^xsd:decimal ;
  mfgq:unitCode "um"^^xsd:string .

ex:Characteristic-Roughness a mfgq:Characteristic ;
  rdfs:label "Surface roughness"@en .

ex:NC-90017 a mfgq:Nonconformance ;
  rdfs:label "NC-90017 - Gearbox housing finish"@en ;
  mfgq:affectedPart ex:Part-PN-204878 ;
  mfgq:affectedBatch ex:Batch-B-2026-10-03-01 ;
  mfgq:associatedWithOrder ex:WO-45018 ;
  mfgq:associatedWithOperation "Finish Grinding"^^xsd:string ;
  mfgq:associatedWithWorkCenter ex:WorkCenter-Cell-03 ;
  mfgq:associatedWithEquipment "CNC-12"^^xsd:string ;
  mfgq:associatedWithSupplier ex:Supplier-Apex ;
  mfgq:hasDefect ex:Defect-SurfaceFinish ;
  mfgq:detectedBy ex:NC-90017-Inspection ;
  mfgq:hasDisposition ex:Rework-90017 ;
  mfgq:severity mfgq:Major ;
  mfgq:status mfgq:UnderInvestigation ;
  mfgq:quantityAffected "14"^^xsd:decimal ;
  mfgq:description "Surface finish exceeded spec on gearbox housing after final machining."^^xsd:string ;
  mfgq:sourceSystem "MES"^^xsd:string ;
  mfgq:sourceId "NC-90017"^^xsd:string ;
  mfgq:sourceRecord "NC/2026/1047"^^xsd:string ;
  mfgq:detectedAt "2026-10-03T08:42:00Z"^^xsd:dateTime .

ex:NC-90017-Inspection a mfgq:Inspection ;
  rdfs:label "Inspection that detected NC-90017"@en ;
  mfgq:producesMeasurement ex:Measurement-9012-01 .

ex:Rework-90017 a mfgq:Rework ;
  rdfs:label "Rework for NC-90017"@en .

ex:NC-90018 a mfgq:Nonconformance ;
  rdfs:label "NC-90018 - Hole concentricity deviation"@en ;
  mfgq:affectedPart ex:Part-PN-330104 ;
  mfgq:associatedWithOrder ex:WO-45019 ;
  mfgq:hasDefect ex:Defect-HoleConcentricity ;
  mfgq:hasDisposition ex:Scrap-90018 ;
  mfgq:severity mfgq:Critical ;
  mfgq:status mfgq:Open ;
  mfgq:quantityAffected "3"^^xsd:decimal ;
  mfgq:description "The bore alignment was outside the tolerance band on the drive shaft."^^xsd:string ;
  mfgq:sourceSystem "QMS"^^xsd:string ;
  mfgq:sourceId "NC-90018"^^xsd:string ;
  mfgq:sourceRecord "QMS/1053"^^xsd:string ;
  mfgq:detectedAt "2026-10-03T11:18:00Z"^^xsd:dateTime .

ex:Scrap-90018 a mfgq:Scrap ;
  rdfs:label "Scrap disposition for NC-90018"@en .
"""


def main() -> None:
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_PATH.write_text(TTL.strip() + "\n", encoding="utf-8")
    print(f"Wrote manufacturing instance data to {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
