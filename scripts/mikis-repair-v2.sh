#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$HOME/mikis13-site"
STATE="$HOME/.mikis13/state"
LOGDIR="$HOME/.mikis13/logs"
REPORT="$LOGDIR/repair-v2.log"
MAX_ATTEMPTS=3

mkdir -p "$STATE" "$LOGDIR"
cd "$ROOT"

touch "$REPORT"

log() {
    printf '[%s] %s\n' "$(date '+%F %T')" "$*" | tee -a "$REPORT"
}

pass() {
    log "✅ $*"
}

fail() {
    log "❌ $*"
}

# ============================================================
# VEILIG LEEGMAKEN
# ============================================================

clear_runtime() {
    log "Runtime/logs veilig leegmaken"

    # Oude PID's opruimen
    find "$STATE" \
      -type f \
      -name '*.pid' \
      -delete 2>/dev/null || true

    # Alleen logs leegmaken, NIET verwijderen
    find "$LOGDIR" \
      -type f \
      -name '*.log' \
      -exec sh -c ': > "$1"' _ {} \; \
      2>/dev/null || true

    # Tijdelijke lokale bestanden
    rm -rf \
      "$ROOT/.cache" \
      "$ROOT/tmp" \
      "$ROOT/.tmp" \
      2>/dev/null || true

    mkdir -p "$ROOT/tmp"

    pass "Runtime opgeschoond"
}

# ============================================================
# TEST 1: GIT
# ============================================================

test_git() {
    git rev-parse --is-inside-work-tree >/dev/null 2>&1
}

repair_git() {
    git fetch origin --prune || return 1
}

# ============================================================
# TEST 2: VEREISTE BESTANDEN
# ============================================================

test_required_files() {
    local missing=0

    for file in \
      index.html \
      contact.html \
      privacy.html \
      voorwaarden.html
    do
        if [ ! -s "$file" ]; then
            log "Ontbreekt: $file"
            missing=1
        fi
    done

    return "$missing"
}

repair_required_files() {
    # Geen inhoud verzinnen.
    # Alleen bekende directories herstellen.
    mkdir -p \
      assets/css \
      assets/js \
      assets/img \
      scripts

    return 0
}

# ============================================================
# TEST 3: JAVASCRIPT
# ============================================================

test_javascript() {
    local rc=0

    while IFS= read -r file
    do
        if ! node --check "$file" >/dev/null 2>&1; then
            log "JavaScript syntaxfout: $file"
            node --check "$file" 2>&1 | tee -a "$REPORT"
            rc=1
            break
        fi
    done < <(
        find . \
          -type f \
          -name '*.js' \
          ! -path './node_modules/*' \
          ! -path './archive/*'
    )

    return "$rc"
}

repair_javascript() {
    log "JavaScript-fouten vereisen broncode-fix; geen gevaarlijke automatische wijziging."
    return 1
}

# ============================================================
# TEST 4: SECRETS
# ============================================================

test_secrets() {
    local pattern
    local tmpfile

    pattern='sk-proj-[A-Za-z0-9_-]{20,}|github_pat_[A-Za-z0-9_]{20,}|gh[pousr]_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}'

    tmpfile="$(mktemp "${TMPDIR:-$PREFIX/tmp}/mikis-secrets.XXXXXX")" || {
        log "Kan tijdelijk bestand voor secret-scan niet maken."
        return 1
    }

    set +e

    git grep -nE "$pattern" -- \
        ':!*.md' \
        ':!.github/workflows/*' \
        ':!backup/*' \
        ':!backup/**/*' \
        ':!archive/*' \
        ':!archive/**/*' \
        >"$tmpfile" 2>/dev/null

    local rc=$?

    set -e

    case "$rc" in
        0)
            log "Mogelijk geheim gevonden:"
            cat "$tmpfile" | tee -a "$REPORT"
            rm -f "$tmpfile"
            return 1
            ;;

        1)
            rm -f "$tmpfile"
            return 0
            ;;

        *)
            log "Secret-scan zelf gaf foutcode $rc"
            rm -f "$tmpfile"
            return 1
            ;;
    esac
}

repair_secrets() {
    log "Secrets worden nooit automatisch verwijderd of vervangen."
    log "Verplaats echte sleutels naar environment variables/GitHub Secrets."
    return 1
}

# ============================================================
# TEST 5: HTML LINKS
# ============================================================

test_links() {
python <<'PY'
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlparse

root = Path(".").resolve()

ignore = {
    ".git",
    "node_modules",
    "archive",
    "backup",
    "backups",
    "admin-backup",
    ".cache",
}

errors = []

class Parser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links = []

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)

        for key in ("href", "src"):
            value = attrs.get(key)
            if value:
                self.links.append(value)

for html in root.rglob("*.html"):

    if any(part in ignore for part in html.parts):
        continue

    parser = Parser()

    try:
        parser.feed(html.read_text(
            encoding="utf-8",
            errors="ignore"
        ))
    except Exception as exc:
        errors.append(
            f"{html}: parse error: {exc}"
        )
        continue

    for link in parser.links:

        if (
            link.startswith("#")
            or link.startswith("mailto:")
            or link.startswith("tel:")
            or link.startswith("javascript:")
        ):
            continue

        parsed = urlparse(link)

        if parsed.scheme in (
            "http",
            "https",
            "data"
        ):
            continue

        clean = parsed.path

        if not clean:
            continue

        if clean.startswith("/"):
            target = root / clean.lstrip("/")
        else:
            target = html.parent / clean

        target = target.resolve()

        candidates = [
            target,
            target / "index.html",
        ]

        if not any(p.exists() for p in candidates):
            errors.append(
                f"{html.relative_to(root)} -> {link}"
            )

if errors:
    print("BROKEN LINKS:")
    for e in errors:
        print(" -", e)
    raise SystemExit(1)

print("HTML links OK")
PY
}

repair_links() {
    log "Broken links worden gerapporteerd zodat de exacte pagina kan worden gerepareerd."
    return 1
}

# ============================================================
# TEST 6: LOKALE SERVER
# ============================================================

test_http() {
    local port=4545
    local pidfile="$STATE/test-http.pid"

    if [ -f "$pidfile" ]; then
        kill "$(cat "$pidfile")" >/dev/null 2>&1 || true
        rm -f "$pidfile"
    fi

    python -m http.server "$port" \
      --bind 127.0.0.1 \
      >>"$LOGDIR/http-test.log" 2>&1 &

    local pid=$!
    echo "$pid" > "$pidfile"

    for i in $(seq 1 15)
    do
        if curl -fsS \
          "http://127.0.0.1:$port/" \
          >/dev/null 2>&1
        then
            kill "$pid" >/dev/null 2>&1 || true
            rm -f "$pidfile"
            return 0
        fi

        sleep 1
    done

    kill "$pid" >/dev/null 2>&1 || true
    rm -f "$pidfile"

    return 1
}

repair_http() {
    pkill -f 'python -m http.server 4545' \
      >/dev/null 2>&1 || true

    sleep 1
    return 0
}

# ============================================================
# TEST ENGINE
# ============================================================

run_check() {

    local name="$1"
    local testfn="$2"
    local repairfn="$3"

    log ""
    log "======================================"
    log "TEST: $name"
    log "======================================"

    if "$testfn"; then
        pass "$name"
        return 0
    fi

    fail "$name"

    for attempt in $(seq 1 "$MAX_ATTEMPTS")
    do
        log "Repair poging $attempt/$MAX_ATTEMPTS"

        "$repairfn" || true

        log "Opnieuw testen..."

        if "$testfn"; then
            pass "$name opgelost na poging $attempt"
            return 0
        fi

        fail "$name nog niet opgelost"
    done

    log "⛔ STOP bij fout: $name"
    return 1
}

# ============================================================
# START
# ============================================================

log ""
log "########################################"
log " MIKIS13 REPAIR ENGINE V2"
log "########################################"

run_check \
    "Git repository" \
    test_git \
    repair_git \
|| exit 10

run_check \
    "Vereiste bestanden" \
    test_required_files \
    repair_required_files \
|| exit 20

run_check \
    "JavaScript syntax" \
    test_javascript \
    repair_javascript \
|| exit 30

run_check \
    "Secret scan" \
    test_secrets \
    repair_secrets \
|| exit 40

run_check \
    "HTML/interne links" \
    test_links \
    repair_links \
|| exit 50

run_check \
    "Lokale HTTP server" \
    test_http \
    repair_http \
|| exit 60

log ""
log "======================================"
log "✅ ALLE TESTS PASS"
log "======================================"

exit 0
