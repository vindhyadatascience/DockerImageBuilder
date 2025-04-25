args = commandArgs(trailingOnly=TRUE)
if (length(args) == 0) {
  stop("Specify the name of a package to check.")
} else if (length(args) > 1) {
  stop("Specify only one package to check.")
}
pkg = args[1]
# if (require(pkg, character.only=T, quietly=T)) {
#suppressWarnings
if (suppressPackageStartupMessages(require(pkg, character.only=T, quietly=F, attach.required=T))) {
  base::message(paste0(pkg, " is installed.")) 
  quit(status=0)
} else {
  base::message(paste0(pkg, " is not installed.")) 
  quit(status=1)
}

# attach.required: logical specifying whether required packages listed in the 'Depends' clause of the 'DESCRIPTION' file should be attached automatically.


 
