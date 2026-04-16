# Changelog

All notable public-release changes to this repository will be documented here.

## 2026-04-16

### Factory vNext and runtime docs alignment

- documented the current official BSC and Base factory profiles
- documented the `0.005 native` graduation-tail assist behavior
- documented pre-graduation transfer-to-contract token sells while ordinary wallet-to-wallet transfers remain disabled
- clarified that public `/health` is minimal and private diagnostics live behind `/health/details`
- updated integration guidance for legacy direct launch pages: old factories stay out of homepage discovery, but token detail / chart routes may still hydrate by direct token address

## 2026-04-12

### Initial public MIT release

- published the first reviewed public MIT snapshot
- based the runnable product surface on snapshot `ae67b87e59370c1ea128a08a39693c99ee18d002`
- kept recent unpublished debugging work out of the first public release
- added trademark and public security policy notes
- sanitized public env templates for self-hosting
- disabled reference metadata upload by default in the public release
- minimized `/health` in the released backend snapshot

### Public docs and interface refresh

- refreshed `README.md` and `README.zh-CN.md`
- added `SECURITY.md`
- added `CONTRIBUTING.md`
- added basic GitHub issue / PR templates
- added initial public release notes in English and Chinese
- updated public integration/spec docs to the latest reviewed state
- updated ABI artifacts and contract interface files to the latest reviewed state
- removed several internal/research-oriented or stale snapshot docs from the public mirror surface
- further reduced public docs by removing release-maintainer-only and operational-maintainer-only docs from the public surface
