#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

# ==========================================================
# MIKIS13 AUTOFORGE
# ==========================================================

REPO="Ice1984m/mikis13-site"
PR="${PR:-31}"
ROOT="$HOME/mikis13-site"

STATE="$HOME/.mikis13/state"
LOGDIR="$HOME/.mikis13/logs"
REPORT="$LOGDIR/autoforge.log"

MAX_WAIT="${MAX_WAIT:-900}"
POLL="${POLL:-10}"

mkdir -p "$STATE" "$LOGDIR"

cd "$ROOT"

exec > >(tee -a "$REPORT") 2>&1

pass() {
    echo "✅ $*"
}

warn() {
    echo "⚠️ $*"
}

fail() {
    echo "❌ $*" >&2
}

section() {
    echo
    echo "=================================================="
    echo "$*"
    echo "=================================================="
}

die() {
    fail "$*"
    exit 1
}

# ==========================================================
# GATE 0 — TOOLS
# ==========================================================

section "GATE 0 — TOOLS"

for cmd in \
    git \
    gh \
    curl \
    jq \
    python \
    node
do
    command -v "$cmd" >/dev/null 2>&1 \
        || die "Commando ontbreekt: $cmd"

    pass "$cmd"
done

gh auth status >/dev/null 2>&1 \
    || die "GitHub CLI niet aangemeld. Gebruik: gh auth login"

pass "GitHub authenticatie"

# ==========================================================
# VEILIGE TMP
# ==========================================================

export TMPDIR="${TMPDIR:-$PREFIX/tmp}"

mkdir -p "$TMPDIR"

test -w "$TMPDIR" \
    || die "TMPDIR niet schrijfbaar: $TMPDIR"

pass "TMPDIR = $TMPDIR"

# ==========================================================
# GATE 1 — GIT CONTEXT
# ==========================================================

section "GATE 1 — GIT"

git rev-parse --is-inside-work-tree >/dev/null \
    || die "Geen Git repository"

CURRENT_BRANCH="$(git branch --show-current)"

echo "Branch: $CURRENT_BRANCH"

git fetch origin --prune

pass "Repository bereikbaar"

# ==========================================================
# GATE 2 — BACKUP ROMMEL OPRUIMEN
# Alleen gegenereerde *.bak-* bestanden.
# ==========================================================

section "GATE 2 — TIJDELIJKE BACKUPS"

find . \
    -type f \
    -name '*.bak-20*' \
    -print \
    -delete \
    2>/dev/null || true

pass "Tijdelijke scriptbackups verwijderd"

# ==========================================================
# GATE 3 — LOKALE REPAIR ENGINE
# ==========================================================

section "GATE 3 — REPAIR ENGINE"

test -x scripts/mikis-repair-v2.sh \
    || die "scripts/mikis-repair-v2.sh ontbreekt"

./scripts/mikis-repair-v2.sh

pass "Repair V2"

# ==========================================================
# GATE 4 — DOCTOR
# ==========================================================

section "GATE 4 — DOCTOR"

./scripts/mikis-doctor.sh

pass "Doctor"

# ==========================================================
# GATE 5 — HTTP
# ==========================================================

section "GATE 5 — LOKALE HTTP"

./scripts/mikis-local-test.sh

pass "Local HTTP"

# ==========================================================
# GATE 6 — PRODUCTIEBESTANDEN
#
# Controleer dat gevoelige/dev mappen niet per ongeluk
# productiepagina's moeten worden.
# ==========================================================

section "GATE 6 — PUBLICATIE AUDIT"

PRIVATE_DIRS=(
    backup
    backups
    archive
    admin-backup
    credentials
    vault
    node_modules
    .git
)

for DIR in "${PRIVATE_DIRS[@]}"
do
    if [ -e "$DIR" ]; then
        echo "Niet voor productie: $DIR"
    fi
done

pass "Publicatie-audit uitgevoerd"

# ==========================================================
# GATE 7 — WORKFLOW CONFIG
# ==========================================================

section "GATE 7 — PAGES WORKFLOW"

WORKFLOW=".github/workflows/pages.yml"

test -s "$WORKFLOW" \
    || die "$WORKFLOW ontbreekt"

grep -q 'actions/configure-pages@v5' "$WORKFLOW" \
    || die "configure-pages@v5 ontbreekt"

grep -q 'actions/upload-pages-artifact@v4' "$WORKFLOW" \
    || die "upload-pages-artifact@v4 ontbreekt"

grep -q 'actions/deploy-pages@v4' "$WORKFLOW" \
    || die "deploy-pages@v4 ontbreekt"

pass "Pages Actions"

# ==========================================================
# Zorg dat backups niet de validator blokkeren
# ==========================================================

python <<'PY'
from pathlib import Path

p = Path(".github/workflows/pages.yml")

s = p.read_text(encoding="utf-8")

needle = '''              "archive",
'''

addition = '''              "archive",
              "backup",
              "backups",
'''

if '"backup",' not in s:

    if needle not in s:
        raise SystemExit(
            "Pages ignore-blok niet veilig gevonden."
        )

    s = s.replace(
        needle,
        addition,
        1,
    )

p.write_text(
    s,
    encoding="utf-8",
)

print("Pages productie-ignore OK")
PY

# ==========================================================
# GATE 8 — DIFF
# ==========================================================

section "GATE 8 — DIFF"

git diff --check

pass "git diff --check"

git status --short

# ==========================================================
# Alleen relevante AutForge-fixes committen
# Laat andere lokale wijzigingen ongemoeid.
# ==========================================================

git add \
    .github/workflows/pages.yml \
    scripts/mikis-repair-v2.sh \
    scripts/mikis-doctor.sh \
    scripts/mikis-local-test.sh \
    scripts/mikis-autoforge.sh

if ! git diff --cached --quiet
then

    section "COMMIT"

    git diff --cached --check

    git commit \
        -m "fix: finalize autonomous Pages deployment"

    git push origin HEAD

    pass "Nieuwe reparatie gepusht"

else
    pass "Geen nieuwe Autoforge-wijzigingen nodig"
fi

# ==========================================================
# GATE 9 — PR BESTAAT
# ==========================================================

section "GATE 9 — PR"

PR_STATE="$(
    gh pr view "$PR" \
        --repo "$REPO" \
        --json state \
        --jq '.state'
)"

echo "PR #$PR: $PR_STATE"

if [ "$PR_STATE" = "MERGED" ]
then
    pass "PR is al gemerged"

elif [ "$PR_STATE" != "OPEN" ]
then
    die "PR #$PR is niet open of gemerged"
fi

# ==========================================================
# GATE 10 — WACHT OP CHECKS
#
# Dit voorkomt het eerdere probleem:
# 'no checks reported'
# ==========================================================

if [ "$PR_STATE" = "OPEN" ]
then

    section "GATE 10 — GITHUB CHECKS"

    START="$(date +%s)"
    HAVE_CHECKS=0

    while true
    do

        HEAD_SHA="$(
            gh pr view "$PR" \
                --repo "$REPO" \
                --json headRefOid \
                --jq '.headRefOid'
        )"

        CHECK_JSON="$(
            gh api \
              -H "Accept: application/vnd.github+json" \
              "/repos/$REPO/commits/$HEAD_SHA/check-runs" \
              2>/dev/null
        )"

        COUNT="$(
            printf '%s' "$CHECK_JSON" |
                jq '.total_count'
        )"

        echo "Checks gevonden: $COUNT"

        if [ "$COUNT" -gt 0 ]
        then
            HAVE_CHECKS=1
            break
        fi

        NOW="$(date +%s)"

        if [ $((NOW - START)) -ge "$MAX_WAIT" ]
        then
            die "Geen GitHub checks aangemaakt binnen timeout"
        fi

        sleep "$POLL"
    done

    [ "$HAVE_CHECKS" -eq 1 ] \
        || die "Geen checks"

    # ------------------------------------------------------
    # Wachten totdat alle checks klaar zijn
    # ------------------------------------------------------

    while true
    do

        HEAD_SHA="$(
            gh pr view "$PR" \
                --repo "$REPO" \
                --json headRefOid \
                --jq '.headRefOid'
        )"

        CHECK_JSON="$(
            gh api \
              -H "Accept: application/vnd.github+json" \
              "/repos/$REPO/commits/$HEAD_SHA/check-runs"
        )"

        RUNNING="$(
            printf '%s' "$CHECK_JSON" |
              jq '[
                    .check_runs[]
                    | select(
                        .status != "completed"
                    )
                  ] | length'
        )"

        FAILED="$(
            printf '%s' "$CHECK_JSON" |
              jq '[
                    .check_runs[]
                    | select(
                        .status == "completed"
                        and
                        (
                          .conclusion != "success"
                          and
                          .conclusion != "skipped"
                          and
                          .conclusion != "neutral"
                        )
                    )
                  ] | length'
        )"

        printf '%s' "$CHECK_JSON" |
          jq -r '
            .check_runs[] |
            "\(.name): \(.status) / \(.conclusion)"
          '

        if [ "$FAILED" -gt 0 ]
        then
            section "MISLUKTE CHECKS"

            printf '%s' "$CHECK_JSON" |
              jq -r '
                .check_runs[]
                | select(
                    .status == "completed"
                    and
                    (
                      .conclusion != "success"
                      and
                      .conclusion != "skipped"
                      and
                      .conclusion != "neutral"
                    )
                  )
                | "\(.name) -> \(.details_url)"
              '

            die "GitHub CI heeft echte rode check(s)"
        fi

        if [ "$RUNNING" -eq 0 ]
        then
            break
        fi

        echo "GitHub is nog bezig..."
        sleep "$POLL"
    done

    pass "GitHub CI groen"

    # ======================================================
    # GATE 11 — MERGE
    # ======================================================

    section "GATE 11 — MERGE"

    MERGEABLE="$(
        gh pr view "$PR" \
          --repo "$REPO" \
          --json mergeable \
          --jq '.mergeable'
    )"

    echo "Mergeable: $MERGEABLE"

    [ "$MERGEABLE" = "MERGEABLE" ] \
        || die "PR is momenteel niet mergeable"

    gh pr merge "$PR" \
      --repo "$REPO" \
      --squash \
      --delete-branch

    pass "PR #$PR gemerged"
fi

# ==========================================================
# GATE 12 — MAIN BIJWERKEN
# ==========================================================

section "GATE 12 — MAIN"

git fetch origin main

# Geen reset van je working tree.
MAIN_SHA="$(
    git rev-parse origin/main
)"

echo "origin/main: $MAIN_SHA"

pass "Main gevonden"

# ==========================================================
# GATE 13 — PAGES CONFIG
# ==========================================================

section "GATE 13 — GITHUB PAGES CONFIG"

PAGES="$(
    gh api "/repos/$REPO/pages"
)"

printf '%s' "$PAGES" |
    jq '{
        build_type,
        cname,
        public,
        https_enforced,
        html_url
    }'

BUILD_TYPE="$(
    printf '%s' "$PAGES" |
      jq -r '.build_type'
)"

if [ "$BUILD_TYPE" != "workflow" ]
then

    gh api \
      --method PUT \
      "/repos/$REPO/pages" \
      -f build_type=workflow \
      >/dev/null

    pass "Pages build_type=workflow ingesteld"
fi

# ==========================================================
# CUSTOM DOMAIN
# ==========================================================

CURRENT_CNAME="$(
    printf '%s' "$PAGES" |
      jq -r '.cname // empty'
)"

if [ "$CURRENT_CNAME" != "mikis13.nl" ]
then

    warn "Pages cname was: $CURRENT_CNAME"

    gh api \
      --method PUT \
      "/repos/$REPO/pages" \
      -f cname="mikis13.nl" \
      -f build_type="workflow" \
      >/dev/null \
      || warn "Custom domain kon niet automatisch worden ingesteld"
fi

# ==========================================================
# HTTPS PROBEREN TE FORCEREN
# GitHub kan dit tijdelijk weigeren zolang certificaat
# nog niet klaar is.
# ==========================================================

if ! gh api \
      --method PUT \
      "/repos/$REPO/pages" \
      -F https_enforced=true \
      >/dev/null 2>&1
then
    warn "HTTPS enforcement nog niet beschikbaar; certificaat/DNS kan nog bezig zijn"
else
    pass "HTTPS enforcement actief"
fi

# ==========================================================
# GATE 14 — MAIN PAGES WORKFLOW
# ==========================================================

section "GATE 14 — MAIN DEPLOYMENT"

# Zoek de nieuwste run van pages.yml voor main.
# Eerst kort wachten tot push-trigger is aangemaakt.

RUN_ID=""

for _ in $(seq 1 30)
do

    RUN_ID="$(
        gh run list \
          --repo "$REPO" \
          --workflow pages.yml \
          --branch main \
          --limit 5 \
          --json databaseId,headSha,event \
          --jq "
             map(
               select(
                 .headSha == \"$MAIN_SHA\"
               )
             )
             | .[0].databaseId // empty
          "
    )"

    if [ -n "$RUN_ID" ]
    then
        break
    fi

    sleep 5
done

if [ -z "$RUN_ID" ]
then
    warn "Geen push-run gevonden; workflow handmatig starten"

    gh workflow run pages.yml \
      --repo "$REPO" \
      --ref main

    sleep 5

    RUN_ID="$(
        gh run list \
          --repo "$REPO" \
          --workflow pages.yml \
          --branch main \
          --limit 1 \
          --json databaseId \
          --jq '.[0].databaseId'
    )"
fi

[ -n "$RUN_ID" ] \
    || die "Pages workflow run niet gevonden"

echo "Pages run: $RUN_ID"

set +e

gh run watch "$RUN_ID" \
    --repo "$REPO" \
    --exit-status

RUN_RC=$?

set -e

if [ "$RUN_RC" -ne 0 ]
then
    section "PAGES FAILURE LOG"

    gh run view "$RUN_ID" \
      --repo "$REPO" \
      --log-failed \
      || true

    die "Pages deployment mislukt"
fi

pass "Pages workflow succesvol"

# ==========================================================
# GATE 15 — LIVE HTTP/HTTPS
# ==========================================================

section "GATE 15 — LIVE WEBSITE"

check_url() {

    local URL="$1"
    local REQUIRED="${2:-yes}"

    local RESULT

    set +e

    RESULT="$(
      curl \
        -L \
        -sS \
        --connect-timeout 15 \
        --max-time 45 \
        -o /dev/null \
        -w '%{http_code}|%{url_effective}' \
        "$URL"
    )"

    local RC=$?

    set -e

    if [ "$RC" -ne 0 ]
    then

        if [ "$REQUIRED" = "yes" ]
        then
            fail "$URL curl=$RC"
            return 1
        fi

        warn "$URL nog niet bereikbaar"
        return 0
    fi

    local CODE="${RESULT%%|*}"
    local FINAL="${RESULT#*|}"

    case "$CODE" in
        200|204)
            pass "$URL"
            echo "   HTTP $CODE -> $FINAL"
            ;;

        *)
            if [ "$REQUIRED" = "yes" ]
            then
                fail "$URL HTTP $CODE"
                return 1
            fi

            warn "$URL HTTP $CODE"
            ;;
    esac
}

# GitHub Pages origin is de harde hosting-gate.
check_url \
  "https://ice1984m.github.io/mikis13-site/" \
  yes

# Custom domain
check_url \
  "https://mikis13.nl/" \
  no

check_url \
  "https://www.mikis13.nl/" \
  no

# ==========================================================
# DNS INFO
# ==========================================================

section "DNS"

if command -v dig >/dev/null 2>&1
then

    echo "--- mikis13.nl ---"
    dig +short mikis13.nl A || true

    echo
    echo "--- www.mikis13.nl ---"
    dig +short www.mikis13.nl CNAME || true

else
    warn "dnsutils niet geïnstalleerd"
fi

# ==========================================================
# FINAL STATUS
# ==========================================================

section "FINAL"

PAGES="$(
    gh api "/repos/$REPO/pages"
)"

printf '%s' "$PAGES" |
  jq '{
      status,
      build_type,
      cname,
      public,
      https_enforced,
      html_url
  }'

echo
echo "=============================================="
echo " ✅ MIKIS13 AUTOFORGE VOLTOOID"
echo "=============================================="
echo
echo "PR:       #$PR"
echo "MAIN:     $MAIN_SHA"
echo "PAGES:    run $RUN_ID"
echo
echo "Publieke URLs:"
echo "  https://ice1984m.github.io/mikis13-site/"
echo "  https://mikis13.nl/"
echo "  https://www.mikis13.nl/"
echo
echo "Log:"
echo "  $REPORT"
echo
