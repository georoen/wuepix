library(tidyverse)
# library(anytime)
#library(doParallel)
#library(foreach)
library(wuepix)


# Site Configuration
setwd("/home/jeremy/Dokumente/1_University/Master/Masterarbeit/method/Hubland_Mo_EOI2/")
load("Results/GTD.RData")
Files <- Files %>%
  arrange(Timestamp) %>%
  select(-starts_with("Hum"))

# Resize IMG Dir
img.folder <- "IMG_resize/"
# Test
test <- jpeg::readJPEG("extra/Ref.jpg")
resize <- 4 # 2.78
resize <-paste0(round(ncol(test)*resize), "x", round(nrow(test)*resize))

# SizeX x SizeY + PostionX + PositionY
cmd <- paste("convert extra/Ref.jpg -resize", resize, "extra/Ref_278.jpg")
system(cmd)
message("Please check cropped Ref.jpg, then proceed")

dir.create(img.folder)
cmd <- paste("mogrify -resize", resize, "-path", img.folder,
             paste0("IMG/", "*.jpg"))
system(cmd)
message("Finished preprocessing")



# Test
Files$hog <- hog_dir(img.folder, winStride = 4, padding = 8, scale = 1.05, predictions = NULL)
Files$hog <- hog_dir(img.folder, winStride = 4, padding = 8, scale = 1.1, predictions = "hog_predictions/")

# Test Threshold
plot(Files$GTD, Files$hog)
table(Files$GTD, Files$hog)

