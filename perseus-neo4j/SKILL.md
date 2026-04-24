---
name: perseus-neo4j
description: >
  Use when the user wants to push a knowledge graph to Neo4j, or asks about
  "neo4j", "graph database", "push to neo4j", "visualize in neo4j".
  Covers build, interlink, push, and verify.
version: 1.0.0
argument-hint: [file-paths-or-graph-id]
---

# Perseus Neo4j — Documents to Neo4j Pipeline

Build a knowledge graph and push it to a running Neo4j instance.

Input: $ARGUMENTS

## Workflow

### Step 1: Check Prerequisites

Verify that the Neo4j environment variables are configured. The MCP server reads these from its environment — if they're missing, the push will fail.

Required env vars:
- `NEO4J_URI` (e.g., `bolt://localhost:7687`)
- `NEO4J_USER` (e.g., `neo4j`)
- `NEO4J_PASSWORD`

If you cannot verify these (they are set in the MCP server's env, not necessarily in the current shell), warn the user: "Make sure `NEO4J_URI`, `NEO4J_USER`, and `NEO4J_PASSWORD` are set in the MCP server's environment. If the push fails with a connection error, check these values."

### Step 2: Build or Reuse Graphs

Examine `$ARGUMENTS`:

- **File paths or directory**: build graphs using `build_graph(file_paths=[...])`.
- **Graph ID** (12-char hex string): reuse an existing graph from the session.
- **No arguments**: call `list_local_graphs()` to check for existing graphs.
  - If graphs exist, ask the user which one(s) to push.
  - If none exist, ask for file paths or text to build from.

### Step 3: Interlink (if multiple graphs)

If more than one graph was built or selected:
1. Call `interlink_graphs(graph_ids=[...])`.
2. Use the merged `graph_id` going forward.

### Step 4: Confirmation Gate

**MANDATORY — do NOT skip this step.**

Before pushing to Neo4j:

1. Call `get_graph_summary(graph_id=...)` and display:
   - Entity count
   - Relation count
   - Namespace list
2. State the target: "This will push to Neo4j at the URI configured in the MCP server."
3. Ask: **"Ready to push this graph to Neo4j? (yes/no)"**
4. **Do NOT call `save_graph_to_neo4j` unless the user explicitly confirms with "yes."**

### Step 5: Push to Neo4j

Call `save_graph_to_neo4j(graph_id=...)`.

Report success and the target database name.

### Step 6: Backup Export

After a successful push, export a portable backup:

Call `export_graph_cql(graph_id=..., output_path="./perseus_neo4j_backup.cql")`.

Tell the user: "Exported a CQL backup to `./perseus_neo4j_backup.cql` — you can replay this into any Neo4j instance."

### Step 7: Suggest Queries

Provide sample Cypher queries the user can run in Neo4j Browser:

```cypher
-- Count nodes by label
MATCH (n) RETURN labels(n) AS label, count(n) AS count ORDER BY count DESC;

-- Count relationships by type
MATCH ()-[r]->() RETURN type(r) AS type, count(r) AS count ORDER BY count DESC;

-- Find most connected nodes
MATCH (n)-[r]-() RETURN n, count(r) AS connections ORDER BY connections DESC LIMIT 10;
```

## Rules

- The confirmation gate in Step 4 is mandatory. Never push without explicit user approval.
- Always export a CQL backup after pushing — this is a safety net.
- If `save_graph_to_neo4j` fails, report the error and suggest checking Neo4j connection settings.
- Keep the user informed at each step — show graph summaries, not raw data.
