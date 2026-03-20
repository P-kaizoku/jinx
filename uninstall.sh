#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
DIM='\033[2m'
NC='\033[0m'

echo -e "${RED}"
cat << 'EOF'
     ██╗██╗███╗   ██╗██╗  ██╗
     ██║██║████╗  ██║╚██╗██╔╝
     ██║██║██╔██╗ ██║ ╚███╔╝ 
██   ██║██║██║╚██╗██║ ██╔██╗ 
╚█████╔╝██║██║ ╚████║██╔╝ ██╗
 ╚════╝ ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝
EOF
echo -e "${NC}"
echo -e "${DIM}uninstalling jinx...${NC}\n"

# confirm
read -p "  are you sure? this will remove jinx globally [y/N]: " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo -e "\n${DIM}aborted.${NC}"
    exit 0
fi

# remove global command
if [ -f "/usr/local/bin/jinx" ]; then
    echo "→ removing global command..."
    sudo rm /usr/local/bin/jinx
else
    echo "→ global command not found, skipping"
fi

# detect model from config
if [ -f "config.json" ]; then
    MODEL=$(python3 -c "import json; print(json.load(open('config.json'))['model'])" 2>/dev/null || echo "phi4-mini")
else
    MODEL="phi4-mini"
fi

echo "→ detected model: $MODEL"

# ask about ollama model
read -p "  remove $MODEL model? frees disk space [y/N]: " REMOVE_MODEL
if [[ "$REMOVE_MODEL" == "y" || "$REMOVE_MODEL" == "Y" ]]; then
    if command -v ollama &> /dev/null; then
        echo "→ removing $MODEL..."
        ollama rm $MODEL
    else
        echo "→ ollama not found, skipping"
    fi
fi

# ask about ollama itself
read -p "  remove ollama entirely? [y/N]: " REMOVE_OLLAMA
if [[ "$REMOVE_OLLAMA" == "y" || "$REMOVE_OLLAMA" == "Y" ]]; then
    echo "→ removing ollama..."
    sudo rm -f /usr/local/bin/ollama
    rm -rf ~/.ollama
    echo "→ ollama removed"
fi

# ask about project files
read -p "  remove jinx project files? [y/N]: " REMOVE_FILES
if [[ "$REMOVE_FILES" == "y" || "$REMOVE_FILES" == "Y" ]]; then
    JINX_DIR="$(pwd)"
    echo "→ removing project files..."
    cd ..
    rm -rf "$JINX_DIR"
    echo -e "\n${RED}→ jinx uninstalled completely${NC}"
    echo -e "${DIM}  it was fun while it lasted. 👋${NC}\n"
    exit 0
fi

echo -e "\n${GREEN}→ jinx uninstalled${NC}"
echo -e "${DIM}  global command removed. project files kept at $(pwd)${NC}\n"