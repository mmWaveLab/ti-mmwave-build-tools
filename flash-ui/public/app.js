"use strict";

const $ = (id) => document.getElementById(id);
const els = {
  refresh: $("refreshBtn"),
  statusStrip: $("statusStrip"),
  statusTitle: $("statusTitle"),
  statusText: $("statusText"),
  portCount: $("portCount"),
  portSelect: $("portSelect"),
  portInput: $("portInput"),
  binSelect: $("binSelect"),
  binInput: $("binInput"),
  dsliteInput: $("dsliteInput"),
  ccxmlInput: $("ccxmlInput"),
  settingsInput: $("settingsInput"),
  cliDirInput: $("cliDirInput"),
  dryRun: $("dryRunBtn"),
  flash: $("flashBtn"),
  confirm: $("confirmInput"),
  progress: $("progressBar"),
  log: $("logBox"),
  toast: $("toast"),
  clearLog: $("clearLogBtn"),
};

let progressTimer = null;

function toast(text) {
  els.toast.textContent = text;
  els.toast.classList.add("show");
  window.clearTimeout(toast.timer);
  toast.timer = window.setTimeout(() => els.toast.classList.remove("show"), 1900);
}

function setStatus(title, text, progress) {
  els.statusTitle.textContent = title;
  els.statusText.textContent = text;
  els.statusStrip.style.setProperty("--sweep", `${Math.min(100, progress || 0)}%`);
  if (typeof progress === "number") els.progress.style.width = `${progress}%`;
}

function log(line, kind = "info") {
  const prefix = kind === "stderr" ? "! " : kind === "ui" ? "> " : "";
  els.log.textContent += `${prefix}${line}\n`;
  els.log.scrollTop = els.log.scrollHeight;
}

function payload() {
  return {
    port: els.portInput.value.trim(),
    bin: els.binInput.value.trim(),
    dslite: els.dsliteInput.value.trim(),
    ccxml: els.ccxmlInput.value.trim(),
    ufsettings: els.settingsInput.value.trim(),
    uniflashCliDir: els.cliDirInput.value.trim(),
    confirm: els.confirm.value.trim(),
  };
}

async function api(path, options = {}) {
  const res = await fetch(path, {
    headers: { "content-type": "application/json" },
    ...options,
  });
  const data = await res.json();
  if (!res.ok) throw new Error(data.error || `HTTP ${res.status}`);
  return data;
}

function startProgress(label) {
  window.clearInterval(progressTimer);
  let value = 8;
  setStatus(label, "任务已提交，正在等待工具输出。", value);
  progressTimer = window.setInterval(() => {
    value = Math.min(92, value + Math.max(1, (96 - value) * 0.035));
    els.progress.style.width = `${value}%`;
  }, 180);
}

function finishProgress(ok) {
  window.clearInterval(progressTimer);
  els.progress.style.width = ok ? "100%" : "100%";
  setTimeout(() => {
    if (ok) els.progress.style.width = "0%";
  }, 900);
}

function watchJob(id) {
  const source = new EventSource(`/api/jobs/${id}/events`);
  source.addEventListener("snapshot", (event) => {
    const job = JSON.parse(event.data);
    for (const item of job.lines || []) log(item.text, item.stream);
  });
  source.addEventListener("line", (event) => {
    const item = JSON.parse(event.data);
    log(item.text, item.stream);
    if (/error|missing|failed/i.test(item.text)) {
      setStatus("需要处理", item.text.slice(0, 120), 88);
    } else {
      setStatus("运行中", item.text.slice(0, 120), undefined);
    }
  });
  source.addEventListener("done", (event) => {
    const done = JSON.parse(event.data);
    const ok = done.status === "success";
    finishProgress(ok);
    setStatus(ok ? "完成" : "失败", ok ? "任务完成，日志已写入。" : `退出码 ${done.exitCode}，看实时日志。`, ok ? 100 : 100);
    toast(ok ? "完成" : "失败，查看日志");
    source.close();
    els.dryRun.disabled = false;
    els.flash.disabled = els.confirm.value.trim() !== "FLASH";
  });
}

async function refresh() {
  els.refresh.classList.add("pulse");
  setTimeout(() => els.refresh.classList.remove("pulse"), 720);
  setStatus("刷新中", "扫描串口、固件和 DSLite。", 18);
  const state = await api("/api/state");

  els.portSelect.innerHTML = "";
  for (const port of state.ports) {
    const option = new Option(port.device, port.device);
    els.portSelect.add(option);
  }
  els.portCount.textContent = `${state.ports.length} ports`;
  if (state.ports[0] && !els.portInput.value) els.portInput.value = state.ports[0].device;

  els.binSelect.innerHTML = "";
  for (const bin of state.bins) {
    const mib = (bin.size / 1024 / 1024).toFixed(2);
    els.binSelect.add(new Option(`${bin.label}  ${mib} MiB`, bin.path));
  }
  if (state.bins[0] && !els.binInput.value) els.binInput.value = state.bins[0].path;
  if (state.dslite && !els.dsliteInput.value) els.dsliteInput.value = state.dslite;

  setStatus("就绪", "刷新完成。建议先 Dry Run。", 0);
  toast("已刷新");
}

async function startDryRun() {
  els.dryRun.disabled = true;
  els.flash.disabled = true;
  log("Dry run requested", "ui");
  startProgress("Dry Run");
  const { id } = await api("/api/dry-run", { method: "POST", body: JSON.stringify(payload()) });
  watchJob(id);
}

async function startFlash() {
  if (els.confirm.value.trim() !== "FLASH") return;
  els.dryRun.disabled = true;
  els.flash.disabled = true;
  log("Flash requested", "ui");
  startProgress("烧录中");
  const { id } = await api("/api/flash", { method: "POST", body: JSON.stringify(payload()) });
  watchJob(id);
}

for (const button of document.querySelectorAll(".magnetic, .icon-button, .ghost")) {
  button.addEventListener("pointerdown", () => {
    button.animate([
      { transform: "scale(1)" },
      { transform: "scale(0.965)" },
      { transform: "scale(1)" },
    ], { duration: 170, easing: "cubic-bezier(.2,.9,.2,1)" });
  });
}

els.portSelect.addEventListener("change", () => { els.portInput.value = els.portSelect.value; });
els.binSelect.addEventListener("change", () => { els.binInput.value = els.binSelect.value; });
els.confirm.addEventListener("input", () => { els.flash.disabled = els.confirm.value.trim() !== "FLASH"; });
els.refresh.addEventListener("click", () => refresh().catch((error) => toast(error.message)));
els.dryRun.addEventListener("click", () => startDryRun().catch((error) => {
  els.dryRun.disabled = false;
  els.flash.disabled = els.confirm.value.trim() !== "FLASH";
  finishProgress(false);
  toast(error.message);
}));
els.flash.addEventListener("click", () => startFlash().catch((error) => {
  els.dryRun.disabled = false;
  els.flash.disabled = els.confirm.value.trim() !== "FLASH";
  finishProgress(false);
  toast(error.message);
}));
els.clearLog.addEventListener("click", () => { els.log.textContent = ""; toast("日志已清空"); });

refresh().catch((error) => {
  setStatus("刷新失败", error.message, 0);
  toast(error.message);
});
