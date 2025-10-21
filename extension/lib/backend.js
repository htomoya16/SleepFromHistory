import { API_BASE } from "./constants.js";

export async function postSleep(payload) {
  return fetch(`${API_BASE}/api/sleep`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload)
  });
}
