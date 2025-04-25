#!/bin/bash

# replaces /var/opt/workspaces/Jupyterlab/start.sh, which comes from:
# https://github.com/dominodatalab/workspace-configs/archive/2021q1-v1.zip

#c.Session.debug = True
#c.Application.log_level = 0
#c.JupyterApp.log_level = 0
#c.ServerApp.autoreload = True

set -o nounset -o errexit

CONF_DIR="$HOME/.jupyter"
CONF_FILE="${CONF_DIR}/jupyter_server_config.py"
mkdir -p "${CONF_DIR}"

PREFIX=/${DOMINO_PROJECT_OWNER}/${DOMINO_PROJECT_NAME}/notebookSession/${DOMINO_RUN_ID}/

cat > $CONF_FILE << EOF
c = get_config()
c.ServerApp.preferred_dir = '/home/rr_user'
c.IdentityProvider.token = ''
c.ServerApp.root_dir = '/'
c.ServerApp.tornado_settings = {'headers': {'Content-Security-Policy': 'frame-ancestors *'}, 'static_url_prefix': '${PREFIX}static/'}
c.ExecutePreprocessor.timeout = 365*24*60*60
c.ZMQChannelsWebsocketConnection.iopub_data_rate_limit = 10000000000
c.ServerApp.base_url = '${PREFIX}'

EOF

COMMAND="jupyter-lab --config=$CONF_FILE --no-browser --ip=0.0.0.0 2>&1"
eval ${COMMAND} 

