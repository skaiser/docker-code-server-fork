# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-ubuntu:noble

# set version label
ARG BUILD_DATE
ARG VERSION
ARG CODE_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="aptalca"

# environment settings
ARG DEBIAN_FRONTEND="noninteractive"
ENV HOME="/config"

RUN \
  echo "**** install runtime dependencies ****" && \
  apt-get update && \
  apt-get install -y \
    git \
    libatomic1 \
    nano \
    net-tools \
    xvfb \
    x11vnc \
    novnc \
    fluxbox \
    websockify \
    software-properties-common \
    wireguard-tools \
    sudo && \
  echo "**** install code-server ****" && \
  if [ -z ${CODE_RELEASE+x} ]; then \
    CODE_RELEASE=$(curl -sX GET https://api.github.com/repos/coder/code-server/releases/latest \
      | awk '/tag_name/{print $4;exit}' FS='[""]' | sed 's|^v||'); \
  fi && \
  mkdir -p /app/code-server && \
  curl -o \
    /tmp/code-server.tar.gz -L \
    "https://github.com/coder/code-server/releases/download/v${CODE_RELEASE}/code-server-${CODE_RELEASE}-linux-amd64.tar.gz" && \
  tar xf /tmp/code-server.tar.gz -C \
    /app/code-server --strip-components=1 && \
  printf "Linuxserver.io version: ${VERSION}\nBuild-date: ${BUILD_DATE}" > /build_version && \
  echo "**** clean up ****" && \
  apt-get clean && \
  rm -rf \
    /config/* \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*
 
# Install Firefox and Chromium (not snaps)
# https://linuxvox.com/blog/ubuntu-install-firefox-without-snap/
# https://officialaptivi.wordpress.com/2025/06/14/installing-chromium-on-ubuntu-without-snap/
RUN add-apt-repository ppa:mozillateam/ppa
RUN add-apt-repository ppa:xtradeb/apps
# Enable package pinning
RUN printf '%s\n' \
      'Package: *' \
      'Pin: release o=LP-PPA-mozillateam' \
      'Pin-priority: 1001' \
      > /etc/apt/preferences.d/mozillateamppa
RUN printf '%s\n' \
      'Package: *' \
      'Pin: release o=LP-PPA-xtradeb' \
      'Pin-priority: 1001' \
      > /etc/apt/preferences.d/xtradebppa
RUN \
  echo "**** installing Firefox and Chromium ****" && \
  apt-get update && \
  apt-get install -y \
    firefox \
    chromium && \
    apt-get clean && \
    rm -rf \
      /config/* \
      /tmp/* \
      /var/lib/apt/lists/* \
      /var/tmp/*
# Install latest chrome dev package and fonts to support major charsets (Chinese, Japanese, Arabic, Hebrew, Thai and a few others)
# Note: this installs the necessary libs to make the bundled version of Chrome for Testing that Puppeteer
# installs, work.
# https://pptr.dev/troubleshooting#running-puppeteer-in-docker
# This is used by playwright/puppeteer in Cloudflare Workers
RUN apt-get update \
    && apt-get install -y wget gnupg \
    && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
    && apt-get update \
    && apt-get install -y google-chrome-stable fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst fonts-freefont-ttf libxss1 \
      --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Xvfb starter (optional)
RUN printf '%s\n' \
      '#!/bin/sh' \
      'set -e' \
      'export DISPLAY=:99' \
      'mkdir -p /config/.vnc' \
      'sudo -u abc sh -c "/usr/bin/Xvfb :99 -screen 0 1920x1080x24 -ac -nolisten tcp -nolisten unix +extension RANDR > /config/.vnc/xvfb.log 2>&1 & echo \\$! > /config/.vnc/xvfb.pid" ' \
      'echo "Xvfb started on DISPLAY=:99 (pid $(sudo cat /config/.vnc/xvfb.pid))"' \
      > /usr/local/bin/start-xvfb.sh \
      && chmod +x /usr/local/bin/start-xvfb.sh

# VNC starter (noVNC on :6080)
# WRONG: Access with http://localhost:6080/vnc.html?host=localhost&port=6080&autoconnect=1
# Access with http://localhost:6080/vnc.html
RUN printf '%s\n' \
      '#!/bin/sh' \
      'set -e' \
      'export DISPLAY=:99' \
      'sudo -u abc sh -lc "fluxbox -display :99 > /config/.vnc/fluxbox.log 2>&1 &"' \
      'sudo -u abc sh -lc "x11vnc -display :99 -forever -shared -nopw -rfbport 5901 > /config/.vnc/x11vnc.log 2>&1 &"' \
      'sudo -u abc sh -lc "websockify --web=/usr/share/novnc/ 6080 localhost:5901 > /config/.vnc/novnc.log 2>&1 &"' \
      'echo "noVNC available on http://localhost:6080"' \
      > /usr/local/bin/start-vnc.sh \
      && chmod +x /usr/local/bin/start-vnc.sh

# To start Firefox or Chromium in VNC
RUN printf '%s\n' \
      '#!/bin/sh' \
      'set -e' \
      'export DISPLAY=:99 && firefox -display :99 &' \
      > /usr/local/bin/start-firefox-in-vnc.sh \
      && chmod +x /usr/local/bin/start-firefox-in-vnc.sh

RUN printf '%s\n' \
      '#!/bin/sh' \
      'set -e' \
      'export DISPLAY=:99 && chromium -display :99 &' \
      > /usr/local/bin/start-chromium-in-vnc.sh \
      && chmod +x /usr/local/bin/start-chromium-in-vnc.sh

# /config/.config/code-server/config.yaml
# install VS Code extensions
RUN /app/code-server/bin/code-server --extensions-dir /config/extensions \
      --install-extension redhat.vscode-yaml \
      --install-extension ms-python.python \
      --install-extension Vue.volar \
      --install-extension esbenp.prettier-vscode \
      --install-extension yoavbls.pretty-ts-errors \
      --install-extension aaron-bond.better-comments \
      --install-extension afterxleep.chromabar \
      --install-extension golang.go \
      --install-extension Davejavu4u.tabs-in-focus \
      --install-extension daveWasTaken.gitworkspace \
      --install-extension ms-playwright.playwright \
      #      --install-extension lennardv.set-window-color-name \
      --install-extension cosmicsarthak.cosmicsarthak-neon-theme \
      --install-extension 3xpo.midnight-codium \
      --install-extension goodfoot.compare-branch
      #      --install-extension solomonkinard.git-blame
#RUN /usr/local/bin/install-extension ms-playwright.playwright
  #
#RUN sed -i 's/cert: false/cert: true/' /config/.config/code-server/config.yaml
#TODO: here install git configs

# add local files
COPY /root /

# ports and volumes
EXPOSE 8443
EXPOSE 8300
EXPOSE 8320
# VNC
EXPOSE 6080
# Wrangler
EXPOSE 8787
EXPOSE 8976
