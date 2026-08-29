# dynacat/Dockerfile
# https://developers.home-assistant.io/docs/apps/configuration#app-dockerfile
#
# Built FROM the official Dynacat image directly (its own alpine:3.21 final stage),
# not from a Home Assistant base image — so no s6-overlay/bashio are available here.
# First-boot config seeding + startup is handled by entrypoint.sh instead of the
# rootfs/etc/services.d s6 pattern used by apps built on HA base images.
FROM ghcr.io/panonim/dynacat:2.4.0

ARG BUILD_VERSION
ARG BUILD_ARCH

COPY dynacat.yml.starter /app/dynacat.yml.starter
COPY --chmod=755 entrypoint.sh /entrypoint.sh

LABEL \
    io.hass.version="${BUILD_VERSION}" \
    io.hass.type="app" \
    io.hass.arch="${BUILD_ARCH}" \
    org.opencontainers.image.title="Dynacat" \
    org.opencontainers.image.description="A self-hosted dashboard focused on dynamic reloading and easy integration with external applications, forked from Glance." \
    org.opencontainers.image.source="https://github.com/Panonim/dynacat" \
    org.opencontainers.image.licenses="AGPL-3.0"

ENTRYPOINT ["/entrypoint.sh"]
