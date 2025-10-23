#!/bin/bash
# initial setup steps to build image, output first Dockerfile
set -e

build_setup=$1
if [[ "$build_setup" == "" ]] ; then echo "specify setup file with build env variables" >& 2 ; exit 1 ; fi
if [[ ! -e "$build_setup" ]] ; then echo "$build_setup not found"  >& 2 ; exit 1 ; fi
source $build_setup

if [[ "$BUILD_PREFIX" == "" ]]; then echo "BUILD_PREFIX is not defined" >& 2 ; exit 1 ; fi

# To clean everything first, do this: 
# docker system prune --all --force

tempdockerfile=$(mktemp -u) && echo $tempdockerfile

cat <<EOF > $tempdockerfile

# Set up GPU Environment
# should these be in a config file?
#ENV NVIDIA_VISIBLE_DEVICES=all NVIDIA_DRIVER_CAPABILITIES=compute,utility NVIDIA_REQUIRE_CUDA="cuda>=10.0 brand=tesla,driver>=384,driver<385 brand=tesla,driver>=410,driver<411"
ENV BUILD_PREFIX=${BUILD_PREFIX}
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility
ENV NVIDIA_REQUIRE_CUDA="cuda>=10.0 brand=tesla,driver>=384,driver<385 brand=tesla,driver>=410,driver<411"
# last setting may be a mistake: how it's defined in the image, with spaces
# NVIDIA_REQUIRE_CUDA=cuda>=10.0 brand=tesla,driver>=384,driver<385 brand=tesla,driver>=410,driver<411

RUN <<EOR
  set -x
  set -e
  # groupadd -g 12574 domino 
  groupadd -g 12574 rr_user
  # useradd -u 12574 -g 12574 -m -N -s /bin/bash domino
  useradd -u 12574 -g 12574 -m -N -s /bin/bash rr_user
  # echo "domino ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
  # adduser domino sudo
  usermod -aG sudo rr_user
  cp /root/.bashrc /root/.bashrc.orig
  echo source ${BUILD_PREFIX}/setup.sh > /root/.bashrc
  cat /root/.bashrc.orig >> /root/.bashrc
  mkdir -p /opt/tbio

  # # in Andrew's minimal Dockerfile; this happens in miscellany_env_vars_domino.sh
  # mkdir -p /home/domino/.ssh
  # sudo chown -R domino:domino /home/domino
  # sudo chmod 0700 /home/domino/.ssh

  # The following commands are needed to get repositories loaded.
  apt-get update -y
  apt-get install -q -y software-properties-common wget
  apt-get -y -q autoremove
  apt-get -y -q autoclean
  rm -fr /var/lib/apt/lists/*
EOR

EOF
#echo $tempdockerfile
# echo "# exiting docker_create_initial_image.sh" >& 2
