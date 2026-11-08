// Mollie-betalingen, volledig server-side.
//
// Veiligheidsregels:
//  - De Mollie API-sleutel staat alleen in de omgevingsvariabele MOLLIE_API_KEY.
//  - Prijzen komen uit de catalogus op de server, nooit uit de browser.
//  - Een bestelling wordt alleen geaccepteerd als COMMERCE_READY=true staat
//    EN het product zelf gpsr_ready en commerce_ready heeft.
//  - De webhook vertrouwt de inhoud niet: de status wordt bij Mollie opgehaald.
import express from "express";
import { randomUUID } from "node:crypto";
import { Firestore } from "@google-cloud/firestore";

const MOLLIE_API = "https://api.mollie.com/v2";
const PRODUCTS_URL =
  process.env.PRODUCTS_URL ||
  "https://ice1984m.github.io/mikis13-site/data/products.json";
const SITE_URL =
  process.env.SITE_URL || "https://ice1984m.github.io/mikis13-site";
const PUBLIC_API_URL = process.env.PUBLIC_API_URL || ""; // bv. https://api.jouwdomein.be
const SHIPPING_CENTS = Number(process.env.SHIPPING_CENTS || 0);
const CATALOG_TTL_MS = 5 * 60 * 1000;

let catalog = { at: 0, byId: new Map() };
let db;
const orders = () => (db ??= new Firestore()).collection("orders");

const commerceOpen = () => process.env.COMMERCE_READY === "true";

async function getCatalog() {
  if (Date.now() - catalog.at < CATALOG_TTL_MS && catalog.byId.size) {
    return catalog.byId;
  }
  const res = await fetch(PRODUCTS_URL);
  if (!res.ok) throw new Error(`Catalogus niet bereikbaar (${res.status})`);
  const data = await res.json();
  const list = Array.isArray(data) ? data : data.products;
  catalog = { at: Date.now(), byId: new Map(list.map((p) => [String(p.id), p])) };
  return catalog.byId;
}

async function mollie(path, init = {}) {
  const key = process.env.MOLLIE_API_KEY;
  if (!key) throw new Error("MOLLIE_API_KEY ontbreekt");
  const res = await fetch(`${MOLLIE_API}${path}`, {
    ...init,
    headers: {
      Authorization: `Bearer ${key}`,
      "Content-Type": "application/json",
      ...(init.headers || {}),
    },
  });
  const body = await res.json();
  if (!res.ok) throw new Error(body?.detail || `Mollie fout ${res.status}`);
  return body;
}

const euro = (cents) => (cents / 100).toFixed(2);
const validEmail = (v) => /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(v);

export function paymentRoutes() {
  const router = express.Router();
  router.use(express.urlencoded({ extended: false, limit: "4kb" }));

  // Browser -> server: bestelling aanmaken en doorsturen naar Mollie.
  router.post("/checkout", async (req, res) => {
    try {
      if (!commerceOpen()) {
        return res.status(503).json({
          error: "De webshop is nog niet open voor bestellingen.",
        });
      }

      const name = String(req.body?.name || "").trim();
      const email = String(req.body?.email || "").trim();
      const address = String(req.body?.address || "").trim();
      const items = Array.isArray(req.body?.items) ? req.body.items : [];

      if (!name || !address || !validEmail(email)) {
        return res.status(400).json({ error: "Naam, adres of e-mail ontbreekt." });
      }
      if (!items.length || items.length > 30) {
        return res.status(400).json({ error: "Winkelwagen is leeg of te groot." });
      }

      const products = await getCatalog();
      let subtotal = 0;
      const lines = [];

      for (const item of items) {
        const product = products.get(String(item?.id));
        const qty = Number.parseInt(item?.qty, 10);
        if (!product || !Number.isInteger(qty) || qty < 1 || qty > 20) {
          return res.status(400).json({ error: "Ongeldig product of aantal." });
        }
        if (!product.gpsr_ready || !product.commerce_ready) {
          return res.status(409).json({
            error: `${product.name} is nog niet beschikbaar voor verkoop.`,
          });
        }
        if (Number.isFinite(product.stock) && qty > product.stock) {
          return res.status(409).json({ error: `${product.name}: onvoldoende voorraad.` });
        }
        const unit = Math.round(Number(product.price) * 100);
        subtotal += unit * qty;
        lines.push({ id: product.id, sku: product.sku, name: product.name, qty, unit_cents: unit });
      }

      const total = subtotal + SHIPPING_CENTS;
      const orderId = `ORD-${randomUUID().slice(0, 8).toUpperCase()}`;

      const payment = await mollie("/payments", {
        method: "POST",
        body: JSON.stringify({
          amount: { currency: "EUR", value: euro(total) },
          description: `Mikis13 bestelling ${orderId}`,
          redirectUrl: `${SITE_URL}/order-status.html?order=${orderId}`,
          webhookUrl: `${PUBLIC_API_URL}/mollie/webhook`,
          locale: "nl_BE",
          metadata: { orderId },
        }),
      });

      await orders().doc(orderId).set({
        orderId,
        name,
        email,
        address,
        lines,
        subtotal_cents: subtotal,
        shipping_cents: SHIPPING_CENTS,
        total_cents: total,
        paymentId: payment.id,
        status: "open",
        createdAt: new Date().toISOString(),
      });

      res.json({ orderId, checkoutUrl: payment._links.checkout.href });
    } catch (error) {
      console.error(error);
      res.status(500).json({ error: "Betaling kon niet gestart worden." });
    }
  });

  // Mollie -> server: status bijwerken. Body bevat alleen het betaal-id.
  router.post("/mollie/webhook", async (req, res) => {
    try {
      const id = String(req.body?.id || "");
      if (!/^tr_[A-Za-z0-9]+$/.test(id)) return res.sendStatus(400);

      const payment = await mollie(`/payments/${id}`);
      const orderId = payment.metadata?.orderId;
      if (!orderId) return res.sendStatus(200);

      const ref = orders().doc(orderId);
      const snap = await ref.get();
      if (!snap.exists || snap.data().paymentId !== id) return res.sendStatus(200);

      // Alleen vooruit in status; een betaalde bestelling gaat niet terug.
      const current = snap.data().status;
      const next = payment.status; // open | pending | paid | failed | canceled | expired
      if (current !== "paid" && current !== next) {
        await ref.update({
          status: next,
          ...(next === "paid" ? { paidAt: payment.paidAt || new Date().toISOString() } : {}),
        });
      }
      res.sendStatus(200);
    } catch (error) {
      console.error(error);
      res.sendStatus(500); // Mollie probeert het later opnieuw
    }
  });

  // Alleen publieke status, geen persoonsgegevens.
  router.get("/orders/:id/status", async (req, res) => {
    try {
      const snap = await orders().doc(String(req.params.id)).get();
      if (!snap.exists) return res.status(404).json({ error: "Onbekende bestelling." });
      res.json({ orderId: req.params.id, status: snap.data().status });
    } catch (error) {
      console.error(error);
      res.status(500).json({ error: "Status niet beschikbaar." });
    }
  });

  return router;
}
