---
name: perseus-ontology
description: >
  Use when the user wants to create an ontology for Perseus, constrain extraction
  to specific entity types, or asks about "ontology", "typed extraction",
  "constrained extraction", "entity types", "schema for extraction".
version: 1.0.0
argument-hint: [entity-types-or-file-path]
---

# Perseus Ontology — Guided Ontology Workflow

Help the user create or upload an ontology, test it with constrained extraction, iterate, and apply at scale.

Input: $ARGUMENTS

## Starter Template

See [templates/starter-ontology.ttl](templates/starter-ontology.ttl) for the base TTL template.

## Workflow

### Step 1: Determine Ontology Source

Examine `$ARGUMENTS`:

- **Entity type names** (e.g., "Drug Gene Disease", "Person Organization Location"): enter Draft Mode (Step 2).
- **File path** (ends in `.ttl` or `.owl`): skip to Upload (Step 3) using `upload_ontology`.
- **No arguments**: ask the user whether they want to:
  - Draft a new ontology by listing entity types
  - Upload an existing TTL/OWL file
  - See the starter template for reference

### Step 2: Draft Mode

Generate a TTL ontology based on the entity types the user specified:

1. Read the starter template from [templates/starter-ontology.ttl](templates/starter-ontology.ttl).
2. For each entity type name in `$ARGUMENTS`:
   - Define it as `ex:TypeName a rdfs:Class .`
3. Infer plausible relationships between the entity types:
   - e.g., if the user listed "Person" and "Organization", add `ex:worksAt a rdf:Property ; rdfs:domain ex:Person ; rdfs:range ex:Organization .`
   - If the user listed "Drug" and "Disease", add `ex:treats a rdf:Property ; rdfs:domain ex:Drug ; rdfs:range ex:Disease .`
4. Show the generated TTL to the user and ask if they want to adjust it before uploading.

### Step 3: Upload

- **Inline TTL** (from Draft Mode or user-provided text): call `upload_ontology_from_text(content=..., name="ontology.ttl")`.
- **File path**: call `upload_ontology(ontology_path=...)`.

Report the ontology ID and status.

### Step 4: Test Extraction

Ask the user for a sample document or text to test against. Then:

1. If they provide text: call `build_graph_from_text(content=..., ontology_ttl=<the TTL from above>)`.
2. If they provide a file: call `build_graph(file_paths=[...], ontology_path=<path>)`.
3. Call `get_graph_summary(graph_id=...)` and `get_graph_entities(graph_id=...)` on the result.

Present the results:
- Entity count and types — are they the types defined in the ontology?
- Relation count and types — do they match the ontology's properties?
- Any surprising or missing extractions?

### Step 5: Iterate

Ask the user:
- "Want to add or remove entity types?"
- "Want to add properties or change relationship definitions?"
- "Want to re-run on the same sample?"

If yes, go back to Step 2 (re-draft) or Step 3 (re-upload) and repeat. Each iteration should show the before/after comparison — how the graph changed with the updated ontology.

### Step 6: Apply at Scale

Once the user is satisfied:
- Offer to run `build_graph(file_paths=[...], ontology_path=...)` across a batch of files.
- If multiple graphs result, offer to `interlink_graphs`.
- Suggest export options (TTL, CQL, Neo4j, FalkorDB).

## Rules

- Always show the generated TTL to the user before uploading — never upload silently.
- When showing test extraction results, highlight whether entity types match the ontology (this is the core value prop).
- Keep the iteration loop tight — minimize steps between "edit ontology" and "see results."
- If the user provides domain-specific entity types you're unfamiliar with, generate the class definitions but flag that the inferred relationships are guesses and should be reviewed.
