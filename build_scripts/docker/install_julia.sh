#!/bin/bash

set -e

build_setup=$1
if [[ "$build_setup" == "" ]] ; then echo "specify setup file with build env variables" >& 2 ; exit 1 ; fi
if [[ ! -e "$build_setup" ]] ; then echo "$build_setup not found"  >& 2 ; exit 1 ; fi
source $build_setup

if [[ "$Julia_version" == "" ]] ; then echo "Julia_version is not defined" >& 2 ; exit 1 ; fi

Julia_version_major=$(echo $Julia_version|cut -d. -f1,2) # for 1.8.5, outputs 1.8

tempdockerfile=$(mktemp -u) && echo $tempdockerfile

cat <<EOF > $tempdockerfile
RUN <<EOR
    set -x
    set -e
    # install Julia
    mkdir -p /home/rr_user
    cd /home/rr_user
    
    #url=https://julialang-s3.julialang.org/bin/linux/x64/1.8
    url=https://julialang-s3.julialang.org/bin/linux/x64/${Julia_version_major}
    julia_dir=julia-${Julia_version}
    gz=\$julia_dir-linux-x86_64.tar.gz
    wget --no-clobber --quiet -P /tmp \$url/\$gz
    tar xzf /tmp/\$gz
    chmod +x \$julia_dir
    # chown -R domino:domino \$julia_dir
    chown -R rr_user:rr_user \$julia_dir
    if test -e /usr/bin/julia; then rm -f /usr/bin/julia; fi
    ln -s /home/rr_user/\$julia_dir/bin/julia /usr/bin/julia
    rm -fr /tmp/*
EOR
EOF

