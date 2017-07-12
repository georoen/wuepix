yolo_single <- function(img, logfile="yolo_detections.txt", predictions="yolo_predictions/") {
  #' @title Detect people using YOLO in a single image.
  #' @description Detect objects using YOLO+CNN (Linux C++), in a single image.
  #'
  #' @param img (Absolute) filepath to image, also known as `now`.
  #' @param logfile Relative filepath to where to store detailed list of
  #' classification results.
  #' @param predictions dirpath to where to store prediction images
  #'
  #' @return Numeric number of detected persons.
  #'
  #' @details Single processing allows storing `predictions` (images with
  #' bounding boxes). Since these can be very insightful, you migth want to
  #' `sapply()` this function instead of `yolo_list()`. However because then
  #' the wights have to be loaded repetivly (~10 seconds) this slows down
  #' processing.
  #' @details It's recomendended avoid spaces in the paths (also in working
  #' directory).
  #' @details
  #' Further ideas:
  #' - Skip saving predictions.png
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
  yolo.bin <- paste0(system.file(package = "wuepix"), "/exec/yolo_single.sh")
  cmd <- paste(yolo.bin, yolo.inst, img, predictions)
  out <- system(cmd, intern = TRUE, show.output.on.console = FALSE)

  # Process output
  ## drop runtime
  rtn <- out[-1]
  ## write classification results to logfile
  cat(basename(img), rtn, file = logfile, fill = TRUE, append = TRUE)
  #writeLines(paste(basename(img), rtn), file = logfile)
  ## return number of persons
  invisible(length(grep("person", rtn)))
}



yolo_list <- function(img.list, logfile="yolo_detections.txt") {
  #' @title Detect people using YOLO in multiple images.
  #' @description Detect objects using YOLO+CNN (Linux C++), in multiple images.
  #'
  #' @param img.list (Absolute) filepath to image, also known as `now`.
  #' @param logfile Relative filepath to where to store detailed list of
  #' classification results.
  #'
  #' @return Numeric number of detected persons.
  #'
  #' @details Unfortuanatly it is not possible to store the prediction images.
  #'
  #' @import tools


  # Depends on a working YOLO insatllation ! See sourcecode of yolo0().
  yolo.inst <- "~/Programmierung/YOLO/"

  # Save img.list with absolute paths in img.file
  img.list <- sapply(img.list, tools::file_path_as_absolute)
  img.file <- tempfile()
  cat(img.list, file = img.file, sep = "\n")

  # Classification
  yolo.bin <- paste0(system.file(package = "wuepix"), "/exec/yolo_list.sh")
  cmd <- paste(yolo.bin, yolo.inst, img.file)
  out <- system(cmd, intern = TRUE, show.output.on.console = FALSE)

  # Process logfile
  ## Drop last row (empty)
  rtn <- out[-length(out)]
  ## Split back into images
  cues <- grep("Enter Image Path: ", rtn)
  ## grep filenames
  grep.names <- function(names) {
    # Drop first half of character string
    rtn.names <- basename(sapply(names,'[[',1))
    # then second (runtime):
    rtn.names <- sapply(sapply(rtn.names, strsplit, ": Predicted"), '[[',1)
    rtn.names
  }
  rtn.names <- grep.names(rtn[cues])
  rtn[cues] <- rtn.names
  ## Add Linebreak
  rtn[cues[-1]] <- paste0("\n", rtn[cues[-1]])
  ## write classification results to logfile
  cat(rtn, file = logfile, fill = FALSE, append = TRUE)

  # Process return
  ## Group output by image
  # https://stackoverflow.com/a/25411832
  rtn.groups <- split(rtn, cumsum(grepl(".jpg", rtn)))
  rtn.people <- lapply(rtn.groups, function(x){length(grep("person", x))})
  ## return number of persons
  invisible(unlist(rtn.people))
}
