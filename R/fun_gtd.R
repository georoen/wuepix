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
