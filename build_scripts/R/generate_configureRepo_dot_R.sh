#!/bin/bash

set -e

# 2023/10/15 - replaced Bioconductor source with env vars, added data/experiment
# before:
# "https://bioconductor.org/packages/${Bioconductor_version}/bioc",
# "https://bioconductor.org/packages/${Bioconductor_version}/data/annotation",
# after:
# "${R_repo_bioconductor}",
# "${R_repo_bioconductor_experimental}"
# "${R_repo_bioconductor_annotation}"

build_setup=$1
outputfile=$2

this_script=${BASH_SOURCE[0]}

if [[ "$build_setup" == "" ]] ; then echo "specify setup file with build env variables" >& 2 ; exit 1 ; fi
if [[ ! -e "$build_setup" ]] ; then echo "$build_setup not found"  >& 2 ; exit 1 ; fi
if [[ "$outputfile" == "" ]] ; then echo "specify outputfile" >& 2 ; exit 1 ; fi

source $build_setup

#if [[ "$BUILD_PREFIX" == "" ]]; then echo "BUILD_PREFIX is not defined" >& 2 ; exit 1 ; fi
if [[ "$local_cache_dir" == "" ]]; then echo "local_cache_dir is not defined" >& 2 ; exit 1 ; fi
if [[ "$Bioconductor_version" == "" ]]; then echo "Bioconductor_version is not defined" >& 2 ; exit 1 ; fi
if [[ "$R_local_repo" == "" ]] ; then echo "R_local_repo is not defined" >& 2 ; exit 1 ; fi
if [[ "$R_repo_bran" == "" ]] ; then echo "R_repo_bran is not defined" >& 2 ; exit 1 ; fi
if [[ "$R_repo_bioconductor" == "" ]] ; then echo "R_repo_bioconductor is not defined" >& 2 ; exit 1 ; fi
if [[ "$R_repo_bioconductor_experimental" == "" ]] ; then echo "R_repo_bioconductor_experimental is not defined" >& 2 ; exit 1 ; fi
if [[ "$R_repo_bioconductor_annotation" == "" ]] ; then echo "R_repo_bioconductor_annotation is not defined" >& 2 ; exit 1 ; fi

# BiocManager::repositories() in an R console to check where BiocManager will look for Bioconductor and CRAN packages.
# This should show the repository URLs configured above. You can also list available packages using BiocManager::available(), or install a package using

if [[ -e $outputfile ]] ; then make_numbered_file_backup_or_quit $outputfile ; fi
#echo "creating $outputfile programmatically from $this_script" >& 2
#echo "" >& 2
cat <<EOF > $outputfile
# programmatically generated with ${this_script}

## These settings are designed to configure your R session to use the BRAN custom package repository. The values set are interpreted by
## the myRepository package. To use your internal repository, you should do ONE of the following:
##     * Copy-paste the contents of this file into an active R session
##     * source() this file, either by URL or by file path (presuming your repository's file system is locally mounted)
## To silence status messages when this file is loaded, add to your .Rprofile:
##    options( myRepoQuiet=TRUE )
### --- Configuration settings for the 'myRepository' package: ---

## Defining your internal and external repositories. Requests to install packages will reference the first repository found in this
## vector that contains the request. This option is the most important one to allow install.packages to utilize your custom repository!

confV  <- "2019-04-02" # Configuration file version
bcVers <- "${Bioconductor_version}" # previously hard-coded


options(repos=stats::setNames(c("${R_repo_bms_cran}",
                                "${R_repo_bran}",
                                "${R_repo_bioconductor}",
                                "${R_repo_bioconductor_annotation}",
                                "${R_repo_bioconductor_experimental}",
                                "${R_repo_bms_revealukb}",
                                "${R_repo_bms_cg_biogit_bran}"),
                               c('CRAN', "BRAN", 'Bioconductor', 'BioCdata', 'BioCexp','revealukb', 'cg-biogit')
                              )
        )

options( myRepoOptions = list(
             
    ## Define the name of your local repository - this is mostly aesthetic
    Name="BRAN",
    
    ## A description of your repositroy (entirely aesthetic):
    Description="Bms R pAckage repositorNy",
    
    ## The local filesystem path of the repo, needed for modifying the
    ## repository. IMPORTANT if you wish to CONTRIBUTE packages!
    Path="/BRAN",
    
    ## The URL to the repository, needed to load information over HTTP/HTTPS
    ## IMPORTANT if you wish to USE packages!
    URL="http://bran.pri.bms.com/",

    ## The URL (or path, if URL is blank) to this configuration script:
    Configure="http://bran.pri.bms.com/resources/configureRepo.R",
    
    ## The CRAN mirror you wish to use. If @CRAN@, will let (make) you
    ## choose each session you interact with CRAN, eg install.packages
    ## IMPORTANT in almost all cases!
    # CRAN=c('https://cran.cnr.berkeley.edu'), 2023/05/01 - no longer active
    CRAN=c('https://cran.case.edu/'),
    
    ## Optional *nix group, applied to user-created files and directories
    ## Usually important if you are contributing packages as a team effort
    Group="bioinfo",
    
    ## Optional domain name for your organization, used to alert users
    ## that an email template might be to people outside your team
    OrgDomain="bms.com",
    
    ## Optional folder for holding built tar.gz archives
    Releases="packageReleases",

    ## Optional folder for holding PDF documentation
    Documentation="packageDocumentation"
))

## AnnotatedMatrix default directory:
options(annotatedmatrixdir="/stash/data/resources/MatrixFiles/byAuthority")

## Provide some feedback
.myRepoVB   <- is.null(getOption("myRepoQuiet")) || !getOption("myRepoQuiet")[1]
.nowInstall <- grepl('^/tmp/.+R\\\\.INSTALL', getwd()) # Does it look like we're in install.packages?

if (.myRepoVB && !.nowInstall) {
    .myRepoName <- getOption("myRepoOptions")\$Name
    .myRepoVers <- utils::installed.packages()
    .myRepoVers <- .myRepoVers[ which(rownames(.myRepoVers) == "myRepository"),
                               "Version"]
    ## Remind our users that BRAN is now 'available', and myRepository
    ## can be used to aid in package development:
    message("Internal ", .myRepoName, " repository will be consulted by install.packages()")
    message(paste0("  BioConductor: ", bcVers))
    if (length(.myRepoVers) == 0) {
        ## Not currently installed
        message("Additional development tools are available via:\n", "  install.packages('myRepository')")
        ## Initially I also auto-attached (library()'ed) myRepository if it was available. THIS IS A BAD IDEA. It causes
        ## significant problems when trying to install.package() newer versions of myRepository *or* any of the dependent packages.
    } else {
        message(sprintf("myRepository %s available via %s\n  More help: %s", .myRepoVers[1],
                        crayon::magenta("library('myRepository')"), crayon::magenta("?myRepository")))
    }
    rm(".myRepoName", ".myRepoVers") # Clean out temp variables
}
rm(".myRepoVB") # Clean out temp variables

# Add our local repository to the repo list
# previously took place in initial steps of R package installation
x=options("repos")
x\$repos["extras"]="file://${R_local_repo}"
options(repos=x\$repos)
rm(x)
EOF

# x\$repos["extras"]="file://${R_local_repo}"
# should be "file:///opt/tbio/domino_202212/src/R-4.2.1/r_package_tarballs"
# not file:///opt/tbio/domino_202212/src/R-4.2.1/r_package_tarballs/src/contrib"

