#!/data/data/com.termux/files/usr/bin/bash

set -e

SITE_DIR="$HOME/mikis13-site"
BACKUP_DIR="$SITE_DIR/backup/neon-$(date +%Y%m%d-%H%M%S)"

cd "$SITE_DIR"
mkdir -p "$BACKUP_DIR" assets

[ -f index.html ] && cp index.html "$BACKUP_DIR/index.html"
[ -f assets/style.css ] && cp assets/style.css "$BACKUP_DIR/style.css"

cat > index.html <<'HTML'
<!doctype html>
<html lang="nl">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="theme-color" content="#09000f">
<meta name="description" content="Mikis13 — Ik bouw wat nog niet bestaat.">
<title>Mikis13 — Ik bouw wat nog niet bestaat</title>
<link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2290%22>💜</text></svg>">
<link rel="stylesheet" href="assets/style.css">
</head>

<body>
<div class="stars"></div>

<nav>
  <a class="logo" href="#home">MIKIS<span>13</span></a>

  <div class="menu">
    <a href="#projecten">Projecten</a>
    <a href="#human-os">Human OS</a>
    <a href="#github">GitHub</a>
  </div>

  <button class="menu-button" aria-label="Menu openen">☰</button>
</nav>

<main id="home">
  <section class="hero">
    <p class="eyebrow">MATTY MOORS — DIGITAL CREATOR</p>

    <div class="globe" aria-hidden="true">
      <div class="globe-ring"></div>
    </div>

    <h1>
      IK BOUW
      <span>WAT NOG</span>
      NIET BESTAAT
    </h1>

    <a class="human-button" href="#human-os">HUMAN OS</a>

    <p class="intro">
      Ik bouw tools, systemen en ervaringen die technologie menselijk maken.
      Open. Veilig. Nuttig. Voor iedereen.
    </p>

    <a class="scroll" href="#projecten" aria-label="Naar projecten">♡</a>
  </section>

  <section class="projects" id="projecten">
    <header>
      <p class="eyebrow">MIJN PROJECTEN</p>
      <h2>NEON LAB</h2>
    </header>

    <div class="project-grid">
      <article class="card">
        <div class="icon">◉</div>
        <div>
          <small>01 / INTELLIGENCE</small>
          <h3>AI ASSISTENTEN</h3>
          <p>Slimme hulpmiddelen die meedenken en ondersteunen.</p>
        </div>
      </article>

      <article class="card">
        <div class="icon">〉_</div>
        <div>
          <small>02 / MOBILE LAB</small>
          <h3>TERMUX ONTWIKKELING</h3>
          <p>Websites en programma’s rechtstreeks gebouwd vanaf Android.</p>
        </div>
      </article>

      <article class="card">
        <div class="icon">⬡</div>
        <div>
          <small>03 / SECURITY</small>
          <h3>CYBER & PRIVACY</h3>
          <p>Bescherming, bewustzijn en privacy als vaste basis.</p>
        </div>
      </article>

      <article class="card">
        <div class="icon">▣</div>
        <div>
          <small>04 / CREATION</small>
          <h3>WEBSITES & APPS</h3>
          <p>Moderne en mensgerichte digitale ervaringen.</p>
        </div>
      </article>

      <article class="card">
        <div class="icon">▥</div>
        <div>
          <small>05 / DASHBOARD</small>
          <h3>MINEVAULT</h3>
          <p>Educatieve simulaties, controle en inzichten in één dashboard.</p>
        </div>
      </article>

      <article class="card">
        <div class="icon">⚒</div>
        <div>
          <small>06 / REPAIR</small>
          <h3>REPAIR TECHNOLOGIE</h3>
          <p>Repareren, hergebruiken en waardevolle techniek behouden.</p>
        </div>
      </article>

      <article class="card">
        <div class="icon">✣</div>
        <div>
          <small>07 / WORLDS</small>
          <h3>GAMING</h3>
          <p>Games en digitale werelden die verbinden en inspireren.</p>
        </div>
      </article>

      <article class="card">
        <div class="icon">♥</div>
        <div>
          <small>08 / HUMAN FIRST</small>
          <h3>HULP VOOR MENSEN</h3>
          <p>Praktische hulpmiddelen voor een betere toekomst.</p>
        </div>
      </article>
    </div>
  </section>

  <section class="human-os" id="human-os">
    <p class="eyebrow">EEN NIEUW SOORT BESTURINGSSYSTEEM</p>

    <h2>HUMAN <span>OS</span></h2>

    <blockquote>
      Technologie hoort mensen sterker te maken,
      zonder iemand schade te doen.
    </blockquote>

    <div class="principles">
      <span>01 — MENS EERST</span>
      <span>02 — OPEN EN UITLEGBAAR</span>
      <span>03 — PRIVACY</span>
      <span>04 — GEEN SCHADE</span>
    </div>
  </section>

  <section class="github-section" id="github">
    <div class="github-icon">⌘</div>

    <div>
      <p class="eyebrow">OPEN SOURCE</p>
      <h2>BOUW MEE OP GITHUB</h2>
      <p>Samen bouwen. Iedere goede bijdrage maakt het project sterker.</p>
    </div>

    <a href="https://github.com/Ice1984m"
       target="_blank"
       rel="noopener">OPEN GITHUB →</a>
  </section>
</main>

<footer>
  <strong>MIKIS13</strong>
  <small>© 2026 Matty Moors — alle rechten voorbehouden</small>
</footer>
</body>
</html>
HTML

cat > assets/style.css <<'CSS'
@import url('https://fonts.googleapis.com/css2?family=Orbitron:wght@500;700;900&family=Montserrat:wght@400;600;800&display=swap');

:root{
  --black:#050008;
  --panel:#100018;
  --purple:#a400ff;
  --pink:#ee55ff;
  --light:#f3d7ff;
  --muted:#bba4c4;
  --line:#d85cff55;
}

*{box-sizing:border-box}

html{scroll-behavior:smooth}

body{
  margin:0;
  overflow-x:hidden;
  color:white;
  background:
    radial-gradient(circle at 50% 14%,#430067,transparent 25%),
    var(--black);
  font-family:Montserrat,sans-serif;
}

a{color:inherit;text-decoration:none}

.stars{
  position:fixed;
  inset:0;
  z-index:-1;
  opacity:.3;
  background-image:
    radial-gradient(#f18cff 1px,transparent 1px),
    radial-gradient(#7c26ff 1px,transparent 1px);
  background-position:0 0,25px 25px;
  background-size:60px 60px;
}

nav,.hero,.projects,.human-os,.github-section,footer{
  width:min(1120px,calc(100% - 36px));
  margin:auto;
}

nav{
  height:82px;
  display:flex;
  align-items:center;
  justify-content:space-between;
  border-bottom:1px solid #ffffff26;
}

.logo{
  font-family:Orbitron,sans-serif;
  font-weight:900;
  letter-spacing:5px;
}

.logo span{
  color:var(--pink);
  text-shadow:0 0 18px var(--pink);
}

.menu{
  display:flex;
  gap:30px;
  font-size:10px;
  font-weight:800;
  letter-spacing:2px;
  text-transform:uppercase;
}

.menu a:hover{color:var(--pink)}

.menu-button{
  display:none;
  color:var(--pink);
  background:transparent;
  border:1px solid var(--pink);
  padding:9px 12px;
}

.hero{
  min-height:900px;
  padding:90px 0 70px;
  position:relative;
  text-align:center;
}

.eyebrow{
  color:#df9aff;
  font-size:10px;
  font-weight:800;
  letter-spacing:4px;
}

.globe{
  position:absolute;
  top:125px;
  left:50%;
  width:430px;
  height:430px;
  transform:translateX(-50%);
  border:1px solid #ed80ff;
  border-radius:50%;
  opacity:.65;
  background:
    repeating-radial-gradient(circle,#b938ff22 0 2px,transparent 3px 30px),
    radial-gradient(circle at 35% 30%,#dd75ff,#7000aa 42%,#180023 72%);
  box-shadow:0 0 100px #a600ff;
}

.globe-ring{
  position:absolute;
  inset:42%;
  border:1px solid white;
  border-radius:50%;
  box-shadow:0 0 30px var(--pink);
}

h1{
  margin:115px auto 35px;
  position:relative;
  z-index:2;
  font:900 clamp(52px,8.5vw,120px)/.88 Orbitron,sans-serif;
  letter-spacing:-6px;
  text-shadow:0 0 20px #be00ff;
}

h1 span{
  display:block;
  color:transparent;
  -webkit-text-stroke:2px var(--pink);
}

.human-button{
  display:inline-block;
  position:relative;
  z-index:2;
  padding:14px 35px;
  color:var(--light);
  border:1px solid var(--pink);
  background:#24002fdd;
  font-family:Orbitron,sans-serif;
  letter-spacing:5px;
  box-shadow:0 0 24px #c000ff77;
}

.intro{
  max-width:620px;
  margin:28px auto;
  position:relative;
  z-index:2;
  color:#d6c1dd;
  line-height:1.8;
}

.scroll{
  display:grid;
  place-items:center;
  width:55px;
  height:55px;
  margin:45px auto;
  border:1px solid var(--pink);
  border-radius:50%;
  color:var(--pink);
  font-size:27px;
  box-shadow:0 0 22px #d000ff;
}

.projects{padding:120px 0}

.projects header{text-align:center}

h2{
  margin:16px 0 55px;
  font:900 clamp(44px,7vw,90px)/.9 Orbitron,sans-serif;
  letter-spacing:-4px;
}

.project-grid{
  display:grid;
  grid-template-columns:1fr 1fr;
  gap:16px;
}

.card{
  min-height:190px;
  padding:22px;
  display:grid;
  grid-template-columns:110px 1fr;
  gap:22px;
  align-items:center;
  border:1px solid var(--line);
  background:linear-gradient(135deg,#180021dd,#09000e);
  transition:.25s;
}

.card:hover{
  transform:translateY(-6px);
  border-color:var(--pink);
  box-shadow:0 15px 45px #70009c55;
}

.icon{
  width:100px;
  height:100px;
  display:grid;
  place-items:center;
  border:1px solid var(--pink);
  border-radius:20px;
  color:var(--pink);
  font:900 35px Orbitron,sans-serif;
  background:radial-gradient(circle,#8e00d766,#13001b);
  box-shadow:inset 0 0 25px #9600d8;
}

.card small{color:#d783ff}

.card h3{
  margin:10px 0;
  font:700 18px Orbitron,sans-serif;
}

.card p{
  margin:0;
  color:var(--muted);
  font-size:13px;
  line-height:1.6;
}

.human-os{
  margin-top:80px;
  margin-bottom:100px;
  padding:90px 60px;
  text-align:center;
  color:#16001d;
  background:#f5e6fa;
}

.human-os .eyebrow{color:#72008f}

.human-os h2{margin-bottom:35px}

.human-os h2 span{color:var(--purple)}

blockquote{
  max-width:800px;
  margin:0 auto 45px;
  font-size:clamp(25px,4vw,48px);
  font-weight:900;
  line-height:1.1;
}

.principles{
  display:grid;
  grid-template-columns:1fr 1fr;
  gap:2px;
  background:#7900a5;
}

.principles span{
  padding:18px;
  color:white;
  background:#22002e;
  font-size:10px;
  font-weight:800;
  letter-spacing:2px;
}

.github-section{
  margin-bottom:100px;
  padding:45px;
  display:grid;
  grid-template-columns:120px 1fr auto;
  gap:30px;
  align-items:center;
  border:1px solid var(--pink);
  background:linear-gradient(90deg,#270035,#100016);
  box-shadow:0 0 50px #9500c944;
}

.github-icon{
  width:100px;
  height:100px;
  display:grid;
  place-items:center;
  border:1px solid var(--pink);
  border-radius:50%;
  color:var(--pink);
  font-size:45px;
}

.github-section h2{
  margin:12px 0;
  font-size:clamp(28px,4vw,50px);
}

.github-section p{color:var(--muted)}

.github-section>a{
  padding:16px 20px;
  color:#18001f;
  background:var(--pink);
  font-size:11px;
  font-weight:900;
  white-space:nowrap;
}

footer{
  padding:30px 0;
  display:flex;
  justify-content:space-between;
  color:#96809d;
  border-top:1px solid #ffffff25;
  font-size:10px;
  letter-spacing:2px;
}

@media(max-width:760px){
  .menu{display:none}
  .menu-button{display:block}
  .hero{min-height:750px}
  .globe{width:260px;height:260px;top:160px}
  h1{margin-top:145px;font-size:15vw;letter-spacing:-3px}
  .project-grid{grid-template-columns:1fr}
  .card{grid-template-columns:82px 1fr}
  .icon{width:75px;height:75px;font-size:25px}
  .human-os{padding:70px 22px}
  .principles{grid-template-columns:1fr}
  .github-section{grid-template-columns:1fr;text-align:center}
  .github-icon{margin:auto}
  footer{display:grid;gap:15px;text-align:center}
}
CSS

printf '\nnode_modules/\n.env\n.env.*\n*.log\n*.pid\nbackup/\n' >> .gitignore

echo
echo "Mikis13 Neon-website is aangemaakt."
echo "Back-up: $BACKUP_DIR"
echo
echo "Test met:"
echo "python -m http.server 4500"
