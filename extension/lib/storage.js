const KEY = "sleepRecords";

export async function loadRecords() {
  const { [KEY]: records = [] } = await chrome.storage.local.get(KEY);
  return records;
}

export async function saveRecord(r) {
  const records = await loadRecords();
  records.unshift({ ...r, savedAt: new Date().toISOString() });
  await chrome.storage.local.set({ [KEY]: records });
}

export async function clearRecords() {
  await chrome.storage.local.set({ [KEY]: [] });
}
