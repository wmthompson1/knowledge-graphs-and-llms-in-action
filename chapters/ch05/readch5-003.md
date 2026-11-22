source: ai return in ongoing research:
williamt

# Chapter 5: Build a Knowledge Graph from Structured Sources

## Reading objective

Learn how to transform structured and unstructured domain data into a knowledge
graph that supports questions about entities, relationships, and patterns.

The chapter's working example uses Rockefeller Foundation program officers'
diaries. Their notes contain valuable historical information, but the language
is abbreviated, domain-specific, and difficult for generic NLP models to
interpret.

## Reading preparation

Before beginning:

- Review [plan5.01.md](./plan5.01.md) for the current section outline and
  accumulated notes.
- Keep these entity types in mind:
  - Person
  - Organization
  - Location
  - Topic
- Distinguish the three `Topic` subtypes:
  - Research discipline
  - Technology
  - Disease

As the chapter progresses, add:

- Important concepts and definitions
- Domain-specific entities and relationships
- Extraction and normalization steps
- Graph schema decisions
- Questions the resulting graph should answer
- Code examples and validation exercises

## Questions to keep in mind

- What patterns tend to precede the funding of an idea?
- Do funded projects follow recommendations from influential scientists or
  previous grantees?
- How many internal discussions occur before a grant is awarded?
- How does funding of research subdisciplines change over time?
- Which relationships in the source text must be preserved in the graph?
- What information cannot be captured accurately by generic named-entity
  categories?

## Repository study workflow

1. Read the next section or excerpt.
2. Summarize its main idea and terminology.
3. Add section-specific working notes to [plan5.01.md](./plan5.01.md).
4. Connect the concept to the importer, reconciliation, or graph-modeling code
   in this chapter when applicable.
5. Run the relevant example or validation command and record the result.

## Practical focus

The code in this directory demonstrates how to:

- Install the chapter dependencies.
- Download disease and microRNA datasets.
- Import structured data into Neo4j.
- Reconcile diseases across datasets.

This practical material complements the chapter's broader lesson: a useful
knowledge graph requires both the extracted facts and domain-aware modeling of
their meaning.

## Exercises

- [ ] Identify the entities and relations present in a sample diary entry.
- [ ] Extend a generic entity schema with the three `Topic` subtypes.
- [ ] Compare generic entity extraction with domain-specific extraction.
- [ ] Decide how ambiguous or abbreviated mentions should be represented.
- [ ] Run the chapter's import pipeline.
- [ ] Verify that reconciled entities link to the intended source records.