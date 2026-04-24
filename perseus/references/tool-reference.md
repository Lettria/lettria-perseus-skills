# Perseus MCP Tools Reference

Quick-reference for all 29 tools exposed by the `lettria-perseus-mcp` server.

## Graph Building (3 tools)

### build_graph

Build knowledge graphs from local files.

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `file_paths` | `list[str]` | yes | — | Local file paths for source documents |
| `ontology_path` | `str` | no | `None` | Path to TTL/OWL ontology file |
| `refresh_graph` | `bool` | no | `False` | Bypass caching and re-process |
| `metadata` | `dict` | no | `None` | Arbitrary metadata |

**Returns:** List of graph summaries with `graph_id`, entity/relation counts, namespaces.

### build_graph_from_text

Build a knowledge graph from inline text.

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `content` | `str` | yes | — | Raw document text |
| `name` | `str` | no | `"document.txt"` | Filename hint for temp file |
| `ontology_ttl` | `str` | no | `None` | Ontology TTL as inline string |
| `refresh_graph` | `bool` | no | `False` | Bypass caching |
| `metadata` | `dict` | no | `None` | Arbitrary metadata |

**Returns:** Graph summary. Raises `ValueError` if content exceeds size limit (default 1 MiB).

### interlink_graphs

Merge multiple graphs into one by matching entities.

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `graph_ids` | `list[str]` | yes | — | Graph IDs to merge (minimum 2) |
| `interlinking_key_uris` | `list[str]` | no | `[rdfs:label]` | Property URIs for entity matching |
| `immutable_properties` | `list[str]` | no | `None` | Properties preserved on conflict |
| `merge_properties_on_conflict` | `bool` | no | `False` | Merge vs. overwrite on conflict |

**Returns:** Merged graph summary with new `graph_id`.

---

## Local Registry (6 tools)

### list_local_graphs

List all graphs held in server memory.

No parameters.

**Returns:** Count and list of all graph IDs.

### get_graph_summary

Get entity/relation/document counts for a graph.

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `graph_id` | `str` | yes | — | Graph identifier |

**Returns:** Entity count, relation count, namespace list.

### get_graph_entities

Retrieve entities from a graph with pagination.

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `graph_id` | `str` | yes | — | Graph identifier |
| `offset` | `int` | no | `0` | Pagination offset |
| `limit` | `int` | no | `50` | Pagination limit |

**Returns:** Paginated entity list with `total`, `offset`, `limit` metadata.

### get_graph_relations

Retrieve relations from a graph with pagination.

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `graph_id` | `str` | yes | — | Graph identifier |
| `offset` | `int` | no | `0` | Pagination offset |
| `limit` | `int` | no | `50` | Pagination limit |

**Returns:** Paginated relation list with `total`, `offset`, `limit` metadata.

### forget_graph

Remove a single graph from server memory.

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `graph_id` | `str` | yes | — | Graph identifier |

**Returns:** Confirmation of removal.

### forget_all_graphs

Remove all graphs from server memory.

No parameters.

**Returns:** Count of graphs removed.

---

## Exports (4 tools)

### export_graph_ttl

Export a graph as a Turtle (TTL) file.

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `graph_id` | `str` | yes | — | Graph identifier |
| `output_path` | `str` | yes | — | Disk path for TTL output |

**Returns:** Graph ID and absolute output path.

### export_graph_cql

Export a graph as Cypher (CQL) statements.

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `graph_id` | `str` | yes | — | Graph identifier |
| `output_path` | `str` | yes | — | Disk path for CQL output |
| `strip_prefixes` | `bool` | no | `True` | Strip RDF prefixes from labels |

**Returns:** Graph ID and absolute output path.

### save_graph_to_neo4j

Push a graph directly to a running Neo4j instance.

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `graph_id` | `str` | yes | — | Graph identifier |
| `strip_prefixes` | `bool` | no | `True` | Strip RDF prefixes from labels |

**Returns:** Confirmation and target database name. Requires `NEO4J_URI`, `NEO4J_USER`, `NEO4J_PASSWORD` env vars.

### save_graph_to_falkordb

Push a graph directly to a running FalkorDB instance.

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `graph_id` | `str` | yes | — | Graph identifier |
| `strip_prefixes` | `bool` | no | `True` | Strip RDF prefixes from labels |

**Returns:** Confirmation and target database name. Requires `FALKORDB_HOST`, `FALKORDB_PORT`, `FALKORDB_USERNAME`, `FALKORDB_PASSWORD`, `FALKORDB_GRAPH_NAME` env vars.

---

## Remote Files (4 tools)

### upload_file

Upload a source document to the Perseus API.

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `file_path` | `str` | yes | — | Local path to source document |
| `wait` | `bool` | no | `True` | Wait for processing completion |

**Returns:** File metadata (id, status).

### list_files

List remote files with optional filters.

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `ids` | `list[str]` | no | `None` | Filter by file IDs |
| `source_hashes` | `list[str]` | no | `None` | Filter by source hashes |

**Returns:** Count and list of files.

### get_file

Fetch a single file record.

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `file_id` | `str` | yes | — | File identifier |

**Returns:** File metadata or `None`.

### delete_file

Delete a remote file.

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `file_id` | `str` | yes | — | File identifier |

**Returns:** Confirmation of deletion.

---

## Remote Ontologies (5 tools)

### upload_ontology

Upload a TTL/OWL ontology file to the Perseus API.

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `ontology_path` | `str` | yes | — | Local path to TTL/OWL file |
| `wait` | `bool` | no | `True` | Wait for processing completion |

**Returns:** Ontology metadata (id, status).

### upload_ontology_from_text

Upload an ontology from inline TTL text.

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `content` | `str` | yes | — | TTL ontology text |
| `name` | `str` | no | `"ontology.ttl"` | Filename hint |
| `wait` | `bool` | no | `True` | Wait for processing completion |

**Returns:** Ontology metadata. Raises `ValueError` if content exceeds size limit.

### list_ontologies

List remote ontologies with optional filters.

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `ids` | `list[str]` | no | `None` | Filter by ontology IDs |
| `source_hashes` | `list[str]` | no | `None` | Filter by source hashes |

**Returns:** Count and list of ontologies.

### get_ontology

Fetch a single ontology record.

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `ontology_id` | `str` | yes | — | Ontology identifier |

**Returns:** Ontology metadata or `None`.

### delete_ontology

Delete a remote ontology.

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `ontology_id` | `str` | yes | — | Ontology identifier |

**Returns:** Confirmation of deletion.

---

## Remote Jobs (7 tools)

### submit_job

Submit an extraction job for an uploaded file.

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `file_id` | `str` | yes | — | Already-uploaded file ID |
| `ontology_id` | `str` | no | `None` | Optional ontology constraint |

**Returns:** Job metadata (id, status).

### get_job

Fetch a single job with status.

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `job_id` | `str` | yes | — | Job identifier |

**Returns:** Job metadata or `None`.

### list_jobs

Fetch multiple jobs by IDs.

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `job_ids` | `list[str]` | yes | — | Job identifiers |

**Returns:** Count and list of jobs.

### find_latest_job

Get the most recent job for a file.

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `file_id` | `str` | yes | — | File identifier |
| `ontology_id` | `str` | no | `None` | Optional ontology filter |

**Returns:** Job metadata or `None`.

### find_latest_succeeded_job

Get the most recent successful job for a file.

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `file_id` | `str` | yes | — | File identifier |
| `ontology_id` | `str` | no | `None` | Optional ontology filter |

**Returns:** Job metadata or `None`.

### run_job

Block until a job reaches a terminal state.

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `job_id` | `str` | yes | — | Job identifier |
| `polling_interval` | `int` | no | `5` | Seconds between polls |
| `timeout` | `int` | no | `3600` | Max seconds to wait |

**Returns:** Terminal job state metadata.

### download_job_output

Download the output of a completed job.

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `job_id` | `str` | yes | — | Completed job ID |
| `output_path` | `str` | no | `None` | Target disk path for JSON output |

**Returns:** Job ID and absolute output path.
