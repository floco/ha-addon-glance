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
COPY --chmod=755 entrypoint.sh /entrypoint.sh

LABEL \
    io.hass.version="${BUILD_VERSION}" \
    io.hass.type="app" \
    io.hass.arch="${BUILD_ARCH}" \
    org.opencontainers.image.title="Glance" \
    org.opencontainers.image.description="A self-hosted, fast, and highly customizable dashboard for all your feeds and widgets." \
    org.opencontainers.image.source="https://github.com/glanceapp/glance" \
    org.opencontainers.image.licenses="MIT"

ENTRYPOINT ["/entrypoint.sh"]
