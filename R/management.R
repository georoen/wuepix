#' @author Jeroen Staab

plotJPEG <- function(img, main=NULL){
  #' @title plotJPEG()
  #' @description Simply plot an image.
  #'
  #' @param img A raster object.
  #' @param main Optional. An overall title for the plot.
  #'
  #' @details Images can be loaded as raster object using `JPEG::readJPEG()`.
  plot(0, xlim = c(0,ncol(img)), ylim = c(nrow(img),0),
       type='n', ylab = "Y", xlab = "X",
       main=main)
  rasterImage(img, 0, nrow(img), ncol(img), 0)
}
