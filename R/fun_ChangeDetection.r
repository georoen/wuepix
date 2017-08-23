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

CD_single <- function(file.now, file.old, min=0.2, max=1, predictions=NULL,
                      extend=NULL, plot=FALSE){
  #' @title Change Detection
  #' @title  Detect changes between two images using image differencing
  #'
  #' @param now Path to first image
  #' @param old Path to second image
  #' @param min Threshold for positive classification
  #' @param max Threshold for positive classification
  #' @param predictions dir path to where to store prediction images
  #' @param extend DEPECATED!
  #' Used to crop images. Has been moved to a seperate preprocess step.
  #'
  #' @return Classification result. Here work is in progess...


  # Load Images
  now <- getImage(file.now, extend, plot)
  old <- getImage(file.old, extend, plot)


  # Image difference
  dif <- now
  dif[] <- now[]-old[]


  # Absolute Values cuz change.dif Direction doesn't matter. Due to different ligth exposures.
  hum <- abs(dif)
  hum[which(dif<0)] <-0 # Keep only positves (now > old. Heller geworden)

  if(!is.null(predictions)){
    dir.create(predictions)
    jpeg::writeJPEG(hum, file.path(predictions, basename(file.now)))
  }

  # Classify Humans
  ###! this is experimental !###
  ### Himmelsrichtung: Von Osten. Position: Mittleres Kaufhaus 3.Stock (Whörl?), Richtung Westen (Festung).
  ## Treshold as from day one.
  classified <- hum[,,1]<max & hum[,,1]>min & hum[,,2]<max & hum[,,2]>min & hum[,,3]<max & hum[,,3]>min

  hum[classified]<-1
  hum[!classified]<-0


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

  act.Data <- foreach::foreach(now=img.list[2:old.stop],
                      old=img.list[1:new.stop],
                      .combine=c) %dopar%
    sum(wuepix::CD_single(now, old, ...))

  parallel::stopCluster(cl)

  act.Data <- c(NA,act.Data)
  act.Data
}
