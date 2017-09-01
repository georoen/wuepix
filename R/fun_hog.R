#' @author Jeroen Staab
hog_list <- function(img.list, winStride = 4, padding = 8,
                    Mscale = 1.05, resize = 1, predictions = NULL) {
  #' @title Detect pedestrians using HOGDescriptor
  #' @description Detect objects using HOG+SVM (implemented in OpenCV) in all Files/Images of 'path'
  #' @details Python and OpenCV have to be installed. Tested on Linux only.
  #' @details Further ideas:
  #' [A] Add more 'hog.detectMultiScale' parameters: winStride=(4, 4), padding=(8, 8), scale=1.05)
  #' [B] Save predictions.png to a folder
  #' @usage hog(img.folder)
  #'
  #' @param img.folder Path to (preprocessed) image archive
  #' @param resize Numeric factor resizing image in integrated pre-processing
  #' step. E.g. 2 will double the image extent. People should be 100 pixels high.
  #' @param winStride Window stride. It must be a multiple of block stride.
  #' @param padding Not implemented yet!
  #' @param Mscale Numeric. Allows multi-scale detection. Coefficient of the detection
  #' window increase.
  #' @param predictions
  #'
  #' @return Numeric vector with number of detected persons.

  # Path to python script
  hog.bin <- paste0(system.file(package = "wuepix"), "/exec/hogdescriptor.py")
  #hog.bin <- "~/Programmierung/Masterarbeit/method/code_obia/detect.py"

  # Write img.list
  img.list.tmp <- tempfile()
  cat(img.list, sep = ",", file = img.list.tmp)
  #write.table(img.list, file = img.list.tmp, row.names = FALSE, col.names = FALSE, eol = "", quote = FALSE, sep=",")

  # Classification
  cmd <- paste("python", hog.bin, "-i", img.list.tmp, "-x", resize,
               "-w", winStride, "-p", padding, "-s", Mscale)

  if(!is.null(predictions))
    cmd <- paste(cmd, "-o", predictions)
  out <- system(cmd, intern = TRUE, show.output.on.console = FALSE)

  rtn <- as.numeric(out)
  invisible(rtn)
}
