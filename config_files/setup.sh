# Setup script for running the Tbio R and other software environment that's on NFS.
export BUILD_PREFIX=/opt/tbio/image_build # must be new dir
export log_dir="logs"
export efs_production_dir=/opt/tbio/prod

export R_version=R-4.5.1
export Bioconductor_version=3.21
export cmdstan_version=2.33.1
export r_config_file=./config_files/rpkg_config.sh
export r_pkg_list_loc=$BUILD_PREFIX/rpkgs.txt

export imagename="local:my_image"
export temp_img_name="my_image"
export Java_version=12.0.1
export JAVA_HOME=$BUILD_PREFIX/binaries/jdk-$Java_version
export PATH=/usr/local/bin:$BUILD_PREFIX/binaries/cmake-3.22.3/bin:$BUILD_PREFIX/binaries/python-3.13.7/bin:$BUILD_PREFIX/binaries/$R_version/bin:$BUILD_PREFIX/bin:$JAVA_HOME/bin:$PATH:/opt/code-server/bin:/usr/lib/rstudio-server/bin/quarto/bin/tools
export PATH=$PATH:$BUILD_PREFIX/Anaconda3/bin # places conda on the path without overriding default Python
export PKG_CONFIG_PATH=$BUILD_PREFIX/lib/pkgconfig
export RETICULATE_PYTHON=$BUILD_PREFIX/binaries/python-3.13.7/bin/python3
export OCI_LIB=/opt/oracle/instantclient_12_1
export TZ="America/New_York"
export Julia_version=1.9.3 # possibly superfluous
export LD_LIBRARY_PATH=$BUILD_PREFIX/lib/:${LD_LIBRARY_PATH}
export CMDSTAN_PATH=$BUILD_PREFIX/binaries/cmdstan-$cmdstan_version
export PYTHON_VERSION="3.13.7" #,3.10.2,3.9.10,3.8.12" # comma delimited list

# export http_proxy=http://proxy-server.bms.com:8080
# export HTTP_PROXY=http://proxy-server.bms.com:8080
# export https_proxy=http://proxy-server.bms.com:8080
# export HTTPS_PROXY=http://proxy-server.bms.com:8080
# export ftp_proxy=http://proxy-server.bms.com:8080
# export FTP_PROXY=http://proxy-server.bms.com:8080
# export no_proxy=.bms.com,169.254.169.254,localhost
# export NO_PROXY=.bms.com,169.254.169.254,localhost
