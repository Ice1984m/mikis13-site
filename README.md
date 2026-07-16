# Mikis13 Site

Professionele digitale oplossingen — software, websites en AI-integratie.

## 🐳 Docker

### Image bouwen (lokaal)

```bash
docker build -t mikis13-site .
```

### Container draaien (lokaal)

```bash
docker run -p 8080:80 mikis13-site
```

Open daarna <http://localhost:8080> in je browser.

### Draaien met Docker Compose

```bash
docker compose up -d
```

De site is beschikbaar op <http://localhost:8080>.  
Stoppen: `docker compose down`

---

## 📦 Gepubliceerde images (GHCR)

Elke push naar `main` of een versie-tag (`v*`) publiceert automatisch een image naar:

```
ghcr.io/ice1984m/mikis13-site
```

Beschikbare tags:

| Tag | Wanneer |
|-----|---------|
| `main` | Laatste commit op de main-branch |
| `v1.2.3` / `1.2` | Na het aanmaken van een Git-tag |
| `sha-<commit>` | Elke individuele build |

Image pullen:

```bash
docker pull ghcr.io/ice1984m/mikis13-site:main
```

---

## 🚀 Deployen op een Docker-host / VPS

1. **Zorg dat Docker geïnstalleerd is** op je server.

2. **Pull de gewenste image:**

   ```bash
   docker pull ghcr.io/ice1984m/mikis13-site:main
   ```

3. **Start de container:**

   ```bash
   docker run -d \
     --name mikis13-site \
     --restart unless-stopped \
     -p 80:80 \
     ghcr.io/ice1984m/mikis13-site:main
   ```

4. *(Optioneel)* Zet een **reverse proxy** (Nginx, Caddy, Traefik) voor HTTPS op poort 443.

5. **Updaten naar een nieuwe versie:**

   ```bash
   docker pull ghcr.io/ice1984m/mikis13-site:main
   docker stop mikis13-site && docker rm mikis13-site
   # Herhaal stap 3
   ```

---

## 🔖 Release aanmaken

```bash
git tag v1.0.0
git push origin v1.0.0
```

De GitHub Actions workflow bouwt daarna automatisch de image en publiceert die als `v1.0.0` en `1.0` naar GHCR.
