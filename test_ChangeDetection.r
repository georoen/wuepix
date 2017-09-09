library(tidyverse)
# library(anytime)
#library(doParallel)
#library(foreach)
library(wuepix)






# Site Configuration
setwd("/home/jeremy/Dokumente/1_University/Master/Masterarbeit/method/Hubland_Mo_EOI2/")
load("Results/GTD.RData")

Min <- 0.2
Max <- 1


# Single Image
#par(mfcol = c(1,2))
## now
now <- Files$Filename[550]
now <- getImage(now, plot = TRUE)
hist(now)
summary(now)
ROI_hist(ROI_draw(now))

## old
old="extra/Ref2.jpg"
old <- Files$Filename[551]
old <- getImage(old, plot = TRUE)
hist(old)
summary(old)
ROI_hist(ROI_draw(old))



# Change Detection
# Image difference
dif <- now
dif[] <- now[]-old[]
summary(dif)
JPEG_plot(dif)

JPEG_plot(JPEG_histStrecht(dif))

# Absolute Values cuz change.dif Direction doesn't matter. Due to different ligth exposures.
hum <- abs(dif)
JPEG_plot(JPEG_histStrecht(hum))
hum[which(dif<0)] <-0 # Keep only positves (now > old. Heller geworden)
JPEG_plot(JPEG_histStrecht(hum))
JPEG_plot(JPEG_grayscale(JPEG_histStrecht(hum)))  # Dont: Grayscaling ruins effect


if(!is.null(predictions)){
  dir.create(predictions)
  jpeg::writeJPEG(hum, file.path(predictions, basename(file.now)))
}

# Classify Humans
###! this is experimental !###
### Himmelsrichtung: Von Osten. Position: Mittleres Kaufhaus 3.Stock (Whörl?), Richtung Westen (Festung).
## Treshold as from day one.
classified <- hum[,,1]<Max & hum[,,1]>Min & hum[,,2]<Max & hum[,,2]>Min & hum[,,3]<Max & hum[,,3]>Min

hum[classified]<-1
hum[!classified]<-0


# plot: geht nicht
# write: geht. Nagative werte werden 0
hum <- dif
hum <- abs(dif)
hum[which(dif<0)] <-0 # Keep only positves (now > old. Heller geworden)
plotJPEG(JPEG_histStrecht(JPEG_grayscale(hum)))
roi <- ROI_draw(JPEG_histStrecht(hum))
roi <- ROI_draw(hum)
ROI_hist(roi)

testThreshold <- function(img, Min=0.1, Max=0.9){
  img <- JPEG_grayscale(img)
  rtn <- img
  rtn[] <- 0.5
  rtn[which(img[] < Min)] <- 0
  rtn[which(img[] > Max)] <- 1
  JPEG_plot(rtn, main=paste("Min:", Min, "Max:", Max))
}
lapply(seq(1,9)/10, testThreshold, img=hum)


classified <- hum[,,1]<max & hum[,,1]>min & hum[,,2]<max & hum[,,2]>min & hum[,,3]<max & hum[,,3]>min
hum[classified]<-1
hum[!classified]<-0
JPEG_plot(hum)




roi <- ROI_draw(hum)
summary(roi)
hist(roi)



k <- dim(old)[3]

