# Home Assistant App: Dynacat

## What this is

This app runs the official [Dynacat](https://github.com/Panonim/dynacat) Docker
image (currently pinned to `2.4.0`) unmodified, and wires it into Home Assistant's
app system: persistent configuration storage, an optional sidebar entry via Ingress,
and an optional direct port. Dynacat is a fork of
[Glance](https://github.com/glanceapp/glance) focused on dynamic reloading and easy
integration with external applications.

## First start

On first start, if no `dynacat.yml` exists yet, a small starter dashboard (clock,
weather, a couple of RSS feeds, and some bookmarks) is copied into place so you don't
land on a blank page. Edit it to make it yours — see "Editing your configuration"
below.

## Editing your configuration

Your config lives at `/addon_configs/<repo>_dynacat/dynacat.yml` on the Home
Assistant host (the exact `<repo>` prefix depends on how you added this repository).
The easiest way to edit it:

1. Install the **Studio Code Server** or **File editor** app from the official Home
   Assistant app store, if you don't already have one.
2. Open the folder containing `dynacat.yml` (its name will contain "dynacat").
3. Edit it following [Dynacat's own configuration reference](
   https://dynacat.artur.zone/configuration) — pages, columns, and widgets are all
   documented there.
4. Restart the **Dynacat** app from **Settings > Apps > Dynacat > Restart** to apply
   changes.

Your edits are never overwritten — the starter file is only copied in when
`dynacat.yml` doesn't exist yet.

## Accessing Dynacat

- **Sidebar (Ingress):** enabled by default — a "Dynacat" entry appears in the Home
  Assistant sidebar, proxied through Home Assistant's own authentication.
- **Direct port:** off by default (not published), so it doesn't compete with
  Ingress on the container's port. To enable it, go to the app's **Network** tab and
  set a host port for `8080/tcp`, then restart the app — it becomes reachable at
  `http://homeassistant.local:<port>` (or your host's address). **Dynacat has no
  login of its own**, and this port bypasses Home Assistant's authentication
  entirely — it is only as safe as your local network. Only enable it for
  kiosks/devices that shouldn't need a Home Assistant login *and* are on a trusted
  network. If you're going to expose it beyond your LAN (e.g. via port forwarding or
  a reverse proxy), put an authenticating proxy in front of it yourself.

### `access_mode`: Ingress and the direct port can't both fully work at once

Dynacat renders its pages and fetches widget data through a single configured
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
and passes it to Dynacat as `server.base-url`, or leaves it empty for `direct` mode.

### Search widget: some search engines show a black screen under Ingress

If you add a `search` widget and search, the sidebar panel can go blank/black when
the results come back — this happens with Google specifically, not with the
default DuckDuckGo engine.

The search widget's `new-tab` option defaults to `false`, so a plain search
navigates the *current frame* to the results page (`window.location.href`). Under
Ingress, that current frame is the `<iframe>` Home Assistant renders the sidebar
panel in. Google's search results send anti-framing headers
(`X-Frame-Options`/CSP `frame-ancestors`) that block browsers from rendering them
inside someone else's iframe, so the panel just goes blank. DuckDuckGo doesn't send
those headers, which is why it works by default and Google doesn't. (This is a
site-specific behavior, not a Dynacat or packaging bug — it also wouldn't happen
under `access_mode: direct`, since there's no iframe there.)

Fix it in your `dynacat.yml` by opening results in a real new tab instead, which
escapes the iframe entirely:

```yaml
- type: search
  search-engine: google
  new-tab: true
```

## Updating

This app is pinned to a specific Dynacat release (see `CHANGELOG.md`). New Dynacat
versions are picked up deliberately — check this repository's releases and update
the app the same way you'd update any other Home Assistant app.

## Support

Bugs in the packaging (this app) → open an issue on
[floco/ha-addon-glance](https://github.com/floco/ha-addon-glance/issues).
Bugs in Dynacat itself, or configuration questions about widgets/pages/themes →
[Panonim/dynacat](https://github.com/Panonim/dynacat).

## License

This app's packaging is MIT-licensed (see the repository's `LICENSE`). Dynacat
itself is licensed AGPL-3.0 by its authors; this app runs the official published
image unmodified and does not redistribute modified source.
