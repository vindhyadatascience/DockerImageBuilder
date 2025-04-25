#!/usr/bin/env python

'''
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

        _help = 'Output commands to create self-contained Docker image.'
        self.parser = argparse.ArgumentParser(description = _help)
        subparsers = self.parser.add_subparsers(help='sub-command help')
        _help_message = {}
        _help_message["get_source_files"] = "Make a list of regular files with actual file size."
        _help_message["make_file_batches"] = "Generate batch files (i.e., lists of regular files) to rsync in each layer."

        all_functions = _help_message.keys()

        _subparser = {}
        for _fn in _help_message.keys():
            _subparser[_fn] = subparsers.add_parser(_fn, help=_help_message[_fn])
            _subparser[_fn].set_defaults(func=_fn)

        _name = self.INPUT_DIR = "inputdir"
        _help = "Where to look for files."
        for _fn in "get_source_files".split():
            _subparser[_fn].add_argument('--' + _name, "-i", type=str, required = True, help= _help)

        _name = self.OUTPUT_FILE_PREFIX = "outputfileprefix"
        _help = "Prefix for output files."
        _default = "rsync_batches"
        _help = self.append_default(_help, _default)
        for _fn in "make_file_batches".split():
            _subparser[_fn].add_argument('--' + _name, "-o", type=str, required = False, help= _help, default=_default)

        _name = self.MAX_BATCH_SIZE = "max_size_per_layer"
        _help = "Maximum size per layer, in bytes." # Every batch but the last exceeds this target."
        _default = 1200000000
        _help = self.append_default(_help, _default)
        for _fn in "make_file_batches".split():
            _subparser[_fn].add_argument('--' + _name, "-b", type=int, required = False, help= _help, default=_default)

        _name = self.FILE_SIZES = "file_sizes"
        _help = "File path + size for regular files"
        _default = "source_files"
        for _fn in "make_file_batches get_source_files".split():
            _subparser[_fn].add_argument('--' + _name, "-s", type=str, required = False, help= _help, default=_default)

def log_message(message, _exit_on_error=False, _show_time = True):
    if _show_time: 
        message = str(dt.now()) + "\t" + message
    print(message, file=sys.stderr)
    if _exit_on_error: sys.exit(1)

def execute_command(command_as_text): #, _exit_on_error=False):
    # returns a list, empty if no output
    import subprocess
    log_message("# running %s" % (command_as_text), _exit_on_error=False)
    try:
        output = subprocess.check_output(command_as_text, shell=True, stderr=subprocess.STDOUT)
    except:
        log_message("Execution of %s failed." % command_as_text)
        return []
    return [line.decode("utf8").rstrip() for line in output.splitlines()]

def get_file_size(file=None):
    return os.stat(file).st_size

def remove_input_dir_path_from_file_paths(data=None, leader = None):
    # data = list of paths
    letters = len(leader)
    newpaths = [x[letters:] for x in data if x.startswith(leader)]
    if len(newpaths) != len(data):
        print_error("input dir was not found in some file paths", _exit_on_error=True)
    return newpaths

def get_source_files(args=None, arg_def=None):
    inputdir = args[arg_def.INPUT_DIR]
    outputfile = args[arg_def.FILE_SIZES]
    if not os.path.exists(inputdir):
        log_message("%s not found." % (inputdir), _exit_on_error=True)
    files = pd.DataFrame(execute_command("find %s -type f" % inputdir), columns = ["path",])
    files["size"] = files["path"].apply(get_file_size)

    _replace = inputdir.rstrip("/") + "/"
    files["path"] = remove_input_dir_path_from_file_paths(data=files["path"], leader = _replace)

    # some R files contain commas; rsync fails if file names are specified, succeeds later in final rsync with symbolic links etc. 
    mask = files["path"].str.contains(",")
    files = files[~mask].copy()

    # 2023/01/08 - don't include transfer dir; this will be included in final sync but must then be deleted
    mask = files["path"].str.startswith("transfer/")
    files = files[~mask].copy()

    files.to_csv(outputfile, sep="\t", index=False)

def make_file_batches(args=None, arg_def=None):
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
        log_message("Input file %s not found." % (inputfile), _exit_on_error=True)
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
        log_message("batch\t%s\t%s\t%s\tbytes" % (batch, outputfile, total2), _show_time = False)
        batchdata[["path"]].to_csv(outputfile, header=None, index=False)

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

