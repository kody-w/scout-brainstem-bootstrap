# Scout-native collaboration root

`rapp_brainstem/agents/experimental/scout` is the installed
`@rapp/scout-native` add-on and the shared working boundary between Microsoft
Scout and the local Brainstem.

## Stable files

| Path | Purpose |
| --- | --- |
| `addon.json` | Installed add-on identity, provenance, permissions, and hashes |
| `SKILL.md` | Scout-first workspace operating contract |
| `brainstem-workspace.ps1` | Invisible Brainstem lifecycle and preview config |
| `exchange.py` | Lossless Agent/Skill and Squad/Skill exchange |
| `AGENT-ROSETTA-1.md` | Host-neutral first-contact draft |
| `RAPP-EXCHANGE-1.md` | Experimental RAPP/1 capability binding |
| `ROSETTA.md` | Scout↔Brainstem map |

## Local collaboration directories

- `candidates/` - proposed agents, skills, automations, and deployment packages;
- `evidence/` - redacted test inputs, expected outputs, hashes, and results;
- `handoffs/` - reviewed manifests for Scout, Copilot Studio, or Copilot Cowork.

These directories stay local and never carry credentials, tokens, `.env`
values, private memory, or raw Microsoft 365 content.

## Loop

1. Interview through the existing `POST /chat` contract.
2. Propose one bounded artifact under `candidates/`.
3. Test both success and failure behavior.
4. Record source revision, SHA-256, side effects, permissions, and redacted
   evidence.
5. Ask the user before hot-loading, scheduling, publishing, sharing, or sending.
6. Put the reviewed transfer manifest under `handoffs/` with
   `published: false`.
