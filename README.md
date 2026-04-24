# Lettria Perseus Skills for Claude Code

Claude Code skills that orchestrate the [Lettria Perseus MCP server](https://github.com/jalakoo/lettria-perseus-mcp) into guided, high-level workflows. Type a slash command, and Claude chains the right MCP tools in the right order.

## Table of Contents

- [Skills](#skills)
  - [/perseus — Build a Knowledge Graph](#perseus--build-a-knowledge-graph)
  - [/perseus-ontology — Ontology-Driven Extraction](#perseus-ontology--ontology-driven-extraction)
  - [/perseus-neo4j — Push to Neo4j](#perseus-neo4j--push-to-neo4j)
  - [/perseus-falkordb — Push to FalkorDB](#perseus-falkordb--push-to-falkordb)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
  - [Quick setup (recommended)](#quick-setup-recommended)
  - [Manual setup](#manual-setup)
- [Usage Examples](#usage-examples)
- [Project Structure](#project-structure)
- [Tool Reference](#tool-reference)
- [License](#license)

---

## Skills

### /perseus — Build a Knowledge Graph

The primary workflow. Takes files, a directory, or inline text and produces a knowledge graph.

```
/perseus ./docs/
/perseus "Marie Curie was born in Warsaw, Poland..."
```

**What it does:**
1. Detects input type (file paths vs. inline text)
2. Builds one graph per source via `build_graph` or `build_graph_from_text`
3. Interlinks graphs automatically if multiple sources were provided
4. Summarizes the result (entity/relation counts, graph ID)
5. Offers next steps: inspect, export (TTL/CQL), or push to a database

### /perseus-ontology — Ontology-Driven Extraction

Guides you through creating or uploading an ontology, testing constrained extraction, and iterating until the graph is clean.

```
/perseus-ontology Drug Gene Disease
/perseus-ontology ./my-ontology.ttl
```

**What it does:**
1. Drafts a TTL ontology from entity type names (or accepts an existing file)
2. Uploads via `upload_ontology_from_text` or `upload_ontology`
3. Runs a test extraction on sample text
4. Shows results — highlights whether entity types match the ontology
5. Supports iterative refinement: edit, re-upload, re-extract
6. Applies the final ontology to a batch of files at scale

Includes a [starter ontology template](perseus-ontology/templates/starter-ontology.ttl) with common entity types and relationships.

### /perseus-neo4j — Push to Neo4j

End-to-end pipeline from documents to a populated Neo4j database.

```
/perseus-neo4j ./docs/
/perseus-neo4j              # reuse graphs from current session
```

**What it does:**
1. Checks Neo4j prerequisites (`NEO4J_URI`, `NEO4J_USER`, `NEO4J_PASSWORD`)
2. Builds or reuses graphs
3. Interlinks if multiple graphs
4. **Asks for confirmation** before pushing (shows graph summary + target)
5. Pushes to Neo4j via `save_graph_to_neo4j`
6. Exports a CQL backup file
7. Suggests sample Cypher queries for Neo4j Browser

### /perseus-falkordb — Push to FalkorDB

Same workflow as `/perseus-neo4j`, targeting FalkorDB instead.

```
/perseus-falkordb ./docs/
/perseus-falkordb           # reuse graphs from current session
```

Requires `FALKORDB_HOST`, `FALKORDB_PORT`, `FALKORDB_USERNAME`, `FALKORDB_PASSWORD`, and `FALKORDB_GRAPH_NAME` env vars in the MCP server's environment.

---

## Prerequisites

**Required tools:**

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) — install with `npm install -g @anthropic-ai/claude-code`
- [uv](https://docs.astral.sh/uv/) (Python package manager) — install with `curl -LsSf https://astral.sh/uv/install.sh | sh`

The Lettria Perseus MCP server must be registered in your Claude Code config before these skills can work:

```bash
claude mcp add lettria-perseus -e PERSEUS_API_KEY=sk-... -- \
  uvx --from git+https://github.com/jalakoo/lettria-perseus-mcp.git lettria-perseus-mcp
```

For database skills, add the relevant env vars:

```bash
# Neo4j
claude mcp add lettria-perseus \
  -e PERSEUS_API_KEY=sk-... \
  -e NEO4J_URI=bolt://localhost:7687 \
  -e NEO4J_USER=neo4j \
  -e NEO4J_PASSWORD=password \
  -- uvx --from git+https://github.com/jalakoo/lettria-perseus-mcp.git lettria-perseus-mcp

# FalkorDB
claude mcp add lettria-perseus \
  -e PERSEUS_API_KEY=sk-... \
  -e FALKORDB_HOST=localhost \
  -e FALKORDB_PORT=6379 \
  -e FALKORDB_USERNAME=default \
  -e FALKORDB_PASSWORD=password \
  -e FALKORDB_GRAPH_NAME=perseus \
  -- uvx --from git+https://github.com/jalakoo/lettria-perseus-mcp.git lettria-perseus-mcp
```

---

## Installation

### Quick setup (recommended)

A single script that registers the MCP server **and** installs the skills:

```bash
git clone https://github.com/jalakoo/lettria-perseus-skills.git
cd lettria-perseus-skills
./setup.sh
```

The script will prompt for your Perseus API key and optionally collect Neo4j / FalkorDB credentials.

### Manual setup

If you prefer to run the steps yourself:

**Step 1 — Register the MCP server** (see [Prerequisites](#prerequisites) for database-specific env vars):

```bash
claude mcp add lettria-perseus -e PERSEUS_API_KEY=sk-... -- \
  uvx --from git+https://github.com/jalakoo/lettria-perseus-mcp.git lettria-perseus-mcp
```

**Step 2 — Install the skills** by symlinking into `~/.claude/skills/`:

```bash
git clone https://github.com/jalakoo/lettria-perseus-skills.git

ln -s /path/to/lettria-perseus-skills/perseus ~/.claude/skills/perseus
ln -s /path/to/lettria-perseus-skills/perseus-ontology ~/.claude/skills/perseus-ontology
ln -s /path/to/lettria-perseus-skills/perseus-neo4j ~/.claude/skills/perseus-neo4j
ln -s /path/to/lettria-perseus-skills/perseus-falkordb ~/.claude/skills/perseus-falkordb
```

After installation, the skills appear in `/help` and Claude can auto-invoke them based on context.

---

## Usage Examples

**Quick graph from a folder:**
```
/perseus ./research-papers/
```

**Ontology-driven medical extraction:**
```
/perseus-ontology Drug Gene Disease ClinicalTrial
```
Then provide a PubMed abstract to test against.

**Documents straight to Neo4j:**
```
/perseus-neo4j ./sec-filings/
```
Claude builds, interlinks, confirms, pushes, and suggests Cypher queries.

**Inline text, no files needed:**
```
/perseus "SpaceX was founded by Elon Musk in 2002. Tesla was founded in 2003."
```

---

## Project Structure

```
lettria-perseus-skills/
├── README.md
├── LICENSE
├── .gitignore
├── perseus/
│   ├── SKILL.md                     # /perseus — primary build workflow
│   └── references/
│       └── tool-reference.md        # All 29 MCP tool signatures
├── perseus-ontology/
│   ├── SKILL.md                     # /perseus-ontology — ontology workflow
│   └── templates/
│       └── starter-ontology.ttl     # Customizable TTL template
├── perseus-neo4j/
│   └── SKILL.md                     # /perseus-neo4j — Neo4j push workflow
└── perseus-falkordb/
    └── SKILL.md                     # /perseus-falkordb — FalkorDB push workflow
```

---

## Tool Reference

The full reference for all 29 Perseus MCP tools (parameters, types, defaults, return values) is in [`perseus/references/tool-reference.md`](perseus/references/tool-reference.md).

---

## License

[MIT](LICENSE)
