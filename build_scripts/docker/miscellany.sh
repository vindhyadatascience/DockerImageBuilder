#!/bin/bash

set -e
#set -x

# to do: move expose statement to init block in make_master_build_script.sh

# To isolate commands into a separate Dockerfile, add these three lines then follow EOF/EOR logic 

# tempdockerfile=$(mktemp -u) && echo $tempdockerfile
# echo "# tempdockerfile=$tempdockerfile" >& 2
# cat <<EOF > $tempdockerfile

# Note: Rstudio driver installation:
#11 24.91 Requires the REMOVAL of the following packages: libiodbc2-dev
#11 24.91 Requires the installation of the following packages: unixodbc-dev
#11 24.91
#11 24.91 RStudio Professional Drivers
#11 24.91 Do you want to install the software package? [y/N]:(Reading database ... ^M(Reading database ... 5%^M(Reading database ... 10%^M(Reading database ... 15%^M(Reading database ... 20%^M(Reading database ... 25%^M(Reading database ... 30%^M(Reading database ... 35%^M(Reading database ... 40%^M(Reading database ... 45%^M(Reading database ... 50%^M(Reading database ... 55%^M(Reading database ... 60%^M(Reading database ... 65%^M(Reading database ... 70%^M(Reading database ... 75%^M(Reading database ... 80%^M(Reading database ... 85%^M(Reading database ... 90%^M(Reading database ... 95%^M(Reading database ... 100%^M(Reading database ... 198304 files and directories currently installed.)^M
#11 31.29 Removing libiodbc2-dev (3.52.9-2.1) ...^M
#11 31.39 Selecting previously unselected package unixodbc-dev:amd64.^M
# new instructions: https://docs.posit.co/pro-drivers/workbench-connect/

build_setup=$1
if [[ "$build_setup" == "" ]] ; then echo "specify setup file with build env variables" >& 2 ; exit 1 ; fi
if [[ ! -e "$build_setup" ]] ; then echo "$build_setup not found"  >& 2 ; exit 1 ; fi
source $build_setup

if [[ "$local_cache_dir" == "" ]] ; then echo "local_cache_dir is not defined" >& 2 ; exit 1 ; fi
if [[ "$local_scripts_dir" == "" ]] ; then echo "local_scripts_dir is not defined" >& 2 ; exit 1 ; fi
if [[ "$BUILD_PREFIX" == "" ]] ; then echo "BUILD_PREFIX is not defined" >& 2 ; exit 1 ; fi
if [[ "$Java_version" == "" ]] ; then echo "Java_version is not defined" >& 2 ; exit 1 ; fi
if [[ "$R_version" == "" ]] ; then echo "R_version is not defined" >& 2 ; exit 1 ; fi
if [[ "$R_studio_drivers_url" == "" ]] ; then echo "R_studio_drivers_url is not defined" >& 2 ; exit 1 ; fi
if [[ "$R_studio_server_url" == "" ]] ; then echo "R_studio_server_url is not defined" >& 2 ; exit 1 ; fi
if [[ "$domino_zip_url" == "" ]] ; then echo "domino_zip_url is not defined" >& 2 ; exit 1 ; fi

for dir in $local_cache_dir $local_scripts_dir ; do
    if [[ ! -d $dir ]] ; then echo "$dir not found" >& 2 ; fi #exit 1 ; fi
done

# RStudio drivers

# https://docs.posit.co/pro-drivers/workbench-connect/#step-1-install-dependencies
# 1. dependencies: 
# sudo apt-get install unixodbc unixodbc-dev gdebi
# 2. Additional steps for using the Oracle database driver
# Install version 19.8 of the Oracle Instant Client
# Link the Oracle library directory to the Posit Pro Drivers library directory by running the following command:
# ln -s /usr/lib/oracle/19.x/client64/lib/* /opt/rstudio-drivers/oracle/bin/lib/
# Please adjust the directory minor version (x) according to the installed version of the Oracle Instant Client.
# 3. install drivers per se
# curl -O https://cdn.rstudio.com/drivers/7C152C12/installer/rstudio-drivers_2023.05.0_amd64.deb
# sudo gdebi rstudio-drivers_2023.05.0_amd64.deb

#tempdockerfile=$(mktemp -u) && echo $tempdockerfile
#R_studio_drivers_deb=$(basename $R_studio_drivers_url)
#
#cat <<EOF >> $tempdockerfile
#
#RUN <<EOR
#    set -x
#    set -e
#
#    # install R Studio drivers
#    # normally: sudo apt-get install unixodbc unixodbc-dev gdebi
#    # due to conflicts, gdebi and unixodbc are installed earlier by add_apts.sh
#    wget --quiet --no-clobber -O /tmp/docker.gpg https://download.docker.com/linux/ubuntu/gpg
#    apt-key add < /tmp/docker.gpg
#    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu noble stable"
#    apt-get update -y -q
#    apt-get install -q -y docker-ce-cli
#    wget --quiet --no-clobber -P /tmp ${R_studio_drivers_url}
#    gdebi --non-interactive --quiet /tmp/$R_studio_drivers_deb
#    rm -f /tmp/docker.gpg /tmp/$R_studio_drivers_deb
#    apt-get -q -y autoremove
#    apt-get -q -y autoclean
    rm -fr /var/lib/apt/lists/*
EOR
EOF

# for R-4.2.3, this outputs 4.2
rlib_ver=$(echo $R_version | cut -f2 -d- | cut -f1-2 -d .)

tempdockerfile=$(mktemp -u) && echo $tempdockerfile
cat <<EOF >> $tempdockerfile

RUN <<EOR
    set -x
    set -e
    mkdir -p /home/rr_user/.ssh
    chown -R rr_user:rr_user /home/rr_user/.ssh
    ls -al /home/rr_user/
    rm -rf /home/rr_user/R /home/rr_user/make_r_libs_user.sh
    mkdir -p /home/rr_user/R/x86_64-pc-linux-gnu-library/${rlib_ver}
    chown -R rr_user:rr_user /home/rr_user/R
    cd /tmp
    url=http://ftp.osuosl.org/pub/blfs/conglomeration/unixODBC
    dir=unixODBC-2.3.4
    gz=\$dir.tar.gz
    wget --no-clobber --quiet \$url/\$gz
    tar -xf \$gz
    cd \$dir
    ./configure --enable-gui=no --enable-drivers=no --enable-iconv --with-iconv-char-enc=UTF8 --with-iconv-ucode-enc=UTF16LE --libdir=/usr/lib/x86_64-linux-gnu --prefix=/usr --sysconfdir=/etc --enable-stats=no
    make
    make install
    ln -s /lib/x86_64-linux-gnu/libssl.so.1.0.0 /lib/x86_64-linux-gnu/libssl.so.10
    ln -s /lib/x86_64-linux-gnu/libcrypto.so.1.0.0 /lib/x86_64-linux-gnu/libcrypto.so.10
    ldconfig
    apt-get -q -y autoremove
    apt-get -q -y autoclean
    cd /tmp
    rm -fr \$gz \$dir
    rm -fr /var/lib/apt/lists/*
EOR

EOF

#### Installing Notebooks,Workspaces,IDEs,etc ####
# Clone in workspaces install scripts

# domino startup

tempdockerfile=$(mktemp -u) && echo $tempdockerfile

for file in domino_Jupyterlab_start.sh domino_jupyter_start Rprofile.txt vscode.install; do
    #temp=$(local_script_path $file)
    temp=$(find_local_file $file $local_scripts_dir)
cat <<EOF >> $tempdockerfile
COPY ${temp} /tmp
EOF
done

# https://github.com/dominodatalab/workspace-configs/archive/2021q1-v1.zip
version=$(basename $domino_zip_url | cut -d . -f 1)
tmpdir=workspace-configs-$version
# 2021q1-v1

# files from Domino zip are used later during vscode installation

cat <<EOF >> $tempdockerfile
RUN <<EOR
    set -x
    set -e
    cp /tmp/Rprofile.txt /home/rr_user/.Rprofile
    mkdir -p /var/opt/workspaces/vscode
    cd /tmp
    wget --quiet --no-clobber https://github.com/dominodatalab/workspace-configs/archive/2021q1-v1.zip # 2023/10: works,  replaced with variable
    unzip 2021q1-v1.zip 
    # 2023/10: works,  replaced with variable
    find /tmp/workspace-configs-2021q1-v1 -type f | xargs perl -p -i -e 's/ubuntu/rr_user/g'
    cp -Rf /tmp/workspace-configs-2021q1-v1/. /var/opt/workspaces
    rm -rf /var/opt/workspaces/workspace-logos /tmp/workspace-configs-2021q1-v1

    # # 2023/01/18 - replace Jupyter & JupyterLab startup scripts for Domino
    # # NOTE: CHECK SEQUENCE
    
    mv -f /var/opt/workspaces/jupyter/start /var/opt/workspaces/jupyter/start.orig
    cp /tmp/domino_jupyter_start /var/opt/workspaces/jupyter/start
    mv -f /var/opt/workspaces/Jupyterlab/start.sh /var/opt/workspaces/Jupyterlab/start.sh.orig
    cp /tmp/domino_Jupyterlab_start.sh /var/opt/workspaces/Jupyterlab/start.sh
    ls -al /var/opt/workspaces/*upyter*/start*
    
    # # Add RProfile including BRAN and update to .libPaths to include /home/domino/rLibrary
    chown rr_user:rr_user /home/rr_user/.Rprofile
    # Use updated VScode code-server install
    cp /tmp/vscode.install /var/opt/workspaces/vscode/install
    rm -fr /tmp/*
EOR
EOF


tempdockerfile=$(mktemp -u) && echo $tempdockerfile

cat <<EOF >> $tempdockerfile

RUN <<EOR
    set -x
    set -e

    wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_amd64.deb
    dpkg -i libssl1.1_1.1.1f-1ubuntu2_amd64.deb

    url=${R_studio_server_url}
    deb=\$(basename \$url)
    wget --no-clobber -P /tmp --quiet \$url
    dpkg --install /tmp/\$deb
    mkdir -p /etc/rstudio/
    echo copilot-enabled=1 >> /etc/rstudio/rsession.conf
    apt -y -q update
    apt-get -q -y -f install
    pandoc=/usr/lib/rstudio-server/bin/quarto/bin/tools/x86_64/pandoc
    ls \$pandoc
    ln -sf \$pandoc /usr/local/bin/pandoc
    apt-get -q -y autoremove
    apt-get -q -y autoclean
    rm -fr /tmp/*
    rm -fr /var/lib/apt/lists/*
EOR
EOF

# replace corrected installation file

tempdockerfile=$(mktemp -u) && echo $tempdockerfile

for file in vscode.install vscode.install.2024.11.14.sh ; do
    temp=$(find_local_file $file $local_scripts_dir)

cat <<EOF >> $tempdockerfile
COPY ${temp} /tmp
EOF
done

cat <<EOF >> $tempdockerfile

RUN <<EOR
    set -x
    set -e
    # Install VSCode from workspaces, but remove the package purging that deletes ImageMagick libraries.
    if ! cmp -s /tmp/vscode.install.2024.11.14.sh /var/opt/workspaces/vscode/install; then
        echo Mismatched VSCode install
        exit 1
    fi
    cp /tmp/vscode.install /var/opt/workspaces/vscode/install
    /var/opt/workspaces/vscode/install 
    echo Modified VSCode worked.
    rm -fr /tmp/*
EOR
EOF

tempdockerfile=$(mktemp -u) && echo $tempdockerfile

cat <<EOF >> $tempdockerfile

RUN <<EOR
    set -x
    set -e
    
    #Install Jupyter and Jupyterlab from workspaces
    # Jupyterlab is already installed in pip_install.sh.
    # The Jupyter install script needs to avoid installing jupyter in Python because it's already there.
    cp /var/opt/workspaces/jupyter/install /var/opt/workspaces/jupyter/install.orig
    sed -e 's/pip install/# pip install/g'  < /var/opt/workspaces/jupyter/install.orig > /var/opt/workspaces/jupyter/install
    chmod +x /var/opt/workspaces/jupyter/install
    /var/opt/workspaces/jupyter/install 

    # Edit the rstudio workspace startup script.
    cd /var/opt/workspaces/rstudio
    cp --backup=numbered start start.orig
    # sed -e 's#bin/rserver#bin/rserver --server-user domino --rsession-which-r ${BUILD_PREFIX}/binaries/${R_version}/bin/R --www-frame-origin=any #' < start.orig >start
    # chown -R domino:domino /var/lib/rstudio-server
    sed -e 's#bin/rserver#bin/rserver --server-user rr_user --rsession-which-r ${BUILD_PREFIX}/binaries/${R_version}/bin/R --www-frame-origin=any #' < start.orig >start
    chown -R rr_user:rr_user /var/lib/rstudio-server/
    chmod +x start

    # Give sudo to domino
    # Set some environment variables
    echo "rr_user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    echo "export R_ZIPCMD=/usr/bin/zip" >> /home/rr_user/.domino-defaults
    # echo "export http_proxy=http://proxy-server.bms.com:8080" >> /home/domino/.domino-defaults
    # echo "export HTTP_PROXY=http://proxy-server.bms.com:8080" >> /home/domino/.domino-defaults
    # echo "export https_proxy=http://proxy-server.bms.com:8080" >> /home/domino/.domino-defaults
    # echo "export HTTPS_PROXY=http://proxy-server.bms.com:8080" >> /home/domino/.domino-defaults
    # echo "export ftp_proxy=http://proxy-server.bms.com:8080" >> /home/domino/.domino-defaults
    # echo "export FTP_PROXY=http://proxy-server.bms.com:8080" >> /home/domino/.domino-defaults
    # echo "export no_proxy=.bms.com,169.254.169.254,localhost" >> /home/domino/.domino-defaults
    # echo "export NO_PROXY=.bms.com,169.254.169.254,localhost" >> /home/domino/.domino-defaults

    groupadd -g 9500 bioinfo
    mkdir -p /var/log/supervisor
    mkdir -p /etc/supervisor/conf.d
    mkdir -p /var/run/sshd
EOR
EOF

# miscellany_env_vars_domino.sh

tempdockerfile=$(mktemp -u) && echo $tempdockerfile

for file in start.sh supervisord.conf id_rsa.pub ; do
    #temp=$(local_cache_path $file)
    temp=$(find_local_file $file $local_cache_dir)
cat <<EOF >> $tempdockerfile
COPY ${temp} /tmp
EOF
done

cat <<EOF >> $tempdockerfile

RUN <<EOR
    set -x
    set -e
    cp -f -p /tmp/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
    yes y | ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N '' 
EOR
EXPOSE 80 22 8787
RUN <<EOR
    set -x
    set -e
    chmod 755 /tmp/start.sh
    /tmp/start.sh

    ###id_rsa.pub should be the apache (or whatever user is running Apache) user's public ssh key (e.g. generated by ssh-keygen -t rsa)
    ###Below enables apache user to run commands inside the running Docker container without entering
    ###a password (i.e. just using ssh keys). E.g. to mount /stash and user home dir with sshfs.
    ###See these 2 links for how to enable passwordless ssh via ssh-keygen:
    ###https://www.tecmint.com/ssh-passwordless-login-using-ssh-keygen-in-5-easy-steps/
    ###http://www.linuxproblem.org/art_9.html
    
    # for user in rr_user domino ; do
    for user in rr_user ; do
        mkdir -p /home/\${user}/.ssh
        # or ADD/COPY /tmp/id_rsa.pub /home/user/.ssh/id_rsa.pub
        cp -f -p /tmp/id_rsa.pub /home/\${user}/.ssh/
        cat /home/\${user}/.ssh/id_rsa.pub >> /home/\${user}/.ssh/authorized_keys
        chown -R \${user} /home/\${user}/.ssh
        # chgrp -R \${user} /home/\${user}/.ssh
        chmod 700 /home/\${user}/.ssh
        chmod 640 /home/\${user}/.ssh/authorized_keys
    done
      
EOR
EOF

# switching from literal to interpolated; the code below leads to:
# export JAVA_HOME=/opt/tbio/domino_202305/binaries/jdk-12.0.1
# export PATH=/opt/tbio/domino_202305/binaries/R-4.3.0/bin:$JAVA_HOME/bin:$PATH
# export LD_LIBRARY_PATH=/opt/tbio/domino_202305/lib/:$LD_LIBRARY_PATH
# export TZ="America/New_York"
# export R_LIBS_USER=/home/domino/R/x86_64-pc-linux-gnu-library/4.3

cat <<EOF >> $tempdockerfile
RUN <<EOR
    # Clean up temporary files an other details.
    rm -fr /var/lib/apt/lists/* /tmp/*
    chown -R rr_user:rr_user /tmp
    chown -R rr_user:bioinfo /home/rr_user
    mkdir -p /home/rr_user/.local
    chown -R rr_user:rr_user /home/rr_user /home/rr_user/.local
    echo 'export JAVA_HOME=${BUILD_PREFIX}/binaries/jdk-${Java_version}' >> /home/rr_user/.bashrc
    echo 'export PATH=${BUILD_PREFIX}/binaries/${R_version}/bin:\$JAVA_HOME/bin:\$PATH' >> /home/rr_user/.bashrc
    echo 'export LD_LIBRARY_PATH=${BUILD_PREFIX}/lib/:\$LD_LIBRARY_PATH' >> /home/rr_user/.bashrc
    echo 'export TZ="America/New_York"' >> /home/rr_user/.bashrc
    echo "export R_LIBS_USER=/home/rr_user/R/x86_64-pc-linux-gnu-library/${rlib_ver}" >> /home/rr_user/.bashrc
EOR
EOF

# echo "# end of docker_miscellany.sh" >& 2
