# Security

## Trust boundary

This repository orchestrates a local install from Microsoft Scout. It does not
ship Microsoft Scout or the RAPP Brainstem runtime.

Executable installer URLs in `SKILL.md` are pinned to immutable Git commits and
SHA-256 values. Scout must download to disk, verify the digest, and only then
execute. A hash mismatch is a hard failure.

The workflow must not expose GitHub tokens, Copilot sessions, Brainstem secrets,
`.env` values, private agents, the user's soul, or local memory.

## Reporting

Report vulnerabilities privately through GitHub Security Advisories for
`kody-w/scout-brainstem-bootstrap`. Do not include credentials, tokens, or
private Brainstem data in a report.

## Supported scope

The current contract supports:

- Windows PowerShell 5.1+;
- macOS and Linux with Bash, Git, and curl;
- a local Brainstem bound to `127.0.0.1:7071`.

Cloud deployment and remote exposure are intentionally out of scope.
