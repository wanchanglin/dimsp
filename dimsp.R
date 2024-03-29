#' wl-10-07-2018, Tue: commence
#' wl-13-07-2018, Fri: make script working
#' wl-17-07-2018, Tue: check xcmsRaw and getSpec
#' wl-06-08-2018, Mon: 1.) unify positive and negative 2.) Use multiple
#' files, not file directory
#' wl-07-08-2018, Tue: finish the first working version for Galaxy
#' wl-12-08-2018, Mon: Modify and debug
#' wl-14-08-2018, Tue: the second working version for galaxy.
#' wl-28-08-2018, Tue: add 'samp_name' especially for galaxy.
#' wl-29-08-2018, Wed: add 'rtrange','marange' and 'hwidth'
#' wl-01-03-2019, Fri: tidy up for outline/tree view in vim and reformat
#'   with R package 'styler'. Remove input file extension checking so it
#'   supports both mzXML and mzML.
#' wl-04-03-2019, Mon: add mz file directory option. It is not for Galaxy
#'   since it is impossible to load data in a specific directory of Galaxy
#'   sever. This option is only for direct use of R script, either in
#'   interactive or command line mode. See shell script in './test'
#' wl-20-03-2019, Wed: change structure of 'test-data' and put results into
#'   this directory for Galaxy planemo test.
#' wl-22-03-2019, Fri: change xls R package from 'WriteXLS' to 'writexl'.
#'   The former gives different file size which leads to planemo test to fail
#'   on xlsx files. The reason may be package version.
#' wl-25-03-2019, Mon: bring back 'WriteXLS' since 'writexl' does not
#'   support data frame's row names
#' wl-15-07-2019, Mon: use xcms to change ranges of time and m/z. Only for
#' debug.
#' wl-19-07-2019, Fri: there is no centroding for spectra. 'xcmsRaw' only
#' loads data without peak detection(peak picking, peak finding). Note that
#' 'xcmsSet' (here not using) performs peak detection via 'findPeaks'. Use
#' 'ProteoWizards' for peak picking when converting data to mzML.
#' wl-24-08-2020, Mon: Review. Remove 'WriteXLS'

## ==== General settings ====
rm(list = ls(all = T))

#' flag for command-line use or not. If false, only for debug interactively.
com_f <- T

#' galaxy will stop even if R has warning message
options(warn = -1) #' disable R warning. Turn back: options(warn=0)

#' ------------------------------------------------------------------------
#' Setup R error handling to go to stderr
#' options( show.error.messages=F, error = function (){
#'   cat( geterrmessage(), file=stderr() )
#'   q( "no", 1, F )
#' })

#' we need that to not crash galaxy with an UTF8 error on German LC settings.
loc <- Sys.setlocale("LC_MESSAGES", "en_US.UTF-8")

suppressPackageStartupMessages({
  library(optparse)
  library(xcms)
  library(data.table)
})

#' wl-28-08-2018, Tue: Convert a string separated by comma into character vector
str_vec <- function(x) {
  x <- unlist(strsplit(x, ","))
  x <- gsub("^[ \t]+|[ \t]+$", "", x) #' trim white spaces
}

## ==== Command line or interactive setting ====
if (com_f) {

  #' -----------------------------------------------------------------------
  #' Setup home directory
  #' wl-24-11-2017, Fri: A dummy function for the base directory. The reason
  #' to write such a function is to keep the returned values by
  #' 'commandArgs' with 'trailingOnly = FALSE' in a local environment
  #' otherwise 'parse_args' will use the results of
  #' 'commandArgs(trailingOnly = FALSE)' even with 'args =
  #' commandArgs(trailingOnly = TRUE)' in its argument area.
  func <- function() {
    argv <- commandArgs(trailingOnly = FALSE)
    path <- sub("--file=", "", argv[grep("--file=", argv)])
  }
  #' prog_name <- basename(func())
  tool_dir <- paste0(dirname(func()), "/")

  option_list <-
    list(
      make_option(c("-v", "--verbose"),
        action = "store_true", default = TRUE,
        help = "Print extra output [default]"
      ),
      make_option(c("-q", "--quietly"),
        action = "store_false",
        dest = "verbose", help = "Print little output"
      ),

      #' -------------------------------------------------------------------
      #' input
      make_option("--mzxml_file",
        type = "character",
        help = "mzXML/ mzML file directory or full file list separated by comma"
      ),
      make_option("--targ_file",
        type = "character",
        help = "Lipid target list with columns of m/z and lipid name"
      ),
      make_option("--samp_name",
        type = "character", default = "",
        help = "Sample names. Default is the names of mz XML file"
      ),
      make_option("--rt_low",
        type = "double", default = 20.0,
        help = "Start time"
      ),
      make_option("--rt_high",
        type = "double", default = 60.0,
        help = "End time"
      ),
      make_option("--mz_low",
        type = "double", default = 200.0,
        help = "Start m/z"
      ),
      make_option("--mz_high",
        type = "double", default = 1200.0,
        help = "End m/z"
      ),
      make_option("--hwidth",
        type = "double", default = 0.01,
        help = "m/z window size/height for peak finder"
      ),

      #' output files (Excel)
      make_option("--sign_file",
        type = "character", default = "signals.tsv",
        help = "Save peak signals (peak table)"
      ),
      make_option("--devi",
        type = "logical", default = TRUE,
        help = "Return m/z deviation results or not"
      ),
      make_option("--devi_file",
        type = "character", default = "deviations.tsv",
        help = "Save m/z deviations"
      ),
      make_option("--indi",
        type = "logical", default = TRUE,
        help = "Return each sample's signal and m/z deviation or not"
      ),
      make_option("--indi_file",
        type = "character", default = "samp_indi.tsv",
        help = "Save individual sample's signal and m/z deviation"
      )
    )

  opt <- parse_args(
    object = OptionParser(option_list = option_list),
    args = commandArgs(trailingOnly = TRUE)
  )
  print(opt)
} else {
  tool_dir <- "~/my_galaxy/dimsp/"
  #' tool_dir <- "C:/R_lwc/dimsp/"         #' for windows
  opt <- list(
    #' input

    #' mzxml_file = paste(paste0(tool_dir, "test-data/mzML")),

    ## mzxml_file = paste(paste0(tool_dir, "test-data/mzXML/030317_mouse_liver_cs16_pos_002.mzXML"),
    ##                    paste0(tool_dir, "test-data/mzXML/030317_mouse_liver_cs16_pos_004.mzXML"),
    ##                    sep = ","),

    mzxml_file = paste(paste0(tool_dir, "test-data/mzML/01_sample.mzML"),
                       paste0(tool_dir, "test-data/mzML/02_sample.mzML"),
                       paste0(tool_dir, "test-data/mzML/03_sample.mzML"),
                       paste0(tool_dir, "test-data/mzML/04_sample.mzML"),
                       sep = ","),

    targ_file = paste0(tool_dir, "test-data/lipid_list/Positive_LipidList.tsv"),
    #' samp_name = "mzXML/030317_mouse_liver_cs16_pos_001.mzXML,mzXML/030317_mouse_liver_cs16_pos_002.mzXML",
    samp_name = "",
    rt_low = 20.0,
    rt_high = 60.0,
    mz_low = 200.0,
    mz_high = 1200.0,
    hwidth = 0.01,
    #' Output
    sign_file = paste0(tool_dir, "test-data/res/mzml_pos_sign.tsv"),
    devi = TRUE,
    devi_file = paste0(tool_dir, "test-data/res/mzml_pos_devi.tsv"),
    indi = TRUE,
    indi_file = paste0(tool_dir, "test-data/res/mzml_pos_indi.tsv")
  )
}
print(opt)

suppressPackageStartupMessages({
  source(paste0(tool_dir, "all_dimsp.R"))
})

## ==== Main process ====

#' ------------------------------------------------------------------------
#' Prepare data and targets

#' Process multiple input files separated by comma
#' wl-04-03-2019, Mon: add file directory option. Note that it is not for
#' galaxy.
if (dir.exists(opt$mzxml_file)) {   ## file directory
  opt$mzxml_file <- list.files(opt$mzxml_file, pattern = "mzml|mzxml",
                               ignore.case = T, recursive = F,
                               full.names = TRUE)
} else {  ## multiple files
  opt$mzxml_file <- str_vec(opt$mzxml_file)
}

targets <- read.table(opt$targ_file, header = T, sep = "\t",
                      stringsAsFactors = F)

targets <- data.table(targets)

#' ------------------------------------------------------------------------
#' Process data
res <- lapply(opt$mzxml_file, function(x) { #' x = files[[1]]
  spec <- suppressMessages(getspectra(
    filename = x,
    rt = c(opt$rt_low, opt$rt_high),
    mz = c(opt$mz_low, opt$mz_high)
  ))
  tgts <- peaktable(targets, spec, opt$hwidth)
  return(tgts)
})

#' handle sample names
if (opt$samp_name == "") {
  opt$samp_name <- opt$mzxml_file
} else {
  opt$samp_name <- str_vec(opt$samp_name)
}
#' extract only sample names (use greedy match)
names(res) <- gsub(".*/|\\..*$", "", opt$samp_name, perl = T)

#' save(res,file=paste0(tool_dir,"res/res.RData"))
#' load(paste0(tool_dir,"res/res.RData"))
#' lapply(res, dim)

#' ------------------------------------------------------------------------
#' Output results
#' get signals (intensity) and mz deviations
tmp        <- targets[, c("name", "mz")]
signals    <- sapply(res, function(x) return(x[, "signal"]))
deviations <- sapply(res, function(x) return(x[, "mz_deviation"]))
signals    <- as.data.frame(cbind(tmp, signals))
deviations <- as.data.frame(cbind(tmp, deviations))

#' save peak table
write.table(signals, file = opt$sign_file, sep = "\t", row.names = F)
#' save m/z deviations
if (opt$devi) {
  write.table(deviations, file = opt$devi_file, sep = "\t", row.names = F)
}

#' save each sample result
#' wl-25-08-2020, Tue: save as tabular format. 'xlsx' make galaxy test fail.
if (opt$indi) {
  #' library(writexl)
  #' write_xlsx(res, path = opt$indi_file, col_names = T, format_headers = T)
  #' WriteXLS(res, ExcelFileName = opt$indi_file, row.names = T, FreezeRow = 1)
  tmp <- lapply(names(res), function(x){
    res <- cbind(sample = x, res[[x]])
  })
  tmp <- do.call("rbind", tmp)
  write.table(tmp, file = opt$indi_file, sep = "\t", row.name = FALSE)
}
