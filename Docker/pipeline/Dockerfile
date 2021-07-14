#initially pdsolutions/ansible_dev
FROM bash:5.1.8

# If installing ansible@testing
#RUN \
#	echo "@testing http://nl.alpinelinux.org/alpine/edge/testing" >> #/etc/apk/repositories

RUN set -x && \
    \
    echo "==> Adding build-dependencies..."  && \
    apk --update add --virtual build-dependencies \
      gcc \
      musl-dev \
      libffi-dev \
      openssl-dev \
      git && \
    \
    echo "==> Upgrading apk and system..."  && \
    apk update && apk upgrade && \
    \
    echo "==> Installing curl and jq" && \
    apk add --no-cache curl jq && \
    echo "==> Cleaning up..."  && \
    apk del build-dependencies && \
    rm -rf /var/cache/apk/*

# Set user and group
ENV USER=pipelineuser
ENV group=pipelinegroup
ENV UID=1337
ENV GID=1337
RUN addgroup -g ${GID} ${group}
RUN adduser \
    -D \
    -g "" \
    -u "$UID" \
    -G "$group" \
    "$USER"

# Switch to user
USER ${UID}:${GID}
