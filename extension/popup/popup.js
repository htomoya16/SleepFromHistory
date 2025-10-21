// popup.js
document.getElementById("open").addEventListener("click", async () => {
  const url = chrome.runtime.getURL("options.html");
  const tabs = await chrome.tabs.query({ url }); // 既存のoptionsタブを探す
  if (tabs.length > 0) {
    await chrome.tabs.update(tabs[0].id, { active: true });
    await chrome.windows.update(tabs[0].windowId, { focused: true });
  } else {
    // 未作成なら新規。optionsページを使うならこれでOK
    await chrome.runtime.openOptionsPage();
    // もしくは独自の dashboard.html を作るなら:
    // await chrome.tabs.create({ url: chrome.runtime.getURL("dashboard.html") });
  }
  window.close(); // popupを閉じてフォーカスを渡す
});
