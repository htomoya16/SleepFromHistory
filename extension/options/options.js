import { analyzeSleepFromHistory } from "../lib/analyze.js";
import { loadRecords, saveRecord, clearRecords } from "../lib/storage.js";
import { postSleep } from "../lib/backend.js";

const out = document.getElementById("out");
document.getElementById("scan").addEventListener("click", onScan);
document.getElementById("clear").addEventListener("click", async () => {
  await clearRecords();
  render();
});

chrome.storage.onChanged.addListener((changes, area) => {
  if (area === "local" && changes.sleepRecords) render();
});


const scanBtn = document.getElementById("scan");

async function onScan() {
  scanBtn.disabled = true;
  try {
    const res = await analyzeSleepFromHistory();
    if (res) {
      const records = await loadRecords();
      const latest = records[0];
      const dup = latest && latest.windowStart === res.windowStart && latest.windowEnd === res.windowEnd;
      if (!dup) await saveRecord(res);
      try { await postSleep(res); } catch {}
    }
  } finally {
    scanBtn.disabled = false;
    render();
  }
}


async function render() {
  const records = await loadRecords();
  if (!records.length) { out.textContent = "記録なし"; return; }
  const fmt = new Intl.DateTimeFormat(undefined, { dateStyle: "short", timeStyle: "short" });
  out.textContent = records.map(r => {
    const s = fmt.format(new Date(r.windowStart));
    const e = fmt.format(new Date(r.windowEnd));
    const h = Math.floor(r.gapMinutes/60), m = r.gapMinutes%60;
    return `• ${s} → ${e}（${h}時間${m}分）`;
  }).join("\n");
}

render();
