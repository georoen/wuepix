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



# Site Configuration
setwd("/home/jeremy/Dokumente/1_University/Master/Masterarbeit/method/Hubland_Montag")
img.folder  <- "IMG/"
load("Results/GTD.RData")




# Single Image
par(mfcol = c(1,2))
## now
now <- Files$Filename[302]

now <- getImage(now)
hist(now)
summary(now)
InspectROI(now) %>%
  na.omit() %>%
  gather("Band", "Value") %>%
  ggplot(aes(Value, color = Band)) +
  scale_colour_manual(values=c("Blue", "Green", "Red")) +
  geom_density()


## old
old <- Files$Filename[301]
old <- getImage(old)
hist(old)
summary(old)




# Change Detection
par(mfcol = c(1,1))


# Image  as in CD_list
dif <- now
dif[] <- now[]-old[]
# plot: geht nicht
# write: geht. Nagative werte werden 0
hum <- dif
#hum <- abs(dif)
hum[which(dif<0)] <-0 # Keep only positves (now > old. Heller geworden)
plotJPEG(hum)
roi <- InspectROI(hum)
histJPEG(roi)


classified <- hum[,,1]<max & hum[,,1]>min & hum[,,2]<max & hum[,,2]>min & hum[,,3]<max & hum[,,3]>min
hum[classified]<-1
hum[!classified]<-0
plotJPEG(hum)




roi <- InspectROI(hum)
summary(roi)
hist(roi)




# Test Threshold
test_threshold_min <- select(Files, -Hum)
CD_multi <- function(Files, min, max=1){
  cores <- detectCores()-1
  cl <- makeCluster(cores)
  registerDoParallel(cl)
  old.stop <- nrow(Files)
  new.stop <- old.stop-1

  act.Data <- foreach(now=Files$Filename[1:new.stop],
                      old=Files$Filename[2:old.stop],
                      .combine=c) %dopar%
    sum(wuepix::ChangeDetection(now, old, min, max))

  stopCluster(cl)

  act.Data <- c(act.Data,NA)
  act.Data
}
test_threshold_min$Hum0005 <- CD_multi(Files, 0.005)
test_threshold_min$Hum001 <- CD_multi(Files, 0.01)
test_threshold_min$Hum005 <- CD_multi(Files, 0.05)
test_threshold_min$Hum01 <- CD_multi(Files, 0.1)
test_threshold_min$Hum02 <- CD_multi(Files, 0.2)
test_threshold_min$Hum03 <- CD_multi(Files, 0.3)
test_threshold_min$Hum04 <- CD_multi(Files, 0.4)
test_threshold_min$Hum05 <- CD_multi(Files, 0.5)
test_threshold_min$Hum06 <- CD_multi(Files, 0.6)
test_threshold_min$Hum07 <- CD_multi(Files, 0.7)
test_threshold_min$Hum08 <- CD_multi(Files, 0.8)
test_threshold_min$Hum09 <- CD_multi(Files, 0.9)

test_threshold_min <- test_threshold_min %>%
  gather("Min", "Hum", 4:15) %>%
  mutate(Min = gsub("Hum0", "0.", Min))

# Acc Ass
ggplot(Files, aes(Timestamp, GTD)) +
  geom_jitter()
ggplot(test_threshold_min, aes(as.factor(GTD), Hum, color=Min)) +
  geom_boxplot()
ggplot(test_threshold_min, aes(Timestamp, Hum, color=Min)) +
  geom_smooth() +
  scale_y_log10() +
  labs(title="Logarithmic Time-Series Testing Different Thresholdes")

# Calibration using purrr
#' Best für 08 und 02. R² = 0.064
# test_threshold_min %>%
#   split(.$Min) %>%
#   map(~ lm(GTD ~ Hum, data = .x)) %>%
#   map(summary)
test_threshold_min %>%
  #filter(Hum > 0) %>%  # Ohne 0
  split(.$Min) %>%
  map(~ lm(GTD ~ Hum, data = .x)) %>%
  map(summary)

test_08 <- test_threshold_min %>%
  filter(Min == "0.8") %>%
  select(-Min)
test_08 %>%
  gather("Method", "Value", 3:4) %>%
  ggplot(aes(Timestamp, Value, color=Method)) +
  geom_point()
test_08 %>%
  ggplot(aes(as.factor(GTD), Hum)) +
  geom_boxplot()

test_02 <- test_threshold_min %>%
  filter(Min == "0.2") %>%
  select(-Min)
test_02 %>%
  gather("Method", "Value", 3:4) %>%
  ggplot(aes(Timestamp, Value, color=Method)) +
  geom_point()
test_02 %>%
  ggplot(aes(as.factor(GTD), Hum)) +
  geom_boxplot()

test_md <- lm(GTD ~ Hum08 + Hum02, data = Files)
summary(test_md)
test_md <- lm(GTD ~ Hum02 +Hum04 +Hum06 +Hum08, data = Files)
summary(test_md)
