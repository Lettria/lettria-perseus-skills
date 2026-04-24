---
name: perseus
description: >
  Use when the user wants to build a knowledge graph, extract entities/relations
  from documents, or asks about "perseus", "knowledge graph", "extract entities",
  "graph from files", "graph from text". Orchestrates the full Perseus MCP pipeline.
version: 1.0.0
argument-hint: [file-paths-or-text]
---

# Perseus — Build a Knowledge Graph

Orchestrate the Lettria Perseus MCP pipeline to turn documents or text into a knowledge graph.

Input: $ARGUMENTS

## Tool Reference

See [references/tool-reference.md](references/tool-reference.md) for all 29 MCP tool signatures.

## Workflow

### Step 1: Detect Input Type

Examine `$ARGUMENTS`:

- **File path(s) or directory** (contains `/`, `.txt`, `.pdf`, `.md`, `.docx`, or similar extensions): proceed with `build_graph`.
- **Directory path**: first discover files with a glob for common document types (`.txt`, `.md`, `.pdf`, `.docx`, `.csv`, `.json`, `.html`), then pass the discovered paths to `build_graph`.
- **Inline text** (a sentence or paragraph with no file-like pattern): proceed with `build_graph_from_text`.
- **No arguments**: ask the user what they'd like to extract from — files, a directory, or inline text.

### Step 2: Build Graph(s)

- **From files**: call `build_graph(file_paths=[...])`. If the user provided an ontology path, pass it via `ontology_path`.
- **From text**: call `build_graph_from_text(content=..., name="document.txt")`. If the user provided ontology TTL, pass it via `ontology_ttl`.

Each call returns a graph summary. Note the `graph_id` from each result.

### Step 3: Interlink (if multiple graphs)

If more than one graph was built:

1. Collect all `graph_id` values.
2. Call `interlink_graphs(graph_ids=[...])`.
3. Note the new merged `graph_id`.

### Step 4: Summarize

Call `get_graph_summary(graph_id=...)` on the final graph (merged or single).

Report to the user:
- The `graph_id` (they will need this for follow-up operations)
- Entity count
- Relation count
- Namespace list
- If interlinking occurred, how many source graphs were merged

### Step 5: Offer Next Steps

Present these options to the user:

- **Inspect**: "Want to browse the entities or relations? I can page through them."
- **Export to file**: "I can export as Turtle (TTL) or Cypher (CQL) — which format?"
- **Push to database**: "I can push to Neo4j or FalkorDB if you have one running."
- **Ontology-driven re-extraction**: "Want to constrain extraction with an ontology? Try `/perseus-ontology`."

Do NOT auto-export or auto-push. Wait for the user to choose.

## Rules

- Always report the `graph_id` in your response so the user can reference it later.
- When building from a directory, list the discovered files before building so the user can confirm.
- If `build_graph` or `build_graph_from_text` fails, report the error clearly and suggest checking the file path or API key.
- Keep responses concise — show counts and IDs, not raw graph data, unless the user asks to inspect.
