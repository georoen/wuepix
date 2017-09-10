library(tidyverse)
library(wuepix)



# Site Configuration
load("Results/GTD.RData")
Files <- Files %>%
  arrange(Timestamp) %>%
  select(-starts_with("Hum"))
Files$Timestamp <- as.POSIXct(Files$Timestamp)




# Resize
dir.create("IMG_3/")
cmd <- paste("mogrify -resize 270x240 -path IMG_3/",
             paste0("IMG/", "*.jpg"))
system(cmd)
message("Finished preprocessing")
Files$Filename <- gsub("IMG/", "IMG_3/", Files$Filename)




# Test
#ttt <- hog_list(img.list = Files$Filename, winStride = 2, padding = 32, Mscale = 1.01)
#GTD_truePositives(Files$GTD, ttt)



# Parameters
#Files$Filename <- gsub("IMG/", "IMG_resize/", Files$Filename)  # Skip resizing!
winStride <- c(2, 4, 8)
padding <- c(16, 24, 32)
Mscale <- c(1, 1.025, 1.05, 1.1)
test_HOG <- expand.grid(par_winStride = winStride, par_padding = padding, par_Mscale = Mscale)

# Wrap Processing
test_HOG_parameters <- function(Files, winStride, padding, Mscale, resize = 1) {
  #' @description Execute HOG and store Benchmakt only.
  #' Loop, not mapply() (did't work)
  #' @usage test_HOG_parameters(Files=Files, winStride = winStride,
  #'                            padding = padding, Mscale = 1.01)
  #' @return Benchmark for test
  # Process
  img.list <- Files[,"Filename"]
  start <- Sys.time()
  HOG <- hog_list(img.list, winStride, padding, as.character(Mscale))
  if(length(HOG) < nrow(Files))
    Files$HOG <- NA
  Files$HOG <- HOG
  runtime <- Sys.time() - start
  # Benchmark
  rtn <- GTD_truePositives(Files$GTD, Files$HOG)
  rtn$runtime <- runtime
  rtn
}

# Loop Wrap
test_RTN <- list()
for (i in 1:nrow(test_HOG)) {
  (test_this <- test_HOG[i,])
  test_RTN[[i]] <- test_HOG_parameters(Files,
                                       test_this$par_winStride,
                                       test_this$par_padding,
                                       test_this$par_Mscale)
}
test_RTN <- do.call(rbind, test_RTN)
test_HOG <- cbind(test_HOG, test_RTN)




# Save
test_HOG_3 <- test_HOG  # Scale 3
save(test_HOG_3, file = "test_HOG_3.RData")
