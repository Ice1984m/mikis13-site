const chatButton = document.querySelector("#chatButton");
const chatPanel = document.querySelector("#chatPanel");
const chatForm = document.querySelector("#chatForm");
const chatInput = document.querySelector("#chatInput");
const messages = document.querySelector("#chatMessages");

chatButton?.addEventListener("click", () => {
    chatPanel.classList.toggle("open");
});

function addMessage(text, user = false) {
    const message = document.createElement("div");
    message.className = user ? "message user" : "message";
    message.textContent = text;
    messages.appendChild(message);
    messages.scrollTop = messages.scrollHeight;
}

function localAnswer(question) {
    const text = question.toLowerCase();

    if (text.includes("github") || text.includes("push")) {
        return "Gebruik meestal: git add . && git commit -m \"Update\" && git push origin main";
    }

    if (text.includes("website") || text.includes("pages")) {
        return "Controleer GitHub → repository → Settings → Pages. De bron moet main en /root zijn.";
    }

    if (text.includes("dns") || text.includes("domein")) {
        return "Voor www.mikis13.nl moet bij Combell een CNAME-record staan: www → ice1984m.github.io.";
    }

    if (text.includes("termux")) {
        return "Plak uitsluitend codeblokken in Termux. Gewone uitleg, pijlen en tabellen zijn geen commando’s.";
    }

    if (text.includes("fout")) {
        return "Kopieer de exacte foutmelding. Controleer ook: gh auth status, git status en git remote -v.";
    }

    return "Deze lokale helper geeft basisinformatie. Voor een uitgebreid antwoord kun je de knop ‘Vraag ChatGPT’ gebruiken.";
}

chatForm?.addEventListener("submit", (event) => {
    event.preventDefault();

    const question = chatInput.value.trim();

    if (!question) {
        return;
    }

    addMessage(question, true);
    chatInput.value = "";

    window.setTimeout(() => {
        addMessage(localAnswer(question));
    }, 300);
});
