# Configuration ----

## Set parallelization
options(Ncpus = parallel::detectCores())

## Get R package list file from environment
rpkg_tbl_file <- Sys.getenv(
    x="R_package_list",
    unset="config_files/R_packages/rpkgs_default.txt"
)

## Get custom R repositories from environment
env_vars <- Sys.getenv()
repo_env_vars <- grep("^R_repo", names(env_vars), value=TRUE)
if (identical(repo_env_vars, character(0))) {
    custom_repos <- c()
} else {
    custom_repos <- env_vars[repo_env_vars]
    names(custom_repos) <- sub("R_repo_", "", names(custom_repos))
}

# Install required packages ----

## Install BiocManager
if (!requireNamespace("BiocManager", quietly=TRUE)) {
    install.packages("BiocManager")
}

## Install remotes
if (!requireNamespace("remotes", quietly=TRUE)) {
    install.packages("remotes")
}

## Install pak
if (!requireNamespace("pak", quietly=TRUE)) {
    install.packages(
        pkgs = "pak",
        repos = sprintf(
            "https://r-lib.github.io/p/pak/%s/%s/%s/%s",
            "stable",
            .Platform$pkgType,
            R.Version()$os,
            R.Version()$arch
        )
    )
    pak::pak_install_extra()
}

# Configure repos ----

## Default repos
repos <- getOption("repos")

## Bioc repos
bioc_repos <- BiocManager::repositories()

## Remove duplicate repos
all_repos <- c(repos, bioc_repos, custom_repos)
unique_repos <- all_repos[!duplicated(all_repos)]

## Set repositories
options(repos = unique_repos)


# Read in package list ----

## Read with base R and extract first column
rpkg_tbl <- read.table(
    file=rpkg_tbl_file,
    sep="\t", 
    header=FALSE,
    quote="",
    fill=TRUE, 
    comment.char="#"
)
rpkgs <- rpkg_tbl[[1]]


# Parse R package list with pak ----

## Get dependency table using pak
## Supposedly the table is in the
## correct installation order by
## dependencies.
## This list should also include
## all the target packages.
deps <- pak::pkg_deps(rpkgs)

## Install system dependencies first
## Pre-install scripts
pre_install <- unique(deps$sysreqs_pre_install)
pre_install <- pre_install[pre_install != ""]
lapply(pre_install, system) |> setNames(pre_install)

## Install scripts
cmd_install <- unique(deps$sysreqs_install)
cmd_install <- cmd_install[cmd_install != ""]
lapply(cmd_install, system) |> setNames(cmd_install)

## Post install scripts
post_install <- unique(deps$sysreqs_post_install)
post_install <- post_install[post_install != ""]
lapply(post_install, system) |> setNames(post_install)


# Install packages ----

## Remove "installed" from dependency list
deps <- deps[deps$type != "installed",]

## Install packages according to their source
## in a loop. Note that pak will break if used
## and they are done in a loop to respect the 
## installation order from the dep table.
for (row in seq_len(nrow(deps))) {
    package <- deps[row, "package"]
    type <- deps[row, "type"]
    ref <- deps[row, "ref"]
    print(paste0("Installing package ", package, " (", row, "/", nrow(deps), ")"))

    ## Check if package is installed
    if (package %in% installed.packages()) {
        print(paste0("Package ", package, " is already installed."))
        next
    }

    ## Install "standard" (cran-like and bioc)
    ## BiocManager will automatically determine whether
    ## the package is from CRAN or Bioconductor and
    ## install it.
    if (type == "standard") {
        BiocManager::install(ref, ask=FALSE)
    }

    if (type == "github") {
        remotes::install_github(ref, ask=FALSE)
    }

    if (type == "url") {
        ref <- sub("url::", "", ref)
        remotes::install_url(ref, ask=FALSE)
    }
}

## Confirm packages are installed
if (all(deps$package %in% installed.packages())) {
    print("All R packages successfully installed!")
} else {
    print("The following R packages were not installed:")
    deps$package[which(!deps$package %in% installed.packages())]
}



