#!/bin/bash

# to do: include Jupyter kernel setup here instead of later

# note: this is not included in the 2023/08 image

# 2023/10/20 updates for scanorama, scikit-learn-telex
# import umap leads to CPU warning; this also occurred in prior releases (2022/06)

# previously included a single list for Python 2 and Python 3, which were then skipped in the Python 2 step

# caution: the --ignore-installed option makes any subsequent updates problematic

# note: it seems that numpy is not listed explicitly because it's a dependency of scanpy
# if scanpy is removed, numpy should be restored

python="$1"
version=$($python --version |& awk '{print $2}' | cut -f1-2 -d.)
echo "pip installing python $python, version $version" >& 2

$python -m pip install --upgrade pip

err=0
# scanpy needs numpy<=1.21, so we'll install it first and hope that the remaining modules can use the earlier version.
# tensorflow and louvain removed.
# 2022.09.28 added ipykernel
# 2022/12/14 replaced sklearn (deprecated) with scikit-learn
# 2023/09: no longer installable in Python 2.7: awscli jupyter statsmodels

p2_and_p3="click xlrd xlwt openpyxl pyjwt requests botocore boto3 urllib3 flask flask_cors certifi requests pycryptodome \
        pynacl cx_Oracle scipy matplotlib scikit-learn \
		notebook jupyterlab ipykernel joblib bs4 python-language-server pylint"

p3_only="scanpy pandas pynacl pysqlite3 tensorflow tensorflow_probability umap-learn garnett python-igraph leidenalg scanorama \
        autopep8 flake8 sas_kernel saspy torch louvain scikit-learn-intelex Starfysh awscli jupyter statsmodels macs2" # numpy

# Python 3.13 incompatible packages (removed for 3.13+)
p3_only_exclude_313="macs2"  # macs2 has compatibility issues with Python 3.13

# The tornado does not build a wheel properly at this time (May 5, 2022). However, it does install from source.

# do this for every Python 3 version?
if [[ "$version" == 3.10 ]] ; then
    if $python -m pip install --upgrade --ignore-installed --no-cache-dir tornado ; then
		echo "tornado installed successfully"  >& 2
    else
		echo "tornado installed failed."  >& 2
		err=1
    fi
fi

# Adjust package list for Python 3.13+
if [[ "$version" == 3.13 ]] ; then
    echo "Python 3.13 detected - excluding incompatible packages: $p3_only_exclude_313"  >& 2
    # Remove macs2 from the package list for Python 3.13
    p3_only=$(echo "$p3_only" | sed 's/macs2//g')
fi

if [[ "$version" == 2.7 ]] ; then
    for pkg in $p2_and_p3 ; do
		if [[ "$pkg" == "cx_Oracle" ]] ; then
			pkg='cx_Oracle==7.3.0'
		fi
		if $python -m pip install --upgrade --ignore-installed --no-cache-dir "$pkg" ; then
			echo "$pkg installation succeeded."  >& 2
		else
			err=1
			echo "Failure: $pkg installation error for Python $version."  >& 2
		fi
    done
else
    if $python -m pip install --upgrade --ignore-installed --no-cache-dir $p3_only $p2_and_p3 ; then
		echo "Success - packages installed: $pkgs"  >& 2
    else
		err=1
		echo "Failure: Python $version package installation errors."  >& 2
    fi
fi

if ((err)) ; then
    echo "Some Python package installations failed."  >& 2
    exit 1
else
    echo "Success!"
    exit 0
fi

