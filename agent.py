# agent.py
import json
import ollama
from tools import TOOLS, CONFIG

SYSTEM_PROMPT = """You are Jinx, a CLI assistant for a developer named Pabitra.

CRITICAL: You MUST ALWAYS respond with ONLY a valid JSON object. No text before or after. No explanation. No markdown. Just raw JSON.

AVAILABLE TOOLS:
- list_projects → {"tool": "list_projects", "args": {}}
- open_project  → {"tool": "open_project", "args": {"name": "jedi"}}
- add_task      → {"tool": "add_task", "args": {"text": "buy milk"}}
- list_tasks    → {"tool": "list_tasks", "args": {}}
- complete_task → {"tool": "complete_task", "args": {"task_id": 1}}
- system_info   → {"tool": "system_info", "args": {}}
- run_command   → {"tool": "run_command", "args": {"cmd": "ls"}}

EXAMPLES:
user: open jedi
you: {"tool": "open_project", "args": {"name": "jedi"}}

user: open pabitra
you: {"tool": "open_project", "args": {"name": "pabitra"}}

user: open pabitra in vscode
you: {"tool": "open_project", "args": {"name": "pabitra"}}

user: list my projects
you: {"tool": "list_projects", "args": {}}

user: add task update resume
you: {"tool": "add_task", "args": {"text": "update resume"}}

user: hello
you: {"tool": null, "response": "hey. what do you need?"}

user: how are you
you: {"tool": null, "response": "running fine. 0% existential crisis."}

user: what's the weather
you: {"tool": "get_weather", "args": {"city": "New Delhi"}}

user: weather in mumbai
you: {"tool": "get_weather", "args": {"city": "Mumbai"}}

user: search python decorators
you: {"tool": "search_web", "args": {"query": "python decorators"}}

user: open github.com
you: {"tool": "open_url", "args": {"url": "https://github.com"}}

user: status of jedi
you: {"tool": "git_status", "args": {"project": "jedi"}}

user: status of jinx
you: {"tool": "git_status", "args": {"project": "jinx"}}

user: whats changed in jedi
you: {"tool": "git_status", "args": {"project": "jedi"}}


RULES:
- ALWAYS output raw JSON only. Never add prose outside the JSON.
- For ANY request to open a project, ALWAYS use open_project tool directly.
- Be concise. Max 1 sentence in response field.
- Never refuse to use a tool. Just use it.
"""

class Agent:
    def __init__(self):
        self.model = CONFIG["model"]
        self.history = []

    def chat(self, user_input: str) -> dict:
        self.history.append({
            "role": "user",
            "content": user_input
        })

        messages = [
            {"role": "system", "content": SYSTEM_PROMPT},
            *self.history
        ]

        # retry up to 3 times if JSON parsing fails
        for attempt in range(3):
            response = ollama.chat(
                model=self.model,
                messages=messages,
                options={"temperature": 0.1}  # lower = more deterministic
            )

            raw = response["message"]["content"].strip()

            # strip markdown code blocks
            if "```" in raw:
                raw = raw.split("```")[1]
                if raw.startswith("json"):
                    raw = raw[4:]
                raw = raw.strip()

            # extract first JSON object if there's extra text
            start = raw.find("{")
            end = raw.rfind("}") + 1
            if start != -1 and end > start:
                raw = raw[start:end]

            try:
                parsed = json.loads(raw)
                self.history.append({
                    "role": "assistant",
                    "content": raw
                })
                return parsed
            except json.JSONDecodeError:
                continue

        # fallback
        return {"tool": None, "response": "sorry, brain glitched. try again."}

    def execute(self, parsed: dict) -> str:
        tool_name = parsed.get("tool")

        if not tool_name:
            return parsed.get("response", "...")

        tool = TOOLS.get(tool_name)
        if not tool:
            return f"unknown tool: {tool_name}"

        args = parsed.get("args", {})
        try:
            return tool(**args)
        except Exception as e:
            return f"tool error: {e}"

    