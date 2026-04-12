# Public-Stage Release Flow

Last updated: **2026-04-11**

This workflow keeps canonical development and public publication separated by using a **local public-stage copy**.

## Goal

Avoid pushing directly from the canonical development workspace into the public mirror.

Instead:

1. select a reviewed source snapshot,
2. build a local public-stage copy,
3. apply sanitization overrides,
4. review the result,
5. push manually to the public repo.

## Recommended directory layout

- Canonical development repo: `~/projects/auto314-private`
- Snapshot worktree: `~/projects/auto314-release-YYYYMMDD`
- Public-stage copy: `~/projects/auto314-public-stage`

## Recommended flow

### A. Choose the release snapshot

For a public release, you may publish a **previous-day runnable snapshot** rather than the newest private debugging work.

Recommended rule:

- contracts: reviewed release state,
- frontend + backend: same compatible snapshot,
- snapshot age: prefer **at least 48 hours old** unless a newer public hotfix is required,
- README, integration docs, ABI artifacts, and interface files may be intentionally overlaid from the latest reviewed state when they define the public integration surface,
- recent debugging-only work: may remain private until the next release,
- P0 fixes for the released surface: must still be backported before publication.

### B. Create a clean snapshot worktree

Example:

```bash
git worktree add ../auto314-release-2026-04-08 <commit-or-tag>
```

Then build the public-stage copy from the current release tooling while pointing it at that frozen source snapshot.

### C. Build the public-stage copy

From the chosen snapshot worktree:

```bash
./scripts/prepare-public-stage.sh ../auto314-public-stage ../auto314-release-2026-04-08
```

This flow:

1. copies the runnable product surface listed in `release/public-stage.manifest` from the chosen snapshot,
2. overlays the current public-release docs and publication files listed in `release/public-stage-overlay.manifest`,
3. removes internal or non-release-facing files listed in `release/public-stage-prune.manifest`,
4. applies common public overrides from `release/public-stage-overrides/`,
5. applies any snapshot-specific backports from `release/public-stage-version-overrides/<git-short-sha>/`,
6. leaves `.git/` in the target directory untouched.

### D. Review the stage directory

In the public-stage directory:

- inspect `git diff`,
- verify the repo link points to `bidaiAI/auto314`,
- verify placeholders replaced official writable origins,
- verify the released frontend/backend pair is still coherent.

### E. Push manually

Only after review should the public-stage repo be pushed to the public mirror.

## Notes

- The public mirror is a **reviewed release mirror**, not a live dev mirror.
- If the newest private work is not ready, publish the last coherent runnable snapshot instead.
- The public-stage copy should be treated as disposable build output for publication, not as the main development workspace.
- The recommended first public release candidate currently verified in local builds is `ae67b87e59370c1ea128a08a39693c99ee18d002` from **2026-04-06 07:23:25 -0500**, because it is older than 48 hours and passed local build + test checks.
