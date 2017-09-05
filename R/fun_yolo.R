#' @author Jeroen Staab
#' @references
#' \insertRef{redmon2016yolo9000}{wuepix}
#' \url{https://pjreddie.com/darknet/yolo/}
yolo_single <- function(img, logfile="yolo_detections.txt",
                        predictions="yolo_predictions/") {
  #' @title Object Detection using YOLO
  #' @description detect people using YOLO+CNN (Linux C++), in a single image.
  #'
  #' @param img file path to image, also known as `now`.
  #' @param logfile file path to where to store detailed list of classification
  #' results.
  #' @param predictions dir path to where to store prediction images
  #'
  #' @return numeric number of detected persons.
  #'
  #' @details depends on a working YOLO installation! See `yolo_install()` and
  #' rerun `yolo_update()` after updating this package (Places yolo.inst in
  #' package directory)
  #' @details single processing allows storing `predictions` (images with
  #' bounding boxes). Since these can be very insightful, you might want to
  #' `sapply()` this function instead of `yolo_list()`. However because then the
  #' wights have to be loaded repetitively (~10 seconds) this slows down
  #' processing.
  #' @details it's recommended avoid spaces in the paths (also in working
  #' directory).
  #' @details an idea for further work on this package would be to actually wrap
  #' YOLO into R (e.g. using Rccp).
  #'
  #' @examples
  #' yolo_single(img)
  #' sapply(img.list, yolo_single)
  #'

  # Depends on a working YOLO insatllation !
  yolo.inst <- paste0(system.file(package = "wuepix"), "/exec/yolo_inst.txt")
  yolo.inst <- readLines(yolo.inst, warn = FALSE)
  if(!exists("yolo.inst"))
    stop("Could not find yolo.inst.\n
         Installation successfull?\n
         Also run `yolo_update(yolo.inst)` after updating this package!")

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
  #' @title Object Detection using YOLO
  #' @description detect people using YOLO+CNN (Linux C++), in multiple images.
  #' Unfortunately it is not possible to store the predictions here, but it is
  #' significant faster on large image archives.
  #'
  #' @param img.list file path to images.
  #' @param logfile file path to where to store detailed list of
  #' classification results.
  #'
  #' @return numeric number of detected persons.
  #'
  #' @seealso \code{\link{yolo_single}}
  #' @import tools

  # Depends on a working YOLO insatllation !
  yolo.inst <- paste0(system.file(package = "wuepix"), "/exec/yolo_inst.txt")
  yolo.inst <- readLines(yolo.inst, warn = FALSE)
  if(!exists("yolo.inst"))
    stop("Could not find yolo.inst.\n
         Installation successfull?\n
         Also run `yolo_update(yolo.inst)` after updating this package!")

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



yolo_install <- function(yolo.inst){
  #' @title Install YOLO Automatically
  #' @description
  #'
  #' @param yolo.inst directory for installation. Will be created
  #'
  #' @details this function wrapped the install procedure (1-3) while renaming
  #' the directory from `darknet` to `basename(yolo.inst)` and additional run a
  #' test to check whether installation succeeded.
  #' @details 1. 'git clone https://github.com/pjreddie/darknet'
  #' @details 2. 'cd darknet'
  #' @details 3. 'make'
  #' @details during installation `Makefile` will be opened, to finetune the
  #' installation, eg. multithreading (OPENMP=1) or GPU processing (GPU=1), off
  #' by default..
  #' @details after successfull installation it will place `yolo.inst` in
  #' `paste0(system.file(package = "wuepix"), "/exec/yolo_inst.txt")`
  #'
  #' @importFrom git2r clone


  # Changing working directory
  wd <- getwd()
  message("Changing working directory during installation!")
  setwd(dirname(yolo.inst))

  # Clone repository
  if(!dir.exists(basename(yolo.inst)))
    git2r::clone("https://github.com/pjreddie/darknet", basename(yolo.inst))
  else
    stop("This directroy already exists. Use yolo_update() instead.")

  # Make install
  setwd(basename(yolo.inst))
  readline("Optional tune parameter, eg `OPENMP=1`. Then press ANY key.")
  file.edit("Makefile")
  system("make")

  # Get wights
  download.file("https://pjreddie.com/media/files/yolo.weights", "yolo.weights")

  # Test
  rtn <- try(system("./darknet detect cfg/yolo.cfg yolo.weights data/dog.jpg",
                intern = TRUE))
  if(length(rtn) == 0)
    stop("Automatic installation failed!\n
          Please retry manually following:\n
          https://pjreddie.com/darknet/yolo/")
  else
    message("Installation sucessful!")

  # Saving yolo.inst
  yolo.bin <- paste0(system.file(package = "wuepix"), "/exec/yolo_inst.txt")
  cat(tools::file_path_as_absolute(yolo.inst), file = yolo.bin)

  # Reset working directory and return
  setwd(wd)
  message("Working directory has been resettet")
  invisible(0)
}



yolo_update <- function(yolo.inst){
  #' @title Update YOLO
  #'
  #' @param yolo.inst directory of YOLO installation.
  #'
  #' @details since YOLO is under active development this function wraps the
  #' update procedure (1-2) and test it.
  #' @details 1. 'git pull'
  #' @details 2. 'make'
  #' @details during installation `Makefile` will be opened, to fine tune the
  #' installation, e.g. turning on multithreading or GPU processing.
  #' @details after successfull update it will place `yolo.inst` in
  #' `paste0(system.file(package = "wuepix"), "/exec/yolo_inst.txt")`

  # Saving yolo.inst
  yolo.bin <- paste0(system.file(package = "wuepix"), "/exec/yolo_inst.txt")
  cat(tools::file_path_as_absolute(yolo.inst), file = yolo.bin)

  # Changing working directory
  wd <- getwd()
  message("Changing working directory during update!")
  setwd(yolo.inst)

  # Pull update
  rtn <- system("git pull")
  if(length(rtn) == 1){  # "Bereits aktuell."
    # Reset working directory and return
    setwd(wd)
    message("Working directory has been resettet")
    return()
  }

  # Make install
  file.edit("Makefile")
  readline("Optional tune parameter, eg `OPENMP=1` for multithreading.
           Then press ANY key.")
  system("make")

  # Test
  rtn <- try(system("./darknet detect cfg/yolo.cfg yolo.weights data/dog.jpg",
                    intern = TRUE))
  if(length(rtn) == 0)
    warning("Automatic installation failed!\n
            Please retry manually following:
            https://pjreddie.com/darknet/yolo/")
  else
    message("Update sucessful!")

  # Reset working directory and return
  setwd(wd)
  message("Working directory has been resettet")
  invisible(0)
}
