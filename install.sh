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

# model selection
echo ""
echo "  available models:"
echo "  [1] phi4-mini    — recommended (smart, 2.5GB)"
echo "  [2] llama3.2:3b  — faster, lighter (2GB)"
echo "  [3] mistral      — great balance (4GB)"
echo "  [4] gemma3:1b    — ultralight, less accurate (800MB)"
echo ""
read -p "  choose model [1]: " MODEL_CHOICE

case $MODEL_CHOICE in
    2) MODEL="llama3.2:3b" ;;
    3) MODEL="mistral" ;;
    4) MODEL="gemma3:1b" ;;
    *) MODEL="phi4-mini" ;;
esac

echo "→ pulling $MODEL..."
ollama pull $MODEL

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
cat > config.json << EOF
{
  "projects_dir": "$PROJECTS_DIR",
  "editor": "$EDITOR",
  "model": "$MODEL",
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
