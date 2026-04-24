#!/bin/bash
set -euo pipefail

# Lettria Perseus — one-command setup for Claude Code
# Registers the MCP server and installs the skills.

REPO="git+https://github.com/jalakoo/lettria-perseus-mcp.git"
SKILL_REPO="jalakoo/lettria-perseus-skills"

echo "=== Lettria Perseus Setup ==="
echo ""

# --- 1. Collect API key ---
if [ -n "${PERSEUS_API_KEY:-}" ]; then
  echo "Using PERSEUS_API_KEY from environment."
  API_KEY="$PERSEUS_API_KEY"
else
  read -rp "Enter your Perseus API key: " API_KEY
  if [ -z "$API_KEY" ]; then
    echo "Error: API key is required." >&2
    exit 1
  fi
fi

# --- 2. Optional: Neo4j credentials ---
echo ""
read -rp "Set up Neo4j connection? (y/N): " SETUP_NEO4J
NEO4J_ARGS=""
if [[ "$SETUP_NEO4J" =~ ^[Yy]$ ]]; then
  read -rp "  NEO4J_URI (default: bolt://localhost:7687): " NEO4J_URI
  NEO4J_URI="${NEO4J_URI:-bolt://localhost:7687}"
  read -rp "  NEO4J_USER (default: neo4j): " NEO4J_USER
  NEO4J_USER="${NEO4J_USER:-neo4j}"
  read -rsp "  NEO4J_PASSWORD: " NEO4J_PASSWORD
  echo ""
  NEO4J_ARGS="-e NEO4J_URI=$NEO4J_URI -e NEO4J_USER=$NEO4J_USER -e NEO4J_PASSWORD=$NEO4J_PASSWORD"
fi

# --- 3. Optional: FalkorDB credentials ---
echo ""
read -rp "Set up FalkorDB connection? (y/N): " SETUP_FALKOR
FALKOR_ARGS=""
if [[ "$SETUP_FALKOR" =~ ^[Yy]$ ]]; then
  read -rp "  FALKORDB_HOST (default: localhost): " FALKORDB_HOST
  FALKORDB_HOST="${FALKORDB_HOST:-localhost}"
  read -rp "  FALKORDB_PORT (default: 6379): " FALKORDB_PORT
  FALKORDB_PORT="${FALKORDB_PORT:-6379}"
  read -rp "  FALKORDB_USERNAME (default: default): " FALKORDB_USERNAME
  FALKORDB_USERNAME="${FALKORDB_USERNAME:-default}"
  read -rsp "  FALKORDB_PASSWORD: " FALKORDB_PASSWORD
  echo ""
  read -rp "  FALKORDB_GRAPH_NAME (default: perseus): " FALKORDB_GRAPH_NAME
  FALKORDB_GRAPH_NAME="${FALKORDB_GRAPH_NAME:-perseus}"
  FALKOR_ARGS="-e FALKORDB_HOST=$FALKORDB_HOST -e FALKORDB_PORT=$FALKORDB_PORT -e FALKORDB_USERNAME=$FALKORDB_USERNAME -e FALKORDB_PASSWORD=$FALKORDB_PASSWORD -e FALKORDB_GRAPH_NAME=$FALKORDB_GRAPH_NAME"
fi

# --- 4. Register MCP server ---
echo ""
echo "Registering MCP server..."
# shellcheck disable=SC2086
claude mcp add lettria-perseus \
  -e PERSEUS_API_KEY="$API_KEY" \
  $NEO4J_ARGS \
  $FALKOR_ARGS \
  -- uvx --from "$REPO" lettria-perseus-mcp

echo "MCP server registered."

# --- 5. Install skills ---
echo ""
echo "Installing skills..."
npx skills add "$SKILL_REPO" -g

echo ""
echo "=== Setup complete ==="
echo "Try it out: type /perseus in Claude Code"
