---
name: scout-brainstem-bootstrap
version: 1.0.0
description: Use Microsoft Scout to install, repair, authenticate, verify, and visibly open a local RAPP Brainstem without asking the user to run terminal commands.
homepage: https://github.com/kody-w/scout-brainstem-bootstrap
metadata: {"category":"ai-agents","runtime":"microsoft-scout","scope":"local-only"}
---

# Scout Brainstem Bootstrap

Use this skill when the user asks Scout to set up, install, repair, update, or
open a local RAPP Brainstem.

The user never runs a terminal command. Scout performs the workflow with its
own shell, browser, filesystem, and skill-management tools.

## Non-negotiable boundaries

- Installing Microsoft Scout itself is the one prerequisite this skill cannot
  perform because the skill runs inside Scout.
- An explicit request to "set this up", install, repair, or update is approval
  for the matching local operation. Before changing the device, explain that
  setup may install Python, Git, and GitHub CLI; write under `~/.brainstem`,
  `~/.local`, and `~/.scout`; and open a GitHub authorization page.
- Never deploy Azure resources, install RAR or unrelated plugins, publish
  content, or send messages as part of this workflow.
- Never modify `rapp_brainstem/brainstem.py`, the Grail `index.html`, or the
  RAPP/1 protocol. Use the supported installer and launcher around the kernel.
- Preserve existing agents, `soul.md`, `.env`, authentication state, and local
  data through the installer's update/backup path. Never delete an existing
  `~/.brainstem`.
- Never print, copy, commit, or transmit GitHub tokens, Copilot sessions,
  `.env` values, or Brainstem secrets.
- Treat `https://aka.ms/rappinstall` as orientation only. If it resolves to
  Azure deployment documentation, do not follow those cloud instructions.
- A reachable page is not success. Require `/health` to report `status: "ok"`,
  then prove one neutral `/chat` request works.

## Pinned bootstrap sources

Use only these immutable installer artifacts:

| Platform | URL | SHA-256 |
| --- | --- | --- |
| Windows | `https://raw.githubusercontent.com/kody-w/rapp-installer/49db80c8c6b6caa7647369beaf477d374a8f293c/install.ps1` | `747a5a8b2e6a41292a4b8b1a719fea588bdd21c523e3a3edb474dd651a8a2fda` |
| macOS/Linux | `https://raw.githubusercontent.com/kody-w/rapp-installer/49db80c8c6b6caa7647369beaf477d374a8f293c/install.sh` | `cc586dd1752520d05fbff99a637eef308bb7051ffae457b7d037aa0574341794` |

The immutable bootstrap installer may update the installed runtime from
`kody-w/rapp-installer` through its normal versioned upgrade path.

## Phase 1: Inspect without changing anything

1. Detect the operating system.
2. Check `http://127.0.0.1:7071/health` with a short timeout.
3. Classify the result:
   - `status: "ok"`: preserve the running installation and continue to
     **Phase 4**.
   - `status: "unauthenticated"`: do not reinstall; continue to **Phase 3**.
   - connection refused or invalid response: continue to **Phase 2**.
   - another application owns port 7071: stop and report the process identity.
     Never terminate an unverified process.

## Phase 2: Install or repair locally

Tell the user what will be installed and where before executing.

### Windows

1. Download the pinned `install.ps1` to a unique file under the current user's
   temporary directory.
2. Compute SHA-256 with `Get-FileHash`. Refuse to execute unless it exactly
   matches the pinned Windows hash.
3. Start the saved installer in a detached Windows PowerShell process. Capture
   its PID and redirect standard output and error to
   `~/.brainstem/scout-bootstrap.log`. Do not use `irm ... | iex`.
4. If Windows asks for package-install elevation, tell the user why and wait
   for that visible approval.

### macOS or Linux

1. Download the pinned `install.sh` to a unique temporary file.
2. Verify it with `shasum -a 256` or `sha256sum`. Refuse to execute unless it
   exactly matches the pinned Unix hash.
3. Run the saved installer as a detached process and write output to
   `~/.brainstem/scout-bootstrap.log`. Do not pipe a network response directly
   into a shell.

### Monitor

Poll `/health` for up to 20 minutes while also checking the installer process.
If the installer exits before Brainstem responds, read the redacted tail of the
bootstrap log and report the failure. Do not retry blindly.

## Phase 3: Complete GitHub authentication

If `/health` reports `unauthenticated`:

1. Visibly open `http://127.0.0.1:7071`.
2. Explain that Brainstem uses the user's GitHub Copilot entitlement and that
   Scout never needs to see or repeat the token.
3. Let the user complete Brainstem's GitHub device-code page.
4. Poll `/health` until it reports `status: "ok"`. Do not claim success while
   authentication is pending.

## Phase 4: Verify real usage

1. Record only these public-safe fields from `/health`: `status`, `version`,
   `model`, and loaded agent names.
2. Send one neutral request to the existing `POST /chat` endpoint:

   ```json
   {
     "user_input": "Reply with exactly: Brainstem is ready.",
     "conversation_history": []
   }
   ```

3. Require HTTP 200, a non-empty `response`, and a `session_id`.
4. If chat fails, report the precise error and leave the logs available. A
   green health check alone is not enough.

## Phase 5: Persist this skill globally

After Git is available:

1. Clone `https://github.com/kody-w/scout-brainstem-bootstrap.git` to
   `~/.scout/bootstrap/scout-brainstem-bootstrap` if absent.
2. If it already exists, update it only with a clean fast-forward. Never
   discard local changes.
3. Prefer Scout's skill-management tool to create or update the local skill
   named `scout-brainstem-bootstrap` from the repository's root `SKILL.md`.
4. If that tool is unavailable, run the matching support script:
   - Windows: `scripts/install-global-skill.ps1`
   - macOS/Linux: `scripts/install-global-skill.sh`
5. Verify the installed global `SKILL.md` is byte-identical to the repository
   copy.

## Phase 6: Leave the experience ready

Visibly navigate Scout's browser to `http://127.0.0.1:7071` and leave
Brainstem open. Do not close it after verification.

Report:

- Brainstem version and model;
- loaded agent names;
- whether fresh install, repair, authentication, or no change was needed;
- global skill installation path;
- the successful chat proof.

Do not offer Azure deployment. End after the local Brainstem is open and ready.

## Recovery rules

- If a prior Brainstem process is healthy, reuse it.
- If port 7071 is occupied, identify the listener before taking any action.
- If an installer hash differs, stop immediately and report a supply-chain
  verification failure.
- If package installation fails, preserve the log and existing installation.
- If authentication is canceled, leave Brainstem running in the sign-in state
  and report that setup is incomplete.
- Never convert a failure into a success-shaped fallback.
