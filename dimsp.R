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
#'   since it is impossible to load data in a specific directiory of Galaxy
#'   sever. This option is only for direct use of R script, either in 
#'   interactive or command line mode. See shell script in './test'

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
  library(WriteXLS)
  library(xcms)
  library(data.table)
})

#' wl-28-08-2018, Tue: Convert a string seperated by comma into character vector
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
        help = "mzXML/ mzML file directory or full file list seperated by comma"
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
        type = "character", default = "sam_indi.xlsx",
        help = "Save individual sample's signal and m/z deviation in Excel"
      )
    )

  opt <- parse_args(
    object = OptionParser(option_list = option_list),
    args = commandArgs(trailingOnly = TRUE)
  )
  #' print(opt)
} else {
  #' tool_dir <- "C:/R_lwc/dimsp/"         #' for windows
  tool_dir <- "~/my_galaxy/dimsp/" #' for linux. must be case-sensitive
  opt <- list(
    #' input

    ## mzxml_file = paste(paste0(tool_dir, "test-data/DIMS_pos/030317_mouse_liver_cs16_pos_001.mzXML"),
    ##                    paste0(tool_dir, "test-data/DIMS_pos/030317_mouse_liver_cs16_pos_002.mzXML"),
    ##                    sep = ","
    ##                    ),

    ## mzxml_file = paste(paste0(tool_dir, "test-data/01_sample.mzML"),
    ##                    paste0(tool_dir, "test-data/02_sample.mzML"),
    ##                    paste0(tool_dir, "test-data/03_sample.mzML"),
    ##                    paste0(tool_dir, "test-data/04_sample.mzML"),
    ##                    sep = ","
    ##                    ),
    
    mzxml_file = paste(paste0(tool_dir, "test-data")),

    targ_file = paste0(tool_dir, "LipidList_generator/Positive_LipidList.tsv"),
    samp_name = "",
    rt_low = 20.0,
    rt_high = 60.0,
    mz_low = 200.0,
    mz_high = 1200.0,
    hwidth = 0.01,
    #' Output
    sign_file = paste0(tool_dir, "res/signals.tsv"),
    devi = TRUE,
    devi_file = paste0(tool_dir, "res/deviations.tsv"),
    indi = TRUE,
    indi_file = paste0(tool_dir, "res/individuals.xlsx")
  )
}

suppressPackageStartupMessages({
  source(paste0(tool_dir, "all_dimsp.R"))
})

## ==== Main process ====

#' process multiple input files seperated by comma
#' wl-04-03-2019, Mon: add file directory option. Note that it is not for
#' galaxy.
if (dir.exists(opt$mzxml_file)) {   ## file directory
  opt$mzxml_file <- list.files(opt$mzxml_file, pattern = "mzml|mzxml", 
                               ignore.case = T, recursive = F, full.names = TRUE)
} else {  ## multiple files
  opt$mzxml_file <- str_vec(opt$mzxml_file)
} 

targets <- read.table(opt$targ_file, header = T, sep = "\t", stringsAsFactors = F)
targets <- data.table(targets)

#' ------------------------------------------------------------
#' temporary debug in interactive mode
if (T) {
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
    opt$samp_name <- opt$mzxml
  } else {
    opt$samp_name <- str_vec(opt$samp_name)
  }
  #' extract only sample names (use greedy match)
  names(res) <- gsub(".*/|\\..*$", "", opt$samp_name, perl = T)

  #' save(res,file=paste0(tool_dir,"res/res.RData"))
} else {
  #' load(paste0(tool_dir,"res/res.RData"))
}

#' --------------------------------------------------------------------
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
#' #' save each sample result
if (opt$indi) {
  WriteXLS(res, ExcelFileName = opt$indi_file, row.names = T, FreezeRow = 1)
}
#' cat("\ngoes here\n")
#' lapply(res, dim)

## ==== DEBUG: Interactive mode ====
#' wl-01-03-2019, Fri: test mzML file which is not mentioned in 'xcms'

if (F) {
  source("./all_dimsp.R")

  #' file path of mzML files
  #' path <- "C:/R_lwc/dims_processing/test-data/"
  path <- "./test-data/"
  files <- list.files(path, pattern = "mzML", recursive = F, full.names = TRUE)
  (files <- files[1:4])

  targets <- read.table("./LipidList_generator/Positive_LipidList.tsv",
    header = T, sep = "\t", stringsAsFactors = F
  )
  targets <- data.table(targets)

  #' ------------------------------------------------------------
  if (T) {
    res <- lapply(files, function(x) {
      #' x = files[[1]]
      spec <- getspectra(filename = x, rt = c(20, 60), mz = c(200, 1200))
      tgts <- peaktable(targets, spec)
      return(tgts)
    })
    #' extract only sample names (use greedy match)
    names(res) <- gsub(".*/|\\..*$", "", files, perl = T)
    save(res, file = "./res/tmp_res.RData")
  } else {
    load("tmp_res.RData")
  }

  lapply(res, dim)

  #' --------------------------------------------------------------------
  #' save single result
  WriteXLS(res,
    ExcelFileName = "./res/tmp_pos.xlsx", row.names = F,
    FreezeRow = 1
  )
  if (F) { #' or use this
    lapply(names(res), function(x) {
      write.csv(res[[x]], file = paste0("./res/", x, ".csv"), row.names = F)
    })
  }

  #' --------------------------------------------------------------------
  #' get signals (intensity) and mz deciations
  tmp <- targets[, c("name", "mz")]
  signals <- sapply(res, function(x) return(x[, "signal"]))
  deviations <- sapply(res, function(x) return(x[, "mz_deviation"]))
  signals <- cbind(tmp, signals)
  deviations <- cbind(tmp, deviations)
  #' save results
  write.csv(signals, file = "./res/tmp_sig.csv", row.names = F)
  write.csv(deviations, file = "./res/tmp_dev.csv", row.names = F)

  #' results <- signals_deviations()
  #' gc() # helps memory allocation errors on low memory systems
}

## ==== DEBUG: Temp codes ====
if (F) { #' Use MSnbase package to read data.
  #' ----------------------------------------------------------------
  raw_data <- readMSData(files, mode = "onDisk")
  raw_data
  slotNames(raw_data)

  #' --------------------
  rt <- rtime(raw_data)
  class(rt) #' numeric
  length(rt) #' 2673 = 9 * 297

  #' --------------------
  mzs <- mz(raw_data)
  #' Split the list by file
  mzs_by_file <- split(mzs, f = fromFile(raw_data))
  length(mzs_by_file) #' 9
  length(mzs_by_file[[1]]) #' 297
  length(mzs_by_file[[1]][[1]]) #' 13004

  #' --------------------
  inten <- intensity(raw_data)
  inten_by_file <- split(inten, f = fromFile(raw_data))
  length(inten_by_file) #' 9
  length(inten_by_file[[1]]) #' 297
  length(inten_by_file[[1]][[1]]) #' 13004
}

## ==== DEBUG: Use xcms to load data ====
if (F) { 
  xr <- xcmsRaw(files[1])
  xr

  #' ----------------------------------------
  #' Lets have a look at the structure of the object
  slotNames(xr)
  #' names(attributes(xr))
  #' str(xr)

  xr@scantime
  xr@scanindex
  head(xr@scanindex)
  xr@mzrange

  names(xr@env) #' profile, mz, intensity
  xr@env$mz[425:430]

  #' ----------------------------------------
  mz.scan1 <- xr@env$mz[(1 + xr@scanindex[1]):xr@scanindex[2]]
  intensity.scan1 <- xr@env$intensity[(1 + xr@scanindex[1]):xr@scanindex[2]]
  plot(mz.scan1, intensity.scan1,
    type = "h",
    main = paste("Scan 1 of file", basename(files[1]), sep = "")
  )

  #' the easier way
  scan1 <- getScan(xr, 1)
  head(scan1)
  plotScan(xr, 1)

  #' ----------------------------------------
  spec <- getSpec(xr, rtrange = c(20, 60), mzrange = c(200, 1200))
  spec_1 <- getSpec(xr, t = c(20, 60), m = c(200, 1200)) #' rtrange and mzrange
  spec_2 <- getSpec(xr, m = c(200, 1200)) #' mzrange
  spec_3 <- getSpec(xr, s = c(98, 297), m = c(200, 1200)) #' scanrange and mzrange
  spec_4 <- getSpec(xr)

  #' Note: The results of 'spec' ~ 'spec_4' are confused:
  #'  - is rt 'scantime' in this case?
  #'  - Source code of `getSpec` does not use 'rtrange'.
  #'  - strange: results of 'spec' and 'spec_1' are not the same.

  dim(spec) #' [1] 2096693       2
  length(unique(spec[, 1])) #' [1] 2096693

  spec[, "mz"] <- round(spec[, "mz"], digits = 4)
  spec <- as.data.table(spec)
  spec <- spec[, mean(intensity), by = mz]
  spec <- na.omit(spec)
}
