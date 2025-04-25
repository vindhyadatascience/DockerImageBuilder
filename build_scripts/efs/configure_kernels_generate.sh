#!/bin/bash -x

# takes place in two steps because executables are not visible inside the image
# creates Jupyter kernel config files for R and Python, creates a zip file later unzipped by docker/configure_kernels_copy.sh

set -e

build_setup=$1
if [[ "$build_setup" == "" ]] ; then echo "specify setup file with build env variables" >& 2 ; exit 1 ; fi
if [[ ! -e "$build_setup" ]] ; then echo "$build_setup not found"  >& 2 ; exit 1 ; fi
source $build_setup

if [[ "$BUILD_PREFIX" == "" ]]; then echo "BUILD_PREFIX is not defined" >& 2 ; exit 1 ; fi
if [[ "$R_version" == "" ]]; then echo "R_version is not defined" >& 2 ; exit 1 ; fi
if [[ "$jupyter_kernels_zip" == "" ]]; then echo "jupyter_kernels_zip is not defined" >& 2 ; exit 1 ; fi
if [[ "$jupyter_kernels_dir" == "" ]]; then echo "jupyter_kernels_dir is not defined" >& 2 ; exit 1 ; fi
if [[ "$efs_cache_dir" == "" ]]; then echo "efs_cache_dir is not defined" >& 2 ; exit 1 ; fi
if [[ "$build_binaries_dir" == "" ]]; then echo "build_binaries_dir is not defined" >& 2 ; exit 1 ; fi

# easier if run as user domino
${build_binaries_dir}/${R_version}/bin/Rscript -e "IRkernel::installspec(name = \"${R_version}\", displayname = \"${R_version}\", prefix=\"/home/rr_user/.local\")" 

# Install ipykernel using pip instead of conda
python3 -m pip install --quiet ipykernel

# Install kernels for each Python version
for python in $(ls ${BUILD_PREFIX}/*/bin/python? ${build_binaries_dir}/*/bin/python? -d) ; do
  name=$(echo $python | rev | cut -d / -f 3|rev)
  $python -m pip install --quiet ipykernel
  $python -m ipykernel install --name $name --prefix=/home/rr_user/.local
done

# Set permissions
# chown -R domino:domino /home/domino/
chown -R rr_user:rr_user /home/rr_user/

# Create zip file with kernel specifications
cd $jupyter_kernels_dir
rm -f $efs_cache_dir/$jupyter_kernels_zip 2> /dev/null
zip -r $efs_cache_dir/$jupyter_kernels_zip *

# #!/bin/bash -x

# # takes place in two steps because executables are not visible inside the image
# # creates Jupyter kernel config files for R and Python, creates a zip file later unzipped by docker/configure_kernels_copy.sh

# set -e

# build_setup=$1
# if [[ "$build_setup" == "" ]] ; then echo "specify setup file with build env variables" >& 2 ; exit 1 ; fi
# if [[ ! -e "$build_setup" ]] ; then echo "$build_setup not found"  >& 2 ; exit 1 ; fi
# source $build_setup

# if [[ "$BUILD_PREFIX" == "" ]]; then echo "BUILD_PREFIX is not defined" >& 2 ; exit 1 ; fi
# if [[ "$R_version" == "" ]]; then echo "R_version is not defined" >& 2 ; exit 1 ; fi
# if [[ "$jupyter_kernels_zip" == "" ]]; then echo "jupyter_kernels_zip is not defined" >& 2 ; exit 1 ; fi
# if [[ "$jupyter_kernels_dir" == "" ]]; then echo "jupyter_kernels_dir is not defined" >& 2 ; exit 1 ; fi
# if [[ "$efs_cache_dir" == "" ]]; then echo "efs_cache_dir is not defined" >& 2 ; exit 1 ; fi
# if [[ "$build_binaries_dir" == "" ]]; then echo "build_binaries_dir is not defined" >& 2 ; exit 1 ; fi


# # easier if run as user domino
# ${build_binaries_dir}/${R_version}/bin/Rscript -e "IRkernel::installspec(name = \"${R_version}\", displayname = \"${R_version}\", prefix=\"/home/domino/.local\")" 
# ${BUILD_PREFIX}/Anaconda3/bin/conda info
# ${BUILD_PREFIX}/Anaconda3/bin/conda install -q -y -c anaconda ipykernel
# ${BUILD_PREFIX}/Anaconda3/bin/conda clean --all -y -q
# for python in $(ls ${BUILD_PREFIX}/Anaconda3/bin/python? ${build_binaries_dir}/*/bin/python? -d) ; do
#   name=$(echo $python | rev | cut -d / -f 3|rev)
#   $python -m ipykernel install --name $name --prefix=/home/domino/.local
# done
# chown -R domino:domino /home/domino/
# cd $jupyter_kernels_dir
# rm -f $efs_cache_dir/$jupyter_kernels_zip 2> /dev/null
# zip -r $efs_cache_dir/$jupyter_kernels_zip *