#!/bin/bash 

set -e

tempdockerfile=$(mktemp -u) && echo $tempdockerfile
cat <<EOF > $tempdockerfile

RUN <<EOR
    set -e
    set -x
    #apt list
    apt-get update -y
    
    # special handling for tzdata
    cat /dev/null > /tmp/tzdata.inp
    echo 12 > /tmp/tzdata.inp
    echo 5 >> /tmp/tzdata.inp
    apt-get --allow-unauthenticated -y -q  install tzdata < /tmp/tzdata.inp

    # apt-get --allow-unauthenticated -y -q  install git locales build-essential cmake wget sudo curl apt-utils net-tools libzmq3-dev ed openssh-server libaio1 vim     gcc-7 g++-7 gfortran-7 nano htop bmon slurm tcptrack iftop nethogs qpdf alien screen tmux sshfs libpoppler-cpp-dev emacs ess texinfo texlive-fonts-extra     texlive-xetex imagemagick libmagick++-dev libfreetype6-dev librsvg2-dev libwmf-dev libgdk-pixbuf2.0-dev libcairo2-dev dos2unix libnlopt0 libnlopt-dev     manpages manpages-dev freebsd-manpages funny-manpages man2html cifs-utils libfontconfig1-dev libpng-dev libhdf5-dev libhdf5-serial-dev libpq-dev     heirloom-mailx libssl-dev libxml2-dev libxt-dev libssh2-1-dev libcurl4-openssl-dev libsasl2-dev libgmp3-dev jags libgsl0-dev libx11-dev     mesa-common-dev libglu1-mesa-dev libmpfr-dev libfftw3-dev libtiff5-dev vpnc passwd supervisor libffi-dev libudunits2-dev libgeos-dev     tk-dev nfs-common s3fs apt-transport-https iputils-ping rsync libopenmpi2 libopenmpi-dev openmpi-bin openmpi-common libsodium-dev libtesseract-dev     libleptonica-dev libboost-all-dev locate libbz2-dev liblzma-dev libopenblas-dev libpcre2-dev libpcre3-dev libreadline-dev libz-dev unzip libavfilter-dev     cargo libnetcdf-c++4 libnetcdf-c++4-1 libnetcdf-c++4-dev libnetcdf-c++4-doc libnetcdf-cxx-legacy-dev libnetcdf-dev     libnetcdff-dev libnetcdff-doc libnetcdff6 netcdf-bin netcdf-doc tree glpk-utils python-glpk libhiredis-dev libhiredis0.13 libwebp-dev tesseract-ocr-eng     bwidget devscripts gdebi apache2 libapache2-mod-perl2 libjson-perl cpanminus ca-certificates gnupg-agent software-properties-common libharfbuzz-dev     libfribidi-dev uuid-dev psmisc libclang-dev libzstd-dev liblz4-dev cuda-command-line-tools-11-0 cuda-compat-11-0 cuda-cudart-11-0 cuda-nvrtc-11-0     libcublas-11-0 libcudnn8 libcufft-11-0 libcurand-11-0 libcusolver-11-0 libcusparse-11-0 aria2 awscli
    apt-get --allow-unauthenticated -y -q  install git locales build-essential cmake wget sudo curl apt-utils net-tools libzmq3-dev ed openssh-server libaio1 vim     nano htop bmon slurm tcptrack iftop nethogs qpdf alien screen tmux sshfs libpoppler-cpp-dev emacs ess texinfo texlive-fonts-extra     texlive-xetex imagemagick libmagick++-dev libfreetype6-dev librsvg2-dev libwmf-dev libgdk-pixbuf2.0-dev libcairo2-dev dos2unix libnlopt0 libnlopt-dev     manpages manpages-dev freebsd-manpages funny-manpages man2html cifs-utils libfontconfig1-dev libpng-dev libhdf5-dev libhdf5-serial-dev libpq-dev     libssl-dev libxml2-dev libxt-dev libssh2-1-dev libcurl4-openssl-dev libsasl2-dev libgmp3-dev jags libgsl0-dev libx11-dev     mesa-common-dev libglu1-mesa-dev libmpfr-dev libfftw3-dev libtiff5-dev vpnc passwd supervisor libffi-dev libudunits2-dev libgeos-dev     tk-dev nfs-common s3fs apt-transport-https iputils-ping rsync libopenmpi-dev openmpi-bin openmpi-common libsodium-dev libtesseract-dev     libleptonica-dev libboost-all-dev locate libbz2-dev liblzma-dev libopenblas-dev libpcre2-dev libpcre3-dev libreadline-dev libz-dev unzip libavfilter-dev     cargo libnetcdf-c++4 libnetcdf-c++4-1 libnetcdf-c++4-dev libnetcdf-c++4-doc libnetcdf-cxx-legacy-dev libnetcdf-dev     libnetcdff-dev libnetcdff-doc netcdf-bin netcdf-doc tree glpk-utils libhiredis-dev libwebp-dev tesseract-ocr-eng     bwidget devscripts gdebi apache2 libapache2-mod-perl2 libjson-perl cpanminus ca-certificates gnupg-agent software-properties-common libharfbuzz-dev     libfribidi-dev uuid-dev psmisc libclang-dev libzstd-dev liblz4-dev cuda-command-line-tools-11-0 cuda-compat-11-0 cuda-cudart-11-0 cuda-nvrtc-11-0     libcublas-11-0 libcudnn8 libcufft-11-0 libcurand-11-0 libcusolver-11-0 libcusparse-11-0 aria2 awscli
    apt-get --allow-unauthenticated  -y -q install libmysqlclient-dev  libsqlite3-dev tdsodbc r-cran-rodbc 
    
    # 2023/04/25: installing unixodbc-dev conflicts with libiodbc2-dev
    # doing this uninstalls unixodbc-dev
    # 1. apt-get --allow-unauthenticated -y -q install unixodbc  unixodbc-dev
    # 2. apt-get --allow-unauthenticated -y -q install libiodbc2-dev libiodbc2
    
    apt-get  --allow-unauthenticated -y -q install unixodbc libiodbc2 libiodbc2-dev 
    
    # see dependencies in miscellany.sh - RStudio & driver installation

    # 2022/12/14 libgit2-dev is required for gert etc. but normally conflicts with libcurl4-openssl-dev
    # remove the repository after installation?

    # add-apt-repository -y ppa:cran/libgit2
    apt update -y
    apt-get install -y -q libgit2-dev
    # add-apt-repository --remove ppa:cran/libgit2
    apt autoremove -y
    apt autoclean -y
    rm -fr /tmp/* 
    rm -fr /var/lib/apt/lists/*
EOR

EOF

#echo "# exiting docker_add_apts.sh" >& 2
