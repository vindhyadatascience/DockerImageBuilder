#!/bin/bash -x

set -e

# unzips zip file created by efs/configure_kernels_generate.sh

build_setup=$1
if [[ "$build_setup" == "" ]] ; then echo "specify setup file with build env variables" >& 2 ; exit 1 ; fi
if [[ ! -e "$build_setup" ]] ; then echo "$build_setup not found"  >& 2 ; exit 1 ; fi
source $build_setup

if [[ "$jupyter_kernels_zip" == "" ]]; then echo "jupyter_kernels_zip is not defined" >& 2 ; exit 1 ; fi
if [[ "$jupyter_kernels_dir" == "" ]]; then echo "jupyter_kernels_dir is not defined" >& 2 ; exit 1 ; fi
if [[ "$local_cache_dir" == "" ]]; then echo "local_cache_dir is not defined" >& 2 ; exit 1 ; fi
if [[ "$dockerfile_dir" == "" ]]; then echo "dockerfile_dir is not defined" >& 2 ; exit 1 ; fi

tempdockerfile=$(mktemp -u) && echo $tempdockerfile
cat <<EOF > $tempdockerfile
COPY ${dockerfile_dir}/${jupyter_kernels_zip} /tmp

RUN <<EOR
  set -e
  set -x
  mkdir -p ${jupyter_kernels_dir}
  cd ${jupyter_kernels_dir}
  unzip /tmp/${jupyter_kernels_zip}
  ls -al */*
  usermod -a -G rstudio-server rr_user
  usermod -a -G 12574 rstudio-server

  # set file permissions to run rstudio-server
  chown -R rr_user:rr_user /home/rr_user/
  chown -R rr_user:rstudio-server /var/run/rstudio-server
  chown -R rr_user:rstudio-server /var/lib/rstudio-server
  chown -R rr_user:rstudio-server /var/log/rstudio
  chmod 2775 /var/lib/rstudio-server
  chmod 2775 /var/log/rstudio
  chmod 1777 /var/run/rstudio-server/rstudio-rserver
  rm /var/run/rstudio-server/rstudio-rserver/session-server-rpc.socket
  
  # set user permission to run rstudio-server
  echo "auth-required-user-group=rr_user" >> /etc/rstudio/rserver.conf
  echo "server-user=rr_user" >> /etc/rstudio/rserver.conf
  echo "server-user=rr_user" >> /etc/rstudio/server.conf
  
EOR
EOF
