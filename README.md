# Scout Brainstem Bootstrap

Give Microsoft Scout one skill file; Scout does the rest of the local RAPP
Brainstem setup.

## What the user does

1. Install and open **Microsoft Scout** from the package or invitation supplied
   by Microsoft or your organization. This repository does not redistribute
   Scout or invent a public download link.
2. Download [`SKILL.md`](https://raw.githubusercontent.com/kody-w/scout-brainstem-bootstrap/main/SKILL.md).
3. Attach the file to a Scout conversation and say:

   > Use this skill to set up my local Brainstem end to end. Do all terminal
   > work yourself and leave Brainstem open when it is ready.

4. Approve an operating-system package prompt or complete GitHub device login
   if Scout explains that either is required.

That is the entire user workflow. The user does not copy or run a terminal
command.

## What Scout does

- checks for an existing Brainstem before changing anything;
- downloads a pinned RAPP installer and verifies SHA-256 before execution;
- installs or repairs prerequisites and Brainstem locally;
- preserves agents, the soul, configuration, auth state, and local data;
- guides GitHub device authentication in a visible browser only when needed;
- requires a healthy `/health` response and proves `POST /chat` works;
- installs this skill globally for future Scout conversations;
- leaves `http://127.0.0.1:7071` open next to Scout.

## What it does not do

- modify the Grail `brainstem.py` or `index.html`;
- deploy Azure resources;
- install unrelated marketplaces or plugins;
- expose credentials or private Brainstem state;
- tell the user to run a one-liner.

## Repository contents

| Path | Purpose |
| --- | --- |
| `SKILL.md` | Portable, feedable, global Scout workflow |
| `bootstrap-manifest.json` | Machine-readable pinned sources and acceptance contract |
| `scripts/install-global-skill.ps1` | Exact-copy global skill installation on Windows |
| `scripts/install-global-skill.sh` | Exact-copy global skill installation on macOS/Linux |
| `scripts/check-brainstem.ps1` | Safe Windows health verifier |
| `scripts/check-brainstem.sh` | Safe macOS/Linux health verifier |
| `tests/test_contract.py` | Prevents drift from the safety and onboarding contract |

## Requirements

- Microsoft Scout is already installed.
- The user has a GitHub account with Copilot access.
- Internet access to GitHub is available during setup.

Brainstem itself remains local and binds to loopback by default.

## Maintainers

Run:

```text
python -m unittest discover -s tests -v
```

The repository also validates PowerShell and shell syntax in GitHub Actions.

## Security

See [SECURITY.md](SECURITY.md). Installer URLs are immutable and their hashes
are duplicated in `SKILL.md` and `bootstrap-manifest.json`; changing either
requires updating tests and reviewing the upstream installer.
