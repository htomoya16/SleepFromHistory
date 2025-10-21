import { DEFAULT_LAST_HOURS, SLEEP_THRESHOLD_MIN } from "./constants.js";

export async function analyzeSleepFromHistory(
  lastHours = DEFAULT_LAST_HOURS,
  thresholdMin = SLEEP_THRESHOLD_MIN
) {
  const endTime = Date.now();
  const startTime = endTime - lastHours * 60 * 60 * 1000;

  const items = await chrome.history.search({
    text: "",
    startTime,
    endTime,
    maxResults: 5000
  });

  const visits = items.map(i => i.lastVisitTime).filter(Boolean).sort((a,b)=>b-a);
  if (!visits.length) return null;

  let maxGap = { gapMin: 0, from: endTime, to: endTime };
  let prev = endTime;
  for (const t of visits) {
    const gapMin = Math.round((prev - t) / 60000);
    if (gapMin > maxGap.gapMin) maxGap = { gapMin, from: t, to: prev };
    prev = t;
  }
  const first = visits[visits.length - 1];
  const headGapMin = Math.round((first - startTime) / 60000);
  if (headGapMin > maxGap.gapMin) maxGap = { gapMin: headGapMin, from: startTime, to: first };

  if (maxGap.gapMin < thresholdMin) return null;
  return {
    candidate: true,
    windowStart: new Date(maxGap.from).toISOString(),
    windowEnd: new Date(maxGap.to).toISOString(),
    gapMinutes: maxGap.gapMin,
    scannedHours: lastHours
  };
}
