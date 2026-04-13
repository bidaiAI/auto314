# Security Policy

Last updated: **2026-04-12**

## Scope

This repository is the public MIT release mirror for Autonomous 314.

- public `main` and reviewed public release snapshots are in scope
- unreleased development work may exist outside the public mirror

## Supported versions

Security fixes are applied on a best-effort basis to:

- the latest public `main` branch state
- the latest reviewed public release snapshot

Older public snapshots may be fixed by replacement with a newer reviewed release instead of direct backport.

## Reporting a vulnerability

If you believe you found a real security issue:

1. **Do not** post exploitable details in a public GitHub issue.
2. Prefer GitHub private vulnerability reporting for this repository **if it is enabled**.
3. If private reporting is not available, use the official maintainer channels listed in [`README.md`](./README.md) to request a private disclosure path first.

Please include:

- affected component(s)
- impact summary
- reproduction steps
- proof-of-concept details that are sufficient to validate the issue
- suggested mitigation if you have one

## Good-faith testing expectations

Please avoid:

- denial-of-service against public infrastructure
- privacy violations
- social engineering
- exploiting real user funds or live production state

If a finding can be demonstrated safely on a local or forked environment, prefer that path.

## Response expectations

Best-effort targets:

- initial acknowledgment within **7 days**
- follow-up once the issue is reproduced or triaged
- public disclosure only after a fix, mitigation, or explicit maintainer approval

## Public hardening principle

This project does **not** treat source secrecy as the primary security boundary.

Public releases are expected to remain safe under the assumption that attackers can read the code.
