# Extracting terms for deep context and competency questions

## What Listing 6.16 teaches

[Listing 6.16](./listings/6.16%20-%20Cypher%20-%20significant%20terms%20and%20topic%20descriptions.txt)
does not extract terms directly from text. It ranks previously extracted
keywords within groups of documents. It counts documents in a community that
mention each keyword, divides by the community's document count, and compares
that fraction with the keyword's frequency across the corpus. It then stores
up to 30 high-scoring terms on each community. The score is
`(community_frequency - corpus_frequency) * community_frequency / corpus_frequency`.
Keywords must occur in more than three documents to be considered.

The original listing ran against our Chapter 6 database and set **zero
properties**: there are no `Community` nodes or membership relationships, and
the keyword frequency properties it requires have not been computed. The
preceding Louvain workflow also requires Graph Data Science, which is not
installed. This is a prerequisite issue, not evidence that the articles have
no useful terms.

As a separate, read-only illustration, we applied the same scoring formula
to the existing BBC topic labels instead of Louvain communities, calculating
document frequencies from keyword links. Among the top results were
`shares` for business, `film` for entertainment, `labour` for politics, and
`software` for technology. Less useful results such as `first` and `people`
also ranked highly. These are **topic-based proxy results**, not the output
of Listing 6.16 or a normalization of its missing communities. They show that
statistical distinctiveness is useful for finding candidates, but it does not
by itself establish meaning, importance, or answerability.

## Preferred approach for one 10–15 page document

My preference is a **source-grounded, reviewable extraction pipeline**, not a
single list of frequent keywords. The goal is to retain enough context to
answer competency questions such as “Which conditions trigger a process?” or
“Who approves a change, and what evidence is required?” A term is useful
only insofar as its meaning and role can be traced back to the document.

### 1. Preserve structure and create a reference baseline

Keep the original file unchanged and extract a text version with page
numbers, headings, paragraphs, tables, and list items where possible. Record
a document identifier and version, and assign each text segment a stable
identifier and source location. For scanned PDFs, check OCR quality and
manually review damaged tables, numbers, negations, and headings.

Segment primarily at headings and paragraph boundaries. For retrieval, group
adjacent paragraphs into manageable passages; a starting point is roughly
350–600 tokens with a small overlap, adjusted for the document's structure.
Keep tables and definitions intact where practical. Overlap is for context,
not independent evidence: retain source offsets so duplicated text is not
counted twice.

Before automated extraction, inspect the table of contents and annotate a
small representative sample. Note important definitions, actors, actions,
constraints, and open questions. This baseline helps identify important
one-off terms that frequency-based methods might miss.

### 2. Generate candidates using complementary methods

Use lightweight local NLP to identify noun phrases, named entities,
abbreviations, and candidate keyphrases. TextRank, as used in the chapter, is
a useful candidate generator. Supplement it with heading and definition
patterns, domain terminology supplied by the author, and phrases from sample
competency questions. Preserve multiword terms such as “change approval”
rather than splitting them into unrelated words.

Frequency can help prioritize candidates, but do not apply Listing 6.16's
`n_docs > 3` rule literally to a single document: important concepts may
occur once. If sections are used as a comparison corpus, document clearly
that frequency means *sections*, not independent documents. Deduplicate
overlapping passages before counting. Treat scores as ranking signals, not
probabilities of correctness.

### 3. Capture meaning and relationships, not just terms

For each candidate, store its original wording, proposed canonical name,
aliases or abbreviation expansions, type, definition if explicitly stated,
and one or more exact evidence locations. Types may include actor, process,
artifact, condition, decision, constraint, and measure. Keep uncertain
matches unresolved for review: an acronym can mean different things in
different sections.

Extract relationships as evidence-backed assertions. Record their direction,
participants, conditions, and relevant time or version. Distinguish “may
approve,” “must approve,” and “approved”; a policy or proposal is not evidence
that an event happened. For example, a fictional passage saying “A manager
approves changes after review” could yield:

| Item | Proposed representation |
| --- | --- |
| Terms | `manager` (actor), `change` (artifact), `review` (process) |
| Assertion | manager **approves** change **after** review |
| Evidence | Document version, page, section, and passage offsets |
| Limitation | Does not establish that any particular change was approved |

An LLM can suggest candidates and relations from one passage at a time, but
its output should remain a proposal until checked against the source. Use an
approved local model or an authorized Copilot workflow if appropriate; do not
send confidential document content to an external service without explicit
authorization. No paid API or external service is required for the basic
local extraction and manual review.

### 4. Design and test competency questions

Write questions covering definitions, participants, process sequence,
conditions, exceptions, and evidence. For each question, identify the
expected answer and supporting passage, and whether the document actually
contains enough information. Include at least one unanswerable question:
the correct outcome is an explicit “not established,” not a guess.

Create a small evaluation set separate from the passages used to tune the
extractor. Compare candidate terms and relations with human annotations;
measure recall for important annotated terms and review precision among the
highest-ranked candidates. For question answering, record whether each answer
has supporting evidence, whether conditions and negation are preserved, and
whether unsupported claims or citations occur. Inspect disagreements and
iterate; the right thresholds depend on the document and its use.

### 5. Build a minimal, traceable representation

Start with a table or JSON records, then optionally load reviewed terms,
assertions, passages, and question-to-evidence links into a graph. Keep
document version and provenance on every assertion. Retrieve relevant
passages using terms and aliases, optionally supplemented by local semantic
search, and answer from the retrieved evidence rather than from graph
connectivity alone. Keep the original text available for verification.

For a document of this size, a CPU-based local pipeline and a small set of
reviewed records are a practical starting point; neither GDS nor the
memory-intensive Chapter 5 reconciliation step is necessary. Resource needs
still depend on the model and document. Record what was actually tested,
unresolved ambiguities, and unanswered competency questions rather than
claiming the extraction is complete.
