# Chapter 6 ontology notebook

This is a working notebook, not a finished ontology. It connects the chapter's
extraction and graph-analysis listings to candidate concepts, proposed
classes and properties, source evidence, and competency questions. Candidate
models and automated labels require review before use.

The chapter's BBC news corpus, the synthetic spaCy example, and the
Rockefeller Archive Center (RAC) diary are **different sources**. Do not combine
their statements as if they were one dataset.

## How to use this notebook

For each new passage or listing, record the original term, context, proposed
meaning, modeling choice, evidence location, and a question the representation
should answer. Record rejected interpretations and unresolved identities
instead of silently normalizing them. A candidate may later become an OWL
class, an individual, an object or datatype property, or a lexical label;
the term alone does not determine which.

Use the following status convention: **observed** means the wording occurs in
the cited source; **candidate** means a proposed interpretation or model;
**unresolved** means the available evidence is insufficient. Neither an
automated label nor an observed mention establishes a real-world claim.

## Listings 6.1–6.3: parsing and entity recognition

Executed the repository scripts with spaCy 3.6.1 and `en_core_web_sm` 3.6.0.
Their `displacy.serve` calls were replaced at runtime with `displacy.render`
to exercise visualization without starting a web server. The input is the
**invented sentence** in the listings, not historical evidence.

| Listing | Observed result | Interpretation |
| --- | --- | --- |
| [6.1](./listings/6.1%20-%20NLP%20with%20dependency%20parsing.py) | `Austen` is `nsubj` of `works`; `writer` is `appos` of `Austen`; `Google` is `pobj` of `for`. | Grammatical relations suggest candidate assertions; they do not prove their truth. |
| [6.2](./listings/6.2%20-%20NER%20pipeline.py) | `Jane Austen` → `PERSON`, `Victorian` → `NORP`, `Google` → `ORG`. | Generic model labels are extraction results, not validated ontology classes. |
| [6.3](./listings/6.3%20-%20Dictionary-based%20NER.py) | The same entities plus `writer` → custom `TITLE`. | The lemma rule adds a domain-specific label; spaCy has no built-in glossary explanation for `TITLE` and prints `None`. |

Listing 6.3 labels the occupation word `writer` as `TITLE`. A model could
instead represent writing as an occupation or role; a particular title or
appointment may have its own dates and context. This distinction is a design
choice, not something established by the label. The example's claim that Jane
Austen works for Google is deliberately not accepted as a historical fact.

### Candidate terms from the example

| Extracted term and evidence | Candidate concept | Possible class / property | Status and competency question |
| --- | --- | --- | --- |
| `Jane Austen` in [6.2](./listings/6.2%20-%20NER%20pipeline.py) | Person mentioned in a sentence | `Person`; a particular person is an individual, not the class | Observed mention; **Which person does this sentence mention?** |
| `writer` in [6.3](./listings/6.3%20-%20Dictionary-based%20NER.py) | Occupation or role | `Occupation` or `Role`; `hasOccupation` or a contextual role assertion | Candidate; **Which occupation is attributed to the person in the sentence?** |
| `Google` in [6.2](./listings/6.2%20-%20NER%20pipeline.py) | Organization mentioned in a sentence | `Organization` | Observed mention; **Which organization is named?** |
| `works ... for` in [6.1](./listings/6.1%20-%20NLP%20with%20dependency%20parsing.py) | Claimed employment relationship | `Employment` event or `worksFor` property | Candidate from synthetic text only; **What relationship does the sentence claim?** |

`Victorian` is an observed `NORP` label, but whether it denotes a historical
period or something else in context requires review. It should not be made
an ontology class just because the model emitted a label.

## Source-grounded diary example

Source: [Warren Weaver diary JSON](../../data/ch8_rac_ww_1939.json),
record `Warren Weaver_Diary_1939-1940_5`, `page_idx` 5, entry dated
January 9, 1939. These are selected examples, not a complete extraction.
The source is OCR text, so retain its wording and review transcription
errors against page images when available.

| Extracted term and source evidence | Candidate concept | Possible class / property | Status and competency question |
| --- | --- | --- | --- |
| `Dr. W. F. Ross` in the entry heading | Person | `Person`; retain the exact mention separately using `Mention` and `refersTo` | Observed mention; **Who is named in the entry?** |
| `R.` after the Ross heading | Abbreviated mention of Ross | `Mention` with a proposed `refersTo` link | Candidate resolution based on this entry's context; **Which mentions may refer to Ross, and what supports the link?** Do not globally equate all `R.` mentions. |
| `Radcliffe College`; `Harvard` | Organizations | `Organization`; `hasParticipant` or `heldAt` on an appointment | Observed mentions; **Which institutions are associated with Ross's appointment?** |
| `Faculty Instructor in biochemistry` and `joint appointment with Radcliffe` | Appointment; occupation or discipline | `Appointment`, `ResearchDiscipline`; `hasAppointee`, `atOrganization`, `hasDiscipline` | Candidate representation; **What appointment and discipline does the entry describe?** |
| `spectroscopic study` in the thesis description | Research method | `ResearchMethod`; `usesMethod` on a study | Candidate; **What method is described in the thesis?** |
| `weekly seminar for biochemistry` | Recurring scholarly activity | `Seminar`, potentially an `EventSeries`; `hasTopic` | Candidate; **What recurring activity is described, and what is its topic?** |
| `prepared to consider the question of research assistants` | Consideration of possible support | `FundingConsideration`; `concerns` and `hasSourceEvidence` | Observed wording, modeled as a proposal; **What support was considered, and was an award established?** |

The source says the appointment is joint and that a seminar was organized.
It does **not** establish that a grant was awarded for research assistants.
Person identity, precise dates of appointments, and participants in each
discussion require additional evidence. Keep the date of the diary entry
separate from any uncertain date of an underlying event.

## Listings 6.10–6.16: graph analysis and evidence

These queries use the separate [BBC corpus](../../data/bbc/) and the existing
isolated `chapter6-news` database, not the RAC diary. They were run without
persisting mutations. The repository has no listings 6.4–6.9 in this folder.

| Listing | Execution and result | Ontology / interpretation note |
| --- | --- | --- |
| [6.10](./listings/6.10%20-%20Cypher%20-%20remove%20meaningless%20keywords.txt) | Original query in a transaction: 5 keyword nodes and 711 relationships would be deleted; rolled back. | Removing a keyword is a preprocessing decision, not proof it is meaningless in every domain. Source documents were not removed. |
| [6.11](./listings/6.11%20-%20Cypher%20-%20Jaccard%20similarities.txt) | Added `n.id = 'business_173'` to bound the original query. It created 8 similarity relationships in a temporary transaction. | Jaccard compares keyword sets; similarity is not identity, shared authorship, causation, or semantic equivalence. The deletion in 6.10 was rolled back first, so these results include any keywords 6.10 would have removed. |
| [6.12](./listings/6.12%20-%20Cypher%20-%20get%20similar%20documents.txt) | Ran the original query within the 6.11 transaction: 27 shared-keyword path rows, then rolled back. | Each row is a path through one shared keyword, not a distinct similar-document count. |
| [6.13](./listings/6.13%20-%20Cypher%20-%20graph%20projection%20for%20GDS.txt) | Attempted; `gds.graph.project` is not installed. | A projection is an analytical view, not a new factual claim. |
| [6.14](./listings/6.14%20-%20Cypher%20-%20run%20Louvain%20algorithm.txt) | Attempted; `gds.louvain.write` is not installed. | No Louvain communities or modularity results were produced. |
| [6.15](./listings/6.15%20-%20Cypher%20-%20assign%20documents%20to%20communities.txt) | Original query ran in a rolled-back transaction; no updates because no documents had a community value. | Communities would be algorithm-dependent groupings, not automatically domain classes. |
| [6.16](./listings/6.16%20-%20Cypher%20-%20significant%20terms%20and%20topic%20descriptions.txt) | Original query ran in a rolled-back transaction; no updates. Community memberships and keyword document-frequency properties are absent. | Significance ranks existing keywords; it does not extract new terms or establish meaning. See the [term-extraction report](./term-extraction-for-competency-questions.md) for a separately labeled topic-based proxy. |

After rollback, the five selected keyword nodes still existed, and there were
zero persisted `SIMILAR_TO` relationships. The database had 2,225 documents,
zero `Community` nodes, zero GDS procedures, and no keywords with either
required frequency property. Installing GDS or creating communities was
outside this safe run.

### A similarity example is not an ontological identity

The bounded 6.11 run found `business_247` most similar to `business_173`
at **0.0909** Jaccard similarity. Listing 6.12 returned shared keywords
including `sales`, `europe`, `western europe`, `net profits`, and
`strong sales`.

| Extracted term / source evidence | Candidate concept | Possible class / property | Competency question |
| --- | --- | --- | --- |
| `Heineken`, `Carlsberg`; the source reports falling profits in [business/173.txt](../../data/bbc/business/173.txt) | Organizations and reported financial results | `Organization`, `FinancialResult`, `reportedFor` | **Which brewers does this article discuss?** |
| `Renault`; the source reports increased profits in [business/247.txt](../../data/bbc/business/247.txt) | Another organization and reported result | `Organization`, `FinancialResult`, `reportedFor` | **Which company does the second article discuss?** |
| Shared keyword `western europe` in the temporary graph paths | Region mentioned by both documents | `Region`, `mentionsRegion` | **Which region appears in both articles?** Review wording and context in each source. |
| `net profits` and `strong sales` in the temporary graph paths | Financial measures / statements | `FinancialMeasure` or a contextual result; `hasMeasure` | **Do the articles report the same direction of profit change?** No: the first reports declines for the brewers, the second a rise for Renault. |

Both articles discuss financial performance, but the overlap does not make
the companies, their results, or the articles equivalent. The result is a
retrieval lead requiring source review, not a factual relation between them.

## Competency-question checklist

| Question | Current answer / evidence | Modeling implication |
| --- | --- | --- |
| Who is named in the January 9 diary entry? | W. F. Ross; diary record 5 heading. | Preserve source mention and a proposed person separately. |
| Which institutions are associated with his joint appointment? | Harvard and Radcliffe; diary record 5 appointment passage. | Represent the appointment and participating organizations. |
| Was support for research assistants awarded? | **Not established**; the entry says it could be considered. | Distinguish consideration, recommendation, decision, and award. |
| Which keyword links the two BBC articles geographically? | `western europe` appears in the temporary 6.12 path; review both article passages. | Link mentions and source documents; do not infer identity. |
| Did Ross's seminar cause a grant to be awarded? | **Not established** by the selected diary passage. | Do not infer causation or influence from co-occurrence or graph paths. |

For future entries, add a source identifier and version, page or section,
exact passage, candidate interpretation and status, possible OWL model,
competency question, expected answer or explicit unknown, and any review
decision. A document mention is evidence of what the source says, not
automatic proof that the described event occurred.
