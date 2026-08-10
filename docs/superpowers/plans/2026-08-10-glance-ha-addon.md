# Glance Home Assistant App (Add-on) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Package upstream Glance `v0.8.5` as an installable Home Assistant app (the
platform's current term for what was previously called an "add-on") and publish it as
a public GitHub repository, `floco/ha-addon-glance`, that HA users can add as a
third-party app repository.

**Architecture:** A single-app HA repository: `repository.yaml` at the root, one app
folder (`glance/`) containing `config.yaml` (the HA app manifest), a `Dockerfile` that
layers a tiny startup script on top of the *unmodified* official `glanceapp/glance`
image, and the docs/branding files HA's app store expects (`README.md`, `DOCS.md`,
`CHANGELOG.md`, `icon.png`, `logo.png`). Configuration is a plain `glance.yml` file
seeded on first boot into HA's persistent per-app config directory — no HA-side
options schema attempts to model Glance's own YAML schema.

**Tech Stack:** Docker (local Supervisor build, no CI/prebuilt image), POSIX `sh`
(Alpine base has no bash), YAML, Python 3 + PyYAML for structural validation,
`shellcheck` for the entrypoint script, `gh` CLI for GitHub repo/release management.

## Global Constraints

- Glance version is pinned to `v0.8.5` (Docker tag) everywhere it appears (Dockerfile
  `FROM`, `config.yaml` `version: "0.8.5"`, `CHANGELOG.md`). Bumping later is a
  deliberate, reviewed change touching all three in one commit.
- No `image:` key in `config.yaml` — the app is always built locally by the
  Supervisor from the `Dockerfile` in this repo. No CI/CD, no prebuilt image, no
  GHCR publishing (confirmed out of scope by the design spec).
- Current HA terminology (confirmed live at home-assistant.io as of 2026.8) renamed
  "add-on" to "app": UI path is **Settings > Apps**, `io.hass.type` label value is
  `"app"`, map type keyword is still `addon_config` (unchanged despite the rename).
  Use "app" as the primary term in all user-facing text, with "(formerly 'add-on')"
  noted once in the root README for users on older HA versions/muscle memory.
- Supported architectures: `amd64`, `aarch64`, `armv7` — confirmed via
  `docker manifest inspect glanceapp/glance:v0.8.5`, which publishes exactly these
  three platforms (`amd64`, `arm64`, `arm/v7`).
- Base image for the app is `docker.io/glanceapp/glance:v0.8.5` directly (its own
  `alpine:3.22` final stage, confirmed via upstream Dockerfile) — **not** one of
  Home Assistant's own base images. Consequence: no `s6-overlay`/`bashio` are present
  in the image, so this app does **not** use the `rootfs/etc/services.d/...` s6
  pattern seen in official HA app examples. Instead, a single POSIX-sh entrypoint
  script handles first-boot config seeding and then `exec`s the Glance binary
  directly as PID 1. This is a deliberate, documented deviation, not an oversight.
- No automated test suite is added to the repo (packaging project, not application
  code — per design spec). Verification per task is local `docker build`/`docker run`
  + structural checks, run by hand, not committed as CI.
- Repo: `floco/ha-addon-glance`, public, on the already-authenticated `floco` GitHub
  account (`gh auth status` confirms `repo` + `workflow` scopes are available).
- The local working directory (`/projects/glance_ha_app`) is already a git repo on
  branch `main`, with one commit (the design spec under `docs/superpowers/`). Do not
  remove or rewrite that commit.

---

### Task 1: Create the GitHub repository and base repo scaffolding

**Files:**
- Create: `repository.yaml`
- Create: `LICENSE`
- Create: `.gitignore`
- Create: `README.md` (root — placeholder now, full content added in Task 5; must
  still be non-empty and valid since Task 1 pushes it)

**Interfaces:**
- Produces: a public GitHub repo at `https://github.com/floco/ha-addon-glance` with
  `main` as the default branch, and a local `origin` remote pointing at it. All later
  tasks push their commits there.
- Produces: `repository.yaml` with top-level key `name` (required by the HA app
  repository spec) — later tasks do not modify this file.

- [ ] **Step 1: Create the GitHub repository**

```bash
gh repo create floco/ha-addon-glance --public \
  --description "Home Assistant app: Glance, a self-hosted dashboard" \
  --source=/projects/glance_ha_app --remote=origin
```

Expected: command prints the new repo URL
`https://github.com/floco/ha-addon-glance` with no errors. This also wires the local
repo's `origin` remote — verify with `git remote -v`, expect a `floco/ha-addon-glance`
URL for both fetch and push.

- [ ] **Step 2: Write `repository.yaml`**

```yaml
# https://developers.home-assistant.io/docs/apps/repository#repository-configuration
name: Glance App Repository
url: "https://github.com/floco/ha-addon-glance"
maintainer: floco <info@mutualis.com>
```

- [ ] **Step 3: Write `LICENSE` (MIT, covers the packaging in this repo only)**

```
MIT License

Copyright (c) 2026 floco

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 4: Write `.gitignore`**

```
.DS_Store
*.swp
```

- [ ] **Step 5: Write a placeholder root `README.md`**

```markdown
# Glance — Home Assistant App Repository

Adds [Glance](https://github.com/glanceapp/glance) as an installable app for Home
Assistant OS / Supervised.

Full install instructions are being finalized — see [glance/](./glance) for the app
itself in the meantime.
```

(This gets fully rewritten in Task 5 — it exists now only so the repo isn't empty
between pushes.)

- [ ] **Step 6: Validate `repository.yaml` parses and has the required `name` key**

```bash
python3 -c "
import yaml
with open('repository.yaml') as f:
    data = yaml.safe_load(f)
assert isinstance(data, dict), 'repository.yaml did not parse to a mapping'
assert 'name' in data and data['name'], 'repository.yaml missing required name key'
print('repository.yaml OK:', data)
"
```

Expected: prints `repository.yaml OK: {...}` with no `AssertionError`.

- [ ] **Step 7: Commit and push**

```bash
cd /projects/glance_ha_app
git add repository.yaml LICENSE .gitignore README.md
git commit -m "Add base repo scaffolding for the Glance HA app repository"
git push -u origin main
```

- [ ] **Step 8: Verify the push landed and the repo is public**

```bash
gh repo view floco/ha-addon-glance --json visibility,url,defaultBranchRef \
  --jq '{visibility, url, branch: .defaultBranchRef.name}'
```

Expected: `{"visibility":"PUBLIC","url":"https://github.com/floco/ha-addon-glance","branch":"main"}`.

---

### Task 2: Write the app manifest (`glance/config.yaml`)

**Files:**
- Create: `glance/config.yaml`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: the HA app manifest that Task 3's `Dockerfile` is built against (slug
  `glance`, folder `glance/`) and that Task 6's structural checklist verifies. Later
  tasks must not rename the `glance` slug or folder.

- [ ] **Step 1: Create the `glance/` folder and write `config.yaml`**

```yaml
# https://developers.home-assistant.io/docs/apps/configuration#app-configuration
name: Glance
version: "0.8.5"
slug: glance
description: A self-hosted, fast, and highly customizable dashboard for all your feeds and widgets.
url: "https://github.com/floco/ha-addon-glance/tree/main/glance"
arch:
  - amd64
  - aarch64
  - armv7
startup: application
boot: auto
ports:
  8080/tcp: 8080
ports_description:
  8080/tcp: Glance web interface
webui: "http://[HOST]:[PORT:8080]/"
ingress: true
ingress_port: 8080
ingress_entry: /
map:
  - addon_config:rw
options: {}
schema: {}
```

- [ ] **Step 2: Validate `config.yaml` structurally**

```bash
python3 -c "
import yaml
with open('glance/config.yaml') as f:
    cfg = yaml.safe_load(f)

required_str_keys = ['name', 'version', 'slug', 'description', 'startup', 'boot']
for k in required_str_keys:
    assert isinstance(cfg.get(k), str) and cfg[k], f'{k} must be a non-empty string'

assert cfg['slug'] == 'glance', 'slug must match the glance/ folder name'
assert isinstance(cfg.get('arch'), list) and set(cfg['arch']) == {'amd64', 'aarch64', 'armv7'}, \
    'arch must list exactly amd64, aarch64, armv7'
assert cfg.get('ports') == {'8080/tcp': 8080}, 'ports must map 8080/tcp to host 8080'
assert cfg.get('ingress') is True, 'ingress must be enabled'
assert cfg.get('ingress_port') == 8080, 'ingress_port must match the container port'
assert cfg.get('map') == ['addon_config:rw'], 'map must request a writable addon_config volume'
assert 'image' not in cfg, 'image key must be absent so the Supervisor builds locally'
print('config.yaml OK:', cfg)
"
```

Expected: prints `config.yaml OK: {...}` with no `AssertionError`.

- [ ] **Step 3: Commit and push**

```bash
git add glance/config.yaml
git commit -m "Add Home Assistant app manifest for Glance"
git push
```

---

### Task 3: Dockerfile, entrypoint script, and starter config — build/run verified

**Files:**
- Create: `glance/Dockerfile`
- Create: `glance/entrypoint.sh`
- Create: `glance/glance.yml.starter`

**Interfaces:**
- Consumes: `glance/config.yaml`'s `slug: glance` (folder name) from Task 2 — no
  other dependency.
- Produces: a buildable image (local tag `ha-glance-app:test` used only for this
  task's verification, not pushed anywhere) that seeds `/config/glance.yml` from
  `/app/glance.yml.starter` on first run if absent, then serves Glance on `:8080`
  inside the container. Task 6's final checklist re-confirms this still builds after
  Tasks 4-5 add non-code files.

- [ ] **Step 1: Write the starter dashboard config**

```yaml
# glance/glance.yml.starter
# Seeded into /config/glance.yml on first start. Edit the copy in /config — this
# bundled file is never read again after the first boot. See:
# https://github.com/glanceapp/glance/blob/main/docs/configuration.md
pages:
  - name: Home
    columns:
      - size: small
        widgets:
          - type: clock
            hour-format: 24h
          - type: weather
            location: London, United Kingdom
            units: metric
      - size: full
        widgets:
          - type: rss
            limit: 10
            collapse-after: 3
            cache: 12h
            feeds:
              - url: https://www.home-assistant.io/atom.xml
                title: Home Assistant Blog
              - url: https://selfh.st/rss/
                title: selfh.st
      - size: small
        widgets:
          - type: bookmarks
            groups:
              - links:
                  - title: Home Assistant
                    url: http://homeassistant.local:8123
                  - title: Glance on GitHub
                    url: https://github.com/glanceapp/glance
```

- [ ] **Step 2: Write the entrypoint script**

```sh
#!/bin/sh
# glance/entrypoint.sh
set -e

CONFIG_FILE="/config/glance.yml"

mkdir -p /config

if [ ! -f "$CONFIG_FILE" ]; then
    echo "[glance] No config found at $CONFIG_FILE, seeding starter dashboard"
    cp /app/glance.yml.starter "$CONFIG_FILE"
fi

echo "[glance] Starting Glance with config $CONFIG_FILE"
exec /app/glance --config "$CONFIG_FILE"
```

- [ ] **Step 3: Make it executable and lint it**

```bash
chmod +x glance/entrypoint.sh
shellcheck glance/entrypoint.sh
```

Expected: `shellcheck` exits 0 with no output (no warnings/errors).

- [ ] **Step 4: Write the Dockerfile**

```dockerfile
# glance/Dockerfile
# https://developers.home-assistant.io/docs/apps/configuration#app-dockerfile
#
# Built FROM the official Glance image directly (its own alpine:3.22 final stage),
# not from a Home Assistant base image — so no s6-overlay/bashio are available here.
# First-boot config seeding + startup is handled by entrypoint.sh instead of the
# rootfs/etc/services.d s6 pattern used by apps built on HA base images.
FROM docker.io/glanceapp/glance:v0.8.5

ARG BUILD_VERSION
ARG BUILD_ARCH

COPY glance.yml.starter /app/glance.yml.starter
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

LABEL \
    io.hass.version="${BUILD_VERSION}" \
    io.hass.type="app" \
    io.hass.arch="${BUILD_ARCH}" \
    org.opencontainers.image.title="Glance" \
    org.opencontainers.image.description="A self-hosted, fast, and highly customizable dashboard for all your feeds and widgets." \
    org.opencontainers.image.source="https://github.com/glanceapp/glance" \
    org.opencontainers.image.licenses="MIT"

ENTRYPOINT ["/entrypoint.sh"]
```

- [ ] **Step 5: Build the image locally**

```bash
docker build \
  --build-arg BUILD_VERSION=0.8.5 \
  --build-arg BUILD_ARCH=amd64 \
  -t ha-glance-app:test \
  glance/
```

Expected: `Successfully tagged ha-glance-app:test` (or BuildKit's equivalent final
`naming to docker.io/library/ha-glance-app:test done` line), exit code 0.

- [ ] **Step 6: Run it with a mounted config volume mimicking the Supervisor's `addon_config` mount, and verify it serves Glance**

```bash
rm -rf /tmp/glance-addon-config-test && mkdir -p /tmp/glance-addon-config-test
docker run -d --rm \
  --name glance-addon-test \
  -p 18080:8080 \
  -v /tmp/glance-addon-config-test:/config \
  ha-glance-app:test

sleep 2
curl -sf http://localhost:18080/ | grep -qi "glance" && echo "HTTP CHECK OK"
docker logs glance-addon-test 2>&1 | grep -F "seeding starter dashboard"
test -f /tmp/glance-addon-config-test/glance.yml && echo "CONFIG SEEDED OK"
```

Expected: `HTTP CHECK OK`, a log line containing `seeding starter dashboard`, and
`CONFIG SEEDED OK`.

- [ ] **Step 7: Verify idempotency — a restart must not clobber user edits**

```bash
echo "# user edit marker" >> /tmp/glance-addon-config-test/glance.yml
docker restart glance-addon-test
sleep 2
grep -q "user edit marker" /tmp/glance-addon-config-test/glance.yml && echo "PRESERVED OK"
docker logs glance-addon-test 2>&1 | grep -c "seeding starter dashboard"
```

Expected: `PRESERVED OK`, and the seeding log line still appears exactly once (not
twice) across both starts.

- [ ] **Step 8: Clean up the test container**

```bash
docker stop glance-addon-test
rm -rf /tmp/glance-addon-config-test
```

- [ ] **Step 9: Commit and push**

```bash
git add glance/Dockerfile glance/entrypoint.sh glance/glance.yml.starter
git commit -m "Add Dockerfile, entrypoint, and starter dashboard for the Glance app"
git push
```

---

### Task 4: Icon and logo assets

**Files:**
- Create: `glance/icon.png`
- Create: `glance/logo.png`

**Interfaces:**
- Consumes: nothing.
- Produces: the two branding files the HA app store reads from `glance/` — Task 6's
  checklist confirms their presence and dimensions.

Generated locally (not downloaded — avoids any question about reuse rights to
Glance's own logo). Simple, original dashboard-grid motif: a dark rounded square with
four accent tiles.

- [ ] **Step 1: Generate the assets with Pillow**

```bash
python3 << 'EOF'
from PIL import Image, ImageDraw

BG = (30, 31, 41, 255)      # dark slate
ACCENT = (79, 209, 197, 255)  # teal

def rounded_tiles(size, margin_ratio=0.16, gap_ratio=0.08, corner_ratio=0.18):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    corner = int(size * corner_ratio)
    draw.rounded_rectangle([0, 0, size - 1, size - 1], radius=corner, fill=BG)

    margin = int(size * margin_ratio)
    gap = int(size * gap_ratio)
    tile = (size - 2 * margin - gap) // 2
    tile_corner = max(2, int(tile * 0.22))
    positions = [
        (margin, margin),
        (margin + tile + gap, margin),
        (margin, margin + tile + gap),
        (margin + tile + gap, margin + tile + gap),
    ]
    for x, y in positions:
        draw.rounded_rectangle(
            [x, y, x + tile, y + tile], radius=tile_corner, fill=ACCENT
        )
    return img

# icon.png: square, 128x128
icon = rounded_tiles(128)
icon.save("glance/icon.png")

# logo.png: 250x100, icon left-aligned + right padding transparent
logo = Image.new("RGBA", (250, 100), (0, 0, 0, 0))
icon_100 = rounded_tiles(100)
logo.paste(icon_100, (0, 0), icon_100)
logo.save("glance/logo.png")

print("icon.png:", icon.size, "logo.png:", logo.size)
EOF
```

Expected: prints `icon.png: (128, 128) logo.png: (250, 100)`.

- [ ] **Step 2: Verify dimensions and format on disk**

```bash
python3 -c "
from PIL import Image
icon = Image.open('glance/icon.png')
logo = Image.open('glance/logo.png')
assert icon.size == (128, 128), icon.size
assert icon.format == 'PNG'
assert logo.format == 'PNG'
assert logo.size[0] >= logo.size[1], 'logo should be wider than tall'
print('icon:', icon.size, icon.format, '| logo:', logo.size, logo.format)
"
```

Expected: `icon: (128, 128) PNG | logo: (250, 100) PNG` with no `AssertionError`.

- [ ] **Step 3: Commit and push**

```bash
git add glance/icon.png glance/logo.png
git commit -m "Add icon and logo assets for the Glance app"
git push
```

---

### Task 5: Documentation (root README, app README/DOCS/CHANGELOG)

**Files:**
- Modify: `README.md` (root — replace Task 1's placeholder)
- Create: `glance/README.md`
- Create: `glance/DOCS.md`
- Create: `glance/CHANGELOG.md`

**Interfaces:**
- Consumes: repo URL and slug from Tasks 1-2 (`floco/ha-addon-glance`, `glance`).
- Produces: the three docs files the HA app store surfaces (short description,
  Documentation tab, Changelog) plus the repo's landing README.

- [ ] **Step 1: Replace the root `README.md`**

```markdown
# Glance — Home Assistant App Repository

Adds [Glance](https://github.com/glanceapp/glance) — a fast, self-hosted, highly
customizable dashboard for feeds and widgets — as an installable Home Assistant app
(what HA called an "add-on" before its 2026 rename).

[![Open your Home Assistant instance and show the app store with this repository pre-filled.](https://my.home-assistant.io/badges/supervisor_store.svg)](https://my.home-assistant.io/redirect/supervisor_store/?repository_url=https%3A%2F%2Fgithub.com%2Ffloco%2Fha-addon-glance)

## Installation

1. Copy this repository's URL: `https://github.com/floco/ha-addon-glance`.
2. In Home Assistant, go to **Settings > Apps** and select **Install app**.
3. Open the three-dot menu (top right) and select **Repositories**.
4. Paste the URL and select **Add**.
5. Find **Glance** in the app store, install it, and start it.
6. Open it from the Home Assistant sidebar (Ingress), or at
   `http://homeassistant.local:8080` if you keep the direct port enabled.

See [glance/DOCS.md](./glance/DOCS.md) for configuration details, and
[glance/CHANGELOG.md](./glance/CHANGELOG.md) for the version history.

## Apps in this repository

### [Glance](./glance)

A self-hosted dashboard that puts all your feeds in one place. Runs the official
`glanceapp/glance` image unmodified, pinned to `v0.8.5`.

## License

The packaging in this repository is MIT-licensed (see [LICENSE](./LICENSE)). Glance
itself is licensed AGPL-3.0 by its authors — this repository runs their published
image unmodified and does not redistribute modified source.
```

- [ ] **Step 2: Write `glance/README.md` (short — this is what the app store list
  view shows)**

```markdown
# Home Assistant App: Glance

_A self-hosted, fast, and highly customizable dashboard for all your feeds and widgets._

![Supports aarch64 Architecture][aarch64-shield]
![Supports amd64 Architecture][amd64-shield]
![Supports armv7 Architecture][armv7-shield]

Runs the official [Glance](https://github.com/glanceapp/glance) `v0.8.5` image.
Configuration lives entirely in your own `glance.yml` — see [DOCS.md](./DOCS.md).

[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg
```

- [ ] **Step 3: Write `glance/DOCS.md`**

```markdown
# Home Assistant App: Glance

## What this is

This app runs the official [Glance](https://github.com/glanceapp/glance) Docker
image (currently pinned to `v0.8.5`) unmodified, and wires it into Home Assistant's
app system: persistent configuration storage, an optional sidebar entry via Ingress,
and an optional direct port.

## First start

On first start, if no `glance.yml` exists yet, a small starter dashboard (clock,
weather, a couple of RSS feeds, and some bookmarks) is copied into place so you don't
land on a blank page. Edit it to make it yours — see "Editing your configuration"
below.

## Editing your configuration

Your config lives at `/addon_configs/<repo>_glance/glance.yml` on the Home Assistant
host (the exact `<repo>` prefix depends on how you added this repository). The
easiest way to edit it:

1. Install the **Studio Code Server** or **File editor** app from the official Home
   Assistant app store, if you don't already have one.
2. Open the folder containing `glance.yml` (its name will contain "glance").
3. Edit it following [Glance's own configuration reference](
   https://github.com/glanceapp/glance/blob/main/docs/configuration.md) — pages,
   columns, and widgets are all documented there.
4. Restart the **Glance** app from **Settings > Apps > Glance > Restart** to apply
   changes.

Your edits are never overwritten — the starter file is only copied in when
`glance.yml` doesn't exist yet.

## Accessing Glance

- **Sidebar (Ingress):** enabled by default — a "Glance" entry appears in the Home
  Assistant sidebar, proxied through Home Assistant's own authentication.
- **Direct port:** also enabled by default, mapped to `8080` — reachable at
  `http://homeassistant.local:8080` (or your host's address). Useful for kiosks or
  devices that shouldn't need a Home Assistant login, or for access outside Home
  Assistant entirely. Disable it in the app's **Network** tab if you only want
  Ingress.

### A note on Ingress compatibility

Home Assistant's Ingress proxy strips its own URL prefix before forwarding requests
to the app, so most apps that use root-relative paths work under Ingress with no
extra configuration — which is how this app is set up (no `server.base-url` is
configured). This hasn't been validated against every part of Glance's UI. If you
see broken images/styles or a blank page under the sidebar entry, but Glance works
fine on the direct port, please open an issue on this repository; the fallback is to
turn Ingress off in the **Network** tab and use the direct port only.

## Updating

This app is pinned to a specific Glance release (see `CHANGELOG.md`). New Glance
versions are picked up deliberately — check this repository's releases and update
the app the same way you'd update any other Home Assistant app.

## Support

Bugs in the packaging (this app) → open an issue on
[floco/ha-addon-glance](https://github.com/floco/ha-addon-glance/issues).
Bugs in Glance itself, or configuration questions about widgets/pages/themes →
[glanceapp/glance](https://github.com/glanceapp/glance).

## License

This app's packaging is MIT-licensed (see the repository's `LICENSE`). Glance itself
is licensed AGPL-3.0 by its authors; this app runs the official published image
unmodified and does not redistribute modified source.
```

- [ ] **Step 4: Write `glance/CHANGELOG.md`**

```markdown
<!-- https://developers.home-assistant.io/docs/apps/presentation#keeping-a-changelog -->
## 0.8.5

- Initial release. Packages Glance `v0.8.5`.
```

- [ ] **Step 5: Sanity-check required sections exist**

```bash
grep -q "## Installation" README.md && echo "root README OK"
grep -q "Supports amd64 Architecture" glance/README.md && echo "app README OK"
grep -q "## Editing your configuration" glance/DOCS.md && echo "DOCS OK"
grep -q "^## 0.8.5" glance/CHANGELOG.md && echo "CHANGELOG OK"
```

Expected: all four `OK` lines print.

- [ ] **Step 6: Commit and push**

```bash
git add README.md glance/README.md glance/DOCS.md glance/CHANGELOG.md
git commit -m "Add Home Assistant app store documentation for Glance"
git push
```

---

### Task 6: Final structural checklist, repo metadata, and release tag

**Files:** none created — verification, GitHub repo metadata, and a release only.

**Interfaces:**
- Consumes: every file produced by Tasks 1-5.
- Produces: repo topics/description on GitHub, and a `v0.8.5` git tag + GitHub
  release marking the first installable version.

- [ ] **Step 1: Rebuild the final image end-to-end (all files present, not just
  Task 3's subset) and re-run the smoke test**

```bash
docker build \
  --build-arg BUILD_VERSION=0.8.5 \
  --build-arg BUILD_ARCH=amd64 \
  -t ha-glance-app:final \
  glance/

rm -rf /tmp/glance-addon-final && mkdir -p /tmp/glance-addon-final
docker run -d --rm \
  --name glance-addon-final \
  -p 18081:8080 \
  -v /tmp/glance-addon-final:/config \
  ha-glance-app:final

sleep 2
curl -sf http://localhost:18081/ | grep -qi "glance" && echo "FINAL HTTP CHECK OK"
docker stop glance-addon-final
rm -rf /tmp/glance-addon-final
docker rmi ha-glance-app:final ha-glance-app:test
```

Expected: `FINAL HTTP CHECK OK`.

- [ ] **Step 2: Verify the full repo file structure matches the design**

```bash
python3 -c "
import os

required = [
    'repository.yaml', 'README.md', 'LICENSE', '.gitignore',
    'glance/config.yaml', 'glance/Dockerfile', 'glance/entrypoint.sh',
    'glance/glance.yml.starter', 'glance/icon.png', 'glance/logo.png',
    'glance/README.md', 'glance/DOCS.md', 'glance/CHANGELOG.md',
    'docs/superpowers/specs/2026-08-10-glance-ha-addon-design.md',
    'docs/superpowers/plans/2026-08-10-glance-ha-addon.md',
]
missing = [p for p in required if not os.path.isfile(p)]
assert not missing, f'Missing files: {missing}'
print(f'All {len(required)} expected files present.')
"
```

Expected: `All 15 expected files present.`

- [ ] **Step 3: Set repo description and topics**

```bash
gh repo edit floco/ha-addon-glance \
  --description "Home Assistant app: Glance, a self-hosted dashboard for feeds and widgets" \
  --homepage "https://github.com/glanceapp/glance" \
  --add-topic home-assistant \
  --add-topic home-assistant-addon \
  --add-topic glance \
  --add-topic hassio
```

Expected: exits 0.

- [ ] **Step 4: Tag and release `v0.8.5`**

```bash
git tag -a v0.8.5 -m "Initial release: packages Glance v0.8.5"
git push origin v0.8.5

gh release create v0.8.5 \
  --title "v0.8.5 — initial release" \
  --notes "Packages Glance v0.8.5 as a Home Assistant app. See glance/DOCS.md for install/config instructions."
```

Expected: `gh release create` prints the release URL
`https://github.com/floco/ha-addon-glance/releases/tag/v0.8.5`.

- [ ] **Step 5: Final verification**

```bash
git status --short
gh repo view floco/ha-addon-glance --json visibility,url,description,repositoryTopics \
  --jq '{visibility, url, description, topics: [.repositoryTopics.nodes[].topic.name]}'
```

Expected: `git status --short` prints nothing (clean tree, everything pushed); the
`gh repo view` output shows `"visibility":"PUBLIC"` and the topics set in Step 3.

---

## Known limitation carried into the shipped repo

Ingress compatibility (Task 3/6's smoke tests only exercise the direct port, since
there's no real Home Assistant Supervisor available in this environment to test
Ingress against) is documented as best-effort in `glance/DOCS.md`, per the design
spec's risk callout. If the user installs this on real HA OS/Supervised hardware and
finds Ingress broken, the documented fallback (disable Ingress, use the direct port)
already exists — no plan changes needed for that outcome, just a possible follow-up
bug/PR against this repo.
