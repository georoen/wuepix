#' @author Jeroen Staab
ChangeDetection <- function(now, old, min=30/255, max=220/255, extend=NULL){
  #' @import jpeg
  #' @title  Detect change.difs using image differencing
  #'
  #' @param now Path to first image
  #' @param old Path to second image
  #' @param min Threshold for positive classification
  #' @param max Threshold for positive classification
  #' @param extend DEPECATED!
  #' Used to crop images. Has been moved to a seperate preprocess step.
  #'
  #' @return Classification result. Here work is in progess...


  #Function:
  ## getImage
  ## load JPEGs and preprocess them
  getImage <- function(filename, extend=NULL){
    file <- jpeg::readJPEG(filename)
    if(!is.null(extend)){file <- file[extend[1]:extend[2], extend[3]:extend[4], ]}
    #plotJPEG(file, filename)
    return(file)
  }


  # Load Images
  now <- getImage(now, extend)
  old <- getImage(old, extend)

  #now <- getImage("now.jpg", extend)
  #old <- getImage("old.jpg", extend)



  # Image difference
  dif <- now
  dif[] <- now[]-old[]


  # Absolute Values cuz change.dif Direction doesn't matter. Due to different ligth exposures.
  hum <- abs(dif)
  hum[which(dif<0)] <-0 # Keep only positves



  # Classify Humans
  ###! this is experimental !###
  ### Himmelsrichtung: Von Osten. Position: Mittleres Kaufhaus 3.Stock (Whörl?), Richtung Westen (Festung).
  ## Treshold as from day one.
  classified <- hum[,,1]<max & hum[,,1]>min & hum[,,2]<max & hum[,,2]>min & hum[,,3]<max & hum[,,3]>min

  hum[classified]<-1
  hum[!classified]<-0


  return(hum)
}


CD_single <- function(now, old, min=30/255, max=220/255, extend=NULL){
  #' @import jpeg
  #' @title  Detect change.difs using image differencing
  #' @description in a single image.
  #'
  #' @param now Path to first image
  #' @param old Path to second image
  #' @param min Threshold for positive classification
  #' @param max Threshold for positive classification
  #' @param extend DEPECATED!
  #' Used to crop images. Has been moved to a seperate preprocess step.
  #'
  #' @return Classification result. Here work is in progess...


  #Function:
  ## getImage
  ## load JPEGs and preprocess them
  getImage <- function(filename, extend=NULL){
    file <- jpeg::readJPEG(filename)
    if(!is.null(extend)){file <- file[extend[1]:extend[2], extend[3]:extend[4], ]}
    #plotJPEG(file, filename)
    return(file)
  }


  #now <- "ROI/Ref.jpg"
  #old <- "ROI/Ref_background.jpg"
  # Load Images
  now <- getImage(now, extend)
  old <- getImage(old, extend)

  # Differerce
  change.dif <- now
  change.dif[] <- now[] - old[]
  hist(change.dif)
  range(change.dif)

  change.dif[] <- (change.dif[] +1) /2

  plotJPEG(change.dif)

  # Absolute Differerce
  change.abs <- now
  change.abs[] <- abs(now[] - old[])
  hist(change.abs)

  plotJPEG(change.abs)

  change.abs[] <- round(change.abs[], 1)

  plotJPEG(change.abs[,,3])



  # Dummmy
  change.new <- now
  change.new[] <- abs(now[] - old[])
  hist(change.new)
  range(change.new)

  change.new[] <- (change.new[] +1) /2

  plotJPEG(change.new)

}
