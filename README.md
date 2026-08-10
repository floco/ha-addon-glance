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
