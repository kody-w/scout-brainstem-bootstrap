# Scout Brainstem Bootstrap

Give Microsoft Scout one skill file; Scout builds a complete local RAPP
Brainstem workspace and keeps the live chat in Scout's middle pane.

## What the user does

1. Install and open **Microsoft Scout** from the package or invitation supplied
   by Microsoft or your organization. This repository does not redistribute
   Scout or invent a public download link.
2. Download [`SKILL.md`](https://raw.githubusercontent.com/kody-w/scout-brainstem-bootstrap/main/SKILL.md).
3. Attach the file to a Scout conversation and say:

   > Use this skill to set up my local Brainstem end to end. Do all terminal
   > work yourself and leave Brainstem connected in this workspace's middle
   > pane when it is ready.

4. Approve an operating-system package prompt or complete GitHub device login
   if Scout explains that either is required.

That is the entire user workflow. The user does not copy or run a terminal
command.

## What Scout does

- checks for an existing Brainstem before changing anything;
- downloads a pinned RAPP installer and verifies SHA-256 before execution;
- installs or repairs prerequisites and Brainstem locally;
- preserves agents, the soul, configuration, auth state, and local data;
- creates a sparse, domain-focused `Brainstem` Scout workspace;
- materializes the byte-pinned working `@rapp/scout-native` profile;
- runs the workspace Brainstem invisibly on localhost;
- generates only an ignored endpoint config and opens the real static
  `index.html` in Scout's middle pane;
- guides the one-time GitHub device authorization before starting the
  workspace, then keeps the final chat inside Scout's middle pane;
- requires a healthy `/health` response and proves `POST /chat` works;
- installs this skill globally for future Scout conversations;
- leaves Brainstem connected inside Scout rather than in a separate window.

## After setup

The skill does not strand the user at "so now what?" It offers five concrete
starting paths:

| Path | First useful outcome |
| --- | --- |
| Teach my twin | Build and safely hot-load one missing local agent |
| Build a daily loop | Schedule a role-based Scout-to-Brainstem `/chat` automation |
| Make a work briefing | Combine local twin context with approved Microsoft 365 retrieval |
| Prototype an automation | Build and test a Brainstem agent or Scout skill locally |
| Promote a tested draft | Prepare an approval-gated Copilot Studio, Copilot Cowork, or Scout draft |

Promotion always starts from the exact locally tested artifact, includes test
evidence and rollback information, and remains `published: false` until the
user approves the target and visibility.

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
| `scripts/setup-workspace.ps1` | Materializes and verifies the exact working workspace profile |
| `scripts/install-addon.ps1` | Generic hash-checked `rapp-brainstem-addon/1` installer |
| `brainstem-addon.json` | First add-on manifest: `@rapp/scout-native` |
| `ADDON-SPEC.md` | Reusable public repository shape for future add-ons |
| `schemas/rapp-brainstem-addon-1.schema.json` | Machine-readable add-on shape |
| `addon/` | Exact Scout-native payload installed into `agents/experimental/scout` |
| `tests/test_contract.py` | Prevents drift from the safety and onboarding contract |

## Requirements

- Microsoft Scout is already installed on Windows.
- The user has a GitHub account with Copilot access.
- Internet access to GitHub is available during setup.

The workspace runtime remains local. Its ignored endpoint configuration connects
the static middle-pane page directly to the selected localhost Brainstem.
Shared work lives under
`rapp_brainstem/agents/experimental/scout/{candidates,evidence,handoffs}`.

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
