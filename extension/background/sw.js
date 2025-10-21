import { analyzeSleepFromHistory } from "../lib/analyze.js";
import { saveRecord } from "../lib/storage.js";
import { postSleep } from "../lib/backend.js";

const ALARM = "scan-history";
const PERIOD_MIN = 60;

async function runOnce() {
  const res = await analyzeSleepFromHistory();
  if (!res) return;
  await saveRecord(res);
  // 手動ではなくSW経由であることを明示
  postSleep(res, "sw").catch(() => {});
}

chrome.runtime.onInstalled.addListener(async () => {
  chrome.alarms.create(ALARM, { periodInMinutes: PERIOD_MIN });
  // 初回即実行（最初のデータをすぐ得たい場合）
  runOnce();
});

chrome.runtime.onStartup.addListener(async () => {
  // ブラウザ再起動時にアラームが無ければ作る（保険）
  const existing = await chrome.alarms.get(ALARM);
  if (!existing) chrome.alarms.create(ALARM, { periodInMinutes: PERIOD_MIN });
  // 起動直後にも一回走らせたいならコメント解除
  // runOnce();
});

chrome.alarms.onAlarm.addListener((a) => {
  if (a.name !== ALARM) return;
  runOnce();
});
