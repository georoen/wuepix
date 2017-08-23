#' @author Jeroen Staab
# JPEG Tools
JPEG_plot <- function(img, main=NULL){
  #' @title Plot a JPEG
  #' @description Simply plot an image.
  #'
  #' @param img A raster object.
  #' @param main Optional. An overall title for the plot.
  #'
  #' @details Images can be loaded as raster object using `JPEG::readJPEG()`.
  #'

  # Check img
  if(min(img)<0){
    warning("img contains negative values. Pixels < 0 will be set to 0 as in
            jpeg::writeJPEG().")
    img[which(img[] < 0)] <- 0
  }
  # Filter NaN
  img[which(is.nan(img[]) | is.na(img[]))] <- 0
  # Range if nessecary
  # range01 <- function(x){(x-min(x))/(max(x)-min(x))}
  # if(min(img)<0 | max(img) >1)
  #   img <- range01(img)

  plot(img, xlim = c(0,ncol(img)), ylim = c(nrow(img),0),
       type='n', ylab = "Y", xlab = "X",
       main=main)
  rasterImage(img, 0, nrow(img), ncol(img), 0)
}
plotJPEG <- JPEG_plot

JPEG_histStrecht <- function(img){
  #' @title Histogram Stretching
  #' @description Stretch values between 0 and 1 as in JPEG convention.
  #' Attention, use this function for plotting only (highlights contrast). But
  #' further processing (i.e. Change Detection) may be limited due altered values.
  #' @param img A raster object.
  #' @return same as input, but ranged between 0 and 1 (nummeric).
  (img-min(img))/(max(img)-min(img))
}

JPEG_grayscale <- function(img, red=1/3, green=1/3, blue=1/3){
  #' @title Convert RGB to Grayscale
  #' @description Convert RGB img to Grayscale. Default is mixing the three
  #' bands equaly. Use camera specific weights if possible.
  #' Stardot red=0.3 green=0.59 blue=0.11
  #' @param img Three layered raster object.
  #' @param red Calibration weight for red.
  #' @param green Calibration weight for green.
  #' @param blue Calibration weight for blue.
  #' @return Singe layer raster object.
  rtn <- img[,,1]
  rtn <- red*img[,,1] + green*img[,,2] + blue*img[,,3]
  rtn
}


# Inspect Region of Interest
ROI_draw <- function(img){
  #' @title Inspect a Region of Interest
  #' @description Draw a region of interest.
  #' @param img A raster object.
  #' @details Insepct a region of interest by drawing a polygone.
  #' See OS-specific ?locator() for how to finish drawing. Minimum three vertex
  #' points are required.
  #' @details roi <- InspectROI(jpeg::readJPEG("../Testbild.jpg"))
  #' @details To visualize roi use histROI() or get it's stats with summary().
  #' @details histROI(roi)
  #' @return numeric dataframe with digital numbers of selected pixels.
  #' @seealso \code{\link{histROI}}
  #'
  #' @importFrom SDMTools pnt.in.poly

  ratio <- dim(img)[1]/dim(img)[2]
  roi.data <- list()
  plotJPEG(img, "Draw Region of Interest. Click finish...")
  vertices <- locator(type = "l")
  polygon(vertices, lwd = 2, border = "red")
  image.array <- expand.grid(rowpos = seq(1:nrow(img)),
                             colpos = seq(1:ncol(img)))
  coordinates <- data.frame(rowpos = vertices$y,
                            colpos = vertices$x)
  pixels.in.roi <- SDMTools::pnt.in.poly(image.array, coordinates)

  out <- list(pixels.in.roi, vertices)
  names(out) <- c("pixels.in.roi", "vertices")
  #out
  roi <- img
  roi <- data.frame(red=c(roi[,,1]), green=c(roi[,,2]), blue=c(roi[,,3]))
  roi[which(pixels.in.roi$pip == 0),] <- NA
  roi <- na.omit(roi)

  roi
}
ROI_hist <- function(roi) {
  #' @title Inspect a Region of Interest
  #' @description Ggplot histogramm of a region of interest.
  #' @param roi A numeric dataframe as returned by InspectROI().

  roi <- gather(roi, "Band", "Value")
  ggplot(roi, aes(Value, color = Band)) +
    scale_colour_manual(values=c("Blue", "Green", "Red")) +
    geom_density()
}
