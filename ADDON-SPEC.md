# RAPP Brainstem Add-on Profile 1

`rapp-brainstem-addon/1` is a portable repository shape for capabilities that
layer around a RAPP Brainstem without redefining RAPP/1.

This is a packaging profile, not a new RAPP wire envelope or registered frame
kind. RAPP/1 remains authoritative. Add-ons communicate with Brainstem through
the existing `POST /chat` wire and may add host-owned files, lifecycle tools,
skills, agents, or UI adapters.

## Required public repository shape

```text
brainstem-addon.json
SKILL.md
addon/
  SKILL.md
  ... declared payload files
scripts/
  install-addon.ps1
```

## Manifest requirements

A `brainstem-addon.json` document:

- uses exact schema `rapp-brainstem-addon/1`;
- references `schemas/rapp-brainstem-addon-1.schema.json`;
- declares a permanent `rappid` identity and semantic version;
- pins the RAPP/1 authority by repository, commit, revision frame hash, and
  normative SHA-256;
- declares `wire.transport` as exactly `POST /chat`;
- declares one relative install root below `rapp_brainstem`;
- lists every payload file with relative path, byte length, and SHA-256;
- declares required permissions, network listeners, secrets, side effects,
  compatibility, acceptance tests, and uninstall behavior;
- keeps local/private collaboration directories out of the published payload.

## Installation

The installer verifies the schema, RAPP/1 wire, destination confinement, unique
paths, absence of reparse points, and every payload hash before copying files.
It never executes a payload merely because it was copied.

When an add-on intentionally manages a path already tracked by the byte-pinned
workspace source, the workspace bootstrap may mark that path
`assume-unchanged`. The add-on installer then owns updates to that path;
unrelated user changes remain visible and block workspace refresh.

The user or host explicitly invokes the declared entrypoint after reviewing the
manifest and granting required permissions.

## Collaboration convention

Host integrations should install under:

```text
rapp_brainstem/agents/experimental/<addon-slug>
```

The installed root contains a colocated `SKILL.md`. Local proposals, evidence,
and handoffs should use declared ignored directories such as:

```text
candidates/
evidence/
handoffs/
```

No credentials, tokens, cookies, `.env`, private memory, or raw host data may
enter a public add-on artifact.

## First conforming add-on

This repository publishes `@rapp/scout-native`, the first
`rapp-brainstem-addon/1` package. It installs at
`agents/experimental/scout`, starts the workspace Brainstem invisibly, writes
an ignored localhost endpoint configuration, and keeps the real static
`index.html` connected in Microsoft Scout's middle workspace pane.
