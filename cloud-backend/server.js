import express from "express";
import { GoogleGenAI } from "@google/genai";

const app = express();
const PORT = process.env.PORT || 8080;
const ALLOWED_ORIGIN =
  process.env.ALLOWED_ORIGIN ||
  "https://ice1984m.github.io";

app.use(express.json({ limit: "32kb" }));

app.use((req, res, next) => {
  res.setHeader("Access-Control-Allow-Origin", ALLOWED_ORIGIN);
  res.setHeader("Vary", "Origin");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");
  res.setHeader("Access-Control-Allow-Methods", "POST,OPTIONS");

  if (req.method === "OPTIONS") {
    return res.sendStatus(204);
  }

  next();
});

app.get("/", (req, res) => {
  res.json({
    service: "Mikis13 AI",
    status: "online"
  });
});

app.post("/chat", async (req, res) => {
  try {
    const message = String(req.body?.message || "").trim();

    if (!message) {
      return res.status(400).json({
        error: "Bericht ontbreekt."
      });
    }

    if (message.length > 2000) {
      return res.status(400).json({
        error: "Bericht is te lang."
      });
    }

    const ai = new GoogleGenAI({
      vertexai: true,
      project: process.env.GOOGLE_CLOUD_PROJECT,
      location: process.env.GOOGLE_CLOUD_LOCATION || "global"
    });

    const result = await ai.models.generateContent({
      model: "gemini-2.5-flash",
      contents: message,
      config: {
        systemInstruction:
          "Je bent Mikis13 AI. Antwoord duidelijk, behulpzaam en in het Nederlands. Doe geen financiële garanties en verzin geen feiten."
      }
    });

    const answer =
      result.text ||
      "Ik kon geen antwoord genereren.";

    res.json({ answer });
  } catch (error) {
    console.error(error);

    res.status(500).json({
      error: "Google AI kon momenteel niet antwoorden."
    });
  }
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Mikis13 AI luistert op poort ${PORT}`);
});
