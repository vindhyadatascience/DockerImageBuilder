#!/bin/bash 

set -e

build_setup=$1
if [[ "$build_setup" == "" ]] ; then echo "specify setup file with build env variables" >& 2 ; exit 1 ; fi
if [[ ! -e "$build_setup" ]] ; then echo "$build_setup not found"  >& 2 ; exit 1 ; fi
source $build_setup

# env variables technically not interpolated here; these checks just make sure build & production are in sync
if [[ "$Java_version" == "" ]] ; then echo "Java_version is undefined" >& 2 ; exit 1 ; fi
if [[ "$BUILD_PREFIX" == "" ]] ; then echo "BUILD_PREFIX is undefined" >& 2 ; exit 1 ; fi
if [[ "$JAVA_HOME" == "" ]] ; then echo "JAVA_HOME is undefined" >& 2 ; exit 1 ; fi

tempdockerfile=$(mktemp -u) && echo $tempdockerfile

cat <<EOF > $tempdockerfile

RUN <<EOR
  set -x
  set -e
  # 2023/03/22 - these next three statements appear to not do anything
  #export JAVA_HOME=$BUILD_PREFIX/binaries/jdk-${Java_version}
  #export PATH=$JAVA_HOME/bin:$PATH
  #export LD_LIBRARY_PATH=$JAVA_HOME/lib/server:${LD_LIBRARY_PATH:-}
  mkdir -p /home/rr_user/
  #echo "export JAVA_HOME=${BUILD_PREFIX}/binaries/jdk-${Java_version}" >> /home/rr_user/.domino-defaults
  echo "export JAVA_HOME=${JAVA_HOME}" >> /home/rr_user/.domino-defaults
  echo 'export PATH=\${JAVA_HOME}/bin:\${PATH:-}' >> /home/rr_user/.domino-defaults
  echo 'export LD_LIBRARY_PATH=\${JAVA_HOME}/lib/server:\${LD_LIBRARY_PATH:-}' >> /home/rr_user/.domino-defaults
  cat /home/rr_user/.domino-defaults
  #rm -fr /tmp/*
EOR

EOF
