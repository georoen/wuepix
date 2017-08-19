#' @author Jeroen Staab

plotJPEG <- function(img, main=NULL){
  #' @title plotJPEG()
  #' @description Simply plot an image.
  #'
  #' @param img A raster object.
  #' @param main Optional. An overall title for the plot.
  #'
  #' @details Images can be loaded as raster object using `JPEG::readJPEG()`.
  plot(img, xlim = c(0,ncol(img)), ylim = c(nrow(img),0),
       type='n', ylab = "Y", xlab = "X",
       main=main)
  rasterImage(img, 0, nrow(img), ncol(img), 0)
}


GTD_list <- function(img.list){
  #' @title Sample Ground Truth Data
  #' @description Manually asses number of persons in multiple images.
  #' @param img.list file path to image, also known as `now`.
  #' @return numeric vector with number of persons.
  #' @import jpeg

  #dev.new()

  # Allocate output
  rtn <- img.list
  rtn[] <- NA

  # Function
  GTD_single <- function(img) {
    plotJPEG(jpeg::readJPEG(img), basename(img))
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
