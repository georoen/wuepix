#' @author Jeroen Staab
# Ground Truth Data Tools
# Function
GTD_single <- function(img) {
  #' @title Sample Ground Truth Data
  #' @description Manually asses number of persons in a single image.
  #' @param img file path to image, also known as `now`.
  #' @return numeric vector with number of persons.
  #' @import jpeg

  JPEG_plot(jpeg::readJPEG(img), basename(img))
  res <- readline("Please enter number of persons: ")
  if(res == ""){
    cat("EMPTY equals 0 persons.")
    res <- 0
  }
  res <- as.numeric(res)
  if(is.na(res)){
    cat("Not numeric - try again!")
    res <- GTD_single(img)
  }
  res
}


GTD_list <- function(img.list){
  #' @title Sample Ground Truth Data
  #' @description Manually asses number of persons in multiple images.
  #' @param img.list file path to image, also known as `now`.
  #' @return numeric vector with number of persons.

  # Allocate output
  rtn <- img.list
  rtn[] <- NA

  # Loop
  p <- round(seq(1, length(img.list), length.out = 10))  # Progress
  for(i in 1:length(img.list)){
    img <- img.list[i]
    rtn[i] <- GTD_single(img)

    if(i %in% p)
      message(paste("Progress:", round(i/length(img.list)*100), "%"))
  }

  as.numeric(rtn)
}


# Accuracy Assesment
GTD_truePositives <- function(GTD, PRD){
  #' @title Benchmark Pedestrian Detection
  #' @description Accuracy Assesment for Object-Based Classifiers as in DALAL
  #' etal. 2005 p. 888
  #' @return FalseNegative, TruePositives, FalsePositive, MissRate,
  #' FalsePositvesPerWindow
  #' @param GTD Numeric vector of Ground-Truth-Data, as returned by GTD_list()
  #' @param PRD Numeric vector of prediction values, as returned by hog_list()
  #' and yolo_list()

  print(cor.test(GTD, PRD))

  df <- data.frame(GTD = GTD, PRD = PRD)

  df %>%
    mutate(FP = PRD - GTD,
           FP = ifelse(FP >=0, FP, 0),  # positive values only
           TP = PRD - FP,
           FN = GTD - PRD,
           FN = ifelse(FN >=0, FN, 0))  %>%
    summarise(FN = sum(FN),
              TP = sum(TP),
              FP = sum(FP),
              MR = FN/(TP + FN),
              FPPW = FP/n())

}
