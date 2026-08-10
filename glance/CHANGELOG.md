<!-- https://developers.home-assistant.io/docs/apps/presentation#keeping-a-changelog -->
## 0.8.5-1

- Drop `armv7` from `arch` — 32-bit ARM is deprecated by Home Assistant Supervisor
  (only `aarch64`/`amd64` machines are current); this removed a Supervisor
  deprecation warning on every restart. Still packages Glance `v0.8.5` (unchanged).

## 0.8.5

- Initial release. Packages Glance `v0.8.5`.
