#!/usr/bin/env node
"use strict";

const fs = require("fs");
const http = require("http");
const path = require("path");
const { spawn } = require("child_process");
const { randomUUID } = require("crypto");

const repoDir = path.resolve(__dirname, "..");
const publicDir = path.join(__dirname, "public");
const jobs = new Map();

const port = Number(process.env.MMWAVELAB_FLASH_PORT || 8765);
const host = process.env.MMWAVELAB_FLASH_HOST || "127.0.0.1";

function sendJson(res, status, value) {
  const body = JSON.stringify(value, null, 2);
  res.writeHead(status, {
    "content-type": "application/json; charset=utf-8",
    "cache-control": "no-store",
  });
  res.end(body);
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let data = "";
    req.setEncoding("utf8");
    req.on("data", (chunk) => {
      data += chunk;
      if (data.length > 1024 * 1024) {
        reject(new Error("request body too large"));
        req.destroy();
      }
    });
    req.on("end", () => {
      if (!data) {
        resolve({});
        return;
      }
      try {
        resolve(JSON.parse(data));
      } catch (error) {
        reject(error);
      }
    });
  });
}

function exists(file) {
  try {
    fs.accessSync(file, fs.constants.F_OK);
    return true;
  } catch {
    return false;
  }
}

function executable(file) {
  try {
    fs.accessSync(file, fs.constants.X_OK);
    return true;
  } catch {
    return false;
  }
}

function globDevice(prefix) {
  const dir = path.dirname(prefix);
  const base = path.basename(prefix).replace("*", "");
  if (!exists(dir)) return [];
  return fs.readdirSync(dir)
    .filter((name) => name.startsWith(base))
    .map((name) => path.join(dir, name))
    .sort();
}

function listPorts() {
  const ports = [...globDevice("/dev/ttyACM*"), ...globDevice("/dev/ttyUSB*")];
  return ports.map((device) => {
    let label = path.basename(device);
    try {
      const stat = fs.lstatSync(device);
      label += stat.isSymbolicLink() ? " symlink" : "";
    } catch {
      // Keep a plain label.
    }
    return { device, label };
  });
}

function findBins() {
  const roots = ["artifacts", "build"]
    .map((name) => path.join(repoDir, name))
    .filter((dir) => exists(dir));
  const bins = [];
  const walk = (dir, depth) => {
    if (depth > 6) return;
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const full = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        if (![".git", "node_modules"].includes(entry.name)) walk(full, depth + 1);
      } else if (entry.isFile() && entry.name.endsWith(".bin")) {
        const stat = fs.statSync(full);
        bins.push({
          path: full,
          label: path.relative(repoDir, full),
          size: stat.size,
          modifiedMs: stat.mtimeMs,
        });
      }
    }
  };
  roots.forEach((root) => walk(root, 0));
  return bins.sort((a, b) => b.modifiedMs - a.modifiedMs).slice(0, 80);
}

function findDslite() {
  const candidates = [];
  if (process.env.DSLITE) candidates.push(process.env.DSLITE);
  if (process.env.UNIFLASH_ROOT) {
    candidates.push(
      path.join(process.env.UNIFLASH_ROOT, "dslite.sh"),
      path.join(process.env.UNIFLASH_ROOT, "dslite"),
      path.join(process.env.UNIFLASH_ROOT, "deskdb/content/TICloudAgent/linux/ccs_base/DebugServer/bin/DSLite"),
    );
  }
  for (const dir of (process.env.PATH || "").split(path.delimiter)) {
    candidates.push(path.join(dir, "dslite.sh"), path.join(dir, "dslite"));
  }
  return candidates.find((candidate) => candidate && executable(candidate)) || "";
}

function envFromPayload(payload, confirmFlash) {
  return {
    ...process.env,
    PORT: payload.port || "",
    BIN: payload.bin || "",
    DSLITE: payload.dslite || "",
    UNIFLASH_ROOT: payload.uniflashRoot || "",
    UNIFLASH_CLI_DIR: payload.uniflashCliDir || "",
    CCXML: payload.ccxml || "",
    UFSETTINGS: payload.ufsettings || "",
    CONFIRM_FLASH: confirmFlash ? "YES" : "",
  };
}

function runScript(script, payload, confirmFlash) {
  const id = randomUUID();
  const job = {
    id,
    status: "running",
    startedAt: new Date().toISOString(),
    exitCode: null,
    lines: [],
    listeners: new Set(),
  };
  jobs.set(id, job);

  const child = spawn(path.join(repoDir, "scripts", script), {
    cwd: repoDir,
    env: envFromPayload(payload, confirmFlash),
    stdio: ["ignore", "pipe", "pipe"],
  });

  const emit = (event, data) => {
    const payloadText = `event: ${event}\ndata: ${JSON.stringify(data)}\n\n`;
    for (const listener of job.listeners) listener.write(payloadText);
  };
  const addLine = (stream, chunk) => {
    const text = chunk.toString();
    for (const line of text.split(/\r?\n/)) {
      if (!line) continue;
      const item = { stream, text: line, at: new Date().toISOString() };
      job.lines.push(item);
      emit("line", item);
    }
  };

  child.stdout.on("data", (chunk) => addLine("stdout", chunk));
  child.stderr.on("data", (chunk) => addLine("stderr", chunk));
  child.on("close", (code) => {
    job.status = code === 0 ? "success" : "failed";
    job.exitCode = code;
    job.finishedAt = new Date().toISOString();
    emit("done", { status: job.status, exitCode: code });
    for (const listener of job.listeners) listener.end();
  });
  child.on("error", (error) => {
    job.status = "failed";
    job.exitCode = 127;
    addLine("stderr", Buffer.from(error.message));
    emit("done", { status: job.status, exitCode: 127 });
  });

  return job;
}

function serveStatic(req, res) {
  const url = new URL(req.url, `http://${req.headers.host}`);
  const pathname = url.pathname === "/" ? "/index.html" : url.pathname;
  const file = path.normalize(path.join(publicDir, pathname));
  if (!file.startsWith(publicDir) || !exists(file)) {
    res.writeHead(404);
    res.end("not found");
    return;
  }
  const ext = path.extname(file);
  const type = {
    ".html": "text/html; charset=utf-8",
    ".css": "text/css; charset=utf-8",
    ".js": "text/javascript; charset=utf-8",
    ".svg": "image/svg+xml",
  }[ext] || "application/octet-stream";
  res.writeHead(200, { "content-type": type, "cache-control": "no-store" });
  fs.createReadStream(file).pipe(res);
}

const server = http.createServer(async (req, res) => {
  try {
    const url = new URL(req.url, `http://${req.headers.host}`);
    if (req.method === "GET" && url.pathname === "/api/state") {
      sendJson(res, 200, {
        repoDir,
        ports: listPorts(),
        bins: findBins(),
        dslite: findDslite(),
        now: new Date().toISOString(),
      });
      return;
    }
    if (req.method === "POST" && url.pathname === "/api/dry-run") {
      const payload = await readBody(req);
      const job = runScript("flash-dry-run.sh", payload, false);
      sendJson(res, 202, { id: job.id });
      return;
    }
    if (req.method === "POST" && url.pathname === "/api/flash") {
      const payload = await readBody(req);
      if (payload.confirm !== "FLASH") {
        sendJson(res, 400, { error: "type FLASH to confirm" });
        return;
      }
      const job = runScript("flash.sh", payload, true);
      sendJson(res, 202, { id: job.id });
      return;
    }
    if (req.method === "GET" && url.pathname.startsWith("/api/jobs/") && url.pathname.endsWith("/events")) {
      const id = url.pathname.split("/")[3];
      const job = jobs.get(id);
      if (!job) {
        sendJson(res, 404, { error: "job not found" });
        return;
      }
      res.writeHead(200, {
        "content-type": "text/event-stream; charset=utf-8",
        "cache-control": "no-store",
        connection: "keep-alive",
      });
      job.listeners.add(res);
      res.write(`event: snapshot\ndata: ${JSON.stringify(job)}\n\n`);
      req.on("close", () => job.listeners.delete(res));
      return;
    }
    serveStatic(req, res);
  } catch (error) {
    sendJson(res, 500, { error: error.message });
  }
});

server.listen(port, host, () => {
  const url = `http://${host}:${port}`;
  console.log(`mmwavelab-flash listening on ${url}`);
  console.log("Press Ctrl+C to stop.");
});
