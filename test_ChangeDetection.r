library(tidyverse)
# library(anytime)
#library(doParallel)
#library(foreach)
library(wuepix)






# Site Configuration
setwd("/home/jeremy/Dokumente/1_University/Master/Masterarbeit/method/Hubland_Mo_EOI2/")
img.folder  <- "IMG/"
load("Results/GTD.RData")



# Single Image
#par(mfcol = c(1,2))
## now
now <- Files$Filename[28]

now <- getImage(now, plot = TRUE)
hist(now)
summary(now)
ROI_hist(ROI_draw(now))

## old
old="extra/Ref2.jpg"
old <- Files$Filename[29]
old <- getImage(old, plot = TRUE)
hist(old)
summary(old)
ROI_hist(ROI_draw(old))



# Change Detection
#par(mfcol = c(1,1))

# Image  as in CD_list
dif <- now
dif[] <- old[]-now[]
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




