# Jinx 🤖

> A local AI agent that lives in your terminal. Fully private — not a single word leaves your machine.

## One-liner install

### macOS / Linux

```bash
git clone https://github.com/P-kaizoku/jinx.git
cd jinx
./install.sh
```

### Windows (PowerShell)

```powershell
git clone https://github.com/P-kaizoku/jinx.git
cd jinx
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

That's it. Then type `jinx` anywhere in your terminal.

## What it does

Jinx understands natural language and executes actions on your system:

- **Open projects** — `open jedi` → launches in VSCode
- **Tasks** — `add task update resume` → stored locally in JSON
- **Git status** — `status of jedi` → last 5 commits + working tree changes
- **Weather** — `weather in mumbai` → instant answer via wttr.in
- **Web search** — `search rust ownership` → DuckDuckGo instant answers, falls back to browser
- **Open URLs** — `open github.com` → launches in browser
- **System info** — `system info` → cpu, ram, disk usage
- **Run commands** — `run ls -la` → executes shell commands

## Demo

```
you: open jedi
⚙ open_project · 0.58s
jinx → opened jedi in code

you: weather in delhi
⚙ get_weather · 0.91s
jinx → New Delhi: ⛅ +17°C

you: add task update resume
⚙ add_task · 0.61s
jinx → task added: update resume

you: git status of jedi
⚙ git_status · 0.65s
jinx → 85bc482 add example env
       fda0287 add readme nd screenshots
       d8b7e62 initial commit

you: system info
⚙ system_info · 1.20s
jinx → cpu: 3.8%
       ram: 7GB / 11GB (64.8%)
       disk: 26GB / 45GB (59.9%)
       os: Linux 6.19.8-arch1-1
```

## Stack

| Part            | Tool                              |
| --------------- | --------------------------------- |
| LLM             | phi4-mini via Ollama (100% local) |
| CLI             | Python + Rich                     |
| Package manager | uv                                |
| Storage         | local JSON files                  |

## Manual Setup

If you prefer to set up manually:

### 1. Install Ollama + pull model

```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama pull phi4-mini
```

### 2. Install uv

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### 3. Clone and install dependencies

```bash
git clone https://github.com/P-kaizoku/jinx.git
cd jinx
uv sync
```

### 4. Configure

Edit `config.json`:

```json
{
  "projects_dir": "/home/yourname/Projects",
  "editor": "code",
  "model": "phi4-mini",
  "invoke": "jinx"
}
```

### 5. Run

```bash
uv run jinx.py
```

## Usage

```
you: open jedi
you: add task review PR
you: list tasks
you: complete task 1
you: git status of jedi
you: weather in delhi
you: search what is a monad
you: open youtube.com
you: system info
you: run git log --oneline
```

Tab autocomplete and arrow key history both work.

## How it works

Jinx uses a local LLM (phi4-mini via Ollama) with a structured system prompt that forces JSON tool-calling responses. Every message is sent with full conversation history so it maintains context across a session. Tools are plain Python functions — no frameworks, no abstractions.

```
user input
    → ollama (phi4-mini) with conversation history
    → JSON tool call {"tool": "open_project", "args": {"name": "jedi"}}
    → tool executes locally
    → result displayed in terminal
```

## Why local?

No API keys. No usage costs. No data leaving your machine. Your projects, tasks, and queries stay yours.

## Requirements

- Python 3.11+
- [Ollama](https://ollama.com)
- [uv](https://astral.sh/uv)
- ~2.5GB disk space for phi4-mini

## Uninstall

### macOS / Linux

```bash
./uninstall.sh
```

### Windows

Delete `%USERPROFILE%\bin\jinx.cmd` to remove the global launcher.

---

Built by [P-kaizoku](https://github.com/P-kaizoku)
