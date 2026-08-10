<!-- https://developers.home-assistant.io/docs/apps/presentation#keeping-a-changelog -->
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
