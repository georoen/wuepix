#img.folder <- "2017/05_crop/"
img.folder <- commandArgs(trailingOnly=TRUE)[1]
library(wuepix)
library(tidyverse)



# Config
# Remove corrupted images by filesize (in byte)
threshold <- 1000
# Filename Patterns
gsub.Date <- function(Filename){gsub("Camera1_M_", "", gsub(".jpg", "", Filename))}
# Date code
date.code <- "%Y-%m-%d-%H%M%S"




# List Files
Files <- data.frame(Filename=list.files(img.folder, pattern = "*.jpg"),
                    stringsAsFactors = FALSE)
# Remove corrupted images
Files$Size <- file.size(paste0(img.folder, Files$Filename)) > threshold
Files <- Files[which(Files$Size),]
Files <- select(Files, -Size)
# Add Timestamp
Files$Timestamp <- strptime(gsub.Date(Files$Filename), date.code)
Files$Timestamp <- as.POSIXct(Files$Timestamp)
Files <- Files[order(Files$Timestamp),]  # Order by Timestamp
# Full Filename
Files$Filename <- paste0(img.folder, Files$Filename)




# Resize
dir.create("IMG_resize/")
cmd <- paste("mogrify -resize 270x240 -path IMG_resize/",
             paste0(img.folder, "*.jpg"))
system(cmd)
message("Finished preprocessing")
Files_resized <- gsub(img.folder, "IMG_resize/", Files$Filename)




# Processing
start <- Sys.time()  # Get start time
HOG <- hog_list(Files_resized, resize = 1, padding = 24, winStride = 2,
                Mscale = 1.05, predictions = "HOG_Predictions/")
(Sys.time() - start)  # Print runtime
Files$HOG <- HOG




# Save
save.image(file = paste0(basename(img.folder),".RData"))
