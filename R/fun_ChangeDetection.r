#' @author Jeroen Staab
# getImage
getImage <- function(filename, extend=NULL, plot=FALSE){
  ## load JPEGs and preprocess them
  #' filename Path to first image
  #' extend Optional extend to crop image, numeric vector.
  #' plot Optional plot loaded image, boolean.
  #' @import jpeg
  file <- jpeg::readJPEG(filename)
  if(!is.null(extend)){file <- file[extend[1]:extend[2], extend[3]:extend[4], ]}
  if(plot)
    JPEG_plot(file, filename)
  return(file)
}

CD_single <- function(file.now, file.old, Min=0.2, Max=1, predictions=NULL,
                      extend=NULL, plot=FALSE, method = "diff"){
  #' @title Change Detection
  #' @title  Detect changes between two images using image differencing
  #'
  #' @param now Path to first image
  #' @param old Path to second image
  #' @param Min Threshold for positive classification
  #' @param Max Threshold for positive classification
  #' @param predictions dir path to where to store prediction images
  #' @param extend DEPECATED!
  #' Used to crop images. Has been moved to a seperate preprocess step.
  #' @param method Select change detection method.
  #' "ratio" Image Rationing. "diff" Image Differencing, absolute changes in
  #' both directions. "diff+" Image Differencing, positive changes only.
  #'
  #' @return Classification result. Here work is in progess...


  # Load Images
  now <- getImage(file.now, extend, plot)
  old <- getImage(file.old, extend, plot)

  # Define change detection methods
  method_diff_pos <- function(now, old, Min, Max) {
    # Image difference. Positiv changes only (brigther. darker parts in next iteration)
    dif <- now
    dif[] <- now[]-old[]
    # Absolute Values cuz change.dif Direction doesn't matter. Due to different ligth exposures.
    #hum <- abs(dif)
    hum <- dif
    hum[which(dif<0)] <-0 # Keep only positves (now > old. Heller geworden)
    # Classify Humans
    ## Treshold as from day one.
    classified <- hum[,,1]<Max & hum[,,1]>Min & hum[,,2]<Max & hum[,,2]>Min & hum[,,3]<Max & hum[,,3]>Min
    hum[classified]<-1
    hum[!classified]<-0
    hum[,,1]
  }

  method_diff <- function(now, old, Min, Max) {
    # Image Difference. Absolute changes (both)
    dif <- now
    dif[] <- now[]-old[]
    # Absolute Values cuz change.dif Direction doesn't matter. Due to different ligth exposures.
    hum <- abs(dif)
    #hum[which(dif<0)] <-0 # Keep only positves (now > old. Heller geworden)
    # Classify Humans
    ## Treshold as from day one.
    classified <- hum[,,1]<Max & hum[,,1]>Min & hum[,,2]<Max & hum[,,2]>Min & hum[,,3]<Max & hum[,,3]>Min
    hum[classified]<-1
    hum[!classified]<-0
    hum[,,1]
  }

  method_ratio <- function(now, old, Min, Max) {
    # Image Ratio. Absolute changes (both)
    dif <- now
    dif[] <- log((now[]+0.0001)/(old[]+0.0001))  # As in BERBERGOLU 2008 p.48
    #dif[] <- atan(now[]/old[]) - pi/4  # As in ILSEVER 2012 p.11
    # Absolute Values cuz change.dif Direction doesn't matter. Due to different ligth exposures.
    hum <- abs(dif)
    #hum[which(dif<0)] <-0 # Keep only positves (now > old. Heller geworden)
    # Classify Humans
    ## Treshold as from day one.
    classified <- hum[,,1]<Max & hum[,,1]>Min & hum[,,2]<Max & hum[,,2]>Min & hum[,,3]<Max & hum[,,3]>Min
    hum[classified]<-1
    hum[!classified]<-0
    hum[,,1]
  }

  method_t_test <- function(now, old, Min, Max){
    # As in RADKE 2005 p. 299
    hum <- t.test(now[], old[])$p.value
    #hum <- hum > Min & hum < Max
    as.numeric(hum)
  }

  # Select change detion method
  method <- paste0("method_", method)
  if(!method %in% ls(environment()))
    stop(cat("Undefined method selected. Implemented: ", lsf.str(environment())))
  method <- get(method)

  hum <- method(now, old, Min, Max)

  if(!is.null(predictions)){
    dir.create(predictions)
    jpeg::writeJPEG(hum, file.path(predictions, basename(file.now)))
  }

  return(c(hum))
}


CD_list <- function(img.list, ...){
  #' @title Change Detection
  #' @description Detect changes using image differencing for a list of images.
  #' Includes parallel processing.
  #'
  #' @param img.list file path to images.
  #' @param ... Arguments passed to CD_single().
  #'
  #' @return Classification result. Here work is in progess...
  #'
  #' @import doParallel
  #' @import foreach
  `%dopar%` <- foreach::`%dopar%`

  cores <- parallel::detectCores()-1
  cl <-parallel:: makeCluster(cores)
  doParallel::registerDoParallel(cl)
  old.stop <- length(img.list)
  new.stop <- old.stop-1

  act.Data <- foreach::foreach(now=img.list[1:new.stop],
                               old=img.list[2:old.stop],
                               .combine=c) %dopar%
    sum(wuepix::CD_single(now, old, ...))

  parallel::stopCluster(cl)

  act.Data <- c(NA,act.Data)
  act.Data
}
