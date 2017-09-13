# Hubland Full
# File selector
setwd("../Hubland/")
#img.folder.raw <- "2017/05/"
img.folder <- "2017/04/"
img.folder.post <- "2017/04_crop/"

library(tidyverse)
library(lubridate)

# Site
threshold <- 1000
gsub.Date <- function(Filename){gsub("Camera1_M_", "", gsub(".jpg", "", Filename))}
date.code <- "%Y-%m-%d-%H%M%S"
convert.string <- "-crop 90x80+455+690"  # Crop

# Files
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
# Subset Time
Files <- Files %>%
  filter(hour(Timestamp) >= 7,
         hour(Timestamp) < 21)
# Full Filename
Files$Filename <- paste0(img.folder, Files$Filename)




# Preprocess All
start <- Sys.time()  # Get start time
tmp.dir <- paste0(tempdir(),"/")
dir.create(tmp.dir)
cmd <- paste("mogrify", convert.string, "-path", tmp.dir,
             paste0(img.folder, "*.jpg"))
system(cmd)
message("Finished preprocessing")
(Sys.time() - start)  # Print runtime

# Change filename
start <- Sys.time()  # Get start time
Files.tmp <- gsub(img.folder, tmp.dir, Files$Filename)
Files$Filename <- gsub(img.folder, img.folder.post, Files$Filename)
# Move valid
dir.create(img.folder.post)
file.copy(Files.tmp, Files$Filename)
# Free Disk
unlink(tmp.dir, recursive = TRUE)
(Sys.time() - start)  # Print runtime
