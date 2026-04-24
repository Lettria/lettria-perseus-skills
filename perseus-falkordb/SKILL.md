---
name: perseus-falkordb
description: >
  Use when the user wants to push a knowledge graph to FalkorDB, or asks about
  "falkordb", "falkor", "push to falkordb". Covers build, interlink, push, and verify.
version: 1.0.0
argument-hint: [file-paths-or-graph-id]
---

# Perseus FalkorDB — Documents to FalkorDB Pipeline

Build a knowledge graph and push it to a running FalkorDB instance.

Input: $ARGUMENTS

## Workflow

### Step 1: Check Prerequisites

Verify that the FalkorDB environment variables are configured. The MCP server reads these from its environment — if they're missing, the push will fail.

Required env vars:
- `FALKORDB_HOST` (e.g., `localhost`)
- `FALKORDB_PORT` (e.g., `6379`)
- `FALKORDB_USERNAME`
- `FALKORDB_PASSWORD`
- `FALKORDB_GRAPH_NAME` (e.g., `perseus`)

If you cannot verify these (they are set in the MCP server's env, not necessarily in the current shell), warn the user: "Make sure `FALKORDB_HOST`, `FALKORDB_PORT`, `FALKORDB_USERNAME`, `FALKORDB_PASSWORD`, and `FALKORDB_GRAPH_NAME` are set in the MCP server's environment. If the push fails with a connection error, check these values."

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

Before pushing to FalkorDB:

1. Call `get_graph_summary(graph_id=...)` and display:
   - Entity count
   - Relation count
   - Namespace list
2. State the target: "This will push to FalkorDB at the host/graph configured in the MCP server."
3. Ask: **"Ready to push this graph to FalkorDB? (yes/no)"**
4. **Do NOT call `save_graph_to_falkordb` unless the user explicitly confirms with "yes."**

### Step 5: Push to FalkorDB

Call `save_graph_to_falkordb(graph_id=...)`.

Report success and the target database/graph name.

### Step 6: Backup Export

After a successful push, export a portable backup:

Call `export_graph_cql(graph_id=..., output_path="./perseus_falkordb_backup.cql")`.

Tell the user: "Exported a CQL backup to `./perseus_falkordb_backup.cql` — you can replay this into any compatible graph database."

### Step 7: Suggest Queries

Provide sample Cypher queries the user can run against FalkorDB:

```cypher
-- Count nodes by label
MATCH (n) RETURN labels(n) AS label, count(n) AS count ORDER BY count DESC

-- Count relationships by type
MATCH ()-[r]->() RETURN type(r) AS type, count(r) AS count ORDER BY count DESC

-- Find most connected nodes
MATCH (n)-[r]-() RETURN n, count(r) AS connections ORDER BY connections DESC LIMIT 10
```

## Rules

- The confirmation gate in Step 4 is mandatory. Never push without explicit user approval.
- Always export a CQL backup after pushing — this is a safety net.
- If `save_graph_to_falkordb` fails, report the error and suggest checking FalkorDB connection settings.
- Keep the user informed at each step — show graph summaries, not raw data.
