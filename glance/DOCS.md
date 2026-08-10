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
- **Direct port:** off by default (not published), so it doesn't compete with
  Ingress on the container's port. To enable it, go to the app's **Network** tab and
  set a host port for `8080/tcp`, then restart the app — it becomes reachable at
  `http://homeassistant.local:<port>` (or your host's address). **Glance has no
  login of its own**, and this port bypasses Home Assistant's authentication
  entirely — it is only as safe as your local network. Only enable it for
  kiosks/devices that shouldn't need a Home Assistant login *and* are on a trusted
  network. If you're going to expose it beyond your LAN (e.g. via port forwarding or
  a reverse proxy), put an authenticating proxy in front of it yourself.

### `access_mode`: Ingress and the direct port can't both fully work at once

Glance renders its pages and fetches widget data through a single configured
"base URL," and it has no way to detect a reverse-proxy prefix per-request. That
prefix is different depending on how you reach it (nothing under Ingress, vs.
`/api/hassio_ingress/<token>` under Ingress) — so only *one* access method can be
fully correct at a time. The other will load an empty/unstyled page (not just
missing styling — its widgets won't fetch data either).

The `access_mode` option (in the app's **Configuration** tab) picks which one:

- **`ingress`** (default): the sidebar entry works correctly. The direct port, if
  you've also enabled it, will show a broken/empty page.
- **`direct`**: the direct port works correctly. The sidebar entry will show a
  broken/empty page.

Change it, save, and **restart the app** for it to take effect. Under the hood,
`entrypoint.sh` asks Home Assistant's Supervisor for this installation's Ingress
path (via the standard per-app Supervisor API token — no extra permissions needed)
and passes it to Glance as `server.base-url`, or leaves it empty for `direct` mode.

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
