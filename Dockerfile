
# syntax=docker/dockerfile:1

ARG MAGPIE_IMAGE=ghcr.io/yetone/magpie:daily
ARG BUN_IMAGE=oven/bun:1

# 官方二进制来源
FROM ${MAGPIE_IMAGE} AS magpie-upstream

# Bun 官方二进制来源
FROM ${BUN_IMAGE} AS bun-upstream

# Debian 12 运行环境
FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates \
       curl \
       bash \
       tmux \
       unzip \
       libatomic1 \
       libgcc-s1 \
       libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

# 保持与 Magpie 官方镜像相同的 UID/GID
RUN groupadd -g 65532 nonroot \
    && useradd -u 65532 -g 65532 \
       -d /config/home -s /bin/bash -M nonroot \
    && mkdir -p \
       /config/home \
       /config/cache \
       /config/data \
       /config/state \
    && chown -R 65532:65532 /config

# 复制 Magpie
COPY --from=magpie-upstream /magpie /magpie

# 复制 Bun
COPY --from=bun-upstream \
     /usr/local/bin/bun /usr/local/bin/bun

RUN ln -s /magpie /usr/local/bin/magpie \
    && ln -s /usr/local/bin/bun /usr/local/bin/bunx \
    && bun --version \
    && tmux -V

# Magpie 官方环境变量
ENV HOME=/config/home \
    XDG_CONFIG_HOME=/config \
    XDG_CACHE_HOME=/config/cache \
    XDG_DATA_HOME=/config/data \
    XDG_STATE_HOME=/config/state \
    MAGPIE_ADDR=0.0.0.0:3425 \
    PATH=/config/home/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

WORKDIR /config/home

USER 65532:65532

VOLUME /config

EXPOSE 3425 3430

HEALTHCHECK --interval=30s --timeout=5s \
    --start-period=10s --retries=3 \
    CMD ["/magpie", "healthcheck"]

ENTRYPOINT ["/magpie"]

CMD ["serve"]
