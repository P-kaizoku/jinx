# jinx.py
import sys
import time
from rich.console import Console
from rich.prompt import Prompt
from rich.spinner import Spinner
from rich.live import Live
from agent import Agent

console = Console()
agent = Agent()

BANNER = """
     ██╗██╗███╗   ██╗██╗  ██╗
     ██║██║████╗  ██║╚██╗██╔╝
     ██║██║██╔██╗ ██║ ╚███╔╝ 
██   ██║██║██║╚██╗██║ ██╔██╗ 
╚█████╔╝██║██║ ╚████║██╔╝ ██╗
 ╚════╝ ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝
"""

def print_banner():
    console.print(BANNER, style="bold green")
    console.print("  local ai agent · fully private · type 'exit' to quit\n", style="dim green")

def print_tool(tool: str, result: str, elapsed: float):
    console.print(f"[dim]⚙ {tool} · {elapsed:.2f}s[/dim]", style="dim yellow")
    console.print(f"[bold cyan]jinx[/bold cyan] [dim]→[/dim] {result}\n")

def print_jinx(text: str, elapsed: float):
    console.print(f"[bold cyan]jinx[/bold cyan] [dim]→[/dim] {text} [dim]({elapsed:.2f}s)[/dim]\n")

def main():
    print_banner()

    while True:
        try:
            user_input = Prompt.ask("[bold green]you[/bold green]")
        except (KeyboardInterrupt, EOFError):
            console.print("\n[dim]jinx out. 👋[/dim]")
            sys.exit(0)

        if not user_input.strip():
            continue

        if user_input.lower() in ("exit", "quit", "q"):
            console.print("\n[dim]jinx out. 👋[/dim]")
            break

        start = time.time()

        with Live(Spinner("dots", text="[dim green]thinking...[/dim green]"), refresh_per_second=10, console=console):
            parsed = agent.chat(user_input)
            result = agent.execute(parsed)

        elapsed = time.time() - start
        tool_name = parsed.get("tool")

        if tool_name:
            print_tool(tool_name, result, elapsed)
        else:
            print_jinx(result, elapsed)

if __name__ == "__main__":
    main()