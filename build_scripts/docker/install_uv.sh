#!/bin/bash

# Install uv - fast Python package installer and resolver
# Documentation: https://docs.astral.sh/uv/

build_setup=$1
if [[ "$build_setup" == "" ]] ; then echo "specify setup file with build env variables" >& 2 ; exit 1 ; fi
if [[ ! -e "$build_setup" ]] ; then echo "$build_setup not found"  >& 2 ; exit 1 ; fi
source $build_setup

tempdockerfile=$(mktemp -u) && echo $tempdockerfile

cat <<EOFINNER >> $tempdockerfile

# Install uv - fast Python package installer and resolver
RUN <<EOR
    set -x
    set -e

    # Install uv using the official installer
    curl -LsSf https://astral.sh/uv/install.sh | sh

    # Make uv available system-wide (installer puts it in /root/.local/bin)
    ln -sf /root/.local/bin/uv /usr/local/bin/uv
    ln -sf /root/.local/bin/uvx /usr/local/bin/uvx

    # Verify installation
    uv --version

    # Also make it available for rr_user
    mkdir -p /home/rr_user/.local/bin
    ln -sf /root/.local/bin/uv /home/rr_user/.local/bin/uv
    ln -sf /root/.local/bin/uvx /home/rr_user/.local/bin/uvx
    chown -R rr_user:rr_user /home/rr_user/.local

    echo "uv installed successfully" >& 2
EOR

EOFINNER
