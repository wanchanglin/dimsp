#' wl-01-11-2018, Thu: commence dimsp filtering implementation
#' wl-18-11-2018, Wed: add MV and RSD distribution plots, which are used to
#'   choose threshold of MV and RSD.
#' wl-20-11-2018, Tue: add MV imputation by univariate or multivariate
#' wl-26-11-2018, Mon: make it work for Galaxy
#' wl-27-11-2018, Tue: restore original annotation, mz and replicate info
#' wl-28-11-2018, Wed: test on command mode and add more error handling.
#'  - Duplicate execution of mv filtering on samples are fine.
#'  - mv filtering must be executed once.
#'  - the choice of rsd threshold is tricky. Default of 20 is aggressive in
#'    the most of time. If the number of variables are dropped largely after
#'    rsd-based qc filtering, consider increasing rsd threshold. Or do not
#'    execute this qc filtering and only carry on mv filtering and blank
#'    filtering.
#'  - group info can include the following items and number of each item
#'    must be no less than 2. Any other item cannot be accepted.
#'    - sample
#'    - sample, qc
#'    - sample, blank
#'    - sample, qc, blank
#' wl-29-11-2018, Thu: debug and polish for Galaxy (command mode)
#'  - grp_file_sel: change from boolean to character purely for galaxy
#' wl-01-03-2019, Fri: tidy up for outline/tree view in vim and reformat
#'   with R package 'styler'

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
  library(writexl)
  #' library(WriteXLS)
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
      make_option("--peak_file",
        type = "character",
        help = "DIMS peak table with the annotation and mz values"
      ),
      make_option("--grp_file_sel",
        type = "character", default = "yes",
        help = "Load sample, qc and blank info from file or not"
      ),
      make_option("--grp_file",
        type = "character",
        help = "sample, qc and blank info file for filtering"
      ),
      make_option("--groups",
        type = "character", default = "",
        help = "Sample, qc and blank info. Delimited by commas."
      ),

      #' QC filtering
      make_option("--qc",
        type = "logical", default = TRUE,
        help = "Performs QC filtering or not"
      ),
      make_option("--qc_rsd_thres",
        type = "double", default = 20.0,
        help = "RSD threshold for QC filtering."
      ),
      make_option("--qc_mv_filter",
        type = "logical", default = TRUE,
        help = "Performs MV filtering inside qc filtering or not"
      ),
      make_option("--qc_mv_qc_sam",
        type = "logical", default = TRUE,
        help = "Performs mv filtering on qc or sample replicates"
      ),
      make_option("--qc_mv_thres",
        type = "double", default = 0.30,
        help = "MV percentage threshold for mv filtering inside qc filtering"
      ),

      #' Blank filtering
      make_option("--bl",
        type = "logical", default = TRUE,
        help = "Performs blank filtering or not"
      ),
      make_option("--bl_method",
        type = "character", default = "mean",
        help = "Blank filtering method. Currently support mean, median and max."
      ),
      make_option("--bl_factor",
        type = "double", default = 1.0,
        help = "Factor for blank filtering"
      ),
      make_option("--bl_mv_filter",
        type = "logical", default = TRUE,
        help = "Performs MV filtering on sample inside blank filtering or not"
      ),
      make_option("--bl_mv_thres",
        type = "double", default = 0.30,
        help = "MV percentage threshold for mv filtering inside blank filtering"
      ),

      #' MV filtering
      make_option("--mv",
        type = "logical", default = TRUE,
        help = "Performs MV filtering on sample or not"
      ),
      make_option("--mv_thres",
        type = "double", default = 0.30,
        help = "MV percentage threshold for mv filtering"
      ),

      #' Merge data (sample, qc and blank)
      make_option("--merge",
        type = "logical", default = TRUE,
        help = "Merge sample, qc and blank or not"
      ),

      #' MV imputation
      make_option("--mv_impute",
        type = "character", default = "knn",
        help = "MV imputation method. Currently support mean, median, min, knn and pca."
      ),

      #' output files
      make_option("--pdf_file",
        type = "character", default = "hist_box.pdf",
        help = "Save histogram and boxplot for both RSD and MV percentage"
      ),
      make_option("--filter_file",
        type = "character", default = "perk_filter.tsv",
        help = "Save filtered peak table"
      )
    )

  opt <- parse_args(
    object = OptionParser(option_list = option_list),
    args = commandArgs(trailingOnly = TRUE)
  )
  #' print(opt)
} else {
  #' tool_dir <- "C:/R_lwc/dimsp/"         #' for windows
  tool_dir <- "~/my_galaxy/dimsp/" #' for linux. Must be case-sensitive
  opt <- list(
    #' Input
    peak_file = paste0(tool_dir, "res/pos_peak.tsv"),
    #' input group information directly or load a file?
    grp_file_sel = "yes",
    grp_file = paste0(tool_dir, "res/grp_sam_qc_bl.tsv"),
    groups = "sample, sample, sample, sample, sample, sample, sample, sample, sample, sample, qc, qc, blank, blank",

    #' QC filtering
    qc = TRUE,
    qc_rsd_thres = 60.0,
    qc_mv_filter = TRUE,
    qc_mv_qc_sam = FALSE,
    qc_mv_thres = 0.30,

    #' blank filtering
    bl = TRUE,
    bl_method = "mean",
    bl_factor = 1,
    bl_mv_filter = TRUE,
    bl_mv_thres = 0.30,

    #' MV filtering on samples
    mv = TRUE,
    mv_thres = 0.30,

    #' Merge data (sample, qc and blank)
    merge = TRUE,

    #' MV imputation
    mv_impute = "mean",

    #' output
    pdf_file = paste0(tool_dir, "res/hist_box.pdf"),
    filter_file = paste0(tool_dir, "res/peak_filter.tsv")
  )
}

suppressPackageStartupMessages({
  source(paste0(tool_dir, "fs_filter.R"))
})

## ==== 1) Data preparation ====

#' Load peak table
peak <- read.table(opt$peak_file,
  header = T, sep = "\t",
  fill = T, stringsAsFactors = F
)

#' get only numerics
dat <- peak[, -c(1:2)]
dat <- as.data.frame(t(dat))

#' record replicate names for final output
rep_names <- rownames(dat)

#' get sample, qc and blank info
if (opt$grp_file_sel == "yes") {
  groups <- read.table(opt$grp_file,
    header = FALSE, sep = "\t",
    stringsAsFactors = F
  )
  groups <- groups[, 1, drop = TRUE]
  #' wl-30-11-2018, Fri: group file must be one column without header. The
  #'  file extension can be tsv, csv or txt. sep="\t" takes no effect on one
  #'  column file.
} else {
  groups <- opt$groups
  groups <- unlist(strsplit(groups, ","))
  groups <- gsub("^[ \t]+|[ \t]+$", "", groups) #' trim white spaces
}
groups <- as.factor(tolower(groups))

#' error handling for group info.
if (nrow(dat) != length(groups)) {
  stop("The number of replicates and length of group is not equal\n")
}

if (!("sample" %in% levels(groups))) {
  stop("Group must include 'sample'!\n")
}

if (!all(levels(groups) %in% c("sample", "qc", "blank"))) {
  stop("Group item must be 'sample', 'qc' or 'blank'!\n")
}

if (!all(table(groups) >= 2)) {
  stop("Number of each item in group must be at least 2!\n")
}

#' change zero as NA
dat <- mv.zene(dat)

#' construct list for "sample", "qc" and "blank"
data <- lapply(levels(groups), function(x) {
  idx <- grep(x, groups)
  tmp <- dat[idx, ]
})
names(data) <- levels(groups)
cat("data dimension:\n")
sapply(data, dim)

## ==== 2) Missing value and RSD checking ====

val_rsd <- lapply(data, rsd)
#' sapply(val_rsd, summary)
p.rsd <- dist_plot(val_rsd, main = "RSD")

val_mv <- lapply(data, function(x) {
  mv.stats(x)$mv.var
})
#' sapply(val_mv, summary)
p.mv <- dist_plot(val_mv, main = "Percentage of Missing values")

pdf(file = opt$pdf_file, onefile = T) # ,width=15, height=10)
plot(p.rsd$p.box)
plot(p.rsd$p.hist)
plot(p.mv$p.box)
plot(p.mv$p.hist)
dev.off()

## ==== 3) Feature filtering ====

#' qc filtering
if (opt$qc) {
  if ("qc" %in% levels(groups)) {
    data <- qc_filter(data,
      thres_rsd = opt$qc_rsd_thres,
      f_mv = opt$qc_mv_filter,
      f_mv_qc = opt$qc_mv_qc_sam,
      thres_mv = opt$qc_mv_thres
    )
    cat("data dimension after qc filtering:\n")
    sapply(data, dim)
  }
}

#' blank filtering
if (opt$bl) {
  if ("blank" %in% levels(groups)) {
    data <- blank_filter(data,
      method = opt$bl_method,
      factor = opt$bl_factor,
      f_mv = opt$bl_mv_filter,
      thres_mv = opt$bl_mv_thres
    )
    cat("data dimension after blank filtering:\n")
    sapply(data, dim)
  }
}

#' mv filtering
if (opt$mv) {
  data <- mv_filter(data, thres_mv = opt$mv_thres)
  cat("data dimension after mv filtering:\n")
  sapply(data, dim)
}

#' wl-28-11-2018, Wed: MV filtering can be done in qc_filter,
#' blank_filter or mv_filter. Note that mv filtering on sample must be
#' performed once. Otherwise even mv imputation does not work for large
#' portion of missing values in some variables.

## ==== 4) Merge data set ====
#' want to merge sample, qc and blank?
if (opt$merge) {
  dat <- do.call(rbind, data)
} else {
  dat <- data$sample
}

## ==== 5) Missing value imputation ====
#' wl-30-11-2018, Fri: mv imputation takes two categories: univariate and
#'   multivariate. 'mean', 'median' and 'min' belongs to the former while
#'   'knn' and 'pca' the later.

dat <- mv.impute(dat, method = opt$mv_impute)

## ==== 6) Tidy up and output ====

#' transpose back
dat <- as.data.frame(t(dat))

#' get the replicate names
col_name <- lapply(levels(groups), function(x) {
  idx <- grep(x, groups)
  tmp <- rep_names[idx]
})
names(col_name) <- levels(groups)

if (opt$merge) {
  col_name <- do.call(c, col_name)
} else {
  col_name <- col_name$sample
}
names(dat) <- col_name

#' get annotation and mz values
row_ind <- rownames(dat)
row_ind <- gsub("[^\\d]", "", row_ind, perl = T)

#' Combine annotation, mz and peaks
peak_filter <- cbind(peak[row_ind, 1:2], dat)

#' save peak table
write.table(peak_filter, file = opt$filter_file, sep = "\t", row.names = F)
