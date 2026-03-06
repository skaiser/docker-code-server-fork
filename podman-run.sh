#!/bin/sh

podman run -d --replace --name coder-server \
	    --secret .ssh_id_ed25519,mode=600,target=/config/.ssh/id_ed25519 \
	    --secret .ssh_id_ed25519.pub,target=/config/.ssh/id_ed25519.pub \
	    -e DOCKER_MODS='linuxserver/mods:code-server-nvm|linuxserver/mods:code-server-pnpm|linuxserver/mods:code-server-golang|linuxserver/mods:code-server-rust|linuxserver/mods:code-server-zsh|linuxserver/mods:code-server-python3|linuxserver/mods:code-server-npmglobal|linuxserver/mods:code-server-extension-arguments' \
	    -e VSCODE_EXTENSION_IDS='vscode-icons-team.vscode-icons|ms-azuretools.vscode-docker' \
	    -e PASSWORD=password \
	    -e SUDO_PASSWORD=password \
	    -e DEFAULT_WORKSPACE=/config/workspace \
	    -e PWA_APPNAME=code-server \
	    -p 8443:8443 \
	    -p 8300:3000 \
	    -p 6080:6080 \
	    -p 8787:8787 \
	    -p 8976:8976 \
	    -v $HOME/code/code-server-workspace:/config/workspace \
            code-server-vnc
	    #lscr.io/linuxserver/code-server:latest
