#!/usr/bin/env node
"use strict";

const { spawn } = require("child_process");
const path = require("path");
const { getState, repoDir, runJobToCompletion } = require("./core");

function usage() {
  return `mmwavelab-flash client

Usage:
  mmwavelab-flash state [--json]
  mmwavelab-flash list [--json]
  mmwavelab-flash doctor [options] [--json|--ndjson]
  mmwavelab-flash dry-run [options] [--json|--ndjson]
  mmwavelab-flash flash --confirm FLASH [options] [--json|--ndjson]
  mmwavelab-flash ui [--host 127.0.0.1] [--port 8765]

Options:
  --port DEVICE              Serial download port.
  --bin FILE                 Flashable firmware image.
  --dslite FILE              DSLite executable.
  --uniflash-root DIR        UniFlash install root.
  --uniflash-cli-dir DIR     Generated UniFlash CLI package.
  --ccxml FILE               TI target configuration.
  --ufsettings FILE          Generated UniFlash settings.
  --confirm FLASH            Required for real flashing.
  --json                     Machine-readable final JSON.
  --ndjson                   Machine-readable event stream.
`;
}

function parse(argv) {
  const args = [...argv];
  const command = args.shift() || "help";
  const options = {
    json: false,
    ndjson: false,
    payload: {},
  };
  for (let i = 0; i < args.length; i += 1) {
    const arg = args[i];
    const take = () => {
      const value = args[i + 1];
      if (!value) throw new Error(`${arg} requires a value`);
      i += 1;
      return value;
    };
    if (arg === "--json") options.json = true;
    else if (arg === "--ndjson") options.ndjson = true;
    else if (arg === "--port" && command === "ui") options.uiPort = take();
    else if (arg === "--port") options.payload.port = take();
    else if (arg === "--bin") options.payload.bin = take();
    else if (arg === "--dslite") options.payload.dslite = take();
    else if (arg === "--uniflash-root") options.payload.uniflashRoot = take();
    else if (arg === "--uniflash-cli-dir") options.payload.uniflashCliDir = take();
    else if (arg === "--ccxml") options.payload.ccxml = take();
    else if (arg === "--ufsettings") options.payload.ufsettings = take();
    else if (arg === "--confirm") options.payload.confirm = take();
    else if (arg === "--host") options.host = take();
    else if (arg === "--ui-port") options.uiPort = take();
    else if (arg === "--listen-port" || arg === "--http-port") options.uiPort = take();
    else if (arg === "--port-http") options.uiPort = take();
    else throw new Error(`unknown option: ${arg}`);
  }
  return { command, options };
}

function writeJson(value) {
  process.stdout.write(`${JSON.stringify(value, null, 2)}\n`);
}

function writeNdjson(event, data) {
  process.stdout.write(`${JSON.stringify({ event, ...data })}\n`);
}

function printState(state) {
  console.log(`repo: ${state.repoDir}`);
  console.log(`dslite: ${state.dslite || "(not found)"}`);
  console.log("\nports:");
  if (state.ports.length === 0) console.log("  (none)");
  for (const port of state.ports) console.log(`  ${port.device}`);
  console.log("\nbins:");
  if (state.bins.length === 0) console.log("  (none)");
  for (const bin of state.bins.slice(0, 12)) console.log(`  ${bin.label}`);
}

function scriptFor(command) {
  if (command === "doctor") return ["flash-doctor.sh", false];
  if (command === "dry-run") return ["flash-dry-run.sh", false];
  if (command === "flash") return ["flash.sh", true];
  throw new Error(`unsupported job command: ${command}`);
}

async function runCommandJob(command, options) {
  if (command === "flash" && options.payload.confirm !== "FLASH") {
    const result = {
      command,
      status: "failed",
      exitCode: 2,
      error: "real flashing requires --confirm FLASH",
    };
    if (options.ndjson) writeNdjson("error", result);
    else if (options.json) writeJson(result);
    else console.error(`ERROR: ${result.error}`);
    process.exitCode = 2;
    return;
  }
  const [script, confirmFlash] = scriptFor(command);
  const events = [];
  const job = await runJobToCompletion(script, options.payload, confirmFlash, (event, data) => {
    if (event === "line") {
      events.push(data);
      if (options.ndjson) writeNdjson(event, data);
      else if (!options.json) {
        const prefix = data.stream === "stderr" ? "ERR " : "";
        console.log(`${prefix}${data.text}`);
      }
    } else if (options.ndjson) {
      writeNdjson(event, data);
    }
  });
  const result = {
    id: job.id,
    command,
    status: job.status,
    exitCode: job.exitCode,
    startedAt: job.startedAt,
    finishedAt: job.finishedAt,
    lines: events,
  };
  if (options.json) writeJson(result);
  if (job.exitCode !== 0) process.exitCode = job.exitCode || 1;
}

function startUi(options) {
  const env = { ...process.env };
  if (options.host) env.MMWAVELAB_FLASH_HOST = options.host;
  if (options.uiPort) env.MMWAVELAB_FLASH_PORT = options.uiPort;
  const child = spawn(process.execPath, [path.join(repoDir, "flash-ui", "server.js")], {
    cwd: repoDir,
    env,
    stdio: "inherit",
  });
  child.on("close", (code) => {
    process.exitCode = code || 0;
  });
}

async function main() {
  const { command, options } = parse(process.argv.slice(2));
  if (["help", "--help", "-h"].includes(command)) {
    console.log(usage());
    return;
  }
  if (command === "state" || command === "list") {
    const state = getState();
    if (options.json) writeJson(state);
    else printState(state);
    return;
  }
  if (command === "ui") {
    startUi(options);
    return;
  }
  if (["doctor", "dry-run", "flash"].includes(command)) {
    await runCommandJob(command, options);
    return;
  }
  throw new Error(`unknown command: ${command}`);
}

main().catch((error) => {
  console.error(`ERROR: ${error.message}`);
  process.exit(2);
});
