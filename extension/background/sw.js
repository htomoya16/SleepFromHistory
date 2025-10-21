import { analyzeSleepFromHistory } from "../lib/analyze.js";
import { saveRecord } from "../lib/storage.js";
import { postSleep } from "../lib/backend.js";

chrome.runtime.onInstalled.addListener(() => {
  chrome.alarms.create("scan-history", { periodInMinutes: 60 });
});

chrome.alarms.onAlarm.addListener(async (a) => {
  if (a.name !== "scan-history") return;
  const res = await analyzeSleepFromHistory();
  if (!res) return;
  await saveRecord(res);
  try { await postSleep(res); } catch {}
});
