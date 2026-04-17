import json
import os
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, HTTPServer


APP_HTML = """<!doctype html>
<html lang="en">
    <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>PropelIQ Developer Assistant</title>
        <style>
            :root {
                --bg-a: #f8fbff;
                --bg-b: #eef6ff;
                --ink: #102033;
                --ink-soft: #334e68;
                --accent: #0ea5a4;
                --accent-2: #0284c7;
                --card: rgba(255, 255, 255, 0.86);
                --line: rgba(16, 32, 51, 0.12);
            }

            * { box-sizing: border-box; }

            body {
                margin: 0;
                min-height: 100vh;
                color: var(--ink);
                font-family: "Segoe UI", "Trebuchet MS", sans-serif;
                background:
                    radial-gradient(1000px 400px at 85% -10%, rgba(14, 165, 164, 0.18), transparent),
                    radial-gradient(900px 420px at -10% 110%, rgba(2, 132, 199, 0.16), transparent),
                    linear-gradient(135deg, var(--bg-a), var(--bg-b));
            }

            .shell {
                max-width: 980px;
                margin: 32px auto;
                padding: 18px;
            }

            .hero {
                padding: 24px;
                border: 1px solid var(--line);
                border-radius: 18px;
                background: var(--card);
                backdrop-filter: blur(8px);
                box-shadow: 0 18px 40px rgba(16, 32, 51, 0.08);
            }

            .title {
                margin: 0;
                font-size: clamp(1.5rem, 3.4vw, 2.4rem);
                letter-spacing: 0.02em;
            }

            .sub {
                margin: 10px 0 0;
                color: var(--ink-soft);
            }

            .grid {
                display: grid;
                gap: 16px;
                margin-top: 16px;
                grid-template-columns: 1.2fr 1fr;
            }

            .panel {
                border: 1px solid var(--line);
                border-radius: 14px;
                background: #fff;
                padding: 14px;
            }

            .label {
                font-weight: 600;
                font-size: 0.95rem;
            }

            textarea {
                margin-top: 8px;
                width: 100%;
                min-height: 150px;
                border-radius: 12px;
                border: 1px solid var(--line);
                padding: 12px;
                font-size: 0.98rem;
                color: var(--ink);
                resize: vertical;
            }

            .bar {
                margin-top: 12px;
                display: flex;
                gap: 10px;
                flex-wrap: wrap;
            }

            button {
                border: 0;
                border-radius: 999px;
                padding: 10px 16px;
                font-weight: 600;
                cursor: pointer;
                transition: transform 0.15s ease, box-shadow 0.15s ease;
            }

            .primary {
                color: #fff;
                background: linear-gradient(120deg, var(--accent), var(--accent-2));
                box-shadow: 0 10px 20px rgba(2, 132, 199, 0.22);
            }

            .secondary {
                color: var(--ink);
                background: #eef4fb;
            }

            button:hover {
                transform: translateY(-1px);
            }

            .status {
                margin-top: 10px;
                color: var(--ink-soft);
                font-size: 0.9rem;
            }

            .response {
                white-space: pre-wrap;
                line-height: 1.45;
                color: var(--ink);
            }

            .meta {
                margin-top: 8px;
                font-size: 0.82rem;
                color: #5f7488;
            }

            @media (max-width: 860px) {
                .grid { grid-template-columns: 1fr; }
            }
        </style>
    </head>
    <body>
        <main class="shell">
            <section class="hero">
                <h1 class="title">PropelIQ Prompt Console</h1>
                <p class="sub">A lightweight developer interface for sending prompts and getting structured assistant responses.</p>

                <div class="grid">
                    <div class="panel">
                        <label class="label" for="prompt">Prompt</label>
                        <textarea id="prompt" placeholder="Ask something like: Create a secure CI/CD checklist for this repo."></textarea>
                        <div class="bar">
                            <button id="run" class="primary">Run Prompt</button>
                            <button id="clear" class="secondary">Clear</button>
                        </div>
                        <div id="status" class="status">Ready</div>
                    </div>

                    <div class="panel">
                        <div class="label">Assistant Response</div>
                        <div id="response" class="response">No response yet.</div>
                        <div id="meta" class="meta"></div>
                    </div>
                </div>
            </section>
        </main>

        <script>
            const runBtn = document.getElementById("run");
            const clearBtn = document.getElementById("clear");
            const promptEl = document.getElementById("prompt");
            const responseEl = document.getElementById("response");
            const statusEl = document.getElementById("status");
            const metaEl = document.getElementById("meta");

            async function runPrompt() {
                const prompt = promptEl.value.trim();
                if (!prompt) {
                    statusEl.textContent = "Enter a prompt first.";
                    return;
                }

                statusEl.textContent = "Running...";
                runBtn.disabled = true;

                try {
                    const res = await fetch("/api/prompt", {
                        method: "POST",
                        headers: { "Content-Type": "application/json" },
                        body: JSON.stringify({ prompt }),
                    });

                    if (!res.ok) {
                        throw new Error(`Request failed: ${res.status}`);
                    }

                    const data = await res.json();
                    responseEl.textContent = data.response;
                    metaEl.textContent = `mode=${data.mode} | timestamp=${data.timestamp}`;
                    statusEl.textContent = "Completed";
                } catch (err) {
                    responseEl.textContent = "Unable to process prompt right now.";
                    metaEl.textContent = "";
                    statusEl.textContent = err.message;
                } finally {
                    runBtn.disabled = false;
                }
            }

            runBtn.addEventListener("click", runPrompt);
            clearBtn.addEventListener("click", () => {
                promptEl.value = "";
                responseEl.textContent = "No response yet.";
                metaEl.textContent = "";
                statusEl.textContent = "Ready";
            });
        </script>
    </body>
</html>
"""


def json_response(handler: BaseHTTPRequestHandler, status_code: int, payload: dict) -> None:
    body = json.dumps(payload).encode("utf-8")
    handler.send_response(status_code)
    handler.send_header("Content-Type", "application/json")
    handler.send_header("Cache-Control", "no-store")
    handler.send_header("Content-Length", str(len(body)))
    handler.end_headers()
    handler.wfile.write(body)


def html_response(handler: BaseHTTPRequestHandler, html: str) -> None:
    body = html.encode("utf-8")
    handler.send_response(200)
    handler.send_header("Content-Type", "text/html; charset=utf-8")
    handler.send_header("Cache-Control", "no-store")
    handler.send_header("Content-Length", str(len(body)))
    handler.end_headers()
    handler.wfile.write(body)


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(b"ok")
            return

        if self.path == "/":
            html_response(self, APP_HTML)
            return

        json_response(self, 404, {"error": "not_found"})

    def do_POST(self):
        if self.path != "/api/prompt":
            json_response(self, 404, {"error": "not_found"})
            return

        content_length = int(self.headers.get("Content-Length", "0"))
        if content_length <= 0 or content_length > 32_768:
            json_response(self, 400, {"error": "invalid_payload"})
            return

        raw = self.rfile.read(content_length)

        try:
            data = json.loads(raw.decode("utf-8"))
        except (json.JSONDecodeError, UnicodeDecodeError):
            json_response(self, 400, {"error": "invalid_json"})
            return

        prompt = str(data.get("prompt", "")).strip()
        if not prompt:
            json_response(self, 400, {"error": "prompt_required"})
            return

        if len(prompt) > 4000:
            json_response(self, 400, {"error": "prompt_too_long"})
            return

        now = datetime.now(timezone.utc).isoformat()
        reply = (
            "Received your prompt.\n\n"
            f"Prompt:\n{prompt}\n\n"
            "This UI is ready for developers. Next integration step is wiring this endpoint "
            "to your assistant backend/model service."
        )

        json_response(
            self,
            200,
            {
                "mode": "developer-ui",
                "timestamp": now,
                "response": reply,
            },
        )

    def log_message(self, format: str, *args):
        # Keep logs concise in Cloud Run; default logs include repeated health checks.
        return


def run() -> None:
        port = int(os.environ.get("PORT", "8080"))
        server = HTTPServer(("0.0.0.0", port), Handler)
        print(f"Starting server on 0.0.0.0:{port}")
        server.serve_forever()


if __name__ == "__main__":
    run()
