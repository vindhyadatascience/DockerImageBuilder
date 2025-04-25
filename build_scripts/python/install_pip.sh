#!/bin/bash

set -e

setup=$1
if [[ ! "$setup" == "" ]] ; then
  if [[ ! -e "$setup" ]] ; then echo "$setup not found"  >& 2 ; exit 1 ; fi
    source $setup
fi

if [[ "$BUILD_PREFIX" == "" ]] ; then echo "BUILD_PREFIX is undefined" >& 2 ; exit 1 ; fi

err=0

detect_python_versions() {
    local versions=()
    if command -v python2 &> /dev/null; then
        versions+=("2")
    fi
    if command -v python3 &> /dev/null; then
        versions+=("3")
    fi
    echo "${versions[@]}"
}

install_pip() {
    local version=$1
    local package_name
    
    if [ "$version" == "2" ]; then
        package_name="python-pip"
    else
        package_name="python3-pip"
    fi
    
    echo "Checking if pip for Python $version is already installed..."
    if python$version -m pip --version &> /dev/null; then
        echo "pip for Python $version is already installed."
        return 0
    fi

    echo "Attempting to install pip for Python $version..."
    if sudo apt-get install -y "$package_name"; then
        echo "Successfully installed $package_name"
    else
        echo "Failed to install $package_name. This may not be available for Python $version on your system."
        if [ "$version" == "2" ]; then
            echo "Python 2 is deprecated. Consider using Python 3 instead."
        fi
        err=1
        return 1
    fi

    # Verify installation
    if python$version -m pip --version &> /dev/null; then
        echo "pip for Python $version installed and verified successfully."
    else
        echo "Failed to verify pip installation for Python $version."
        err=1
        return 1
    fi
}

install_pip_get_pip() {
    local version=$1
    local get_pip_url="https://bootstrap.pypa.io/get-pip.py"
    
    if [ "$version" == "2" ]; then
        get_pip_url="https://bootstrap.pypa.io/pip/2.7/get-pip.py"
    fi

    echo "Attempting to install pip for Python $version using get-pip.py..."
    if wget -O get-pip.py "$get_pip_url" && sudo python$version get-pip.py; then
        echo "Successfully installed pip for Python $version using get-pip.py"
        rm get-pip.py
        return 0
    else
        echo "Failed to install pip for Python $version using get-pip.py"
        rm -f get-pip.py
        return 1
    fi
}

# Check if we're on an Ubuntu system
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$ID" != "ubuntu" ]]; then
        echo "This script is intended for Ubuntu systems only." >&2
        exit 1
    fi
else
    echo "Unable to determine the operating system." >&2
    exit 1
fi

# Detect installed Python versions
python_versions=($(detect_python_versions))

if [ ${#python_versions[@]} -eq 0 ]; then
    echo "No Python installation detected. Please install Python before running this script." >& 2
    exit 1
fi

# Update package lists
sudo apt-get update

# Install pip for each detected Python version
for version in "${python_versions[@]}"; do
    if ! install_pip "$version"; then
        echo "Attempting alternative installation method for Python $version..."
        if ! install_pip_get_pip "$version"; then
            echo "All installation methods failed for Python $version."
            err=1
        fi
    fi
done

if ((err)) ; then
    echo "Pip installation failed for one or more Python versions." >& 2
    exit 1
else
    echo "Pip installation succeeded for all detected Python versions!" >& 2
    exit 0
fi