library(tidyverse)
library(wuepix)



# Site Configuration
setwd("/home/jeremy/Dokumente/1_University/Master/Masterarbeit/method/Hubland_Mo_EOI2/")
load("Results/GTD.RData")
Files <- Files %>%
  arrange(Timestamp) %>%
  select(-starts_with("Hum"))



# Test
ttt <- hog_dir(img.list = Files$Filename, winStride = 2, padding = 32, Mscale = 1.01)
GTD_truePositives(Files$GTD, ttt)



# Parameters
Files$Filename <- gsub("IMG/", "IMG_resize/", Files$Filename)  # Skip resizing!
winStride <- c(2, 4, 8)
padding <- c(16, 24, 32)
Mscale <- c(1, 1.001, 1.01, 1.02, 1.05, 1.1)
test_HOG <- expand.grid(par_winStride = winStride, par_padding = padding, par_Mscale = Mscale)

# Wrap Processing
test_HOG_parameters <- function(Files, winStride, padding, Mscale, resize = 1) {
  # Process
  img.list <- Files[,"Filename"]
  start <- Sys.time()
  Files$HOG <- hog_dir(img.list, winStride, padding, as.character(Mscale))
  runtime <- Sys.time() - start
  # Benchmark
  rtn <- GTD_truePositives(Files$GTD, Files$HOG)
  rtn$runtime <- runtime
  rtn
}
#jo <- test_HOG_parameters(Files=Files, winStride = winStride, padding = padding, Mscale = 1.01)

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


#test_HOG2 <- test_HOG  # Scale 2
#save(test_HOG2, file = "test_HOG2.RData")


# Analyses
ggplot(test_HOG2, aes(FPPW, MR, color=as.factor(par_Mscale), size=runtime)) +
  geom_point() +
  facet_grid(par_winStride ~ par_padding) +
  labs(title = "HOG Benchmark",
       x = "FalsePositives / Frame (FPPW)",
       y = "Miss Rate (MR)")
ggsave("FIG_HOG_ParameterOptimization.png", units = "cm", width = 15, height = 8)
