#!/bin/bash

set -e

GREEN='\033[0;32m'
DIM='\033[2m'
NC='\033[0m'

echo -e "${GREEN}"
cat <<'EOF'
     ██╗██╗███╗   ██╗██╗  ██╗
     ██║██║████╗  ██║╚██╗██╔╝
     ██║██║██╔██╗ ██║ ╚███╔╝ 
██   ██║██║██║╚██╗██║ ██╔██╗ 
╚█████╔╝██║██║ ╚████║██╔╝ ██╗
 ╚════╝ ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝
EOF
echo -e "${NC}"
echo -e "${DIM}installing jinx...${NC}\n"

# check dependencies
if ! command -v ollama &>/dev/null; then
  echo "→ installing ollama..."
  curl -fsSL https://ollama.com/install.sh | sh
else
  echo "→ ollama already installed"
fi

if ! command -v uv &>/dev/null; then
  echo "→ installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.cargo/bin:$PATH"
else
  echo "→ uv already installed"
fi

# pull model
echo "→ pulling phi4-mini (this may take a few minutes)..."
ollama pull phi4-mini

# install dependencies
echo "→ installing python dependencies..."
uv sync

# get projects dir
echo ""
read -p "  projects directory [~/Personal]: " PROJECTS_DIR
PROJECTS_DIR=${PROJECTS_DIR:-"$HOME/Personal"}

# get editor
read -p "  editor [code]: " EDITOR
EDITOR=${EDITOR:-"code"}

# write config
cat >config.json <<EOF
{
  "projects_dir": "$PROJECTS_DIR",
  "editor": "$EDITOR",
  "model": "phi4-mini",
  "invoke": "jinx"
}
EOF

# write empty tasks
echo '{"tasks": []}' >tasks.json

# create global launcher
JINX_DIR="$(pwd)"
LAUNCHER="/usr/local/bin/jinx"

echo "→ creating global command..."
sudo tee "$LAUNCHER" >/dev/null <<EOF
#!/bin/bash
cd "$JINX_DIR"
uv run jinx.py "\$@"
EOF

sudo chmod +x "$LAUNCHER"

echo ""
echo -e "${GREEN}→ jinx installed successfully${NC}"
echo -e "${DIM}  type 'jinx' anywhere to start${NC}\n"
