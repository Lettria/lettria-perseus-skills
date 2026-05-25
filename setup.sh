#!/bin/bash
set -euo pipefail

# Lettria Perseus — one-command setup for Claude Code
# Registers the MCP server(s) and installs the skills.

# --- Colors (disabled if not a terminal) ---
if [ -t 1 ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  BLUE='\033[0;34m'
  BOLD='\033[1m'
  RESET='\033[0m'
else
  RED='' GREEN='' YELLOW='' BLUE='' BOLD='' RESET=''
fi

REPO="git+https://github.com/Lettria/perseus-mcp.git"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"
SKILL_NAMES=("perseus" "perseus-ontology" "perseus-neo4j" "perseus-falkordb")

# --- Helper: register an MCP server (handles "already exists") ---
register_mcp() {
  local NAME="$1"
  shift
  local MCP_OUTPUT=""

  if MCP_OUTPUT=$(claude mcp add "$NAME" -s user "$@" 2>&1); then
    echo -e "  ${GREEN}$NAME — registered successfully.${RESET}"
    return 0
  fi

  if echo "$MCP_OUTPUT" | grep -qi "already exists"; then
    echo -e "  ${YELLOW}$NAME — already registered.${RESET}"
    read -rp "  Overwrite existing configuration? (y/N): " OVERWRITE
    if [[ "$OVERWRITE" =~ ^[Yy]$ ]]; then
      claude mcp remove "$NAME" -s user 2>/dev/null || true
      if claude mcp add "$NAME" -s user "$@" 2>&1; then
        echo -e "  ${GREEN}$NAME — re-registered successfully.${RESET}"
        return 0
      else
        echo -e "  ${RED}$NAME — failed to re-register.${RESET}"
        return 1
      fi
    else
      echo -e "  ${GREEN}$NAME — keeping existing configuration.${RESET}"
      return 0
    fi
  fi

  echo -e "  ${RED}$NAME — registration failed.${RESET}"
  return 1
}

echo ""
echo -e "${BOLD}=== Lettria Perseus Setup ===${RESET}"
echo ""

# --- 1. Collect API key ---
echo -e "${BLUE}[Step 1/4]${RESET} API Key"
if [ -n "${PERSEUS_API_KEY:-}" ]; then
  echo -e "  Using PERSEUS_API_KEY from environment."
  API_KEY="$PERSEUS_API_KEY"
else
  read -rp "  Enter your Perseus API key: " API_KEY
  if [ -z "$API_KEY" ]; then
    echo ""
    echo -e "${RED}Setup failed: API key is required.${RESET}"
    exit 1
  fi
fi

# --- 2. Optional: database credentials ---
echo ""
echo -e "${BLUE}[Step 2/4]${RESET} Database connections (optional)"

# Neo4j
SETUP_NEO4J="n"
NEO4J_ARGS=""
NEO4J_URI=""
NEO4J_USER=""
NEO4J_PASSWORD=""
read -rp "  Set up Neo4j connection? (y/N): " SETUP_NEO4J
if [[ "$SETUP_NEO4J" =~ ^[Yy]$ ]]; then
  read -rp "    NEO4J_URI (default: bolt://localhost:7687): " NEO4J_URI
  NEO4J_URI="${NEO4J_URI:-bolt://localhost:7687}"
  read -rp "    NEO4J_USER (default: neo4j): " NEO4J_USER
  NEO4J_USER="${NEO4J_USER:-neo4j}"
  read -rsp "    NEO4J_PASSWORD: " NEO4J_PASSWORD
  echo ""
  NEO4J_ARGS="-e NEO4J_URI=$NEO4J_URI -e NEO4J_USER=$NEO4J_USER -e NEO4J_PASSWORD=$NEO4J_PASSWORD"
  echo -e "  ${GREEN}Neo4j credentials configured.${RESET}"
else
  echo -e "  ${YELLOW}Skipping Neo4j.${RESET}"
fi

# FalkorDB
SETUP_FALKOR="n"
FALKOR_ARGS=""
FALKORDB_HOST=""
FALKORDB_PORT=""
FALKORDB_USERNAME=""
FALKORDB_PASSWORD=""
FALKORDB_GRAPH_NAME=""
echo ""
read -rp "  Set up FalkorDB connection? (y/N): " SETUP_FALKOR
if [[ "$SETUP_FALKOR" =~ ^[Yy]$ ]]; then
  read -rp "    FALKORDB_HOST (default: localhost): " FALKORDB_HOST
  FALKORDB_HOST="${FALKORDB_HOST:-localhost}"
  read -rp "    FALKORDB_PORT (default: 6379): " FALKORDB_PORT
  FALKORDB_PORT="${FALKORDB_PORT:-6379}"
  read -rp "    FALKORDB_USERNAME (default: default): " FALKORDB_USERNAME
  FALKORDB_USERNAME="${FALKORDB_USERNAME:-default}"
  read -rsp "    FALKORDB_PASSWORD: " FALKORDB_PASSWORD
  echo ""
  read -rp "    FALKORDB_GRAPH_NAME (default: perseus): " FALKORDB_GRAPH_NAME
  FALKORDB_GRAPH_NAME="${FALKORDB_GRAPH_NAME:-perseus}"
  FALKOR_ARGS="-e FALKORDB_HOST=$FALKORDB_HOST -e FALKORDB_PORT=$FALKORDB_PORT -e FALKORDB_USERNAME=$FALKORDB_USERNAME -e FALKORDB_PASSWORD=$FALKORDB_PASSWORD -e FALKORDB_GRAPH_NAME=$FALKORDB_GRAPH_NAME"
  echo -e "  ${GREEN}FalkorDB credentials configured.${RESET}"
else
  echo -e "  ${YELLOW}Skipping FalkorDB.${RESET}"
fi

# --- 3. Register MCP servers ---
echo ""
echo -e "${BLUE}[Step 3/4]${RESET} Registering MCP servers"
echo ""

# 3a. Perseus MCP server (write — build/interlink/push graphs)
# shellcheck disable=SC2086
if ! register_mcp lettria-perseus \
  -e PERSEUS_API_KEY="$API_KEY" \
  $NEO4J_ARGS \
  $FALKOR_ARGS \
  -- uvx --from "$REPO" lettria-perseus-mcp; then
  echo ""
  echo -e "${RED}Setup failed: could not register Perseus MCP server.${RESET}"
  echo ""
  echo "Make sure the following are installed:"
  echo "  1. Claude Code CLI — install with: npm install -g @anthropic-ai/claude-code"
  echo "     Then verify with: claude --version"
  echo "  2. uv (Python package manager) — install with: curl -LsSf https://astral.sh/uv/install.sh | sh"
  echo "     Then verify with: uv --version"
  echo ""
  echo "For more info see: https://docs.anthropic.com/en/docs/claude-code"
  exit 1
fi

# 3b. Neo4j MCP server (read — query via Cypher)
if [[ "$SETUP_NEO4J" =~ ^[Yy]$ ]]; then
  echo ""
  echo "  Registering Neo4j query server (read access)..."
  # shellcheck disable=SC2086
  register_mcp neo4j-cypher \
    -e NEO4J_URI="$NEO4J_URI" \
    -e NEO4J_USERNAME="$NEO4J_USER" \
    -e NEO4J_PASSWORD="$NEO4J_PASSWORD" \
    -e NEO4J_DATABASE=neo4j \
    -- uvx mcp-neo4j-cypher || \
    echo -e "  ${YELLOW}Neo4j query server registration failed — you can still push graphs, but querying Neo4j from Claude won't be available.${RESET}"
fi

# 3c. FalkorDB MCP server (read — query via Cypher)
if [[ "$SETUP_FALKOR" =~ ^[Yy]$ ]]; then
  echo ""
  echo "  Registering FalkorDB query server (read access)..."
  register_mcp falkordb \
    -e FALKORDB_HOST="$FALKORDB_HOST" \
    -e FALKORDB_PORT="$FALKORDB_PORT" \
    -e FALKORDB_USERNAME="$FALKORDB_USERNAME" \
    -e FALKORDB_PASSWORD="$FALKORDB_PASSWORD" \
    -- npx -y @falkordb/mcpserver || \
    echo -e "  ${YELLOW}FalkorDB query server registration failed — you can still push graphs, but querying FalkorDB from Claude won't be available.${RESET}"
fi

# --- 4. Install skills via symlink ---
echo ""
echo -e "${BLUE}[Step 4/4]${RESET} Installing skills"
echo ""
echo "  Installing skills to $SKILLS_DIR ..."
mkdir -p "$SKILLS_DIR"

INSTALLED=0
SKIPPED=0
for SKILL in "${SKILL_NAMES[@]}"; do
  SRC="$SCRIPT_DIR/$SKILL"
  DEST="$SKILLS_DIR/$SKILL"

  if [ ! -d "$SRC" ]; then
    echo -e "    ${YELLOW}Warning: $SKILL directory not found at $SRC — skipping.${RESET}"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  if [ -e "$DEST" ] || [ -L "$DEST" ]; then
    echo -e "    ${YELLOW}$SKILL — already exists, replacing...${RESET}"
    rm -f "$DEST"
  fi

  ln -s "$SRC" "$DEST"
  echo -e "    ${GREEN}$SKILL — installed.${RESET}"
  INSTALLED=$((INSTALLED + 1))
done

if [ "$INSTALLED" -eq 0 ]; then
  echo ""
  echo -e "${RED}Setup failed: no skills were installed.${RESET}"
  echo "Make sure you are running this script from the perseus-skills directory."
  exit 1
fi

# --- Done ---
echo ""
echo -e "${BOLD}${GREEN}=== Setup complete ===${RESET}"
echo -e "  Perseus MCP server: ${GREEN}registered${RESET} (build/push graphs)"
if [[ "$SETUP_NEO4J" =~ ^[Yy]$ ]]; then
  echo -e "  Neo4j query server: ${GREEN}registered${RESET} (read via Cypher)"
fi
if [[ "$SETUP_FALKOR" =~ ^[Yy]$ ]]; then
  echo -e "  FalkorDB query server: ${GREEN}registered${RESET} (read via Cypher)"
fi
echo -e "  Skills installed: ${GREEN}$INSTALLED${RESET} (skipped: $SKIPPED)"
echo ""
echo "Open Claude Code and type /perseus to get started."
