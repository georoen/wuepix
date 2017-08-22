library(tidyverse)
# library(anytime)
library(doParallel)
library(foreach)
library(wuepix)




# Functions
getImage <- function(filename, extend=NULL){
  file <- jpeg::readJPEG(filename)
  if(!is.null(extend)){file <- file[extend[1]:extend[2], extend[3]:extend[4], ]}
  plotJPEG(file, filename)
  return(file)
}

# locator
InspectROI <- function(img){
  #' @importFrom SDMTools pnt.in.poly
  #' @description Insepct a region of interest by drawing a polygone.
  #' @details See OS-specific ?locator()
  #' @details roi <- InspectROI(jpeg::readJPEG("../Testbild.jpg"))

  ratio <- dim(img)[1]/dim(img)[2]
  roi.data <- list()
  plotJPEG(img, "Draw Region of Interest. Click finish...")
  vertices <- locator(type = "l")
  polygon(vertices, lwd = 2, border = "red")
  image.array <- expand.grid(rowpos = seq(1:nrow(img)),
                             colpos = seq(1:ncol(img)))
  coordinates <- data.frame(rowpos = vertices$y,
                            colpos = vertices$x)
  pixels.in.roi <- SDMTools::pnt.in.poly(image.array, coordinates)

  out <- list(pixels.in.roi, vertices)
  names(out) <- c("pixels.in.roi", "vertices")
  #out
  roi <- img
  roi <- data.frame(red=c(roi[,,1]), green=c(roi[,,2]), blue=c(roi[,,3]))
  roi[which(pixels.in.roi$pip == 0),] <- NA
  roi <- na.omit(roi)

  roi
}

histJPEG <- function(roi) {
    roi <- gather(roi, "Band", "Value")
    ggplot(roi, aes(Value, color = Band)) +
    scale_colour_manual(values=c("Blue", "Green", "Red")) +
    geom_density()
}

histStrecht <- function(x){(x-min(x))/(max(x)-min(x))}

bwJPEG <- function(img){
  #' @description Convert RGB Image to Grayscale.
  rtn <- img[,,1]
  rtn <- (img[,,1] + img[,,2] + img[,,3])/3
  rtn
}




# Site Configuration
setwd("/home/jeremy/Dokumente/1_University/Master/Masterarbeit/method/Hubland_Montag")
img.folder  <- "IMG/"
load("Results/GTD.RData")

todo <- which(Files$GTD > 0)
Files <- Files[todo,]



# Single Image
par(mfcol = c(1,2))
## now
now <- Files$Filename[27]

now <- getImage(now)
plotJPEG(now)
hist(now)
summary(now)
InspectROI(now) %>%
  na.omit() %>%
  gather("Band", "Value") %>%
  ggplot(aes(Value, color = Band)) +
  scale_colour_manual(values=c("Blue", "Green", "Red")) +
  geom_density()


## old
old <- Files$Filename[28]
old <- getImage(old)
plotJPEG(old)
hist(old)
summary(old)
InspectROI(old) %>%
  na.omit() %>%
  gather("Band", "Value") %>%
  ggplot(aes(Value, color = Band)) +
  scale_colour_manual(values=c("Blue", "Green", "Red")) +
  geom_density()



# Change Detection
par(mfcol = c(1,1))


# Image  as in CD_list
dif <- now
dif[] <- old[]-now[]
# plot: geht nicht
# write: geht. Nagative werte werden 0
hum <- dif
hum <- abs(dif)
hum[which(dif<0)] <-0 # Keep only positves (now > old. Heller geworden)
plotJPEG(histStrecht(bwJPEG(hum)))
roi <- InspectROI(histStrecht(hum))
roi <- InspectROI(hum)
histJPEG(roi)

testThreshold <- function(img, Min=0.1, Max=0.9){
  img <- bwJPEG(img)
  rtn <- img
  rtn[] <- 0.5
  rtn[which(img[] < Min)] <- 0
  rtn[which(img[] > Max)] <- 1
  plotJPEG(rtn, main=paste("Min:", Min, "Max:", Max))
}
lapply(seq(1,9)/10, testThreshold, img=hum)


classified <- hum[,,1]<max & hum[,,1]>min & hum[,,2]<max & hum[,,2]>min & hum[,,3]<max & hum[,,3]>min
hum[classified]<-1
hum[!classified]<-0
plotJPEG(hum)




roi <- InspectROI(hum)
summary(roi)
hist(roi)




