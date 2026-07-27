"use strict";

const BOT_URL = "http://127.0.0.1:8795";
const botMessage = document.getElementById("botMessage");
const botState = document.getElementById("botState");
const botDot = document.getElementById("botDot");
const systemStatus = document.getElementById("systemStatus");

document.getElementById("year").textContent =
  new Date().getFullYear();

function openBot() {
  window.location.href = `${BOT_URL}/?v=${Date.now()}`;
}

async function checkBot() {
  botMessage.textContent = "Lokale Order Bot controleren…";

  try {
    const response = await fetch(
      `${BOT_URL}/health?t=${Date.now()}`,
      {
        method: "GET",
        cache: "no-store"
      }
    );

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }

    const data = await response.json();

    botDot.className = "status-dot online";
    botState.textContent =
      `${data.activeWorkers || 0}/${data.maxWorkers || 20} actief`;

    systemStatus.textContent = "Online";

    botMessage.textContent =
      `Order Bot online — wachtend: ${data.waiting || 0}, ` +
      `voltooid: ${data.completed || 0}.`;
  } catch (error) {
    botDot.className = "status-dot offline";
    botState.textContent = "Niet bereikbaar";
    systemStatus.textContent = "Website online";

    botMessage.textContent =
      "De publieke website werkt. Start de lokale Order Bot " +
      "in Termux om de wachtrij te beheren.";
  }
}

document
  .getElementById("openBot")
  .addEventListener("click", openBot);

document
  .getElementById("openDashboard")
  .addEventListener("click", openBot);

document
  .getElementById("checkDashboard")
  .addEventListener("click", checkBot);

checkBot();
