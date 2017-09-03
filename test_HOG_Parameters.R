library(tidyverse)
library(wuepix)



# Site Configuration
setwd("/home/jeremy/Dokumente/1_University/Master/Masterarbeit/method/Hubland_Mo_EOI2/")
load("Results/GTD.RData")
Files <- Files %>%
  arrange(Timestamp) %>%
  select(-starts_with("Hum"))



# Test
ttt <- hog_list(img.list = Files$Filename, winStride = 2, padding = 32, Mscale = 1.01)
GTD_truePositives(Files$GTD, ttt)



# Parameters
Files$Filename <- gsub("IMG/", "IMG_resize/", Files$Filename)  # Skip resizing!
winStride <- c(2, 4, 8)
padding <- c(16, 24, 32, 64)
Mscale <- c(1, 1.001, 1.01, 1.02, 1.05, 1.1)
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
test_HOG_2 <- test_HOG  # Scale 2
save(test_HOG_2, file = "test_HOG_2.RData")


# Load
load("hog_test64/test_HOG_3.RData")
load("hog_test64/test_HOG_4.RData")
# load("hog_test64/test_HOG_2.RData")  # resize x4 same as x3. This means par_Mscale only dowscales images


# Analyses
test_HOG_2$resize <- 2
test_HOG_3$resize <- 3
# test_HOG_4$resize <- 4
test_HOG <- rbind(test_HOG_2, test_HOG_3)
# test_HOG <- rbind(test_HOG_2, test_HOG_3, test_HOG_4)
ggplot(test_HOG, aes(FPPW, MR,
                     size=as.factor(par_Mscale),
                     color=runtime,
                     shape = paste("Resizing x",resize))) +
  geom_point() +
  facet_grid(paste("winStride =", par_winStride)
             ~ paste("padding =", par_padding)) +
  labs(title = "HOG Benchmarks",
       x = "FalsePositives / Frame (FPPW)",
       y = "Miss Rate (MR)") +
  ylim(0, 1) +
  scale_shape("Preprocessing") +
  scale_size_discrete("Scale Parameter", range = c(1,3)) +
  scale_color_gradient("Runtime (Secs)", low="green", high="red") +
  theme(legend.title = element_text(size = rel(0.7)),
        legend.text = element_text(size = rel(0.5)),
        legend.key.size = unit(1, units = "lines"))+
  theme(panel.spacing = unit(15, units = "pt"))+
  theme(legend.position="bottom",
        legend.box="horizontal") +
  guides(colour = guide_colourbar(title.position="top", title.hjust = 0.5),
         size = guide_legend(title.position="top", title.hjust = 0.5),
         shape = guide_legend(title.position="top", title.hjust = 0.5))
ggsave("FIG_HOG_ParameterOptimization_2.png", units = "cm", width = 15, height = 12)

# Impact Model
lm(MR ~ resize + par_winStride + par_padding + par_Mscale, data = test_HOG) %>%
  summary()
lm(FPPW ~ resize + par_winStride + par_padding + par_Mscale, data = test_HOG) %>%
  summary()
