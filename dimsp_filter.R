## wl-01-11-2018, Thu: commence dimsp filtering implementation
## wl-18-11-2018, Wed: add MV and RSD distribution plots, which are used to
##   choose threshold of MV and RSD.
## wl-20-11-2018, Tue: add MV imputation by univariate or multivariate
## wl-26-11-2018, Mon: make it work for Galaxy

## to-do:
##  1) restore original dim names
##  2) read groups information or input directly

rm(list=ls(all=T))

## flag for command-line use or not. If false, only for debug interactively.
com_f  <- F

## ------------------------------------------------------------------------
## galaxy will stop even if R has warning message
options(warn=-1) ## disable R warning. Turn back: options(warn=0)

## ------------------------------------------------------------------------
## Setup R error handling to go to stderr
## options( show.error.messages=F, error = function (){
##   cat( geterrmessage(), file=stderr() )
##   q( "no", 1, F )
## })

## we need that to not crash galaxy with an UTF8 error on German LC settings.
loc <- Sys.setlocale("LC_MESSAGES", "en_US.UTF-8")

suppressPackageStartupMessages({
  library(optparse)
  library(WriteXLS)
})

## wl-28-08-2018, Tue: Convert a string seperated by comma into character vector
str_vec <- function(x) {
  x   <- unlist(strsplit(x,","))
  x   <- gsub("^[ \t]+|[ \t]+$", "", x)  ## trim white spaces
}

if(com_f){

  ## -----------------------------------------------------------------------
  ## Setup home directory
  ## wl-24-11-2017, Fri: A dummy function for the base directory. The reason
  ## to write such a function is to keep the returned values by
  ## 'commandArgs' with 'trailingOnly = FALSE' in a local environment
  ## otherwise 'parse_args' will use the results of
  ## 'commandArgs(trailingOnly = FALSE)' even with 'args =
  ## commandArgs(trailingOnly = TRUE)' in its argument area.
  func <- function(){
    argv <- commandArgs(trailingOnly = FALSE)
    path <- sub("--file=","",argv[grep("--file=",argv)])
  }
  ## prog_name <- basename(func())
  tool_dir <- paste0(dirname(func()),"/")

  option_list <-
    list(
        make_option(c("-v", "--verbose"), action="store_true", default=TRUE,
                    help="Print extra output [default]"),
        make_option(c("-q", "--quietly"), action="store_false",
                    dest="verbose", help="Print little output"),

        ## -------------------------------------------------------------------
        ## input
        make_option("--mzxml_file", type="character",
                    help="DIMS mzXML files list, seperated by comma"),
        make_option("--targ_file", type="character",
                    help="Lipid target list with columns of m/z and lipid name"),
        make_option("--samp_name", type="character", default="",
                    help="Sample names. Default is the names of mz XML file"),
        make_option("--rt_low",type="double", default = 20.0,
                    help="Start time"),
        make_option("--rt_high",type="double", default = 60.0,
                    help="End time"),
        make_option("--mz_low",type="double", default = 200.0,
                    help="Start m/z"),
        make_option("--mz_high",type="double", default = 1200.0,
                    help="End m/z"),
        make_option("--hwidth",type="double", default = 0.01,
                    help="m/z window size/height for peak finder"),
         
        ## output files (Excel)
        make_option("--sign_file",type="character", default="signals.tsv",
                    help="Save peak signals (peak table)"),
        make_option("--devi", type="logical", default=TRUE,
                    help="Return m/z deviation results or not"),
        make_option("--devi_file",type="character", default="deviations.tsv",
                    help="Save m/z deviations"),
        make_option("--indi", type="logical", default=TRUE,
                    help="Return each sample's signal and m/z deviation or not"),
        make_option("--indi_file",type="character", default="sam_indi.xlsx",
                    help="Save individual sample's signal and m/z deviation in Excel")
    )

  opt <- parse_args(object=OptionParser(option_list=option_list),
                    args = commandArgs(trailingOnly = TRUE))
  ## print(opt)

} else {
  ## tool_dir <- "C:/R_lwc/dimsp/"         ## for windows
  tool_dir <- "~/my_galaxy/dimsp/"  ## for linux. must be case-sensitive
  opt  <- list(
      peak_file = paste0(tool_dir,"res/pos_peak.tsv"),
      groups = "sample, sample, sample, sample, sample, sample, sample, sample, sample, sample, qc, qc, blank, blank",
      ## QC filtering 
      qc           = TRUE,
      qc_rsd_thres = 20.0,
      qc_mv_filter = TRUE,
      qc_mv_qc_sam = TRUE,
      qc_mv_thres  = 0.30,

      ## blank filtering
      bl           = TRUE,
      bl_method    = "mean",
      bl_factor    = 1,
      bl_mv_filter = TRUE,
      bl_mv_thres  = 0.30,

      ## MV filtering on samples
      mv = TRUE,
      mv_thres = 0.30,

      ## Merge data (sample, qc and blank)
      merge = TRUE,
      ## MV imputation
      mv_impute = "mean"

  )

}

suppressPackageStartupMessages({
  source(paste0(tool_dir,"fs_filter.R"))
})


## ========================================================================
## 1) Data preparation
## ========================================================================

## Load peak table
peak <- read.table(opt$peak_file, header = T, sep = "\t",
                   fill = T,stringsAsFactors = F)

## get only numberics
dat <- peak[,-c(1:2)]
dat <- as.data.frame(t(dat)) 

## record replicate names
rep_names <- rownames(dat)

## get sample, qc and blank info
droups <- opt$groups
groups <- unlist(strsplit(groups,","))
groups <- gsub("^[ \t]+|[ \t]+$", "", groups)  ## trim white spaces
(groups <- factor(groups))

## change zero as NA
dat <- mv.zene(dat)          

## construct list for "sample", "qc" and "blank"
data <- lapply(levels(groups), function(x){
  idx <- grep(x,groups)
  tmp <- dat[idx,]
})
names(data) <- levels(groups)
sapply(data,dim)


## ========================================================================
## 2) Missing value and RSD checking
## ========================================================================

val_rsd <- lapply(data,rsd)
## sapply(val_rsd, summary)
p.rsd   <- dist_plot(val_rsd,main="RSD")
p.rsd$p.box
p.rsd$p.hist

val_mv <- lapply(data, function(x) { mv.stats(x)$mv.var })
## sapply(val_mv, summary)
p.mv   <- dist_plot(val_mv,main="Percentage of Missing values")
p.mv$p.box
p.mv$p.hist

## ========================================================================
## 3) Feature filtering
## ========================================================================

## qc filtering
if (opt$qc){
  data <- qc_filter(data, 
                    thres_rsd = opt$qc_rsd_thres,
                    f_mv      = opt$qc_mv_filter,
                    f_mv_qc   = opt$qc_mv_qc_sam,
                    thres_mv  = opt$qc_mv_thres)
  sapply(data,dim) 
}

## blank filtering
if (opt$bl){
  data <- blank_filter(data, 
                       method   = opt$bl_method,
                       factor   = opt$bl_factor,
                       f_mv     = opt$bl_mv_filter,
                       thres_mv = opt$bl_mv_thres)
  sapply(data,dim)
}

## mv filtering
if (opt$mv){
  data <- mv_filter(data, thres_mv = opt$mv_thres)
  sapply(data,dim)
}


## ========================================================================
## 4) Merge data set
## ========================================================================

if (opt$merge){
  dat <- do.call(rbind,data)
} else {
  dat <- data$sample
}


## ========================================================================
## 5) Missing value imputation
## ========================================================================

dat <- mv.impute(dat, method = opt$mv_impute)

## ========================================================================
## 6) Tidy up and output
## ========================================================================

## to-do: restore original dim names

