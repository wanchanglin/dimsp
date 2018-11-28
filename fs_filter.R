## wl-06-11-2018, Tue: filter functions for DIMSP 

suppressPackageStartupMessages({
  library(reshape)
  library(lattice)
  library(impute)
  library(pcaMethods)
})

## =========================================================================
## wl-02-06-2011: Relative standard deviation of matrix/data frame in
## column wise
rsd <- function(x) {
  mn  <- colMeans(x,na.rm=TRUE)
  std <- apply(x,2,sd, na.rm=TRUE)
  ## std <- sd(x,na.rm=TRUE)           ## sd(<data.frame>) is deprecated.
  res <- 100 * std/mn
  return(res)
}

## =======================================================================
## wl-11-12-2007: Statistics and plot for missing values
mv.stats <- function(dat,grp=NULL,...) {
  ## overall missing values rate
  mv.all <- sum(is.na(as.matrix(dat)))/length(as.matrix(dat))

  ## MV stats function for vector
  vec.func  <-
    function(x)  round(sum(is.na(x)|is.nan(x))/length(x), digits=3)
  ## vec.func  <- function(x)  sum(is.na(x)|is.nan(x)) ## number of MV
  ## sum(is.na(x)|is.nan(x)|(x==0))

  ## get number of Na, NaN and zero in each of feature/variable
  ## mv.rep <- apply(dat, 1, vec.func)
  mv.var <- apply(dat, 2, vec.func)

  ret <- list(mv.overall = mv.all,mv.var = mv.var)

  ## -------------------------------------------------------------------
  if (!is.null(grp)){
    ## MV rate with respect of variables and class info
    mv.grp <- sapply(levels(grp), function(y) {
                       idx <- (grp == y)
                       mat <- dat[idx,]
                       mv <- apply(mat, 2, vec.func)
                     })
    ## --------------------------------------------------------------------
    ## wl-10-10-2011: Use aggregate. Beware that values passed in the
    ## function is vector(columns).
    ## mv.grp <- aggregate(dat, list(cls), vec.func)
    ## rownames(mv.grp) <- mv.grp[,1]
    ## mv.grp <- mv.grp[,-1]
    ## mv.grp <- as.data.frame(t(mv.grp),stringsAsFactors=F)

    ## reshape matrix for lattice
    mv.grp.1     <- data.frame(mv.grp)
    mv.grp.1$all <- mv.var              ## Combine all

    var         <- rep(1:nrow(mv.grp.1), ncol(mv.grp.1))
    mv.grp.1     <- stack(mv.grp.1)
    mv.grp.1$ind <- factor(mv.grp.1$ind,
                           levels = unique.default(mv.grp.1$ind))
    mv.grp.1$var <- var

    mv.grp.plot <-
      xyplot(values ~ var |ind, data=mv.grp.1, groups=ind, as.table=T,
             layout=c(1,nlevels(mv.grp.1$ind)), type="l",
             auto.key=list(space="right"),
             ## main="Missing Values Percentage With Respect of Variables",
             xlab="Index of variables", ylab="Percentage of missing values",
             ...)

    ## --------------------------------------------------------------------
    ret$mv.grp       <- mv.grp
    ret$mv.grp.plot  <- mv.grp.plot
  }

  ret
}

## =========================================================================
## wl-11-10-2011: replace zero/negative with NA.
mv.zene <- function(dat) {
  vec.func <- function(x) {
    x <- ifelse(x < .Machine$double.eps, NA, x)  ## vectorisation of ifelse
  }

  dat <- as.data.frame(dat, stringsAsFactors=F)
  res <- sapply(dat, function(i) vec.func(i))
  return(res)
}

## ========================================================================
## wl-06-11-2018, Tue: feature filter index based on missing values
## Arguments:
##   x: a data frame where columns are features
##   thres_mv: threshold of missing values. Features less than this
##             threshold will be kept.
## Return:
##   a logical vector of index for keeping features
.mv_filter <- function(x, thres_mv = 0.30){
  res <- mv.stats(x)
  idx <- res$mv.var < thres_mv
  return(idx)
}

## ========================================================================
## wl-06-11-2018, Tue: feature filter index based on RSD
## Arguments:
##   x: a data frame where columns are features
##   thres_rsd: threshold of RSD. Features less than this threshold will be
##              kept.
## Return:
##   a logical vector of index for keeping features
## ========================================================================
.rsd_filter <- function(x, thres_rsd = 20){
  res <- rsd(x)
  idx <- res < thres_rsd
  idx[is.na(idx)] <- FALSE
  ## some stats
  if (F) {
    summary(res)
    tmp <- hist(res,plot=F)$counts
    hist(res, xlab="rsd",ylab="Counts",col='lightblue',
         ylim=c(0, max(tmp)+10))
  }
  return(idx)
}

## ========================================================================
## wl-06-11-2018, Tue: Feature filtering based on missing values of samples
## Arguments:
##   data: a data matrix list including "sample", "qc" and "blank"
##   thres_mv: threshold of missing values on sample. Features less than this
##             threshold will be kept.
## Return:
##   a filtered data list including "sample", "qc" and "blank"
## ========================================================================
mv_filter <- function(data, thres_mv = 0.30){
  idx  <- .mv_filter(data$sample,thres_mv = thres_mv)
  data <- lapply(data, function(x){ x <- x[, idx] })

  return(data)
}

## ========================================================================
## wl-06-11-2018, Tue: Feature filtering based on QC's RSD
## wl-14-11-2018, Wed: add flag to missing value filtering
## Arguments:
##   data: a data matrix list including "sample", "qc" and "blank"
##   thres_rsd: threshold of RSD on QC. Features less than this
##             threshold will be kept.
##   f_mv: a flag indicating whether or not to performance missing value
##         filtering.
##   f_mv_qc: a flag for filtering using percentage of missing values on "qc"
##            or "sample". TRUE is for "qc".
##   thres_mv: threshold of missing values. Features less than this
##             threshold will be kept.
## Return:
##   a filtered data list including "sample", "qc" and "blank"
## ========================================================================
qc_filter <- function(data, thres_rsd = 20, f_mv = TRUE, 
                      f_mv_qc = FALSE, thres_mv = 0.30){
  ## ----------------------------------------------------------------------  
  ## 1) filtering based on missing values: sample or qc.
  if (f_mv) {
    if (f_mv_qc) {
      mat <- data$qc
    } else {
      mat <- data$sample
    } 
    idx  <- .mv_filter(mat,thres_mv = thres_mv)
    data <- lapply(data, function(x){ x <- x[, idx] })
  }

  ## ----------------------------------------------------------------------  
  ## 2) filtering based rsd of "qc"
  idx  <- .rsd_filter(data$qc,thres_rsd = thres_rsd)
  data <- lapply(data, function(x){ x <- x[, idx] })

  return(data)
}

## ========================================================================
## wl-06-11-2018, Tue: Feature filtering based on blank
## wl-14-11-2018, Wed: change order of missing value filtering
## Arguments:
##   data: a data matrix list including "sample", "qc" and "blank"
##   method: method for stats. Support "mean", "median" and "max"
##   factor: multiplier for blank stats
##   f_mv: a flag indicating whether or not to performance missing value
##         filtering.
##   thres_mv: threshold of missing values on QC. Features less than this
##             threshold will be kept.
## Return:
##   a filtered data list including "sample", "qc" and "blank"
## ========================================================================
blank_filter <- function(data, method = c("mean","median","max"), 
                         factor = 1, f_mv = TRUE, thres_mv = 0.30){
  method <- match.arg(method)
  ## ----------------------------------------------------------------------  
  ## 1) filtering based on missing values of "sample".
  if (f_mv) {
    idx  <- .mv_filter(data$sample, thres_mv = thres_mv)
    data <- lapply(data, function(x){ x <- x[, idx] })
  }

  ## ----------------------------------------------------------------------  
  ## 2) filtering based on characteristics of blank intensities: mean, median
  ##    or max
  
  stats.blank  <- apply(data$blank, 2, method, na.rm=TRUE)
  stats.blank  <- factor * stats.blank
  stats.sample <- apply(data$sample, 2, method, na.rm=TRUE)

  ## keep features with sample stats are larger than blank 
  idx <- stats.sample >= stats.blank
  idx[is.na(idx)] <- FALSE
  ## Also keep features whose values are NA in blank
  idx.1 <- is.na(stats.blank)
  ## take union
  idx <- idx | idx.1

  data <- lapply(data, function(x){ x <- x[, idx] })

  return(data)
}

## =======================================================================
## wl-19-11-2018, Mon: wrapper function for distribution of data stats such
## as rsd and percentage of missing values.
## Arguments:
##   x: an vector list including "sample", "qc" and "blank"
##   main: plot title
## Return:
##   a list of lattice plot objects including histogram and boxplot
## 
dist_plot <- function(x,main=""){
  x <- melt(x)
  p.hist <- histogram(~ value | L1, data=x, 
                 type="count", ## type="density",
                 nint = 100,
                 as.table=T,  layout = c(1,3), main=main,
                 scales=list(cex =.75,relation="free"))

  ## --------------------------------------------------------------------- 
  ## histogram with density (problem with missing values)
  ## --------------------------------------------------------------------- 
  ## p <- histogram(~ value | L1, data = x, type = 'density',nint = 50,
  ##                as.table=T,  layout = c(1,3), main=main,
  ##                scales=list(cex =.75,relation="free"),
  ##                panel = function(x, subscripts, ...) {
  ##                  panel.histogram(x, ...)
  ##                  panel.mathdensity(dnorm, col = 'red', ...)
  ##                  panel.densityplot(x, plot.points = FALSE, col = 'navy',...)
  ##                } )

  ## boxplot
  p.box <- bwplot(value ~ L1, data=x, main = main)

  return(list(p.hist=p.hist, p.box=p.box))
}

## ========================================================================
## lwc-23-04-2010: Fill the zero/NA values by univariate.
mv.fill <- function(dat,method="mean",ze_ne = FALSE) {
  method <-
    if (is.function(method)) method
    else if (is.character(method)) get(method)
    else eval(method)

  vec.func <- function(x) {
    if (ze_ne) {
      x <- ifelse(x < .Machine$double.eps, NA, x)
      ## vectorisation of ifelse
    }
    m <- method(x, na.rm=TRUE)

    x[is.na(x)] <- m
    x
  }

  dat <- as.data.frame(dat, stringsAsFactors=F)
  res <- sapply(dat, function(i) vec.func(i))
  return(res)
}

## =======================================================================
## wl-20-11-2018, Tue: Missing value imputation
## 
mv.impute <- function(x, method=c("mean","median","min","knn","pca")){
  method <- match.arg(method)
  if (method == "knn") {
    x <- t(impute::impute.knn(t(x))$data)
    ## x <- suppressWarnings(t(impute.knn(t(x))$data))
  } else if (method == "pca"){
    x <- pcaMethods::pca(x, method="ppca", nPcs=5)@completeObs
    x[x<0] <- min(x[x>0])	## in case negative value
  } else {
    x <- mv.fill(x,method=method)
  }
  x <- as.data.frame(x)
}
