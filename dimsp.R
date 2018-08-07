## wl-10-07-2018, Tue: commence
## wl-13-07-2018, Fri: make script working
## wl-17-07-2018, Tue: check xcmsRaw and getSpec
## wl-06-08-2018, Mon: 
##  1.) unify positive and negative
##  2.) how to deal with multiple files? use zip or individual?
## ======================================================================

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
  library(xcms)
  library(data.table)
})

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
        ## input files
        make_option("--mzxml_file", type="character",
                    help="DIMS mzXML files list, seperated by comma"),
        make_option("--targ_file", type="character",
                    help="Lipid target list with columns of m/z and lipid name"),

        ## output files (Excel)
        make_option("--indi_file",type="character", default="sam_indi.xlsx",
                    help="Save sample individual result in Excel"),
        make_option("--sign_file",type="character", default="signals.tsv",
                    help="Save peak signals (peak table)"),
        make_option("--devi_file",type="character", default="deviations.tsv",
                    help="Save peak deviations")
    )

  opt <- parse_args(object=OptionParser(option_list=option_list),
                    args = commandArgs(trailingOnly = TRUE))
  ## print(opt)

} else {
  tool_dir <- "C:/R_lwc/dims_processing/"         ## for windows
  ## tool_dir <- "~/my_galaxy/isolab/"  ## for linux. must be case-sensitive
  opt  <- list(
      ## input files
      mzxml_file = paste(paste0(tool_dir,"test-data/DIMS_pos/030317_mouse_liver_cs16_pos_001.mzXML"),
                         paste0(tool_dir,"test-data/DIMS_pos/030317_mouse_liver_cs16_pos_002.mzXML"),
                         paste0(tool_dir,"test-data/DIMS_pos/030317_mouse_liver_cs16_pos_003.mzXML"),
                         paste0(tool_dir,"test-data/DIMS_pos/030317_mouse_liver_cs16_pos_004.mzXML"),
                         sep=","),

      targ_file  = paste0(tool_dir,"LipidList_generator/Positive_LipidList.tsv"),

      ## Excel files
      indi_file = paste0(tool_dir,"res/sam_indi.xlsx"),
      sign_file = paste0(tool_dir,"res/signals.tsv"),
      devi_file = paste0(tool_dir,"res/deviations.tsv")
  )

}

suppressPackageStartupMessages({
  source(paste0(tool_dir,"all_dimsp.R"))
})

## process multiple input files seperated by comma
tmp            <- opt$mzxml_file
tmp            <- unlist(strsplit(tmp,","))
tmp            <- gsub("^[ \t]+|[ \t]+$", "", tmp)  ## trim white spaces
opt$mzxml_file <- tmp

## file path of mzML files
## path  <- "C:/R_lwc/dims_processing/test-data/DIMS_pos"
## files <- list.files(path, pattern="mzXML",recursive = F, full.names = TRUE)
files <- opt$mzxml_file

## targets <- read.table("./Positive_LipidList.csv", header=T, sep=',', stringsAsFactors = F)
targets <- read.table(opt$targ_file, header=T, sep='\t', stringsAsFactors = F)
targets <- data.table(targets)

## ------------------------------------------------------------ 
res  <- lapply(files, function(x){  ## x = files[[1]]
                 spec <- getspectra(filename=x, rt=c(20,60), mz=c(200,1200))
                 tgts <- peaktable(targets,spec)
                 return(tgts)
})
## extract only sample names (use greedy match)
names(res) <- gsub(".*/|\\..*$","",files,perl=T)
## save(res,file="./res/res.RData")
## lapply(res, dim)

## --------------------------------------------------------------------  
## save single result
WriteXLS(res, ExcelFileName = opt$indi_file,row.names = F, 
         FreezeRow = 1)

## --------------------------------------------------------------------  
## get signals (intensity) and mz deciations
tmp        <- targets[,c("name","mz")]
signals    <- sapply(res,function(x) return(x[,"signal"]))
deviations <- sapply(res,function(x) return(x[,"mz_deviation"]))
signals    <- cbind(tmp,signals)
deviations <- cbind(tmp,deviations)
## save results
write.table(signals, file=opt$sign_file, sep="\t",row.names=F)
write.table(deviations, file=opt$devi_file,sep="\t",row.names=F)

######################################################################
## Original R codes
######################################################################
if (F){
  source("all_dimsp.R") 

  ## file path of mzML files
  path  <- "C:/R_lwc/dims_processing/test-data/DIMS_pos"
  files <- list.files(path, pattern="mzXML",recursive = F, full.names = TRUE)

  targets <- read.table("./LipidList_generator/Positive_LipidList.csv", header=T, sep=',',
                        stringsAsFactors = F)
  targets <- data.table(targets)

  ## ------------------------------------------------------------ 
  if (T) {
    res  <- lapply(files, function(x){   
                     ## x = files[[1]]
                     spec <- getspectra(filename=x, rt=c(20,60), mz=c(200,1200))
                     tgts <- peaktable(targets,spec)
                     return(tgts)
                        })
    ## extract only sample names (use greedy match)
    names(res) <- gsub(".*/|\\..*$","",files,perl=T)
    save(res,file="./res/res.RData")
  } else {
    load("res.RData")
  }

  lapply(res, dim)

  ## --------------------------------------------------------------------  
  ## save single result
  WriteXLS(res, ExcelFileName = "./test-data/res_POS.xlsx",row.names = F, 
           FreezeRow = 1)
  if (F) { ## or use this 
    lapply(names(res),function(x){
             write.csv(res[[x]], file=paste0("./test-data/",x,".csv"),row.names=F)
           })
  }

  ## --------------------------------------------------------------------  
  ## get signals (intensity) and mz deciations
  tmp        <- targets[,c("name","mz")]
  signals    <- sapply(res,function(x) return(x[,"signal"]))
  deviations <- sapply(res,function(x) return(x[,"mz_deviation"]))
  signals    <- cbind(tmp,signals)
  deviations <- cbind(tmp,deviations)
  ## save results
  write.csv(signals, file="./test-data/signals.csv",row.names=F)
  write.csv(deviations, file="./test-data/deviations.csv",row.names=F)

  ## results <- signals_deviations()   
  ## gc() # helps memory allocation errors on low memory systems

}

######################################################################
## Temp codes for debugging only
######################################################################
## ===================================================================
if (F) { ## Use MSnbase package to read data.
  ## ----------------------------------------------------------------
  raw_data <- readMSData(files, mode = "onDisk")
  raw_data
  slotNames(raw_data)
  
  ## -------------------- 
  rt  <- rtime(raw_data)
  class(rt)                          ## numeric
  length(rt)                         ## 2673 = 9 * 297

  ## -------------------- 
  mzs <- mz(raw_data)
  ## Split the list by file
  mzs_by_file <- split(mzs, f = fromFile(raw_data))
  length(mzs_by_file)                ## 9 
  length(mzs_by_file[[1]])           ## 297 
  length(mzs_by_file[[1]][[1]])      ## 13004 
  
  ## -------------------- 
  inten  <- intensity(raw_data)
  inten_by_file <- split(inten, f = fromFile(raw_data))
  length(inten_by_file)              ## 9
  length(inten_by_file[[1]])         ## 297
  length(inten_by_file[[1]][[1]])    ## 13004
}

## ===================================================================
if (F){   ## use xcms to load data
  ## ----------------------------------------------------------------
  xr <- xcmsRaw(files[1])
  xr

  ## ---------------------------------------- 
  ## Lets have a look at the structure of the object
  slotNames(xr)
  ## names(attributes(xr)) 
  ## str(xr)

  xr@scantime
  xr@scanindex
  head(xr@scanindex)
  
  names(xr@env)     ## profile, mz, intensity
  xr@env$mz[425:430]

  ## ---------------------------------------- 
  mz.scan1        <- xr@env$mz[(1+xr@scanindex[1]):xr@scanindex[2]]
  intensity.scan1 <- xr@env$intensity[(1+xr@scanindex[1]):xr@scanindex[2]]
  plot(mz.scan1, intensity.scan1, type="h", 
       main=paste("Scan 1 of file", basename(files[1]), sep=""))

  ## the easier way
  scan1 <- getScan(xr, 1)
  head(scan1)
  plotScan(xr, 1)

  ## ---------------------------------------- 
  spec   <- getSpec(xr, rtrange=c(20,60), mzrange=c(200,1200)) 
  spec_1 <- getSpec(xr, t=c(20,60), m=c(200,1200))   ## rtrange and mzrange
  spec_2 <- getSpec(xr, m=c(200,1200))               ## mzrange
  spec_3 <- getSpec(xr, s=c(98,297), m=c(200,1200))  ## scanrange and mzrange
  spec_4 <- getSpec(xr)
  
  ## Note: The results of 'spec' ~ 'spec_4' are confused:
  ##  - is rt 'scantime' in this case?
  ##  - Source code of `getSpec` does not use 'rtrange'. 
  ##  - strange: results of 'spec' and 'spec_1' are not the same.
  
  dim(spec)                 ## [1] 2096693       2
  length(unique(spec[,1]))  ## [1] 2096693
  
  spec[,"mz"] <- round(spec[,"mz"], digits=4)
  spec <- as.data.table(spec)
  spec <- spec[,mean(intensity), by=mz]
  spec <- na.omit(spec)

}
