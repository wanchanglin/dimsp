## ======================================================================
## wl-01-11-2018, Thu: commence dimsp filtering implementation
## wl-18-11-2018, Wed: add MV and RSD distribution plots, which are used to
##   choose threshold of MV and RSD.
## wl-20-11-2018, Tue: add MV imputation by univariate or multivariate
## ======================================================================
## To-do:
##   1) wrap for galaxy
##   2) Merge data set?

## ========================================================================
## 1) Setting
## ========================================================================
rm(list=ls(all=T))   ## clear all
tool_dir  <- "C:/R_lwc/dimsp_filter/"
source(paste0(tool_dir,"fs_filter.R"))

## ========================================================================
## 2) Data loading
## ========================================================================
load(paste0(tool_dir,"res/pos_res.RData"))
dat  <- sapply(res,function(x) return(x[,"signal"]))

## ========================================================================
## 3) Data preparation
## ========================================================================
## transpose data set
dat <- as.data.frame(t(dat)) 

## get sample, qc and blan info
cls <- rownames(dat)
cls <- gsub("\\d|_", "", cls, perl=T)
cls <- gsub("pool", "qc", cls, perl=T)
(cls <- as.factor(cls))

## change zero as NA
dat <- mv.zene(dat)          

## construct list for "sample", "qc" and "blank"
data <- lapply(levels(cls), function(x){
  idx <- grep(x,cls)
  tmp <- dat[idx,]
})
names(data) <- levels(cls)
sapply(data,dim)

## ===================================================================
## 4) Missing value and RSD checking
## =========================================================================

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
## 5) Feature filtering
## ========================================================================
## MV filtering on 'sample'
data.mv <- mv_filter(data, thres_mv = 0.30)
sapply(data.mv,dim)

## qc filtering
data.qc <- qc_filter(data, thres_rsd = 20, 
                     f_mv = T, f_mv_qc = T, thres_mv = 0.30)
sapply(data.qc,dim) 

## blank filtering
data.blank <- blank_filter(data, method = "mean", factor = 1, 
                           f_mv = T, thres_mv = 0.30)
sapply(data.blank,dim)

## combine qc and blank filtering
data.qb <- qc_filter(data, thres_rsd = 20, 
                     f_mv = T, f_mv_qc = T, thres_mv = 0.50)
sapply(data.qb,dim) 

## blank filtering
data.qb <- blank_filter(data.qb, method = "mean", factor = 1, 
                           f_mv = T, thres_mv = 0.50)
sapply(data.qb,dim)

## ========================================================================
## 6) Missing value imputation
## ========================================================================

dat      <- data.qb$sample

dat.mean <- mv.impute(dat, method = "mean")
dat.min  <- mv.impute(dat, method = "min")
dat.knn  <- mv.impute(dat, method = "knn")
dat.pca  <- mv.impute(dat, method = "pca")

