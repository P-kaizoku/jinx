# tools.py
import os
import json
import subprocess
import platform
import shutil
from datetime import datetime
from pathlib import Path
import webbrowser
import urllib.parse
import urllib.request

BASE = Path(__file__).parent
CONFIG = json.loads((BASE / "config.json").read_text())
TASKS_FILE = BASE / "tasks.json"

def get_tasks():
    return json.loads(TASKS_FILE.read_text())

def save_tasks(data):
    TASKS_FILE.write_text(json.dumps(data, indent=2))

# ── tools ──────────────────────────────────────────────

def list_projects() -> str:
    projects_dir = Path(CONFIG["projects_dir"])
    if not projects_dir.exists():
        return f"projects dir not found: {projects_dir}"
    projects = [p.name for p in projects_dir.iterdir() if p.is_dir()]
    return f"available projects: {', '.join(projects)}"

def open_project(name: str) -> str:
    projects_dir = Path(CONFIG["projects_dir"])
    match = None
    for p in projects_dir.iterdir():
        if p.is_dir() and name.lower() in p.name.lower():
            match = p
            break
    if not match:
        return f"project '{name}' not found"
    editor = CONFIG.get("editor", "code")
    subprocess.Popen([editor, str(match)])
    return f"opened {match.name} in {editor}"

def add_task(text: str) -> str:
    data = get_tasks()
    task = {
        "id": len(data["tasks"]) + 1,
        "text": text,
        "done": False,
        "created": datetime.now().isoformat()
    }
    data["tasks"].append(task)
    save_tasks(data)
    return f"task added: {text}"

def list_tasks() -> str:
    data = get_tasks()
    pending = [t for t in data["tasks"] if not t["done"]]
    if not pending:
        return "no pending tasks"
    result = "pending tasks:\n"
    for t in pending:
        result += f"  [{t['id']}] {t['text']}\n"
    return result.strip()

def complete_task(task_id: int) -> str:
    data = get_tasks()
    for t in data["tasks"]:
        if t["id"] == task_id:
            t["done"] = True
            save_tasks(data)
            return f"task {task_id} marked done"
    return f"task {task_id} not found"

def system_info() -> str:
    import psutil
    cpu = psutil.cpu_percent(interval=1)
    ram = psutil.virtual_memory()
    disk = psutil.disk_usage('/')
    return (
        f"cpu: {cpu}%\n"
        f"ram: {ram.used // 1024**3}GB / {ram.total // 1024**3}GB ({ram.percent}%)\n"
        f"disk: {disk.used // 1024**3}GB / {disk.total // 1024**3}GB ({disk.percent}%)\n"
        f"os: {platform.system()} {platform.release()}"
    )

def run_command(cmd: str) -> str:
    try:
        result = subprocess.run(
            cmd, shell=True, capture_output=True,
            text=True, timeout=10
        )
        return result.stdout or result.stderr or "command executed"
    except subprocess.TimeoutExpired:
        return "command timed out"
    except Exception as e:
        return f"error: {e}"

# ── new tools ──────────────────────────────────────────

def get_weather(city: str = "New Delhi") -> str:
    try:
        url = f"https://wttr.in/{urllib.parse.quote(city)}?format=3"
        req = urllib.request.Request(url, headers={"User-Agent": "curl/7.0"})
        with urllib.request.urlopen(req, timeout=5) as r:
            return r.read().decode().strip()
    except Exception as e:
        return f"weather fetch failed: {e}"

def search_web(query: str) -> str:
    try:
        encoded = urllib.parse.quote(query)
        url = f"https://api.duckduckgo.com/?q={encoded}&format=json&no_html=1&skip_disambig=1"
        req = urllib.request.Request(url, headers={"User-Agent": "jinx-agent/1.0"})
        with urllib.request.urlopen(req, timeout=8) as r:
            data = json.loads(r.read().decode())

        results = []
        if data.get("Answer"):
            results.append(f"→ {data['Answer']}")
        if data.get("AbstractText"):
            results.append(f"→ {data['AbstractText'][:300]}")
        for topic in data.get("RelatedTopics", [])[:3]:
            if isinstance(topic, dict) and topic.get("Text"):
                results.append(f"· {topic['Text'][:150]}")

        if results:
            return "\n\n".join(results)

        # fallback — open in browser
        webbrowser.open(f"https://duckduckgo.com/?q={encoded}")
        return f"no instant answer found — opened '{query}' in browser"

    except Exception as e:
        return f"search failed: {e}"

def open_url(url: str) -> str:
    try:
        if not url.startswith("http"):
            url = "https://" + url
        webbrowser.open(url)
        return f"opened {url} in browser"
    except Exception as e:
        return f"failed to open url: {e}"

def git_status(project: str) -> str:
    try:
        projects_dir = Path(CONFIG["projects_dir"])
        match = None
        for p in projects_dir.iterdir():
            if p.is_dir() and project.lower() in p.name.lower():
                match = p
                break
        if not match:
            return f"project '{project}' not found"

        result = subprocess.run(
            "git status --short && git log --oneline -5",
            shell=True, capture_output=True,
            text=True, cwd=str(match)
        )
        output = result.stdout.strip()
        return output if output else "nothing to commit, working tree clean"
    except Exception as e:
        return f"git error: {e}"


# tool registry — agent uses this
TOOLS = {
    "list_projects": list_projects,
    "open_project": open_project,
    "add_task": add_task,
    "list_tasks": list_tasks,
    "complete_task": complete_task,
    "system_info": system_info,
    "run_command": run_command,
    "get_weather": get_weather,
    "search_web": search_web,
    "open_url": open_url,
    "git_status": git_status,
}