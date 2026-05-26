#!/usr/bin/env node
"use strict";

const fs = require("fs");
const http = require("http");
const path = require("path");
const { exists, getState, jobs, repoDir, runScript } = require("./core");

const publicDir = path.join(__dirname, "public");

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
      sendJson(res, 200, getState());
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
