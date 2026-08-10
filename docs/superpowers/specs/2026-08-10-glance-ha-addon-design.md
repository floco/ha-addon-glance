# Glance Home Assistant Add-on — Design

Date: 2026-08-10
Status: Approved

## Summary

Package [Glance](https://github.com/glanceapp/glance) (a self-hosted dashboard) as a
Home Assistant OS Supervisor add-on, distributed via a new public GitHub repo,
`floco/ha-addon-glance`, that acts as a custom HA add-on repository.

## Goals / Non-goals

**Goals**
- Installable by adding the repo URL to Settings → Add-ons → Add-on Store → Repositories.
- Runs upstream Glance unmodified, pinned to a specific released version.
- Reachable both as a direct port (e.g. `http://homeassistant.local:8080`) and via HA
  Ingress (a "Glance" entry in the HA sidebar).
- User has full access to Glance's own YAML configuration schema — the add-on does not
  attempt to re-model Glance's config as HA add-on options.
- Multi-arch (aarch64, amd64, armv7 — the common HA OS targets).

**Non-goals**
- No HACS integration / no HA entities or sensors derived from Glance.
- No attempt to keep an HA-native options UI in sync with Glance's evolving schema.
- No CI-based auto-bump of the pinned Glance version (manual for now).

## Architecture

```
ha-addon-glance/                  (GitHub repo = HA add-on repository)
├── repository.yaml               marks repo as an HA add-on store, sets repo display name
├── README.md                     install instructions, screenshots, ingress caveat
├── LICENSE                       MIT (scaffolding only; Glance itself stays AGPL-3.0,
│                                  we run its published image unmodified)
└── glance/                       the add-on
    ├── config.yaml                HA add-on manifest: name, version, arch list, ports,
    │                              ingress config, map (config path), options/schema
    ├── build.yaml                 per-arch BUILD_FROM base image mapping
    ├── Dockerfile                 FROM glanceapp/glance:v0.8.5 (per build.yaml arg)
    │                              + s6-overlay init script
    ├── rootfs/
    │   └── etc/services.d/glance/
    │       ├── run                 s6 service: seeds config, execs glance
    │       └── finish              s6 service: logs non-zero exit
    ├── icon.png / logo.png        add-on store branding
    ├── DOCS.md                    long-form docs shown in HA's add-on "Documentation" tab
    └── CHANGELOG.md               per HA add-on convention, read by the Supervisor UI
```

### Component responsibilities

- **`repository.yaml`** — the only thing that makes this a valid add-on *repository*
  (as opposed to a single add-on). Just a name/URL/maintainer stub.
- **`config.yaml`** — declares the add-on to the Supervisor: slug, version (tracks
  Glance's version, e.g. `0.8.5`), supported architectures, `ingress: true` +
  `ingress_port: 8080`, `ports: {"8080/tcp": 8080}` with `ports_description`, and a
  `map` entry so the add-on gets a persistent config directory
  (`/config/addons_config/<slug>/` → mounted at `/config` inside the container).
- **`Dockerfile` / `build.yaml`** — builds `FROM glanceapp/glance:v0.8.5` (version pinned
  here, one line to bump), layering in `s6-overlay` service scripts. Uses the official
  Glance image as the base rather than re-implementing its build, so we inherit
  upstream's own multi-arch binaries.
- **`rootfs/etc/services.d/glance/run`** — startup script (s6 service, HA add-on
  convention):
  1. If `/config/glance.yml` does not exist, copy a bundled starter `glance.yml` into
     place (first-boot seeding, never overwrites an existing user file).
  2. `exec` the Glance binary pointed at `/config/glance.yml` on port 8080.
- **Starter `glance.yml`** — a minimal but non-empty dashboard (e.g. clock, weather via
  IP, a couple of RSS widgets) so first boot isn't a blank page, committed under
  `glance/rootfs/etc/glance/glance.yml.starter` and copied in by the run script.

## Data flow

1. User adds `https://github.com/floco/ha-addon-glance` as a repository in the HA
   Add-on Store, installs "Glance", starts it.
2. Supervisor creates `/config/addons_config/glance/` on the host, bind-mounts it to
   `/config` in the container, and starts the container per `config.yaml`.
3. s6 `run` script seeds `/config/glance.yml` on first boot, then execs Glance.
4. Glance serves HTTP on `:8080` inside the container.
   - Direct access: Supervisor's port mapping exposes container `:8080` on the host
     port the user configured (default `8080`).
   - Ingress access: Supervisor's ingress proxy forwards
     `https://<ha-host>/api/hassio_ingress/<token>/...` to container `:8080`, stripping
     its own prefix before forwarding — Glance sees ordinary root-relative requests, so
     `server.base-url` is left unset by default.
5. User edits `/config/addons_config/glance/glance.yml` (via the Studio Code
   Server/File Editor add-on, Samba, or SSH) and restarts the Glance add-on to apply
   changes. No add-on rebuild needed.

## Error handling

- **Missing/invalid `glance.yml`**: Glance's own startup validation handles this; its
  stderr surfaces in the HA add-on log viewer. We don't pre-validate YAML ourselves —
  duplicating Glance's schema validation would drift from upstream.
- **Port conflict** on the direct-access port: surfaced by the Supervisor's normal
  "add-on failed to start" UI; documented in README to change the mapped port if 8080
  is taken by another add-on.
- **Ingress incompatibility**: flagged as a known risk below, not silently swallowed —
  README calls it out explicitly with the fallback (disable ingress, use direct port).

## Known risk: Ingress compatibility is unverified

No existing HA add-on for Glance was found to confirm this pattern works (searched
GitHub code/repo search for prior art — none exists). Home Assistant's ingress proxy
strips its own path prefix before forwarding to the container, which normally makes
root-relative apps work with zero config, but this hasn't been confirmed against
Glance specifically (e.g. WebSocket-based live-reload, absolute asset URLs). This will
be verified in a real HA OS (or supervised) environment during implementation; if
broken, the fallback is `server.base-url` configuration or ingress-disabled/direct-port
operation, documented in the README either way.

## Testing / verification plan

- `docker build` the add-on image locally for at least `amd64`, confirm Glance starts
  and serves `:8080` with the starter config.
- Validate `config.yaml` / `repository.yaml` against the HA add-on schema (the
  Supervisor's `local` add-on install path can be used if a real HA OS/Supervised
  instance is available; otherwise rely on schema linting since the harness has no HA
  instance to install into).
- Manually confirm, in the README, which parts are verified vs. best-effort (ingress).
- No automated test suite — this is a packaging project around a third-party binary,
  not application code; correctness is "does the container start and serve Glance
  correctly under the declared config," which is what the build/run check above covers.

## Versioning & release process

- Add-on `config.yaml` `version` mirrors the pinned Glance tag (`0.8.5`).
- Bumping Glance: edit the `FROM` line in `Dockerfile` and the `version` in
  `config.yaml` in the same commit, add a `CHANGELOG.md` entry, tag/release the repo.
- No CI auto-update; deliberate, reviewed bumps only.

## Out of scope / follow-ups (not built now)

- CI workflow to build/publish prebuilt images to GHCR (HA add-ons can build locally
  on the device instead; prebuilt images are a later optimization if build time on
  low-power devices like RPi becomes an issue).
- Automated version-bump PRs (Renovate/Dependabot) for the pinned Glance version.
