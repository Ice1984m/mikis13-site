# MIKIS13 Autonomous Development Blueprint

## Repair cycle

DETECT → DIAGNOSE → BACKUP → FIX → TEST → VERIFY → LOG

## Principles

- Existing repository first.
- Root cause before workaround.
- Official documentation first.
- Small reversible changes.
- Never hardcode secrets.
- CI must be green before merge.
- GitHub Pages hosts static production.
- Termux handles local development and tooling.
- Add regression checks after repairing recurring failures.
- Avoid permanent worker farms; start workers on demand.

## Deployment gate

A release is healthy when:

1. mandatory files exist;
2. secret scan passes;
3. HTML validation passes;
4. local server returns HTTP 200;
5. GitHub Actions passes;
6. deployment succeeds;
7. public URL returns HTTP 200.

## Automated repair

Maximum three attempts per detected failure.

Every new attempt must use additional diagnostic evidence instead of repeating the same failed command.
