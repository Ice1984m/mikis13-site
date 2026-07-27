import express from "express";
import OpenAI from "openai";
import path from "node:path";
import { fileURLToPath } from "node:url";

const app = express();
const PORT = Number(process.env.PORT || 4500);
const HOST = process.env.HOST || "127.0.0.1";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

app.use(express.json({ limit: "1mb" }));
app.use(express.static(__dirname));

const bots = {
  architect: {
    name: "GPT Architect",
    model: process.env.MODEL_ARCHITECT || "gpt-5",
    fallback: "gpt-5",
    task:
      "Je bent hoofdarchitect van Mikis13. Ontwerp veilige, duidelijke en uitvoerbare oplossingen. Controleer eerst de structuur en geef daarna complete code."
  },

  codex: {
    name: "Codex Programmeur",
    model: process.env.MODEL_CODEX || "gpt-5.1-codex",
    fallback: "gpt-5",
    task:
      "Je bent een gespecialiseerde programmeerbot. Schrijf robuuste productiecode, herstel fouten en lever volledige bestanden. Gebruik duidelijke foutafhandeling."
  },

  debugger: {
    name: "GPT Debugger",
    model: process.env.MODEL_DEBUGGER || "gpt-5-mini",
    fallback: "gpt-5",
    task:
      "Je bent een debugger. Zoek concrete fouten in code, logs, GitHub Actions, Termux, HTML, JavaScript en servers. Geef de oorzaak en een werkende reparatie."
  },

  security: {
    name: "GPT Security",
    model: process.env.MODEL_SECURITY || "gpt-5",
    fallback: "gpt-5",
    task:
      "Je bent een defensieve securitycontroleur. Controleer geheimen, invoervalidatie, authenticatie, rechten en configuratie. Geef uitsluitend legale beschermingsmaatregelen."
  },

  reviewer: {
    name: "GPT Reviewer",
    model: process.env.MODEL_REVIEWER || "gpt-5-nano",
    fallback: "gpt-5",
    task:
      "Je bent de laatste kwaliteitscontrole. Controleer antwoorden van andere bots op fouten, ontbrekende stappen, risico's en eenvoud. Maak één verbeterde eindversie."
  }
};

function getClient() {
  const apiKey = process.env.OPENAI_API_KEY;

  if (!apiKey) {
    throw new Error(
      "OPENAI_API_KEY ontbreekt. Start eerst: export OPENAI_API_KEY='jouw_sleutel'"
    );
  }

  return new OpenAI({ apiKey });
}

async function askModel(client, model, instructions, input) {
  const response = await client.responses.create({
    model,
    instructions,
    input,
    store: false
  });

  return response.output_text || "Geen tekst ontvangen.";
}

app.get("/api/status", (req, res) => {
  res.json({
    online: true,
    port: PORT,
    apiKeyConfigured: Boolean(process.env.OPENAI_API_KEY),
    bots: Object.entries(bots).map(([id, bot]) => ({
      id,
      name: bot.name,
      model: bot.model,
      task: bot.task
    }))
  });
});

app.post("/api/ask", async (req, res) => {
  const botId = String(req.body?.bot || "");
  const prompt = String(req.body?.prompt || "").trim();

  if (!bots[botId]) {
    return res.status(400).json({ error: "Onbekende bot." });
  }

  if (!prompt) {
    return res.status(400).json({ error: "Voer eerst een opdracht in." });
  }

  try {
    const client = getClient();
    const bot = bots[botId];

    let answer;
    let usedModel = bot.model;
    let fallbackUsed = false;

    try {
      answer = await askModel(client, bot.model, bot.task, prompt);
    } catch (firstError) {
      if (bot.model === bot.fallback) {
        throw firstError;
      }

      usedModel = bot.fallback;
      fallbackUsed = true;

      answer = await askModel(
        client,
        bot.fallback,
        bot.task,
        prompt
      );
    }

    res.json({
      bot: botId,
      name: bot.name,
      requestedModel: bot.model,
      usedModel,
      fallbackUsed,
      answer
    });
  } catch (error) {
    console.error(error);

    res.status(500).json({
      error: error?.message || "De AI-opdracht is mislukt."
    });
  }
});

app.post("/api/combine", async (req, res) => {
  const prompt = String(req.body?.prompt || "").trim();

  if (!prompt) {
    return res.status(400).json({ error: "Voer eerst een opdracht in." });
  }

  try {
    const client = getClient();
    const results = [];

    for (const [id, bot] of Object.entries(bots)) {
      let answer;
      let usedModel = bot.model;

      try {
        answer = await askModel(client, bot.model, bot.task, prompt);
      } catch {
        usedModel = bot.fallback;
        answer = await askModel(client, bot.fallback, bot.task, prompt);
      }

      results.push({
        id,
        name: bot.name,
        model: usedModel,
        answer
      });
    }

    const combinedInput = [
      `Oorspronkelijke opdracht:\n${prompt}`,
      "",
      "Antwoorden van de vijf bots:",
      ...results.map(
        result =>
          `\n--- ${result.name} (${result.model}) ---\n${result.answer}`
      )
    ].join("\n");

    const finalAnswer = await askModel(
      client,
      bots.reviewer.fallback,
      "Combineer de vijf analyses tot één correcte, veilige, complete en direct uitvoerbare eindoplossing. Verwijder herhaling en herstel tegenstrijdigheden.",
      combinedInput
    );

    res.json({
      results,
      finalAnswer
    });
  } catch (error) {
    console.error(error);

    res.status(500).json({
      error: error?.message || "Combineren is mislukt."
    });
  }
});

app.listen(PORT, HOST, () => {
  console.log(`Mikis13 draait op http://${HOST}:${PORT}`);
  console.log(`AI-console: http://${HOST}:${PORT}/ai-console.html`);
  console.log(`Gokpagina:  http://${HOST}:${PORT}/goksites.html`);
});
