#!/usr/bin/env python

'''
2023/10/15 - updated R package installation due to skipping by BiocManager::install
- added R_repo_bioconductor_experimental (https://bioconductor.org/packages/$Bioconductor_version/data/experiment) to configureRepo.R via generate_configureRepo_dot_R.sh
- replaced:
    BiocManager::install("{pkg}", version="{bioconductor_version}", configure_vars={_configvars}, update=TRUE, ask=FALSE);
  with:

# to do:


- install.packages is a better option than BiocManager::install for Bioconductor packages; if already installed as a dependency, bioconductor skips it even

  with dep=true (setting --force=T only installs a subset of all packages that come via )
- restore destdir
- update=True, force=True
- grep re-install
package(s) not installed when version(s) same as or greater than current; use
  `force = TRUE` to re-install: 'AnnotationHub'



note: actual cran is decided by build_setup.sh

Generates batches of files for rsync based on specified target size for each layer.
Any file that exceeds max size is transferred in a batch by itself.
The last batch is split among previous batches since it's typically much smaller.

This script assumes that Python 3 is installed.

NOTE: 

  Batches contain only regular files, which excludes:
  -  directories
  -  symbolic links 
  - file names containing commas (R)

  It's assumed that directory sync takes place first, then regular files, then everything remaining.
  
  The destination dir is removed from file paths.

'''

import sys, os, re, argparse
import pandas as pd
from datetime import datetime as dt
import numpy as np

class ArgsClass():
    def append_allowed_values(self, help_message, allowed_values):
        return help_message + " Allowed values: " + ", ".join(allowed_values)

    def append_default(self, help_message, default_value):
        return help_message + " Default = %s." % (str(default_value))

    def __init__(self):

        _help = 'Generate scripts for Docker image build.'
        self.parser = argparse.ArgumentParser(description = _help)
        subparsers = self.parser.add_subparsers(help='sub-command help')
        _help_message = {}
        '''
        to do: split into sub-sub-parsers by build stage
        _sub_subparsers = {}

        _help_message["self_contained"] = "Generate scripts for self-contained image stage."
        _help_message["R_packages"] = "Generate scripts for R package installation stage."

        _help_message["get_source_files"] = "Self-contained image: make a list of regular files with actual file size."
        _help_message["make_file_batches"] = "Self-contained image: generate batch files (i.e., lists of regular files) to rsync in each layer."
        _help_message["R_package_install_script"] = "Generate script to install R packages."
        _help_message["R_check_install_script"] = "Generate script to check R package installation."
        
        '''
        _help_message["sc_get_source_files"] = "Self-contained image: make a list of regular files with actual file size."
        _help_message["sc_make_file_batches"] = "Self-contained image: generate batch files (i.e., lists of regular files) to rsync in each layer."
        _help_message["R_bioc_install_script"] = "Generate script to install Biocmanager and drat."
        _help_message["R_package_install_script_v2"] = "Generate script to install R packages."
        _help_message["R_package_install_script"] = "Generate script to install R packages."
        _help_message["R_check_install_script"] = "Generate script to check R package installation."
        _help_message["R_dependencies"] = "Generate script to find R package dependencies using pak."
        _help_message["R_installed_packages"] = "Generate command to output installed R packages."
        #all_functions = _help_message.keys()

        _subparser = {}
        for _fn in _help_message.keys():
            _subparser[_fn] = subparsers.add_parser(_fn, help=_help_message[_fn])
            _subparser[_fn].set_defaults(func=_fn)

        _sub_subparsers = {}
        _name = self.INPUT_DIR = "inputdir"
        _help = "Where to look for files."
        for _fn in "sc_get_source_files".split():
            _subparser[_fn].add_argument('--' + _name, "-i", type=str, required = True, help= _help)

        _name = self.OUTPUT_FILE_PREFIX = "outputfileprefix"
        _help = "Prefix for output files."
        _default = "rsync_batches"
        _help = self.append_default(_help, _default)
        for _fn in "sc_make_file_batches".split():
            _subparser[_fn].add_argument('--' + _name, "-o", type=str, required = False, help= _help, default=_default)

        _name = self.MAX_BATCH_SIZE = "max_size_per_layer"
        _help = "Maximum size per layer, in bytes." # Every batch but the last exceeds this target."
        _default = 1200000000
        _help = self.append_default(_help, _default)
        for _fn in "sc_make_file_batches".split():
            _subparser[_fn].add_argument('--' + _name, "-b", type=int, required = False, help= _help, default=_default)

        _name = self.FILE_SIZES = "file_sizes"
        _help = "Output file."
        _default = "source_files"
        _help = self.append_default(_help, _default)
        for _fn in "sc_get_source_files".split():
            _subparser[_fn].add_argument('--' + _name, "-s", type=str, required = False, help= _help, default=_default)

        _name = self.FILE_SIZES = "file_sizes"
        _help = "Input file with file path and size for regular files."
        _default = "source_files"
        _help = self.append_default(_help, _default)
        for _fn in "sc_make_file_batches".split():
            _subparser[_fn].add_argument('--' + _name, "-s", type=str, required = False, help= _help, default=_default)

        _name = self.INPUT_FILE = "inputfile"
        _help = "R package manifest (e.g. R_packages_list.txt)."
        for _fn in "R_package_install_script R_check_install_script R_package_install_script_v2".split(): # R_dependencies
            _subparser[_fn].add_argument('--' + _name, "-i", type=str, required = True, help= _help)

        _name = self.PACKAGES = "packages"
        _help = "R packages separated by spaces"
        for _fn in "R_dependencies".split(): # R_dependencies
            _subparser[_fn].add_argument('--' + _name, "-p", type=str, required = True, help= _help, nargs="+")

        _name = self.OUTPUT_FILE = "outputfile"
        _help = "Output file. Omit for stdout."
        for _fn in "R_package_install_script R_check_install_script R_bioc_install_script R_package_install_script_v2 R_dependencies R_installed_packages".split():
            _subparser[_fn].add_argument('--' + _name, "-o", type=str, required = False, help= _help)

        _name = self.BIOCONDUCTOR_VERSION = "bioconductor_version"
        _help = "Bioconductor version"
        for _fn in "R_package_install_script".split():
            _subparser[_fn].add_argument('--' + _name, "-b", type=str, required = True, help= _help)

        _name = self.BUILD_SETUP = "build_setup"
        _help = "bash script with build env vars"
        for _fn in "R_package_install_script_v2 R_bioc_install_script R_check_install_script".split():
            _subparser[_fn].add_argument('--' + _name, "-b", type=str, required = True, help= _help)

        _name = self.BUILD_SETUP = "build_setup"
        _help = "bash script with build env vars"
        for _fn in "R_installed_packages".split():
            _subparser[_fn].add_argument('--' + _name, "-b", type=str, required = False, help= _help)

        _name = self.BUILD_PREFIX = "build_prefix"
        _help = "BUILD_PREFIX"
        for _fn in "R_package_install_script".split():
            _subparser[_fn].add_argument('--' + _name, "-p", type=str, required = True, help= _help)

        _name = self.TARBALL_DEST = "tarballdest"
        _help = "destination subfolder for R installation tarballs, likely tar-balls/src/contrib"
        for _fn in "R_package_install_script".split():
            _subparser[_fn].add_argument('--' + _name, "-d", type=str, required = True, help= _help)

        _name = self.CPUS = "cpus"
        _help = "Number of CPUs to use during installation."
        _default = int(execute_command("grep -c ^processor /proc/cpuinfo")[0])
        _help = self.append_default(_help, _default)
        for _fn in "R_package_install_script R_package_install_script_v2".split():
            _subparser[_fn].add_argument('--' + _name, "-c", type=int, required = False, help= _help, default=_default)

        _name = self.MAX_PACKAGES = "maxpackages"
        _help = "Max packages to install in one step. Reverts to 1 for github etc."
        _default = 50
        _help = self.append_default(_help, _default)
        for _fn in "R_package_install_script_v2".split():
            _subparser[_fn].add_argument('--' + _name, "-m", type=int, required = False, help= _help, default=_default)

        _name = self.LANGUAGE = "language"
        _help = "Language of output, bash or R"        
        for _fn in "R_check_install_script".split():
            _subparser[_fn].add_argument('--' + _name, "-l", type=str, required = True, help= _help, choices=["R", "bash"])

        '''
        _name = self.R_SCRIPT = "R_script"
        _help = "R script to run for each package if language is bash"
        for _fn in "R_check_install_script".split():
            _subparser[_fn].add_argument('--' + _name, "-r", type=str, required = False, help= _help)
        '''
        _name = self.TARBALL_SRC = "tarballsource"
        _help = "source subfolder for R installation tarballs, likely r_package_tarballs/src/contrib"
        for _fn in "R_package_install_script".split():
            _subparser[_fn].add_argument('--' + _name, "-s", type=str, required = True, help= _help)

        _name = self.IMAGE = "image"
        _help = "Image in which to run the command via docker run. Defaults to current environment."
        for _fn in "R_installed_packages".split():
            _subparser[_fn].add_argument('--' + _name, "-i", type=str, required = False, help= _help)
        
def log_message(message, _exit_on_error=False):
    print(message, file=sys.stderr)
    if _exit_on_error: sys.exit(1)

def execute_command(command_as_text): #, _exit_on_error=False):
    # returns a list, empty if no output
    import subprocess
    #log_message(f"# running {command_as_text}", _exit_on_error=False)
    try:
        output = subprocess.check_output(command_as_text, shell=True, stderr=subprocess.STDOUT)
    except:
        log_message(f"Execution of {command_as_text} failed.")
        return []
    return [line.decode("utf8").rstrip() for line in output.splitlines()]

def get_env_vars(bash_script = None, required = None):
    if not os.path.exists(bash_script):
        log_message(f"{bash_script} not found.", _exit_on_error=True)
    build_setup = {}
    for line in execute_command(f"source {bash_script} && env"):
        temp = line.split("=")
        if len(temp) == 2: build_setup[temp[0]] = temp[1]
    if required:
        if missing := set(required) - set(build_setup.keys()):
            missing = "\n".join(list(missing))
            log_message(f"Undefined env vars:\n{missing}", _exit_on_error=True)
    return build_setup

def get_file_size(file=None):
    return os.stat(file).st_size

def get_file_details(file=None):
    temp = os.stat(file)
    return temp.st_size, temp.st_atime, temp.st_mtime, temp.st_ctime
    # st_atime: Time of last access.
    # st_mtime: Time of last modification.
    # st_ctime: time of the last metadata change

def remove_input_dir_path_from_file_paths(data=None, leader = None):
    # data = list of paths
    letters = len(leader)
    newpaths = [x[letters:] for x in data if x.startswith(leader)]
    if len(newpaths) != len(data):
        print_error("input dir was not found in some file paths", _exit_on_error=True)
    return newpaths

def sc_get_source_files(args=None, arg_def=None):
    inputdir = args[arg_def.INPUT_DIR]
    outputfile = args[arg_def.FILE_SIZES]
    if os.path.exists(outputfile):
        log_message(f"{outputfile} exists.", _exit_on_error=True)
    if not os.path.exists(inputdir):
        log_message(f"{inputdir} not found.", _exit_on_error=True)
    files = pd.DataFrame(execute_command(f"find {inputdir} -type f"), columns = ["path",])
    #files["size"] = files["path"].apply(get_file_size)
    files[["size", "atime", "mtime", "ctime"]] = files.apply(lambda x: get_file_details(x["path"]), axis=1, result_type="expand")

    _replace = inputdir.rstrip("/") + "/"
    files["path"] = remove_input_dir_path_from_file_paths(data=files["path"], leader = _replace)

    # some R files contain commas; rsync fails if file names are specified, succeeds later in final rsync with symbolic links etc. 
    mask = files["path"].str.contains(",")
    files = files[~mask].copy()

    # 2023/01/08 - don't include transfer dir; this will be included in final sync but must then be deleted
    mask = files["path"].str.startswith("transfer/")
    files = files[~mask].copy()

    files.to_csv(outputfile, sep="\t", index=False)

def sc_make_file_batches(args=None, arg_def=None):
    '''
    path    size
    /opt/tbio/domino_202212/transfer/README.txt     308
    /opt/tbio/domino_202212/transfer/Python-3.10.2_setup.py 116619
    /opt/tbio/domino_202212/transfer/Python-3.10.6_setup.py 116893
    '''
    inputfile = args[arg_def.FILE_SIZES]
    if os.path.exists(inputfile):
        file_sizes = pd.read_csv(args[arg_def.FILE_SIZES], header=0, sep="\t")
    else:
        log_message(f"Input file {inputfile} not found.", _exit_on_error=True)
    outputfileprefix = args[arg_def.OUTPUT_FILE_PREFIX]
    if os.path.exists(outputfileprefix  + ".1"):
        log_message("output file(s) found", _exit_on_error=True)

    max_size_per_layer = args[arg_def.MAX_BATCH_SIZE] 

    # some R files contain commas; rsync fails if file names are specified, succeeds later in final rsync with symbolic links etc. 
    mask = file_sizes["path"].str.contains(",")
    file_sizes = file_sizes[~mask].copy()

    file_sizes = file_sizes.sort_values(by="size",ascending=False).set_index("path")
    file_sizes["batch"] = 0
    maxbatch = 1
    minbatch = 1 # when reshuffling large batch, skip early batches with big files
    batch_totals = {maxbatch : 0}
    for i in file_sizes.index:
        file_size = file_sizes.at[i, "size"]
        if file_size >= max_size_per_layer:
            file_sizes.at[i, "batch"] = maxbatch
            batch_totals[maxbatch] += file_size
            maxbatch += 1
            batch_totals[maxbatch] = 0
            minbatch = maxbatch
        else:
          ok = 0
          for batch in range(minbatch, maxbatch + 1):
              if batch_totals[batch] + file_size <= max_size_per_layer:
                  file_sizes.at[i, "batch"] = batch
                  batch_totals[batch] += file_size
                  ok = 1
                  break
          if ok == 0:
              maxbatch += 1
              batch_totals[maxbatch] = file_size
              file_sizes.at[i, "batch"] = maxbatch

    # redistribute the last batch among the others since it's usually small
    mask = file_sizes["batch"] == maxbatch
    temp = file_sizes[mask].copy()
    file_sizes = file_sizes[~mask].copy()
    temp["batch"] = np.random.randint(low=minbatch, high=maxbatch, size=temp.shape[0])
    file_sizes = pd.concat([file_sizes, temp], sort = False).sort_values(by="batch")
    file_sizes = file_sizes.sort_values(by="batch").reset_index().rename(columns = {"index":"path"})
    for batch, batchdata in file_sizes.groupby("batch"):
        outputfile = outputfileprefix + "." + str(batch)
        #total1 = batch_totals[batch] #* 1024
        total2 = sum(batchdata["size"]) #* 1024
        log_message(f"batch\t{batch}\t{outputfile}\t{total2}\tbytes")
        batchdata[["path"]].to_csv(outputfile, header=None, index=False)

def R_bioc_install_script(args=None, arg_def=None):
    outputfile = args[arg_def.OUTPUT_FILE]
    if outputfile and os.path.exists(outputfile):
        log_message(f"{outputfile} exists.", _exit_on_error=True)
    required = "Bioconductor_version R_repo_cran".split()
    env_vars = get_env_vars(bash_script = args[arg_def.BUILD_SETUP], required = required)
    text="""
options(repos=c(CRAN="%s"));
install.packages("drat", quiet=T);
drat::addRepo("cloudyr", "http://cloudyr.github.io/drat");
install.packages("BiocManager", quiet=T);
BiocManager::install(version="%s", ask=FALSE, update=TRUE);
if (! library(drat, logical.return=TRUE)) {
  quit(status=1);
}
if (! library(BiocManager, logical.return=TRUE)) {
  quit(status=1);
}
quit(status=0)
""" % (env_vars["R_repo_cran"],  env_vars["Bioconductor_version"])
    text = text.lstrip()
    with (open(outputfile, "w") if outputfile else sys.stdout) as tempout:
        print(text, file=tempout)

def R_package_install_script_v2(args=None, arg_def=None):
    # R package list
    inputfile = args[arg_def.INPUT_FILE]
    if not os.path.exists(inputfile):
        log_message(f"{inputfile} not found.", _exit_on_error=True)

    outputfile = args[arg_def.OUTPUT_FILE]
    if outputfile and os.path.exists(outputfile):
        log_message(f"{outputfile} exists.", _exit_on_error=True)

    required = "Bioconductor_version BUILD_PREFIX R_tarball_dest R_tarball_src local_R_package_cache efs_cache_dir".split()
    env_vars = get_env_vars(bash_script = args[arg_def.BUILD_SETUP], required = required)

    bioconductor_version = env_vars["Bioconductor_version"]
    R_tarball_dest = env_vars["R_tarball_dest"]
    R_tarball_src = env_vars["R_tarball_src"].rstrip("/")
    build_prefix = env_vars["BUILD_PREFIX"]

    R_tar_files_dir = os.path.join(env_vars["efs_cache_dir"], env_vars["local_R_package_cache"])
    data = pd.read_csv(inputfile, sep="\t", header=0, dtype=object, comment="#")
    missing_columns = set(["package", "source", "parameters"]) - set(data.columns)
    if missing_columns:
        missing_columns = ", ".join(list(missing_columns))
        log_message(f"columns missing in {inputfile}: {missing_columns}", _exit_on_error=True)
    if args[arg_def.CPUS] > 1:
        cpus = f", Ncpus={args[arg_def.CPUS]}"
    else:
        cpus = ""
    _ldflags = "'" + f"-rpath,{build_prefix}/lib,-rpath,{build_prefix}/lib64" + "'"
    _libs = "'" + f"-L{build_prefix}/lib -L{build_prefix}/lib64" + "'"
    _configvars = (f'"LDFLAGS={_ldflags}  LIBS={_libs}"')
    _dest = '"' + R_tarball_dest + '"'

    with (open(outputfile, "w") if outputfile else sys.stdout) as tempout:
        print('source("configureRepo.R");', file=tempout)
        print('getOption("repos");', file=tempout)
        print('options(timeout=300);', file=tempout)

        for i, row in data.iterrows():
            repo = row["source"] or "unknown"
            pkg = row["package"]
            params = row["parameters"]
        
            # skipping if already installed 
            # print(f'if (nchar(system.file(package="{pkg}"))) message("{pkg} is already installed") else' + " {", file=tempout)

            print(f'', file=tempout)
            print(f'    # about to try installing {pkg} from {repo}"', file=tempout)
            print(f'    message("installing {pkg} from {repo}")', file=tempout)
            if repo == "bioconductor":
                # 2023/10/15: BiocManager::install skips packages if already installed, so dependencies are not installed 
                # omitting dependencies leads to inclusion of c("Depends", "Imports", "LinkingTo"), omission of Suggests (which otherwise leads to excessive packages)
                print(f'    install.packages("{pkg}", configure_vars={_configvars}, quiet=F, keep_outputs=T{cpus});', file=tempout)
                # 2023/10/11: changed update from false to true
                # print(f'    BiocManager::install("{pkg}", version="{bioconductor_version}", configure_vars={_configvars}, update=TRUE, ask=FALSE);', file=tempout)
                # removed 2023/07/10 destdir={_dest}, 
            elif repo in ["bms-cg-biogit-bran", "bms-cran", "bran", "unknown", "revealukb", "local", "cran"]:
                print(f'    install.packages("{pkg}", configure_vars={_configvars}, dependencies=T, quiet=F, keep_outputs=T{cpus});', file=tempout)
                # for local, use package name
                # removed 2023/07/10 destdir={_dest}, 
                '''
                need to revisit - should be the same as bms-cran
                elif repo in ["cran", ]:
                    # necessary for nanostringr due to dependency versions out of sync in bms-cran
                    # is update valid?
                    print(f'    install.packages("{pkg}", repos="https://cloud.r-project.org/", configure_vars={_configvars}, dependencies=T, update=FALSE, quiet=F, keep_outputs=T{cpus});', file=tempout)
                    # removed 2023/07/10 destdir={_dest}, 
                '''
            elif repo == "local_file":
                # unlike  local or local_no_dep, use file name
                print(f'    install.packages("{params}", configure_vars={_configvars}, dependencies=T, quiet=F, keep_outputs=T{cpus});', file=tempout)
                # removed 2023/07/10 destdir={_dest}, 
                '''
                need to revisit - should be the same as bms-cran
                elif repo in ["cran", ]:
                    # necessary for nanostringr due to dependency versions out of sync in bms-cran
                    # is update valid?
                    print(f'    install.packages("{pkg}", repos="https://cloud.r-project.org/", configure_vars={_configvars}, dependencies=T, update=FALSE, quiet=F, keep_outputs=T{cpus});', file=tempout)
                    # removed 2023/07/10 destdir={_dest}, 
                '''
            elif repo == "r-forge":
                print(f'    install.packages("{pkg}", repos="http://R-Forge.R-project.org", configure_vars={_configvars}, dependencies=F, quiet=F, keep_outputs=T{cpus});', file=tempout)
                # removed 2023/07/10 destdir={_dest}, 
            elif repo == "local_no_dep": # was "tarballs":
                # should be the same as local but dep=F
                #print(f'    install.packages("{R_tar_files_dir}/{params}", configure_vars={_configvars}, dependencies=F, quiet=F, keep_outputs=T{cpus});', file=tempout)
                print(f'    install.packages("{pkg}", configure_vars={_configvars}, dependencies=F, quiet=F, keep_outputs=T{cpus});', file=tempout)
            elif repo == "github":
                # 2023/07 - changed depencies to true, 2023/10 reverted to false
                print('    require(devtools);', file=tempout)
                print(f'    devtools::install_github("{params}", dependencies=FALSE, quiet=FALSE, upgrade="never");', file=tempout)
            elif repo == "url":
                print('    require(devtools);', file=tempout)
                print(f'    devtools::install_url("{params}", dependencies=FALSE, quiet=FALSE, upgrade="never");', file=tempout)
            elif repo == "giturl":
                print('    require(devtools);', file=tempout)
                print(f'    devtools::install_git("{params}", dependencies=FALSE, quiet=FALSE, upgrade="never");', file=tempout)
            elif repo == "bitbucket":
                # untested
                print('    require(devtools);', file=tempout)
                print(f'    devtools::install_bitbucket("{params}", dependencies=FALSE, quiet=FALSE, upgrade="never");', file=tempout)
            else:
                log_message(f"Unknown repo {repo} for package {pkg}", _exit_on_error=True, file=tempout)
                #print(f'    install.packages("{pkg}", repos="{repo}", configure_vars={_configvars}, dependencies=T, quiet=F, keep_outputs=T{cpus});', file=tempout)
                # removed 2023/07/10 destdir={_dest}, 
                # log_message(f"Unknown repo {repo} for package {pkg}", _exit_on_error=True, file=tempout)
            print(f'    if (nchar(system.file(package="{pkg}"))) message("{pkg} was installed successfully") else message("{pkg} installation may have failed")', file=tempout)
            #print("    if (nchar(system.file(package="{pkg}"))) {", file=tempout)
            #print("    if (require("{pkg}")) {", file=tempout)
            #print("        message(\"" + pkg + " was installed successfully\")", file=tempout)
            #print("    } else {", file=tempout)
            #print("        message(\"" + pkg + " installation may have failed\") }", file=tempout)
            
            # skipping if already installed
            # print("}", file=tempout)


def R_package_install_script(args=None, arg_def=None):
    inputfile = args[arg_def.INPUT_FILE]
    if not os.path.exists(inputfile):
        log_message(f"{inputfile} not found.", _exit_on_error=True)
    outputfile = args[arg_def.OUTPUT_FILE]
    if outputfile and os.path.exists(outputfile):
        log_message(f"{outputfile} exists.", _exit_on_error=True)
    bioconductor_version = args[arg_def.BIOCONDUCTOR_VERSION]
    dest = args[arg_def.TARBALL_DEST]
    src = args[arg_def.TARBALL_SRC].rstrip("/")
    build_prefix = args[arg_def.BUILD_PREFIX]
    data = pd.read_csv(inputfile, sep="\t", header=0, dtype=object, comment="#")
    missing_columns = set(["package", "source", "parameters"]) - set(data.columns)
    if missing_columns:
        missing_columns = ", ".join(list(missing_columns))
        log_message(f"columns missing in {inputfile}: {missing_columns}", _exit_on_error=True)


    if args[arg_def.CPUS]:
        cpus = f", Ncpus={args[arg_def.CPUS]}"
    else:
        cpus = ""

    # configure_vars=\"LDFLAGS='-rpath," + build_prefix + "/lib,-rpath," + build_prefix + "/lib64'  LIBS='-L" + build_prefix + "/lib -L" + build_prefix + "/lib64'\", 
    # LDFLAGS='-rpath," + build_prefix + "/lib,-rpath," + build_prefix + "/lib64'
    _ldflags = "'" + f"-rpath,{build_prefix}/lib,-rpath,{build_prefix}/lib64" + "'"
    # LIBS='-L" + build_prefix + "/lib -L" + build_prefix + "/lib64'
    _libs = "'" + f"-L{build_prefix}/lib -L{build_prefix}/lib64" + "'"
    _configvars = (f'"LDFLAGS={_ldflags}  LIBS={_libs}"')
    _dest = '"' + dest + '"'
    with (open(outputfile, "w") if outputfile else sys.stdout) as tempout:
        print('source("configureRepo.R");', file=tempout)
        print('getOption("repos");', file=tempout)
        print('options(timeout=120);', file=tempout)

        for i, row in data.iterrows():
            repo = row["source"] or "unknown"
            pkg = row["package"]
            params = row["parameters"]
        
            print(f'if (nchar(system.file(package="{pkg}"))) message("{pkg} is already installed") else' + " {", file=tempout)
            #print("if (require("{pkg}")) {", file=tempout)
            #print("if (nchar(system.file(package="{pkg}"))) {", file=tempout)
            #print("    message(\"" + pkg + " is already installed\")", file=tempout)
            #print("} else {", file=tempout)
            print(f'    message("installing {pkg} from {repo}")', file=tempout)
            if repo == "bioconductor":
                #print("    BiocManager::install("{pkg}", version = \"" + bioconductor_version + "\", configure_vars=\"LDFLAGS='-rpath," + build_prefix + "/lib,-rpath," + build_prefix + "/lib64'  LIBS='-L" + build_prefix + "/lib -L" + build_prefix + "/lib64'\", destdir={_dest}, update=FALSE, ask=FALSE);", file=tempout)
                print(f'    BiocManager::install("{pkg}", version="{bioconductor_version}", configure_vars={_configvars}, update=FALSE, ask=FALSE);', file=tempout)
                # removed 2023/07/10 destdir={_dest}, 
            elif repo in ["bms-cg-biogit-bran", "bms-cran", "bran", "unknown", "revealukb", "local"]:
                #print("    install.packages("{pkg}", configure_vars=\"LDFLAGS='-rpath," + build_prefix + "/lib,-rpath," + build_prefix + "/lib64'  LIBS='-L" + build_prefix + "/lib -L" + build_prefix + "/lib64'\", destdir={_dest}, dependencies=T, quiet=F, keep_outputs=T"{cpus}");", file=tempout)
                print(f'    install.packages("{pkg}", configure_vars={_configvars}, dependencies=T, quiet=F, keep_outputs=T{cpus});', file=tempout)
                # removed 2023/07/10 destdir={_dest}, 
            elif repo in ["cran"]:
                # necessary for nanostringr due to dependency versions out of sync in bms-cran
                # is update valid?
                print(f'    install.packages("{pkg}", repos="https://cloud.r-project.org/", configure_vars={_configvars}, dependencies=T, update=FALSE, quiet=F, keep_outputs=T{cpus});', file=tempout)
                # removed 2023/07/10 destdir={_dest}, 
            elif repo == "r-forge":
                # dependencies true may be problematic - single-source
                print(f'    install.packages("{pkg}", repos="http://R-Forge.R-project.org", configure_vars={_configvars}, dependencies=T, quiet=F, keep_outputs=T{cpus});', file=tempout)
                # removed 2023/07/10 destdir={_dest}, 
            elif repo == "local_no_dep": # was "tarballs":
                # should be the same as local but dep=F
                print(f'    install.packages("{src}/{params}", configure_vars={_configvars}, dependencies=F, quiet=F, keep_outputs=T{cpus});', file=tempout)
            elif repo == "giturl":
                print('    require(devtools);', file=tempout)
                print(f'    devtools::install_git("{params}", dependencies=FALSE, quiet=FALSE, upgrade="never");', file=tempout)
            elif repo == "github":
                # 2023/07 - changed depencies to true
                print('    require(devtools);', file=tempout)
                print(f'    devtools::install_github("{params}", dependencies=TRUE, quiet=FALSE, upgrade="never");', file=tempout)
            elif repo == "url":
                print('    require(devtools);', file=tempout)
                print(f'    devtools::install_url("{params}", dependencies=FALSE, quiet=FALSE, upgrade="never");', file=tempout)
            else:
                print(f'    install.packages("{pkg}", repos="{repo}", configure_vars={_configvars}, dependencies=T, quiet=F, keep_outputs=T{cpus});', file=tempout)
                # removed 2023/07/10 destdir={_dest}, 
                # log_message(f"Unknown repo {repo} for package {pkg}", _exit_on_error=True, file=tempout)
            print(f'    if (nchar(system.file(package="{pkg}"))) message("{pkg} was installed successfully") else message("{pkg} installation may have failed")', file=tempout)
            #print("    if (nchar(system.file(package="{pkg}"))) {", file=tempout)
            #print("    if (require("{pkg}")) {", file=tempout)
            #print("        message(\"" + pkg + " was installed successfully\")", file=tempout)
            #print("    } else {", file=tempout)
            #print("        message(\"" + pkg + " installation may have failed\") }", file=tempout)
            print("}", file=tempout)

def R_check_install_script(args=None, arg_def=None):
    inputfile = args[arg_def.INPUT_FILE]
    if not os.path.exists(inputfile):
        log_message(f"{inputfile} not found.", _exit_on_error=True)
    outputfile = args[arg_def.OUTPUT_FILE]
    if outputfile and os.path.exists(outputfile):
        log_message(f"{outputfile} exists.", _exit_on_error=True)

    if args[arg_def.LANGUAGE] == "bash":
        required = "check_if_package_is_installed_dot_R".split()
        env_vars = get_env_vars(bash_script = args[arg_def.BUILD_SETUP], required = required)
        R_script = env_vars["check_if_package_is_installed_dot_R"]

    data = pd.read_csv(inputfile, sep="\t", header=0, dtype=object, comment="#")
    if data.columns[0] != "package":
        log_message(f"package column missing in {inputfile}", _exit_on_error=True)
    #packages = data[data.columns[0]].unique().tolist()
    packages = list(data[data.columns[0]].drop_duplicates())

    if args[arg_def.LANGUAGE] == "bash":
        with (open(outputfile, "w") if outputfile else sys.stdout) as tempout:
            #print("#!/bin/bash", file=tempout)
            print('''
#!/bin/bash
set -e
build_setup=$1
if [[ "$build_setup" == "" ]] ; then echo "Specify build setup script, likely build_setup.sh." >& 2 ; exit 1 ; fi
if [[ ! -e "$build_setup" ]] ; then echo "$build_setup not found"  >& 2 ; exit 1 ; fi
source $build_setup
'''.lstrip(), file=tempout)
            #print(f"script=$1", file=tempout)
            #print(f'script=$(efs_cache_path {R_script})', file=tempout)
            print(f'script=$(find_local_file {R_script} $efs_cache_dir)', file=tempout)
            #print("if [[ ! -e $script ]] ; then echo \"$script not found\" >& 2 ; exit 1 ; fi", file=tempout)
            print('err=0', file=tempout)
            for pkg in packages:
                print(f'if ! Rscript --vanilla $script {pkg} ; then err=1 ; fi', file=tempout)
            print('if ((err)) ; then echo "Some R packages failed to be loadable." >& 2 ; exit 1 ; fi', file=tempout)
            print('echo "All R packages installed OK." >& 2 \nexit 0', file=tempout)
    else:
        # output Python
        open_bracket = "{"
        close_bracket = "}"
        with (open(outputfile, "w") if outputfile else sys.stdout) as tempout:
            for pkg in packages:
                # detach must happen before message because of gmailr
                # 2023/09 detach may no longer necessary with base:: to disambiguate, added after error `message()` was deprecated in gmailr 2.0.0 and is now defunct.
                # quotes needed because of R.oo
                #print(f'if (suppressPackageStartupMessages(require("{pkg}", quietly=F, attach.required=T))) {open_bracket} detach("package:{pkg}", unload=T, force=T) ; base::message("{pkg} is installed.") {close_bracket} else base::message("{pkg} is not installed.")', file=tempout)
                print(f'if (suppressPackageStartupMessages(requireNamespace("{pkg}", quietly=F))) {open_bracket} unloadNamespace("{pkg}") ; base::message("{pkg} is installed.") {close_bracket} else base::message("{pkg} is not installed.")', file=tempout)


def R_dependencies(args=None, arg_def=None):
    for pkg in args[arg_def.PACKAGES]:
        print('Rscript --vanilla -e "library(pak); pak::pkg_deps_tree(\\"' + pkg + '\\")" &> ' + pkg + ".pak.log")
        print('Rscript --vanilla -e "library(pak); pak::pkg_deps_tree(\\"' + pkg + '\\", dependencies=TRUE)" &> ' + pkg + ".pak.all.log")

def R_dependencies_v1(args=None, arg_def=None):
    outputfile = args[arg_def.OUTPUT_FILE]
    if outputfile and os.path.exists(outputfile):
        log_message(f"{outputfile} exists.", _exit_on_error=True)
    inputfile = args[arg_def.INPUT_FILE]
    if not os.path.exists(inputfile):
        log_message(f"{inputfile} not found.", _exit_on_error=True)
    data = pd.read_csv(inputfile, sep="\t", header=0, dtype=object, comment="#")
    keep = "bioconductor bms-cran local local_no_dep r-forge".split()
    mask = data["source"].isin(keep)
    packages = list(data[mask]["package"])
    with (open(outputfile, "w") if outputfile else sys.stdout) as tempout:
        if outputfile:
            print("#!/bin/bash",  file=tempout)
        for pkg in packages:
            print('Rscript --vanilla -e "library(pak); pak::pkg_deps_tree(\\"' + pkg + '\\")" &> ' + pkg + ".pak.log", file=tempout)

def R_installed_packages(args=None, arg_def=None):
    pass


if __name__ == "__main__":
    arg_def = ArgsClass()
    parser = arg_def.parser
    arglen = len(sys.argv)
    if arglen == 1:
        parser.print_help()
    else:
        args = parser.parse_args()
        _vars = vars(args)
        _fn = eval(args.func)
        _fn(args=_vars, arg_def=arg_def)

