import { NextRequest, NextResponse } from "next/server";

export async function POST(req: NextRequest){
  const body = await req.json().catch(()=>({}));
  const message = String(body?.message || "").trim().slice(0, 4000);
  if(!message) return NextResponse.json({error:"Message required"}, {status:400});

  const key = process.env.OPENAI_API_KEY;
  if(!key) return NextResponse.json({error:"Server not configured"}, {status:500});

  const r = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${key}`
    },
    body: JSON.stringify({
      model: process.env.OPENAI_MODEL || "gpt-4.1-mini",
      input: [{ role: "user", content: message }]
    })
  });

  if(!r.ok) return NextResponse.json({error:"Provider error"}, {status:502});
  const d = await r.json();
  return NextResponse.json({reply: d?.output_text || "Geen antwoord."});
}
