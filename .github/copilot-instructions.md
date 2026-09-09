# Repository instructions

This repository is the public onboarding bridge from an already-installed
Microsoft Scout to a healthy local RAPP Brainstem shown inside a Scout
workspace.

- Keep root `SKILL.md` self-contained and feedable.
- The user never runs terminal commands; Scout executes them.
- Never add a Microsoft Scout installer or claim a public Scout download URL.
- Never add automatic Azure deployment, RAR/plugin installation, publishing,
  or outbound messaging to bootstrap.
- Never synthesize a replacement UI, iframe, or gateway. Preserve the
  byte-pinned `@rapp/scout-native` pattern: real static `index.html`, ignored
  `preview-config.js`, and the live Brainstem endpoint.
- Never redefine RAPP/1. Add-ons continue to use `POST /chat`.
- Pin executable network artifacts to immutable commits and SHA-256.
- Preserve existing local Brainstem data and credentials.
- Require controller health, connected real middle-pane `index.html`, and one
  neutral `/chat` proof before reporting success.
- Follow-on deployment paths must create drafts or import packages first and
  wait for explicit approval before publishing or enabling.
- Keep support scripts dependency-free and compatible with Windows PowerShell
  5.1 or Bash 3.2+.
- Update `bootstrap-manifest.json`, `SKILL.md`, and tests together when changing
  versions or installer pins.
