#!/bin/bash 
set -e
build_setup=$1
if [[ "$build_setup" == "" ]] ; then echo "specify setup file with build env variables" >& 2 ; exit 1 ; fi
if [[ ! -e "$build_setup" ]] ; then echo "$build_setup not found"  >& 2 ; exit 1 ; fi
source $build_setup
if [[ "$OCI_LIB" == "" ]] ; then echo "OCI_LIB is not defined" >& 2 ; exit 1 ; fi

# \EOF makes the text appear verbatim in the Dockerfile
# Using "" allows the interpolation of $install_dir but not ${PATH} when echo is executed
#   cat <<\EOF > $tempdockerfile
#   RUN <<EOR
#        install_dir=/opt/oracle/instantclient_12_1
#        echo "export LD_LIBRARY_PATH=$install_dir:\${LD_LIBRARY_PATH:-}" >> /home/domino/.domino-defaults
#        echo "export PATH=$install_dir:\${PATH:-}" >> /home/domino/.domino-defaults
# leads to this in # .domino-defaults (correct):
#        export LD_LIBRARY_PATH=/opt/oracle/instantclient_12_1:${LD_LIBRARY_PATH:-}
#        export PATH=/opt/oracle/instantclient_12_1:${PATH:-}

# In contrast (incorrect):
#   cat <<\EOF > $tempdockerfile
#   RUN <<EOR
#         install_dir=/opt/oracle/instantclient_12_1
#         echo "export LD_LIBRARY_PATH=$install_dir:${LD_LIBRARY_PATH:-}" >> /home/domino/.domino-defaults
#         echo "export PATH=$install_dir:${PATH:-}" >> /home/domino/.domino-defaults
# leads to:
# export LD_LIBRARY_PATH=/opt/oracle/instantclient_12_1:
# export PATH=/opt/oracle/instantclient_12_1:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# instructions:
# https://support.posit.co/hc/en-us/articles/360001770154-Configuring-Oracle-on-RStudio-Connect

#dir=$(dirname $(readlink -f $(dirname "${BASH_SOURCE[0]}")))
#setup=$(find $dir -name build_setup.sh)
#if [[ "$setup" == "" ]] ; then echo "$setup not found." >& 2 ; exit 1 ; fi
#source $setup

tempdockerfile=$(mktemp -u) && echo $tempdockerfile
cat <<\EOF > $tempdockerfile

RUN <<EOR
    set -x
    set -e
    locale-gen --purge en_US.UTF-8
    dpkg-reconfigure --frontend=noninteractive locales
    mkdir -p /scripts
    printf "#!/bin/bash\\nservice ssh start\\n" > /scripts/start-ssh
    chmod +x /scripts/start-ssh
    mkdir -p /home/rr_user/
    echo 'export PYTHONIOENCODING=utf-8' >> /home/rr_user/.domino-defaults
    echo 'export LANG=en_US.UTF-8' >> /home/rr_user/.domino-defaults
    echo 'export JOBLIB_TEMP_FOLDER=/tmp' >> /home/rr_user/.domino-defaults
    echo 'export LC_ALL=en_US.UTF-8' >> /home/rr_user/.domino-defaults

    echo "EST" > /etc/timezone
    dpkg-reconfigure -f noninteractive tzdata
    sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
    echo 'LANG="en_US.UTF-8"' > /etc/default/locale
    dpkg-reconfigure --frontend=noninteractive locales
    update-locale LANG=en_US.UTF-8
    # url=https://s3-us-west-2.amazonaws.com/domino-operations/mirror
    # wget --no-clobber --quiet -O /tmp/oracle-instantclient.rpm $url/oracle-instantclient12.1-basic-12.1.0.2.0-1.x86_64.rpm
    # wget --no-clobber --quiet -O /tmp/oracle-instantclient-devel.rpm $url/oracle-instantclient12.1-devel-12.1.0.2.0-1.x86_64.rpm
    # alien -i /tmp/oracle-instantclient.rpm
    # alien -i /tmp/oracle-instantclient-devel.rpm
    # rm -rf /tmp/oracle-instantclient.rpm
    # rm -rf /tmp/oracle-instantclient-devel.rpm
    echo "/usr/lib/oracle/12.1/client64/lib" > /etc/ld.so.conf.d/oracle.conf
    ldconfig
    install_dir=/opt/oracle/instantclient_12_1 # was /opt/oracle/instantclient_12_1
    mkdir -p $install_dir
    url=https://github.com/f00b4r/oracle-instantclient/raw/master
    zip1=instantclient-basic-linux.x64-12.1.0.2.0.zip
    zip2=instantclient-sdk-linux.x64-12.1.0.2.0.zip
    wget --quiet --no-clobber -P /tmp $url/$zip1 $url/$zip2
    cd /opt/oracle
    unzip /tmp/$zip1
    unzip /tmp/$zip2
    cd $install_dir
    ln -s libclntsh.so.12.1 libclntsh.so
    ln -s libocci.so.12.1 libocci.so

    echo "export LD_LIBRARY_PATH=$install_dir:\${LD_LIBRARY_PATH:-}" >> /home/rr_user/.domino-defaults
    echo "export PATH=$install_dir:\${PATH:-}" >> /home/rr_user/.domino-defaults
    # chown -R domino:domino /home/domino
    chown -R rr_user:rr_user /home/rr_user
    cat /home/rr_user/.domino-defaults
    rm -fr /tmp/*
    # apt autoremove -y
    # apt autoclean -y
EOR

EOF
