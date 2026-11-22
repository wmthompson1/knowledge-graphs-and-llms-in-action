Entity Identification, Relationship Extraction, and Normalization
Foundational Concepts for Knowledge Graph Construction
Introduction

Knowledge graphs (KGs) transform information into a network of entities and relationships that computers can analyze. Whether the source is scientific literature, medical records, contracts, emails, or web pages, three foundational tasks are required before a useful knowledge graph can be built:

Entity Identification – finding the important things mentioned in text.
Relationship Extraction – identifying how those things are connected.
Normalization – ensuring the same real-world concept is represented consistently.

These three activities form the bridge between unstructured text and structured graph data.

Unstructured Text
        ↓
Entity Identification
        ↓
Relationship Extraction
        ↓
Normalization
        ↓
Knowledge Graph

1. Entity Identification
Definition

Entity Identification (often called Named Entity Recognition, or NER) is the process of finding and classifying important concepts within text.

An entity is a thing that has meaning within a domain.

Examples include:

Domain	Example EntitiesMedicine	Diseases, drugs, genes, proteins
Finance	Companies, stocks, currencies
Legal	People, organizations, contracts
Retail	Products, brands, customers

The goal is to answer:

"What are the important objects being mentioned?"

Example 1: Biomedical Text

Consider the sentence:

"miR-21 is strongly associated with breast cancer."

An entity identification system might produce:

Text	Entity TypemiR-21	MiRNA
breast cancer	Disease

Result:

[MiRNA: miR-21]
[Disease: breast cancer]

Example 2: Business Text

Sentence:

"Microsoft acquired GitHub in 2018."

Identified entities:

Text	Entity TypeMicrosoft	Company
GitHub	Company
2018	Date

Result:

[Company: Microsoft]
[Company: GitHub]
[Date: 2018]

Why Entity Identification Matters

Without identifying entities, a graph has nothing to connect.

For example:

The patient has breast cancer.


becomes

(Disease: Breast Cancer)


before any relationships can be created.

Think of entity identification as identifying the nodes of a graph.

Node discovery

2. Relationship Extraction
Definition

Relationship Extraction determines how identified entities are connected.

If entity identification finds the nodes, relationship extraction finds the edges.

The goal is to answer:

"How are these things related?"

Example 1: Biomedical Domain

Sentence:

"miR-21 regulates TP53."

Entities:

MiRNA: miR-21
Gene: TP53


Extracted relationship:

(miR-21)-[:REGULATES]->(TP53)


Graph:

miR-21 ----REGULATES----> TP53

Example 2: Disease Association

Sentence:

"miR-21 has been linked to breast cancer."

Entities:

MiRNA: miR-21
Disease: Breast Cancer


Relationship:

(miR-21)-[:ASSOCIATED_WITH]->(Breast Cancer)

Example 3: Business Domain

Sentence:

"Microsoft acquired GitHub."

Entities:

Microsoft
GitHub


Relationship:

(Microsoft)-[:ACQUIRED]->(GitHub)

Why Relationship Extraction Matters

A collection of entities without relationships is merely a list.

For example:

miR-21
Breast Cancer
TP53


contains information but no structure.

After relationship extraction:

(miR-21)-[:ASSOCIATED_WITH]->(Breast Cancer)

(miR-21)-[:REGULATES]->(TP53)


we obtain a graph.

This enables:

Graph traversals
Path-finding
Centrality analysis
Community detection
Similarity analysis
Challenges

Relationship extraction is often harder than entity identification.

Consider:

"The study suggests that miR-21 may indirectly influence TP53 activity."

Humans understand there's a possible relationship.

Machines must determine:

Does a relationship exist?
What type?
How certain is it?
What direction should it have?

This is why traditional NLP often requires specialized relation-extraction models.

3. Normalization
Definition

Normalization is the process of mapping different textual representations of the same real-world concept to a single canonical representation.

The goal is to answer:

"Are these different names actually referring to the same thing?"

Example 1: Disease Names

A dataset may contain:

Breast cancer
breast carcinoma
mammary carcinoma
Malignant neoplasm of breast


Humans recognize these as referring to the same disease concept.

A computer may initially treat them as different entities.

Without normalization:

(Disease: Breast Cancer)

(Disease: breast carcinoma)

(Disease: mammary carcinoma)


Three separate nodes are created.

After Normalization

All variants map to one standard concept:

(Disease {
    id: "MONDO:0007254",
    name: "Breast Cancer"
})


Graph:

Breast cancer
breast carcinoma
mammary carcinoma
        │
        ▼
   Breast Cancer

Example 2: Company Names

Text may contain:

Microsoft
Microsoft Corp.
Microsoft Corporation
MSFT


Normalization recognizes these as:

Microsoft Corporation

Example 3: Person Names

Documents may mention:

William Thompson
Bill Thompson
W. Thompson


Normalization attempts to determine whether these references describe the same person.

Why Normalization Matters

Without normalization, graphs become fragmented.

Imagine three papers that mention:

breast cancer
breast carcinoma
mammary carcinoma


Without normalization:

Paper A -> breast cancer
Paper B -> breast carcinoma
Paper C -> mammary carcinoma


The graph sees three diseases.

With normalization:

Paper A ─┐
Paper B ─┼──► Breast Cancer
Paper C ─┘


The graph now sees one disease supported by multiple sources.

Connecting These Concepts to Chapter 5

The workflow in Chapter 5 can be viewed as:

Biomedical Sources
        ↓
Identify Entities
        ↓
Identify Relationships
        ↓
Normalize Diseases
        ↓
Construct Knowledge Graph
        ↓
Run Graph Algorithms


The imported graph contains entities such as:

MiRNA
Disease
Target


and relationships such as:

RELATED_TO
REGULATES
HAS_TARGET


The disease reconciliation step attempts normalization by linking similar disease names to a common representation.

This is why the reconciliation phase matters so much:

Breast cancer
breast carcinoma
mammary carcinoma
        ↓
Normalization
        ↓
Single Disease Node


A normalized graph is typically cleaner, less fragmented, and more useful for analysis.

Summary
Concept	Purpose	Graph EquivalentEntity Identification	Find important concepts in text	Nodes
Relationship Extraction	Determine how concepts are connected	Edges
Normalization	Merge equivalent concepts into canonical forms	Entity Resolution

Together these three steps transform text into a knowledge graph:

Text
 ↓
Entities
 ↓
Relationships
 ↓
Normalized Concepts
 ↓
Knowledge Graph


A useful way to remember the progression is:

Entity Identification finds the things. Relationship Extraction finds the connections. Normalization ensures that the same thing is represented only once.

Those three capabilities form the foundation of most modern knowledge graph pipelines, whether they are built using traditional NLP techniques, large language models, or a combination of both.