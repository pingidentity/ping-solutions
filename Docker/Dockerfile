FROM alpine:3.7

ENV BUILD_PACKAGES \
  git \
  python \
  py-boto \
  py-dateutil \
  py-httplib2 \
  py-jinja2 \
  py-paramiko \
  py-pip \
  py-yaml \
  ca-certificates

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
      git \
      python-dev && \
    \
    echo "==> Upgrading apk and system..."  && \
    apk update && apk upgrade && \
    \
    echo "==> Adding Python runtime..."  && \
    apk add --no-cache ${BUILD_PACKAGES} && \
    pip install --upgrade pip && \
    pip install python-keyczar docker-py && \
    \
    echo "==> Installing Ansible..."  && \
    pip install ansible && \
    \
    echo "==> Cleaning up..."  && \
    apk del build-dependencies && \
    rm -rf /var/cache/apk/* && \
    \
    echo "==> Adding hosts for convenience..."  && \
    mkdir -p /etc/ansible /ansible && \
    echo "[local]" >> /etc/ansible/hosts && \
    echo "localhost" >> /etc/ansible/hosts

# Set user and group
ENV USER=ansibleuser
ENV group=ansiblegroup
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

COPY ./resources/entrypoint.sh /ansible/entrypoint.sh

ENV ANSIBLE_RETRY_FILES_ENABLED false
ENV PYTHONPATH /ansible/lib
ENV PATH /ansible/bin:$PATH
ENV ANSIBLE_LIBRARY /ansible/library

WORKDIR /ansible/playbooks

ENTRYPOINT /ansible/entrypoint.sh