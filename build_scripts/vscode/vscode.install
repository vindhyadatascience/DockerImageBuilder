#!/bin/bash -x

# Install VSCode from workspaces, but remove the package purging that deletes ImageMagick libraries.

set -o nounset -o errexit -o pipefail

#python_ext_installation=$1

#if [[ ! -e "$python_ext_installation" ]] ; then echo "$python_ext_installation not found" >& 2 ; exit 1 ; fi

# errexit = -e
# pipefail: return value of a pipeline = value of the last (rightmost) command to exit with a non-zero status, or zero if all commands succeed
# nounset = -u = Treat unset variables/parameters other than special parameters ‘@’ or ‘*’, or array variables subscripted with ‘@’ or ‘*’, as 
# an error when performing parameter expansion.

# 2022-09-22: pip install was the last step before apt-get clean just below, but all of these packages are included in pip_install.sh
# pip install -q python-language-server autopep8 flake8 pylint

# ##Install VSCode and requirements including Node
# apt-get update -qq
# curl -fsSL https://deb.nodesource.com/setup_14.x | bash -
# apt-get -y -q install jq libx11-dev libxkbfile-dev libsecret-1-dev node-gyp nodejs
# apt-get clean
# rm -rf /var/lib/apt/lists/* /var/tmp/*

##Install VSCode and requirements including Node
apt-get update -qq
# 2024-10-03 - updated source for installation, reordered steps to address installation issues
# curl -fsSL https://deb.nodesource.com/setup_14.x | bash -
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get -y -q install nodejs
npm install -g node-gyp
apt-get -y -q install jq libx11-dev libxkbfile-dev libsecret-1-dev
# apt-get -y -q install jq libx11-dev libxkbfile-dev libsecret-1-dev node-gyp nodejs
apt-get clean
rm -rf /var/lib/apt/lists/* /var/tmp/*

#apt autoremove -y
#apt autoclean -y

#CODE_SERVER_VERSION=3.7.3
# https://github.com/coder/code-server/releases
# 2023/05/16
CODE_SERVER_VERSION=4.12.0

mkdir -p /opt/code-server
cd /opt/code-server
wget -qO- https://github.com/coder/code-server/releases/download/v$CODE_SERVER_VERSION/code-server-$CODE_SERVER_VERSION-linux-amd64.tar.gz | tar zxf - --strip-components=1

echo 'export PATH=/opt/code-server/bin:$PATH' >> /home/rr_user/.domino-defaults
apt-get clean
rm -rf /var/lib/apt/lists/* /var/tmp/*

# uninstalled in older versions
# apt-get purge --auto-remove -y libx11-dev libxkbfile-dev libsecret-1-dev

#apt autoremove -y
#apt autoclean -y
#rm -rf /var/lib/apt/lists/* /var/tmp/*

#Install VSCode extensions for python (pinned to this version due to a bug)
export PATH=/opt/code-server/bin:$PATH
cd /tmp
mkdir -p /home/rr_user/.local/share/code-server/
mkdir -p /home/rr_user/.local/share/code-server/User
echo "{\"extensions.autoCheckUpdates\": false, \"extensions.autoUpdate\": false}" > /home/rr_user/.local/share/code-server/User/settings.json

#https://open-vsx.org/api/ms-python/python/2023.6.0/file/ms-python.python-2023.6.0.vsix
version=2023.6.0 # url also works with 2023.8.0 but incompatible with vscode engine in server version
python_ext_installation=ms-python.python-$version.vsix
url=https://open-vsx.org/api/ms-python/python/$version/file/$python_ext_installation

# https://github.com/microsoft/vscode-python/releases/download/2020.10.332292344/ms-python-release.vsix
# version=2020.10.332292344
# python_ext_installation=ms-python-release.vsix
# url=https://github.com/microsoft/vscode-python/releases/download/$version/$python_ext_installation

wget --no-clobber -q -P /tmp $url
code-server --install-extension /tmp/$python_ext_installation --extensions-dir /home/rr_user/.local/share/code-server/extensions || true
# chown -R domino:domino /home/domino/.local/
chown -R rr_user:rr_user /home/rr_user/.local/
rm -rf /tmp/*
