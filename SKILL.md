---
name: scout-brainstem-bootstrap
version: 1.1.0
description: Use Microsoft Scout to materialize the byte-pinned Scout-native Brainstem add-on, run Brainstem invisibly, and keep the real static index.html connected in Scout's middle pane without asking the user to run terminal commands.
homepage: https://github.com/kody-w/scout-brainstem-bootstrap
metadata: {"category":"ai-agents","runtime":"microsoft-scout","scope":"local-only"}
---

# Scout Brainstem Bootstrap

Use this skill when the user asks Scout to set up, install, repair, update, or
open a local RAPP Brainstem workspace.

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
  content, or send messages during bootstrap.
- Never synthesize a replacement UI, gateway, or integration. Materialize and
  verify the byte-pinned working profile declared in `brainstem-addon.json`.
  After materialization, do not edit `brainstem.py` or `index.html`.
- Never redefine the RAPP/1 wire. The add-on continues to use `POST /chat`.
- Preserve existing agents, `soul.md`, `.env`, authentication state, and local
  data through the installer's update/backup path. Never delete an existing
  `~/.brainstem`.
- Never print, copy, commit, or transmit GitHub tokens, Copilot sessions,
  `.env` values, or Brainstem secrets.
- Treat `https://aka.ms/rappinstall` as orientation only. If it resolves to
  Azure deployment documentation, do not follow those cloud instructions.
- A reachable page is not success. Require the workspace controller to report
  `status: "ok"`, the real static `index.html` to show `connected` in Scout's
  middle pane, and one neutral `/chat` proof.

## Pinned bootstrap sources

Use only these immutable installer artifacts:

| Platform | URL | SHA-256 |
| --- | --- | --- |
| Windows | `https://raw.githubusercontent.com/kody-w/rapp-installer/49db80c8c6b6caa7647369beaf477d374a8f293c/install.ps1` | `747a5a8b2e6a41292a4b8b1a719fea588bdd21c523e3a3edb474dd651a8a2fda` |
| macOS/Linux | `https://raw.githubusercontent.com/kody-w/rapp-installer/49db80c8c6b6caa7647369beaf477d374a8f293c/install.sh` | `cc586dd1752520d05fbff99a637eef308bb7051ffae457b7d037aa0574341794` |

The immutable bootstrap installer may update the installed runtime from
`kody-w/rapp-installer` through its normal versioned upgrade path.

## Phase 0: Check host capabilities and preservation boundaries

Before installing anything:

1. Confirm the host exposes workspace selection and file-preview controls.
   Shell, filesystem, and browser tools alone do not establish that Scout can
   open its own middle pane. If those controls are unavailable, explain the
   limitation and ask whether to proceed with backend-only setup and a manual
   preview step. Report `preview_pending`, not completion, until the real page
   is visibly connected. Do not substitute a browser tab or blind window clicks.
2. Inspect the proposed workspace before materialization. If it contains
   unrelated files or local changes, preserve it and ask to use a separate
   folder, such as `Brainstem-Scout`. Do not silently reuse or overwrite it.
3. Inspect the global installation as well as the workspace. A separate
   workspace still shares the managed Python environment and authentication
   under `~/.brainstem`; it is not a fully separate installation. Preserve its
   version, custom agents, and local changes unless an upgrade is approved.
   Do not run an update path that resets existing source merely to start a
   stopped server.

## Phase 1: Install this skill and its public support files

1. Clone `https://github.com/kody-w/scout-brainstem-bootstrap.git` to
   `~/.scout/bootstrap/scout-brainstem-bootstrap` if absent.
2. If it already exists, update it only with a clean fast-forward. Never
   discard local changes.
3. Prefer Scout's skill-management tool to create or update the global skill
   named `scout-brainstem-bootstrap` from the repository's root `SKILL.md`.
4. If the tool is unavailable or cannot preserve the exact source bytes, run
   the repository's `scripts/install-global-skill.ps1` on Windows or
   `scripts/install-global-skill.sh` on macOS/Linux. A tool that generates new
   frontmatter is not a byte-identical import.
5. Verify that the installed global `SKILL.md` is byte-identical to the
   repository copy, then load it through Scout's skill-management tools to
   confirm it is discoverable.

## Phase 2: Inspect without changing the Brainstem installation

1. Detect the operating system.
2. Check `http://127.0.0.1:7071/health` with a short timeout.
3. Classify the result:
   - `status: "ok"` or `status: "unauthenticated"`: preserve the installation.
   - connection refused or invalid response: determine whether an existing
     installation is merely stopped before continuing to **Phase 3**. A failed
     health request is not evidence that its source needs upgrading.
   - another application owns port 7071: identify it and stop the bootstrap.
     The stable installer uses 7071 for its authentication gate and must never
     terminate an unrelated listener.

## Phase 3: Install or repair the supported runtime

Tell the user what will be installed and where before executing.

### Windows

1. Download the pinned `install.ps1` to a unique file under the current user's
   temporary directory.
2. Compute SHA-256 with `Get-FileHash`. Refuse to execute unless it exactly
   matches the pinned Windows hash.
3. Windows PowerShell 5.1 may decode a BOM-less UTF-8 script as ANSI. In the
   detached child process, explicitly read the verified file as UTF-8 and
   parse it with its original filename before execution:

   ```powershell
   $tokens = $null
   $parseErrors = $null
   $source = [IO.File]::ReadAllText(
       $installerPath, (New-Object Text.UTF8Encoding($false, $true))
   )
   $ast = [Management.Automation.Language.Parser]::ParseInput(
       $source, $installerPath, [ref]$tokens, [ref]$parseErrors
   )
   if ($parseErrors.Count) { throw "Verified installer failed UTF-8 parsing." }
   $installerScript = $ast.GetScriptBlock()
   & $installerScript
   ```

   `$installerPath` must be the absolute path already verified in step 2.
   Keep its bytes unchanged; do not add a BOM or rewrite the downloaded file.
   Retaining the filename preserves the installer's `$PSCommandPath` and its
   file-based failure exit behavior. Never parse or execute an unverified
   network response. If the installation plan includes reviewed arguments,
   such as an approved version pin, pass those arguments to `$installerScript`
   rather than silently invoking the installer's default update path.
4. Start that child with `Start-Process`, capture its PID, and use separate
   `-RedirectStandardOutput` and `-RedirectStandardError` files, such as
   `~/.brainstem/scout-bootstrap.out.log` and
   `~/.brainstem/scout-bootstrap.err.log`. Do not merge native stderr into a
   PowerShell pipeline with `2>&1` or `*>` under
   `$ErrorActionPreference = "Stop"`: an ordinary native-process warning can
   become a terminating `NativeCommandError`. Inspect exit codes and health,
   not the mere presence of stderr. Do not use `irm ... | iex`.
5. If Windows asks for package-install elevation, tell the user why and wait
   for that visible approval.

### macOS or Linux

1. Download the pinned `install.sh` to a unique temporary file.
2. Verify it with `shasum -a 256` or `sha256sum`. Refuse to execute unless it
   exactly matches the pinned Unix hash.
3. Run the saved installer as a detached process and write output to
   `~/.brainstem/scout-bootstrap.log`. Do not pipe a network response directly
   into a shell.

### Monitor the installer

Poll the installer process and its log. It is acceptable for the installer to
start a global Brainstem temporarily; the workspace controller will run an
isolated copy on separate loopback ports. If the installer exits unsuccessfully,
read the redacted tail of the bootstrap log and report the failure. Do not retry
blindly.

If dependency installation and authentication succeeded but server startup
failed, record that installer failure separately. Do not rerun installation
or update source solely to retry startup. After confirming port ownership,
start the existing compatible runtime with its supported launcher or a hidden
`Start-Process` using its managed Python, existing `brainstem.py`, and separate
stdout/stderr logs. Require the normal health and authentication gates below.
Never suppress all errors or treat a real nonzero exit as success.

For a safe Windows diagnosis, Scout can run
`scripts/repro-windows-bootstrap.ps1` from this repository. It uses offline
fixtures by default; `-DownloadPinnedInstaller` additionally downloads and
hash-checks the declared installer for parse-only inspection. Neither mode
executes that installer, signs in, or changes a Brainstem installation.

## Phase 4: Complete the authentication gate

Before starting the workspace controller, require the installed Brainstem at
`http://127.0.0.1:7071/health` to report `status: "ok"`.

If it reports `unauthenticated`:

1. Explain that Brainstem uses the user's GitHub Copilot entitlement.
2. Let the installer or Brainstem open the temporary device-code flow.
3. Never display, read, or repeat the resulting token.
4. Poll `/health` until it reports `ok`.

The temporary authentication page is not the final Brainstem experience. After
authorization, keep the working chat only in Scout's middle workspace pane.
Do not start the exact workspace controller with a stale or unauthenticated
global Brainstem token.

## Phase 5: Materialize the Brainstem Scout workspace

Use the current Scout workspace when it is an empty local folder. Otherwise use
the user's Documents folder and create `Microsoft Scout/Brainstem`.

`@rapp/scout-native` 1.0 currently declares Windows support. On another
operating system, do not claim the native middle-pane setup is complete.

On Windows, run:

```powershell
& "$HOME\.scout\bootstrap\scout-brainstem-bootstrap\scripts\setup-workspace.ps1" `
  -WorkspaceRoot "<chosen-local-workspace-path>"
```

Require the result to report:

- `schema: rapp-brainstem-addon/1`;
- `addon: @rapp/scout-native`;
- the workspace path;
- `rapp_brainstem/index.html`;
- the declared `grail_id`;
- `verified: true`.

This creates a sparse workspace whose visible root stays focused on
`rapp_brainstem`. It checks out the exact known-good Scout-native source commit,
verifies the Brainstem, static page, and controller hashes, installs the public
add-on payload under `agents/experimental/scout`, and excludes local
collaboration state through the workspace repository's local Git exclude file.

Treat `rapp_brainstem/agents/experimental/scout` as the collaboration root.
Read its colocated `SKILL.md` and `COLLABORATION.md` before doing shared work.
Place proposed artifacts in `candidates/`, public-safe validation records in
`evidence/`, and reviewed host-transfer manifests in `handoffs/`.

## Phase 6: Start the hidden workspace runtime

Run:

```powershell
& "<workspace>\rapp_brainstem\agents\experimental\scout\brainstem-workspace.ps1" start
& "<workspace>\rapp_brainstem\agents\experimental\scout\brainstem-workspace.ps1" status
```

The controller must:

- run the workspace Brainstem invisibly;
- choose a free localhost port without killing unrelated processes;
- write ignored `agents/experimental/scout/preview-config.js` with the selected
  live endpoint and install secret;
- report `status: "ok"` or the actionable `unauthenticated` state;
- report `brainstem_dir` as this workspace's `rapp_brainstem` directory.

## Phase 7: Put Brainstem in Scout's middle pane

Open `<workspace>/rapp_brainstem/index.html` in the active Scout workspace
preview and keep it selected. Do not open a separate browser window.

This is the real static Brainstem page used by the proven local pattern. It
loads the ignored `preview-config.js` and talks directly to the live endpoint.
Do not create `SCOUT.html`, an iframe, a copied UI, or a sidecar gateway.

If the preview does not show `connected`, stop and diagnose the endpoint,
preview config, or authentication gate. Do not replace the working pattern.

## Phase 8: Verify real usage

1. Record only these public-safe fields: `status`, `version`, `model`, and
   loaded agent names.
2. Send through the workspace Brainstem's selected live endpoint:

   ```json
   {
     "user_input": "Reply with exactly: Brainstem is ready.",
     "conversation_history": []
   }
   ```

3. Require HTTP 200, a non-empty `response`, and a `session_id`.
4. Require the middle-pane UI to remain connected after the request.
5. If chat fails, report the precise error and leave the private workspace logs
   in place. Never convert a failure into success.

## Phase 9: Solve the "now what?" moment

After setup succeeds, briefly explain the pairing:

- **Brainstem** is the user's local workshop: durable context, agents, fast
  prototypes, and a standard `POST /chat` loop.
- **Scout** is the outer workshop: files, browser, Microsoft 365, testing,
  approvals, scheduled automations, and deployment paths.
- Together they can prototype locally, test with evidence, and promote only the
  reviewed artifact.

Then present these starting paths as discrete choices:

1. **Teach my twin** - interview the user and Brainstem, identify one missing
   capability, generate a small agent, test it, and hot-load only after checks.
2. **Build a daily loop** - create a Scout automation that calls Brainstem's
   existing `/chat` contract through roles such as interviewer, builder,
   verifier, and curator. Durable learning remains a proposal until approved.
3. **Make a work briefing** - let Brainstem shape the user's local context while
   Scout gathers explicitly requested Microsoft 365 information. Keep private
   details out of outbound messages unless the user approves the exact text.
4. **Prototype an automation** - define inputs, outputs, side effects, and test
   cases; implement locally as a Brainstem agent or Scout skill; run a failure
   test and a success test; retain hashes and evidence under the Scout
   collaboration root.
5. **Promote a tested draft** - after the user names **Copilot Studio**,
   **Microsoft Copilot Cowork**, or **Scout** as the target, package the exact
   locally tested artifact for that host.

For path 5:

1. Ask which target and environment the user intends.
2. Re-run local acceptance tests and identify the artifact by revision and
   SHA-256.
3. Inspect the target's currently available deployment tools and permissions;
   never guess that a connector or environment exists.
4. Create a **draft**, preview, or manual import package first. Do not publish.
5. Return the target, visibility, recipients, configuration, test evidence,
   rollback path, and `published: false` to Brainstem and write the reviewed
   manifest under `agents/experimental/scout/handoffs/`.
6. Show the user exactly what will become visible and to whom. Wait for
   explicit user confirmation before publish, send, sharing, or enabling a
   scheduled action.

Report:

- Brainstem version and model;
- loaded agent names;
- whether fresh install, repair, authentication, or no change was needed;
- workspace and middle-pane preview paths;
- global skill installation path;
- the successful chat proof.

Also distinguish fresh provisioning from recovery or reuse. Record which of
Python, Git, GitHub CLI, dependencies, and Copilot authentication already
existed. A new workspace on an authenticated machine is not a clean-machine
install test. Keep runtime readiness, chat proof, and middle-pane readiness
as separate results; `preview_pending` remains an incomplete setup.

End with the five starting paths, not a generic "what would you like to do?"

## Recovery rules

- If a prior global Brainstem process is healthy, preserve it; the isolated
  workspace may use different ports.
- If a preferred port is occupied, let the controller select another one.
- If an installer hash differs, stop immediately and report a supply-chain
  verification failure.
- If package installation fails, preserve the log and existing installation.
- If authentication is canceled, leave Brainstem running in the sign-in state
  and report that setup is incomplete.
- If the workspace contains unrelated files or local Git changes, stop rather
  than overwriting them.
- Never convert a failure into a success-shaped fallback.
