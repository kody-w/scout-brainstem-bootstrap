# Security

## Trust boundary

This repository orchestrates a local install from Microsoft Scout. It does not
ship Microsoft Scout or the RAPP Brainstem runtime.

Executable installer URLs in `SKILL.md` are pinned to immutable Git commits and
SHA-256 values. Scout must download to disk, verify the digest, and only then
execute. A hash mismatch is a hard failure.

The workflow must not expose GitHub tokens, Copilot sessions, Brainstem secrets,
`.env` values, private agents, the user's soul, or local memory. Generated
preview configuration stays ignored under
`rapp_brainstem/agents/experimental/scout`.

The Scout-native profile permits the static workspace preview only with the
per-install secret and only from loopback. The public add-on installer verifies
the source commit and every declared artifact before startup.

## Reporting

Report vulnerabilities privately through GitHub Security Advisories for
`kody-w/scout-brainstem-bootstrap`. Do not include credentials, tokens, or
private Brainstem data in a report.

## Supported scope

The current contract supports:

- Windows PowerShell 5.1+;
- macOS and Linux with Bash, Git, and curl;
- a local Brainstem workspace with a dynamically selected localhost port.

Automatic cloud deployment and remote exposure are intentionally out of scope.
Optional promotion creates a draft or manual import package and requires a
separate user confirmation before anything is published or shared.
