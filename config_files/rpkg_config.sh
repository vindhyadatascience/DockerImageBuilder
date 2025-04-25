#!/bin/bash

## R package installation ####

## Single column list of R packages to install.
## Format:
##  GitHub repos: repository/packagename
##     CRAN/BIOC: packagename
##           URL: url::https://path/to/package.tar.gz    
export R_package_list=$r_pkg_list_loc

## Set GitHub Personal Access Token (PAT)
## for accessing packages through GitHub.
export GITHUB_PAT=

# Custom repositories for R packages.
# These will be added to options("repos")
# along with the default CRAN and BIOC repos
# for the specified R version.
# Preface these variables with "R_repo_".
# example
# export R_repo_prod_cran=https://my_pkg_mngr.bms.com/prod

# need to add these lines to get this to work in ubuntu 18.04
add-apt-repository universe
apt-get update
## Custom package system dependencies.
## Most system dependencies are captured
## by pak. However, sometimes there are
## system requirements (like python package)
## dependencies that need to be included.
## Install these here.
apt-get install -y python3-pip #Essential for ontoProc package
pip install owlready2 #Essential for ontoProc package