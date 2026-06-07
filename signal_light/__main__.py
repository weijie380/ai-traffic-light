#!/usr/bin/env python3
"""
🚦 AI Traffic Light — 主入口
signal-light play working|permission|idle|completed
signal-light list
signal-light serve
signal-light hook <event-name>
"""

import argparse
import json
import os
import sys
import time
from pathlib import Path

# ─── Config ────────────────────────────────────────────────────────────────
SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_DIR = SCRIPT_DIR.parent

# Find writable status dir
STATUS_DIR = None
for d in [
    os.environ.get("AI_TRAFFIC_LIGHT_DIR"),
    str(PROJECT_DIR / ".ai-traffic-light"),
    os.path.expanduser("~/.ai-traffic-light"),
]:
    if d:
        try:
            os.makedirs(d, exist_ok=True)
            test = os.path.join(d, ".test")
            open(test, "w").close()
            os.remove(test)
            STATUS_DIR = d
            break
        except (OSError, PermissionError):
            continue

if not STATUS_DIR:
    STATUS_DIR = str(PROJECT_DIR / ".ai-traffic-light")
    os.makedirs(STATUS_DIR, exist_ok=True)

STATUS_FILE = os.path.join(STATUS_DIR, "status.json")
SESSION_FILE = os.path.join(STATUS_DIR, "sessions.json")

# ─── Signal Definitions ────────────────────────────────────────────────────
SIGNALS = {
    "idle":      {"status": "idle",      "label": "空闲",   "emoji": "⚫", "pattern": "off",          "priority": 0},
    "completed": {"status": "completed", "label": "已完成", "emoji": "🟡", "pattern": "pulse-yellow", "priority": 1},
    "working":   {"status": "working",   "label": "运行中", "emoji": "🟢", "pattern": "pulse-green",  "priority": 2},
    "attention": {"status": "waiting",   "label": "需关注", "emoji": "🔴", "pattern": "pulse-red",   "priority": 3},
    "waiting":   {"status": "waiting",   "label": "等待授权","emoji": "🔴", "pattern": "flash-red",    "priority": 4},
    "blocked":   {"status": "waiting",   "label": "阻塞",   "emoji": "🔴", "pattern": "flash-red",   "priority": 5},
}

# Event → signal mapping for AI tool hooks
EVENT_MAP = {
    "SessionStart": "idle",
    "UserPromptSubmit": "working",
    "PreToolUse": "working",
    "PostToolUse": "working",
    "PostToolUseFailure": "blocked",
    "PermissionRequest": "waiting",
    "Notification": "attention",
    "Stop": "completed",
    "SessionEnd": "completed",
    "onTaskStart": "working",
    "onTaskEnd": "completed",
    "onError": "blocked",
    "onPermissionRequest": "waiting",
}

# ─── Status I/O ────────────────────────────────────────────────────────────

def read_status():
    try:
        with open(STATUS_FILE) as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return {"status": "idle", "tool": "", "message": "空闲", "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())}

_transition_counter = 0

def write_status(signal, tool="Reasonix", message=""):
    global _transition_counter
    sig = SIGNALS.get(signal)
    if not sig:
        print(f"Unknown signal: {signal}", file=sys.stderr)
        return False
    _transition_counter += 1
    data = {
        "status": sig["status"],
        "signal": signal,
        "tool": tool,
        "message": message or sig["label"],
        "emoji": sig["emoji"],
        "pattern": sig["pattern"],
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "heartbeat": int(time.time()),
        "transition_count": _transition_counter,
    }
    with open(STATUS_FILE, "w") as f:
        json.dump(data, f, indent=2)
    return True

# ─── Session Management ────────────────────────────────────────────────────

def read_sessions():
    try:
        with open(SESSION_FILE) as f:
            data = json.load(f)
            if isinstance(data, dict) and "sessions" in data:
                return data["sessions"]
            return {}
    except (FileNotFoundError, json.JSONDecodeError):
        return {}

def write_sessions(sessions):
    with open(SESSION_FILE, "w") as f:
        json.dump({"sessions": sessions, "updated_at": time.time()}, f, indent=2)

def aggregate_signals(sessions):
    """From multiple sessions, pick the highest-priority signal."""
    best = "idle"
    best_pri = 0
    for sid, state in sessions.items():
        sig = state.get("signal", "idle")
        pri = SIGNALS.get(sig, {}).get("priority", 0)
        if pri > best_pri:
            best_pri = pri
            best = sig
    return best

def apply_session_signal(session_key, signal_name):
    sessions = read_sessions()
    if signal_name in ("completed", "idle"):
        sessions.pop(session_key, None)
    elif signal_name == "off":
        sessions.clear()
    else:
        sessions[session_key] = {"signal": signal_name, "updated_at": time.time()}
    write_sessions(sessions)
    aggregate = aggregate_signals(sessions)
    write_status(aggregate, tool="Reasonix", message=SIGNALS[aggregate]["label"])
    return aggregate

# ─── CLI ────────────────────────────────────────────────────────────────────

def cmd_list():
    print("🚦 AI Traffic Light — 灯语")
    print()
    for name, sig in sorted(SIGNALS.items(), key=lambda x: x[1]["priority"]):
        print(f"  {sig['emoji']} {name:12s} {sig['label']}")
    print()
    print("事件映射:")
    for event, sig in sorted(EVENT_MAP.items()):
        se = SIGNALS.get(sig, {})
        print(f"  {event:25s} → {se.get('emoji','')} {sig}")

def cmd_play(signal, tool="Reasonix", message=""):
    if signal not in SIGNALS:
        print(f"未知信号: {signal}。可用: {', '.join(SIGNALS.keys())}", file=sys.stderr)
        return 1
    write_status(signal, tool, message)
    s = SIGNALS[signal]
    print(f"  {s['emoji']} {s['label']} — {message or s['label']}")
    return 0

def cmd_hook(event, tool="Reasonix"):
    signal = EVENT_MAP.get(event, "working")
    if signal not in SIGNALS:
        signal = "working"
    se = SIGNALS[signal]
    write_status(signal, tool, se["label"])
    print(f"  {se['emoji']} {event} → {signal}")
    return 0

def cmd_status():
    s = read_status()
    print(json.dumps(s, ensure_ascii=False, indent=2))

def cmd_serve():
    """Start the HTTP + SSE server for web UI."""
    from http.server import HTTPServer, BaseHTTPRequestHandler
    from socketserver import ThreadingMixIn
    from urllib.parse import urlparse
    import threading
    from queue import Queue

    class ThreadedServer(ThreadingMixIn, HTTPServer):
        allow_reuse_address = True
        daemon_threads = True

    HOST = "localhost"
    PORT = 19876
    HTML_PATH = os.path.join(str(PROJECT_DIR), "traffic-light.html")

    # SSE clients registry - use a list inside a dict so nested classes can reach it
    ctx = {"clients": [], "last_mtime": 0}

    def broadcast(data):
        dead = []
        for q in ctx["clients"]:
            try:
                q.put(data)
            except:
                dead.append(q)
        for q in dead:
            if q in ctx["clients"]:
                ctx["clients"].remove(q)

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            parsed = urlparse(self.path)
            path = parsed.path

            if path == "/":
                self.send_response(200)
                self.send_header("Content-Type", "text/html; charset=utf-8")
                self.end_headers()
                try:
                    with open(HTML_PATH, "rb") as f:
                        self.wfile.write(f.read())
                except FileNotFoundError:
                    self.wfile.write(b"<h1>traffic-light.html not found</h1>")
                return

            if path == "/state":
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.send_header("Access-Control-Allow-Origin", "*")
                self.end_headers()
                self.wfile.write(json.dumps(read_status()).encode())
                return

            if path == "/events":
                self.send_response(200)
                self.send_header("Content-Type", "text/event-stream")
                self.send_header("Cache-Control", "no-cache")
                self.send_header("Connection", "keep-alive")
                self.send_header("Access-Control-Allow-Origin", "*")
                self.end_headers()

                q = Queue()
                ctx["clients"].append(q)
                try:
                    q.put(read_status())
                    while True:
                        data = q.get()
                        self.wfile.write(f"data: {json.dumps(data)}\n\n".encode())
                        self.wfile.flush()
                except (BrokenPipeError, ConnectionResetError):
                    pass
                finally:
                    if q in ctx["clients"]:
                        ctx["clients"].remove(q)
                return

            if path == "/update":
                self.send_response(405)
                self.end_headers()
                self.wfile.write(b"Use POST")
                return

            # Static files
            base_dir = str(PROJECT_DIR)
            allowed = {".json", ".svg", ".png", ".ico"}
            _, ext = os.path.splitext(path)
            if ext in allowed:
                safe = os.path.basename(path)
                fp = os.path.join(base_dir, safe)
                if os.path.isfile(fp):
                    mime = {".json": "application/json", ".svg": "image/svg+xml", ".png": "image/png", ".ico": "image/x-icon"}
                    self.send_response(200)
                    self.send_header("Content-Type", mime.get(ext, "application/octet-stream"))
                    self.end_headers()
                    with open(fp, "rb") as f:
                        self.wfile.write(f.read())
                    return

            self.send_response(404)
            self.end_headers()

        def do_POST(self):
            path = urlparse(self.path).path
            if path == "/update":
                length = int(self.headers.get("Content-Length", 0))
                body = self.rfile.read(length)
                try:
                    data = json.loads(body)
                    signal = data.get("signal", data.get("status", "idle"))
                    write_status(signal, data.get("tool", "API"), data.get("message", ""))
                    broadcast(read_status())
                    self.send_response(200)
                    self.send_header("Content-Type", "application/json")
                    self.end_headers()
                    self.wfile.write(json.dumps(read_status()).encode())
                except Exception as e:
                    self.send_response(400)
                    self.end_headers()
                    self.wfile.write(json.dumps({"error": str(e)}).encode())
                return
            self.send_response(404)
            self.end_headers()

        def log_message(self, *a):
            pass

    def watch_file():
        while True:
            try:
                mtime = os.path.getmtime(STATUS_FILE)
                if mtime != ctx["last_mtime"]:
                    ctx["last_mtime"] = mtime
                    broadcast(read_status())
            except OSError:
                pass
            time.sleep(0.3)

    watcher = threading.Thread(target=watch_file, daemon=True)
    watcher.start()

    server = ThreadedServer((HOST, PORT), Handler)
    print(f"\n  🚦  AI Traffic Light server running at http://{HOST}:{PORT}")
    print(f"  📁  Status file: {STATUS_FILE}")
    print(f"  ⌨️   Ctrl+C to stop\n")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n  👋 Shutting down...")
        server.shutdown()

def main():
    parser = argparse.ArgumentParser(prog="signal-light", description="🚦 AI Traffic Light")
    sub = parser.add_subparsers(dest="command")

    p = sub.add_parser("play", help="🎬 播放信号")
    p.add_argument("signal", choices=list(SIGNALS.keys()), help="信号名称")
    p.add_argument("--tool", default="Reasonix", help="工具名称")
    p.add_argument("--msg", default="", help="消息")

    sub.add_parser("list", help="📋 列出所有信号")
    sub.add_parser("status", help="📊 查看当前状态")
    sub.add_parser("serve", help="🌐 启动 Web 服务器")

    p = sub.add_parser("hook", help="🔗 处理 AI 工具事件")
    p.add_argument("event", help="事件名称 (如 PermissionRequest, PreToolUse)")
    p.add_argument("--tool", default="Reasonix")

    args = parser.parse_args()

    if args.command == "list":
        cmd_list()
    elif args.command == "play":
        return cmd_play(args.signal, args.tool, args.msg)
    elif args.command == "status":
        cmd_status()
    elif args.command == "serve":
        cmd_serve()
    elif args.command == "hook":
        return cmd_hook(args.event, args.tool)
    else:
        parser.print_help()

if __name__ == "__main__":
    sys.exit(main())
