#!/bin/bash 

set -e
#echo "# in docker_add_package_libraries.sh" >& 2

build_setup=$1
if [[ "$build_setup" == "" ]] ; then echo "specify setup file with build env variables" >& 2 ; exit 1 ; fi
if [[ ! -e "$build_setup" ]] ; then echo "$build_setup not found"  >& 2 ; exit 1 ; fi
source $build_setup

## Ubuntu Packages For R - Brief Instructions - http://cran.rstudio.com/bin/linux/ubuntu/
## update indices
# sudo apt update -qq
## install two helper packages we need
# sudo apt install --no-install-recommends software-properties-common dirmngr
## add the signing key (by Michael Rutter) for these repos
## To verify key, run gpg --show-keys /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc 
## Fingerprint: E298A3A825C0D65DFD57CBB651716619E084DAB9
# wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | sudo tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
## add the R 4.0 repo from CRAN -- adjust 'focal' to 'groovy' or 'bionic' as needed
# sudo add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"


if [[ "$local_cache_dir" == "" ]] ; then echo "local_cache_dir is not defined" >& 2 ; exit 1 ; fi
if [[ ! -d $local_cache_dir ]] ; then echo "$local_cache_dir not found" >& 2 ; exit 1 ; fi

mkdir -p $local_cache_dir/linux

# 2023/10 wget now installed in create_initial_image
# wget --quiet --no-clobber -P $local_cache_dir/linux https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc
# wget --quiet --no-clobber -P $local_cache_dir/linux https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-keyring_1.0-1_all.deb

tempdockerfile=$(mktemp -u) && echo $tempdockerfile

#for file in marutter_pubkey.asc cuda-keyring_1.0-1_all.deb ; do
#    temp=$(find_local_file $file $local_cache_dir)
#cat <<EOF >> $tempdockerfile
#COPY ${temp} /tmp
#EOF
#done
cat <<EOF >> $tempdockerfile

RUN <<EOR
    set -x
    set -e
    add-apt-repository -y universe
    add-apt-repository -y ppa:git-core/ppa
    add-apt-repository -y ppa:linuxuprising/java
    add-apt-repository -y ppa:deadsnakes/ppa

    # The next batch of commands takes care of Postgres and R related stuff
    # 2022-09-12: added these three lines to next section for libzstd-dev liblz4-dev
    #    echo "deb http://us.archive.ubuntu.com/ubuntu/ xenial main universe" | tee -a >> /etc/apt/sources.list\
    #    echo "deb-src http://us.archive.ubuntu.com/ubuntu/ xenial main universe" | tee -a >> /etc/apt/sources.list\
    #    apt-get update -y
    # 2022-09-13 - added for cuda libraries
    # wget is not yet installed in the image

    # previously a separate block
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8
    # echo "deb http://apt.postgresql.org/pub/repos/apt/ noble-pgdg main" > /etc/apt/sources.list.d/pgdg.list
    echo "deb http://apt.postgresql.org/pub/repos/apt/ noble-pgdg main" > /etc/apt/sources.list.d/pgdg.list
    apt-get update -y
    gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E084DAB9
    gpg -a --export E084DAB9 | apt-key add -
    # echo "deb https://cloud.r-project.org/bin/linux/ubuntu noble-cran40/" | tee -a /etc/apt/sources.list
    add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu noble-cran40/"
    wget --quiet --no-clobber -P /tmp https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc
    cat /tmp/marutter_pubkey.asc >> /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
    apt-get update -y
    apt-get -y -q install apt-utils
    echo "deb http://us.archive.ubuntu.com/ubuntu/ noble main universe" | tee -a >> /etc/apt/sources.list
    echo "deb-src http://us.archive.ubuntu.com/ubuntu/ noble main universe" | tee -a >> /etc/apt/sources.list
    apt-get update -y
    wget --quiet --no-clobber -P /tmp https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-keyring_1.0-1_all.deb
    dpkg -i /tmp/cuda-keyring_1.0-1_all.deb
    apt-get update -y
    # 2024-09-24 - added in the next 3 lines below to address compilation issues with JAGS
    apt install -y libcppunit-dev
    apt-get install -y gfortran
    apt-get update -y
    #rm /tmp/marutter_pubkey.asc /tmp/cuda-keyring_1.0-1_all.deb
    rm -fr /tmp/*
    apt autoremove -y
    apt autoclean -y
    rm -fr /var/lib/apt/lists/*
EOR

EOF
#echo "# exiting docker_add_package_libraries.sh" >& 2
