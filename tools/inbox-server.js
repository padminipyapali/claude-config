/**
 * Claude Annotation Inbox Server
 * Serves annotate.js and accepts POST /inbox to save feedback.
 * Inbox: ~/.claude/inbox/<timestamp>.json
 *
 * Usage: node ~/.claude/tools/inbox-server.js
 */
const http = require("http");
const fs = require("fs");
const path = require("path");

const PORT = 9876;
const TOOLS_DIR = path.join(process.env.HOME, ".claude", "tools");
const INBOX_DIR = path.join(process.env.HOME, ".claude", "inbox");

// Ensure inbox directory exists
if (!fs.existsSync(INBOX_DIR)) {
  fs.mkdirSync(INBOX_DIR, { recursive: true });
}

const server = http.createServer((req, res) => {
  // CORS headers for all responses
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") {
    res.writeHead(204);
    res.end();
    return;
  }

  // POST /inbox — save annotation feedback
  if (req.method === "POST" && req.url === "/inbox") {
    let body = "";
    req.on("data", chunk => { body += chunk; });
    req.on("end", () => {
      try {
        const data = JSON.parse(body);
        const ts = new Date().toISOString().replace(/[:.]/g, "-");
        const filename = `annotation-${ts}.json`;
        fs.writeFileSync(path.join(INBOX_DIR, filename), JSON.stringify(data, null, 2));
        const count = fs.readdirSync(INBOX_DIR).filter(f => f.endsWith(".json")).length;
        res.writeHead(200, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ ok: true, file: filename, pending: count }));
        console.log(`[inbox] Saved ${filename} (${count} pending)`);
      } catch (e) {
        res.writeHead(400, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ error: "Invalid JSON" }));
      }
    });
    return;
  }

  // GET /inbox — list pending items
  if (req.method === "GET" && req.url === "/inbox") {
    const files = fs.readdirSync(INBOX_DIR).filter(f => f.endsWith(".json")).sort();
    const items = files.map(f => {
      const data = JSON.parse(fs.readFileSync(path.join(INBOX_DIR, f), "utf8"));
      return { file: f, ...data };
    });
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify(items, null, 2));
    return;
  }

  // GET /annotate.js — serve the toolkit
  if (req.method === "GET" && req.url === "/annotate.js") {
    const content = fs.readFileSync(path.join(TOOLS_DIR, "annotate.js"), "utf8");
    res.writeHead(200, { "Content-Type": "application/javascript" });
    res.end(content);
    return;
  }

  // 404
  res.writeHead(404);
  res.end("Not found");
});

server.listen(PORT, () => {
  console.log(`[inbox] Claude annotation server on http://localhost:${PORT}`);
  console.log(`[inbox] Bookmarklet loads from http://localhost:${PORT}/annotate.js`);
  console.log(`[inbox] Feedback saved to ${INBOX_DIR}`);
});
