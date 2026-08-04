import fs from "node:fs";
import path from "node:path";

const root = process.cwd();
const changes = [];
const errors = [];

function exactFile(file, content) {
  const target = path.join(root, file);
  const old = fs.existsSync(target) ? fs.readFileSync(target, "utf8") : "";
  if (old !== content) {
    fs.mkdirSync(path.dirname(target), { recursive: true });
    fs.writeFileSync(target, content);
    changes.push(file);
  }
}

exactFile("CNAME", "www.mikis13.nl\n");

for (const file of [
  "index.html",
  "contact.html",
  "privacy.html",
  "voorwaarden.html",
  "jobs.html",
  "assets/style.css",
]) {
  const target = path.join(root, file);
  if (!fs.existsSync(target) || fs.statSync(target).size === 0) {
    errors.push(`${file} ontbreekt of is leeg`);
  }
}

const index = path.join(root, "index.html");
if (fs.existsSync(index)) {
  const old = fs.readFileSync(index, "utf8");
  const fixed = old.replaceAll('href="/ai-console.html"', 'href="./ai-console.html"');
  if (fixed !== old) {
    fs.writeFileSync(index, fixed);
    changes.push("index.html");
  }
}

console.log(JSON.stringify({ changes, errors }, null, 2));
if (errors.length) process.exit(2);
