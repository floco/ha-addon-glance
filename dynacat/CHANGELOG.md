<!-- https://developers.home-assistant.io/docs/apps/presentation#keeping-a-changelog -->
## 3.0.0-1

- Upgrade packaged Dynacat from `2.4.0` to `3.0.0`. No changes were needed to
  `entrypoint.sh` or `dynacat.yml.starter` — the Dockerfile, config file location,
  `--config` flag, and the `clock`/`weather`/`rss`/`bookmarks` widgets used by the
  starter dashboard are all unchanged between the two versions.
- Note: `3.0.0` adds a built-in web UI editor that writes directly to `dynacat.yml`,
  enabled by default (`server.allow-editing: true`). Left on at Dynacat's default —
  Dynacat has no concept of Home Assistant users, so it can't scope the editor to
  admins on its own.
- Set `panel_admin: true` so the whole sidebar (Ingress) app, viewing and editing
  alike, is restricted to Home Assistant admin accounts, enforced by Supervisor.
  Non-admin users no longer see the "Dynacat" sidebar entry. Does not affect the
  direct port, which already bypasses Home Assistant authentication entirely — see
  DOCS.md.

## 2.4.0-2

- Set `panel_icon: mdi:cat` so the Home Assistant sidebar entry shows a cat icon
  matching Dynacat's branding, instead of the default `mdi:puzzle`.

## 2.4.0-1

- Replace Glance with [Dynacat](https://github.com/Panonim/dynacat) `2.4.0`, a fork
  of Glance focused on dynamic reloading and easy integration with external
  applications. This app's slug changes from `glance` to `dynacat`, so Home
  Assistant treats it as a new app install rather than an in-place upgrade — your
  old Glance app and its `glance.yml` are untouched; a fresh `dynacat.yml` starter
  dashboard is seeded on Dynacat's first start. Config filename changes from
  `glance.yml` to `dynacat.yml` and the binary from `glance` to `dynacat`, but the
  `server.base-url` mechanism and `access_mode` option work identically — Dynacat
  kept the same `${VAR}` config substitution and `server.base-url` setting Glance
  has. All entries below this one describe the packaging history while this app
  still ran Glance.

## 0.8.5-4

- Fix Ingress loading an empty/unstyled page even after `v0.8.5-3`'s redirect fix.
  Root cause: Glance references its CSS/JS/asset URLs with absolute paths
  (`/static/...`) and has no ingress-awareness of its own (doesn't read
  `X-Ingress-Path`/`X-Forwarded-Prefix`), so those requests escaped the
  ingress-prefixed path entirely once the redirect bug was no longer masking it.
  Glance does support a `server.base-url` setting for exactly this, but it's a
  single static value — it can't be simultaneously correct for both Ingress and
  the direct port, since Glance can't detect its access path per-request.
  Added a new `access_mode` app option (`ingress` default, or `direct`);
  `entrypoint.sh` now asks Supervisor for this installation's Ingress path (via
  `GET /apps/self/info` using the app's own Supervisor token — no extra
  permissions required) and passes it to Glance as `server.base-url` when
  `access_mode: ingress`, or leaves it empty for `access_mode: direct`. Whichever
  mode isn't active will show a broken/empty page — see DOCS.md. Existing
  `/config/glance.yml` files (from before this fix) are migrated in place on next
  start to add the required `server:` block, without touching anything else in
  the file.

## 0.8.5-3

- Fix the actual Ingress bug: remove the explicit `ingress_entry: /` key.
  Supervisor only concatenates `ingress_entry` onto the ingress base URL
  (`/api/hassio_ingress/<token>/`) when the key is *present at all* in
  config.yaml — it doesn't matter that `/` is the documented default when
  the key is absent. With the key present, the request path ended in a
  doubled slash (`.../<token>//`), which triggered Glance's own
  double-slash-canonicalization redirect (`307` to `/`, a *relative*
  Location header). Under Ingress, the browser resolves that relative
  redirect against Home Assistant's own origin, not the ingress-prefixed
  path — landing back on the HA dashboard instead of Glance. Confirmed by
  reading Supervisor's `ingress_url` property directly (`apps/app.py`) and
  reproducing the redirect locally. `v0.8.5-2`'s `ports`/`init` change was a
  real improvement worth keeping, but did not address this.

## 0.8.5-2

- Fix Ingress not routing to the container. `ports: 8080/tcp` was published
  unconditionally on the same container port Ingress targets; changed it to
  `null` (opt-in via the app's Network tab instead) and added `init: false`,
  matching the pattern used by established Ingress add-ons (e.g.
  hassio-addons/addon-grafana). The direct port is now off by default — see
  DOCS.md to enable it.

## 0.8.5-1

- Drop `armv7` from `arch` — 32-bit ARM is deprecated by Home Assistant Supervisor
  (only `aarch64`/`amd64` machines are current); this removed a Supervisor
  deprecation warning on every restart. Still packages Glance `v0.8.5` (unchanged).

## 0.8.5

- Initial release. Packages Glance `v0.8.5`.
