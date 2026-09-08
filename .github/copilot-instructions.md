# Repository instructions

This repository is the public onboarding bridge from an already-installed
Microsoft Scout to a healthy local RAPP Brainstem.

- Keep root `SKILL.md` self-contained and feedable.
- The user never runs terminal commands; Scout executes them.
- Never add a Microsoft Scout installer or claim a public Scout download URL.
- Never add Azure deployment, RAR/plugin installation, or outbound messaging.
- Never modify or patch the Brainstem Grail (`brainstem.py`, `index.html`, or
  RAPP/1). Use supported installers and launchers.
- Pin executable network artifacts to immutable commits and SHA-256.
- Preserve existing local Brainstem data and credentials.
- Require both `/health` and one neutral `/chat` proof before reporting success.
- Keep support scripts dependency-free and compatible with Windows PowerShell
  5.1 or Bash 3.2+.
- Update `bootstrap-manifest.json`, `SKILL.md`, and tests together when changing
  versions or installer pins.
