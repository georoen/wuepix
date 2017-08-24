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
                      extend=NULL, plot=FALSE){
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
  #'
  #' @return Classification result. Here work is in progess...


  # Load Images
  now <- getImage(file.now, extend, plot)
  old <- getImage(file.old, extend, plot)


  method_1 <- function(now, old, Min, Max) {
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

  method_2 <- function(now, old, Min, Max) {
    # Image difference. Absolute changes (both)
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

  hum <- method_2(now, old, Min, Max)

  if(!is.null(predictions)){
    dir.create(predictions)
    jpeg::writeJPEG(hum, file.path(predictions, basename(file.now)))
  }

  return(hum)
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


CD_seq <- function(img.list, ...){
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

  act.Data <- foreach::foreach(now=img.list1[seq(1,new.stop, by=2)],
                               old=img.list[seq(2,old.stop, by=2)],
                               .combine=c) %dopar%
    sum(wuepix::CD_single(now, old, ...))

  parallel::stopCluster(cl)

  act.Data <- c(NA,act.Data)
