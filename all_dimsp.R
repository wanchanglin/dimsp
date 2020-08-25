#' wl-10-07-2018, Tue: Begin to modify
#' wl-11-07-2018, Wed: test 'getspectra'
#' wl-29-08-2018, Wed: add 'hwidth' for peaktable
#' wl-01-03-2019, Fri: reformat with 'styler' and change comment string
#' wl-25-08-2020, Tue: Review

#' =======================================================================
#' This function uses xcms to get the average spectra for a sample and
#' cleans up the spectra by rounding the ms data to 4 decimal places as well
#' as removing NA values. The function has three arguments, a file name the
#' retention time window that data will be averaged from the direct infusion
#' of sample and the mass spectral range that is desired.  common values
#' are: rt <- c(0,60) and mz <- c(200,1800)
getspectra <- function(filename, rt, mz) {
  spectrum <- getSpec(xcmsRaw(filename), rtrange = rt, mzrange = mz)
  spectrum[, "mz"] <- round(spectrum[, "mz"], digits = 4)
  spectrum <- as.data.table(spectrum)
  spectrum <- spectrum[, mean(intensity), by = mz]
  spectrum <- na.omit(spectrum)
  setkey(spectrum, mz)
  return(spectrum)
}

#' =======================================================================
#' This function calls the peakfinding algorithm in a loop finding the
#' closest peak maximum m/z and intensity values appending results to
#' variables signals and nearest_mz.  It returns the data.frame peak_id
#' which includes all results from the targeted analysis of the current
#' spectra
#' wl-29-08-2018, Wed: add 'hwidth'
peaktable <- function(targets, spectra, hwidth = 0.01) {
  nearest_mz <- vector(length = length(targets$mz)) # predefine length later
  signal <- vector(length = length(targets$mz)) # predefine length later
  for (i in 1:length(targets$mz)) {
    target <- targets[i, mz]
    peak <- peakfind_midpoint(target, spectra, hwidth, warnings)
    nearest_mz[i] <- peak[1, mz]
    signal[i] <- peak[1, V1]
  }

  mz_deviation <- targets[, mz] - nearest_mz
  peak_id <- data.frame(
    targets$name, targets$mz, nearest_mz,
    mz_deviation, signal
  )
  return(peak_id)
}

#' =======================================================================
#' This is a refined peak finder that calculates the midpoint between a line
#' drawn at the half height. This will give closer m/z values, but does not
#' correct any small errors in intensity calculations from the peak max
#' finder.  Used in main() as of 28/01/2014. -Luke Marney
peakfind_midpoint <- function(target, spectra, hwidth, warnings) {
  window <- subset(spectra, spectra$mz > target - hwidth &
                            spectra$mz < target + hwidth)

  if (nrow(window) == 0) { # no data for target?
    ## enter zero intensity for target mass
    peak <- data.table("mz" = target, "V1" = 0)
  } else if (sum(window$V1) < 5000) { # very low s/n?
    peak <- peakfind_max(target, spectra, hwidth)

    #' uses older peakmax finder for low s/n peaks, while less accurate this
    #' helps with exception handling dramatically

    warning(paste("low signal/noise found for target mass-", target,
                  "-using older peakmax finder. Identification may not be accurate",
                  sep = " "))
  } else { #' now we run the peak width peak finder

    #' at this point we need to readjust window first to the maximum found
    #' with peakfind_max(). This centers the peak better in a window, so
    #' that the entire peak is sampled for width at half height
    #' calculations. The rest of this function does this as well as the
    #' actual width at half height calculations.##

    peak <- peakfind_max(target, spectra, hwidth)
    hh_close <- peak[1, V1] / 2
    window <- subset(spectra, spectra$mz > peak$mz - hwidth &
                              spectra$mz < peak$mz + hwidth)

    if (window$V1[length(window$mz)] > hh_close | window$V1[1] > hh_close) {
      ## window doesn't sample the width of the peak?
      ## this will sort table by intensity, thus finding peak maximum as last
      ## entry in table
      setkey(window, V1)
      ## get last entry of table for the peak maximum
      peak <- window[length(window$mz)]
      window <- subset(spectra, spectra$mz > peak$mz - hwidth &
                                spectra$mz < peak$mz + hwidth)
      setkey(window, mz)
      if (window$V1[length(window$mz)] > hh_close | window$V1[1] > hh_close) {
        ## is the bad sampling of peak due to interference?
        ## this will sort table by intensity, thus finding peak maximum as last
        ## entry in table
        setkey(window, V1)
        ## get last entry of table for the peak maximum
        peak <- window[length(window$mz)]
        warning((paste("interfered peak detected for target mass-", target,
                       "-older peak_max() function used", sep = " ")))
      }
    } else {
      #' for resolved peaks (at half height) the follow code is run ##
      ## this will sort table by intensity, thus finding peak maximum as last
      ## entry in table
      setkey(window, V1)
      ## get last entry of table for the peak maximum
      peak <- window[length(window$mz)]
      hh <- peak[1, V1] / 2
      nearmz <- peak[1, mz]
      #' separate left and right side of peak
      left <- window[window[, mz] <= peak$mz]
      right <- window[window[, mz] >= peak$mz]
      left_one <- left[left[, V1] <= hh]
      ## closest point below hh needs to index last entry in table
      left_one <- left_one[length(left_one[, mz])]
      ## can do an index of 1, because it is sorted by intensity
      left_two <- left[left[, V1] >= hh][1]
      ## can do an index of 1, because it is sorted by intensity
      right_one <- right[right[, V1] >= hh][1]
      right_two <- right[right[, V1] <= hh]
      ## closest point below hh needs to index last entry in table
      right_two <- right_two[length(right_two[, mz])]

      if (left_two[, mz] == right_one[, mz]) {
        warning(paste("Same point seen for left and right side of", target,
                      ". Possible undersampled peaks?"))
      }

      #' organize data into a data frame (called midpoints) for easier handling
      left_mzs <- c(left_one[, mz], left_two[, mz])
      left_int <- c(left_one[, V1], left_two[, V1])
      right_mzs <- c(right_one[, mz], right_two[, mz])
      right_int <- c(right_one[, V1], right_two[, V1])
      midpoints <- data.frame(left_mzs, left_int, right_mzs, right_int)
      #' there has got to be a way to combine the last five rows into one row
      coordinates <- list()
      left <- coefficients(lm(left_int ~ left_mzs, data = midpoints))
      right <- coefficients(lm(right_int ~ right_mzs, data = midpoints))
      ## midpoint between the intersection points of both lines from a y=hh flat
      ## line
      midpoint <- ((hh - left[1]) / left[2] + (hh - right[1]) / right[2]) / 2
      ## modify the peaks variable with the new more accurate m/z value
      peak$mz <- round(midpoint[1], digits = 4)
    }
  }
  return(peak)
}

#' =======================================================================
#' This function is the simplest peak finder.  It finds the maximum
#' intensity in a defined  window around the target m/z. Not used in main()
#' as of 28/01/2014. -Luke Marney
peakfind_max <- function(target, spectra, hwidth) {
  window <- subset(spectra, spectra$mz > target - hwidth &
                            spectra$mz < target + hwidth)
  setkey(window, V1)
  #' this will sort table by intensity, thus finding peak maximum as last
  #' entry in table
  peak <- window[length(window$mz)] # get last entry of table for the peak maximum
  #' plot(window, type='h', lwd=1)
  return(peak)
}
