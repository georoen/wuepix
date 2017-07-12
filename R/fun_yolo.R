yolo <- function(img, logfile="yolo_detections.txt", predictions="yolo_predictions/") {
  #' @title Detect people usind YOLOv2
  #' @description Detect objects using YOLO+CNN (Linux C++), in a single image.
  #'
  #' @param img (Absolute) filepath to image, also known as `now`.
  #' @param logfile Relative filepath to where to store detailed list of
  #' classification results.
  #' @param predictions dirpath to where to store predictions
  #'
  #' @return Numeric number of detected persons.
  #'
  #' @details It's recomendended avoid spaces in the paths (also in working
  #' directory).
  #' @details
  #' Further ideas:
  #' - Skip saving predictions.png
  #' - Wrap detection into list-based processing
  #'    ./darknet detect cfg/yolo.cfg yolo.weights < listofabsolutepaths.txt
  #' - Use RCCP to wrap YOLO into R.
  #'

  # Depends on a working YOLO insatllation !
  yolo.inst <- "~/Programmierung/YOLO/"
  # How to install?
  # See also: https://pjreddie.com/darknet/yolo/
  # 1. YOLO Darknet has to be installed:
  # 'git clone https://github.com/pjreddie/darknet'
  # 'cd darknet'
  # 'make'
  # 2. Where I moved the darknetfolder to ~/Programmierung/YOLO/
  # 3. And a small helper script was created to interact with R: yolo.sh
  # yolo.bin is path to bash script executing the classification
  # Since it is important to process in the yolo directory, the script mainly
  # 'cd's to the installation path. However additional actions as archiving
  # predicted.png and parameters like '-thresh 0.1' can also be placed there.
  # In case of a new installation write those two lines into yolo.bin:
  # 'cd ~/Programmierung/YOLO/'
  # './darknet detect cfg/yolo.cfg yolo.weights "$file"'

  # Check predictions folder
  if(!dir.exists(predictions))
    dir.create(predictions)

  # Classification
  yolo.bin <- paste0(system.file(package = "wuepix"), "/exec/yolo.sh")
  cmd <- paste(yolo.bin, yolo.inst, img, predictions)
  out <- system(cmd, intern = TRUE, show.output.on.console = FALSE)

  # Process output
  ## drop processing time
  rtn <- out[-1]
  ## write classification results to logfile
  cat(basename(img), rtn, file = logfile, fill = TRUE, append = TRUE)
  #writeLines(paste(basename(img), rtn), file = logfile)
  ## return number of persons
  invisible(length(grep("person", rtn)))
}
