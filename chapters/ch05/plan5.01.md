# Chapter 5.1 Working Plan

## Section focus

- Study the Rockefeller Foundation program officers' diaries as a source of unstructured, domain-specific historical knowledge.
- Adapt machine-learning methods to extract entities, relationships, and patterns from the diaries.
- Use the extracted information later to construct a knowledge graph and answer complex relational questions.

## Questions to investigate

- Which patterns tend to precede the funding of an idea?
- Which grants follow recommendations from influential scientists or previous grantees?
- How many internal discussions occur before a grant is awarded?
- Which research subdisciplines receive funding, and how does that change over time?

## Domain-specific NLP requirements

- Generic entity categories such as Person, Location, and Organization are insufficient for this domain.
- The model must identify conversation topics as well as people and organizations.
- A Topic entity must distinguish three subtypes:
  - Research discipline
  - Technology
  - Disease

## Exercise: diary entities and relations

Source: [Warren Weaver diary, page 5](../../data/ch8_rac_ww_1939.json),
entry dated January 9, 1939. These are selected assertions, not a complete
transcription:

| Entity or mention | Type | Evidence |
| --- | --- | --- |
| Dr. W. F. Ross | Person | Entry heading |
| Radcliffe College | Organization | Entry heading and laboratory discussion |
| Harvard | Organization | Ross's faculty appointment |
| Cambridge, Massachusetts | Location | Entry heading |
| Biochemistry | Topic: research discipline | His faculty appointment and weekly seminar |
| Spectroscopic study | Topic: technology or method | His thesis on protein constituents |

Supported relations include Ross's joint appointment at Harvard and
Radcliffe, Radcliffe furnishing funds for equipment, and Ross and others
organizing a weekly biochemistry seminar. Weaver indicates a willingness to
consider support for research assistants; this is not evidence that a grant
was awarded.

Represent a discussion or funding decision as an event with its date,
participants, topic, and source passage. This preserves who said what and
avoids turning a proposal into an award. The topic hierarchy includes
research discipline, technology, and disease; the selected passage does not
provide an example of a disease.

### Generic versus domain-specific extraction

Generic person, organization, and location categories can capture some
participants and institutions, but cannot distinguish biochemistry as a
research discipline from a spectroscopic method or a disease. A
domain-specific schema adds these topic subtypes and the event and funding
relations. This is a schema comparison, not a measured model evaluation:
the generic model has not been run on this entry.

Keep the original mention and source span alongside any normalized entity.
For example, "R." refers to Ross in this entry, but should be linked using
the entry context rather than globally equated with every "R." mention.
Record uncertain or unresolved matches for review instead of asserting them
as facts.

## Exercise: Listing 5.6

[Listing 5.6](./listings/5.6%20-%20Compute%20the%20ingested%20miRNAs%20distribution)
was run against the imported `hmdd2.0` graph without disease reconciliation.
It returned 3,903 miRNA nodes across 21 label combinations. The largest
combination was `MiRNA_dbDEMC` and `MiRNA_RDB`: 1,741 nodes.

Individual source-label membership counts, which overlap, were:

| Source label | miRNA nodes |
| --- | ---: |
| `MiRNA_dbDEMC` | 3,545 |
| `MiRNA_RDB` | 2,575 |
| `MiRNA_miRBase` | 1,370 |
| `MiRNA_HMDD` | 1,206 |
| `MiRNA_miR2Disease` | 459 |

Listing rows count exact label combinations, so they sum to 3,903; individual
source counts do not sum to the number of distinct nodes. These biomedical
datasets are a separate structured-data example from the archival diary.
Verification of `REPRESENTS` links remains blocked until reconciliation can
run; no normalized disease links were produced in the attempted run.