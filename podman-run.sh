#!/bin/sh

podman run -d --name coder-server-vnc \
	    --cpus 2 \
	    --shm-size '1024m' \
	    --secret .ssh_id_ed25519,mode=600,target=/config/.ssh/id_ed25519 \
	    --secret .ssh_id_ed25519.pub,target=/config/.ssh/id_ed25519.pub \
	    -e DOCKER_MODS='linuxserver/mods:code-server-nvm|linuxserver/mods:code-server-pnpm|linuxserver/mods:code-server-golang|linuxserver/mods:code-server-rust|linuxserver/mods:code-server-zsh|linuxserver/mods:code-server-python3|linuxserver/mods:code-server-npmglobal|linuxserver/mods:code-server-extension-arguments' \
	    -e VSCODE_EXTENSION_IDS='vscode-icons-team.vscode-icons|ms-azuretools.vscode-docker' \
	    -e PASSWORD=password \
	    -e SUDO_PASSWORD=password \
	    -e DEFAULT_WORKSPACE=/config/workspace \
	    -e PWA_APPNAME=code-server-vnc \
	    -p 127.0.0.1:8443:8443 \
	    -p 127.0.0.1:6080:6080 \
	    -v $HOME/code/code-server-workspace:/config/workspace \
	    code-server-vnc
	    #lscr.io/linuxserver/code-server:latest
