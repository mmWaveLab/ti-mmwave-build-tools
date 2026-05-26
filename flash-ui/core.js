"use strict";

const fs = require("fs");
const path = require("path");
const { spawn } = require("child_process");
const { randomUUID } = require("crypto");

const repoDir = path.resolve(__dirname, "..");
const jobs = new Map();

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

function getState() {
  return {
    repoDir,
    ports: listPorts(),
    bins: findBins(),
    dslite: findDslite(),
    now: new Date().toISOString(),
  };
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

function runScript(script, payload = {}, confirmFlash = false) {
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

function runJobToCompletion(script, payload = {}, confirmFlash = false, onEvent = () => {}) {
  return new Promise((resolve) => {
    const job = runScript(script, payload, confirmFlash);
    onEvent("start", { id: job.id, status: job.status, startedAt: job.startedAt });

    const listener = {
      write(chunk) {
        for (const block of chunk.split("\n\n")) {
          if (!block.trim()) continue;
          const eventMatch = block.match(/^event: (.+)$/m);
          const dataMatch = block.match(/^data: (.+)$/m);
          if (!eventMatch || !dataMatch) continue;
          onEvent(eventMatch[1], JSON.parse(dataMatch[1]));
        }
      },
      end() {},
    };
    job.listeners.add(listener);

    const poll = setInterval(() => {
      if (job.status === "running") return;
      clearInterval(poll);
      job.listeners.delete(listener);
      resolve(job);
    }, 25);
  });
}

module.exports = {
  repoDir,
  jobs,
  exists,
  getState,
  runScript,
  runJobToCompletion,
};
