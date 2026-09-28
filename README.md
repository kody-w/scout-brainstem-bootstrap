# Scout Brainstem Bootstrap

<!-- rapp1:network-header:start -->
[![RAPP/1](https://kody-w.github.io/rapp-hive-public/portfolio/badges/scout-brainstem-bootstrap.svg)](https://github.com/kody-w/rapp-hive-public/blob/main/portfolio/repos/scout-brainstem-bootstrap.md) · **New to RAPP?** [Start here: get your Brainstem →](https://github.com/kody-w/rapp-installer#start-here)
<!-- rapp1:network-header:end -->

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

With workspace controls available, that is the entire user workflow. Scout
checks those controls before installation; if they are unavailable, it asks
before proceeding with backend-only setup and a manual preview step. A running
server alone is not completed onboarding. The user does not copy or run a
terminal command.

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
| `scripts/repro-windows-bootstrap.ps1` | Safe Windows encoding and native-stderr reproductions |
| `brainstem-addon.json` | First add-on manifest: `@rapp/scout-native` |
| `ADDON-SPEC.md` | Reusable public repository shape for future add-ons |
| `schemas/rapp-brainstem-addon-1.schema.json` | Machine-readable add-on shape |
| `addon/` | Exact Scout-native payload installed into `agents/experimental/scout` |
| `tests/test_contract.py` | Prevents drift from the safety and onboarding contract |

## Requirements

- Microsoft Scout is already installed on Windows.
- The user has a GitHub account with Copilot access.
- Internet access to GitHub is available during setup.
- Scout exposes workspace selection and file-preview controls for fully
  automatic middle-pane setup.

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

### Reproduce Windows PowerShell 5.1 startup failures

The pinned Windows installer exposed two failures during an existing-install
recovery run:

1. Windows PowerShell 5.1's default ANSI decoding can turn the installer's
   BOM-less UTF-8 punctuation into syntax errors. On the affected host,
   default parsing reported nine errors; explicit UTF-8 parsing reported zero.
2. Under `$ErrorActionPreference = "Stop"`, merging native stderr into a
   PowerShell stream caused Flask's normal startup warning to terminate the
   installer with `NativeCommandError`. A hidden native process with separate
   output files started successfully.

Maintainers can reproduce both mechanisms without running the installer,
installing Flask, reading credentials, opening a browser, or binding a port:

```powershell
powershell.exe -NoProfile -File scripts\repro-windows-bootstrap.ps1
```

Python is needed only for the harmless native-stderr fixture; use
`-PythonPath "<path-to-python.exe>"` when it is not on PATH. The default
reproduction is offline and is exercised by the existing Windows unittest job.
For the real artifact's encoding case, opt into a download:

```powershell
powershell.exe -NoProfile -File scripts\repro-windows-bootstrap.ps1 -DownloadPinnedInstaller
```

Alternatively, pass `-InstallerPath "<verified-install.ps1>"`. The script
checks the file against `bootstrap-manifest.json` before parsing it, never
executes or modifies it, and removes its own temporary files. Its JSON report
contains counts, exit status, and booleans rather than raw logs or user paths.
A hash mismatch aborts the reproduction.

Expected results: explicit UTF-8 parsing has zero errors, the Windows-1252
fixture has parsing errors, merged native stderr raises `NativeCommandError`,
and separate native streams retain both logs with exit code zero. The actual
default-parser error count depends on the host's ANSI code page; UTF-8-enabled
hosts may not exhibit that part of the failure.

These are safe mechanism reproductions, not proof of fresh provisioning or
full Scout onboarding. Clean-install coverage still needs missing prerequisites,
first-time and canceled authorization, occupied ports, preservation of existing
data, and unavailable workspace controls. The recovery run reused existing
tools, dependencies, and Copilot authentication; middle-pane completion was
not established. Installer and add-on pins remain unchanged by this guidance.

## Security

See [SECURITY.md](SECURITY.md). Installer URLs are immutable and their hashes
are duplicated in `SKILL.md` and `bootstrap-manifest.json`; changing either
requires updating tests and reviewing the upstream installer.
