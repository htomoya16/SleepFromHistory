import { DEFAULT_LAST_HOURS, SLEEP_THRESHOLD_MIN } from "./constants.js";

export async function analyzeSleepFromHistory(
  lastHours = DEFAULT_LAST_HOURS,
  thresholdMin = SLEEP_THRESHOLD_MIN
) {
  // 解析対象の時間窓を UTC ミリ秒で決定する
  const endTime = Date.now();
  const startTime = endTime - lastHours * 60 * 60 * 1000;

  // 直近 lastHours 時間の履歴を取得する
  const items = await chrome.history.search({
    text: "",
    startTime,
    endTime,
    maxResults: 5000
  });

  // 各履歴の最終訪問時刻 lastVisitTime（UTC ms）だけに射影し、null を除外、降順（新→古）で並べる
  const visits = items.map(i => i.lastVisitTime).filter(Boolean).sort((a,b)=>b-a);
  if (!visits.length) return null;

  // 見つかった中で最大のギャップを保持するための初期値
  // とりあえず「今（endTime）から最初の比較まで」のギャップを基準にする
  let maxGap = { gapMin: 0, from: endTime, to: endTime };
  
  // 直前時刻 prev を「今（endTime）」として開始する
  let prev = endTime;

    // 降順（新→古）で並んだ各訪問時刻 t について、
  // 「prev（直近の基準時刻） - t（この訪問）」の差分を分に変換し、最大ギャップを更新する
  for (const t of visits) {
    const gapMin = Math.floor((prev - t) / 60000);
    if (gapMin > maxGap.gapMin) maxGap = { gapMin, from: t, to: prev };
    prev = t;
  }

  // 窓の「先頭（startTime）」から最初の訪問（配列の末尾）までのギャップも評価する
  const first = visits[visits.length - 1];
  const headGapMin = Math.round((first - startTime) / 60000);
  if (headGapMin > maxGap.gapMin) maxGap = { gapMin: headGapMin, from: startTime, to: first };

    // 最大ギャップが閾値に満たない場合は睡眠候補ではないので null
  if (maxGap.gapMin < thresholdMin) return null;
  
  // 閾値以上なら睡眠候補として返す。
  // windowStart / windowEnd は UTC の ISO 8601 文字列（末尾 'Z'）である。
  return {
    candidate: true,
    // UTC→UTC文字列（表示用に整形）
    windowStart: new Date(maxGap.from).toISOString(),
    windowEnd: new Date(maxGap.to).toISOString(),
    gapMinutes: maxGap.gapMin,
    scannedHours: lastHours
  };
}
