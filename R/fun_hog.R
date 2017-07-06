#' @author Jeroen Staab
hog <- function(img.folder, winStride, padding, scale) {
  #' @title Detect pedestrians using HOGDescriptor
  #' @description Detect objects using HOG+SVM (implemented in OpenCV) in all Files/Images of 'path'
  #' @details Python and OpenCV have to be installed. Tested on Linux only.
  #' @details Further ideas:
  #' [A] Add more 'hog.detectMultiScale' parameters: winStride=(4, 4), padding=(8, 8), scale=1.05)
  #' [B] Save predictions.png to a folder
  #' @usage hog(img.folder)
  #'
  #' @param img.folder Path to (preprocessed) image archive
  #' @param winStride Not implemented yet!
  #' @param padding Not implemented yet!
  #' @param scale Not implemented yet!
  #'
  #' @return Numeric vector with number of detected persons.

  # Path to python script
  hog.bin <- paste0(system.file(package = "wuepix"), "/exec/hogdescriptor.py")
  #hog.bin <- "~/Programmierung/Masterarbeit/method/code_obia/detect.py"

  # Classification
  cmd <- paste("python", hog.bin, "-i", img.folder)
  out <- system(cmd, intern = TRUE, show.output.on.console = FALSE)

  rtn <- as.numeric(out)
  invisible(rtn)
}
