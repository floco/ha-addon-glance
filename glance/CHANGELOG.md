<!-- https://developers.home-assistant.io/docs/apps/presentation#keeping-a-changelog -->
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
