library(tidyverse)
library(wuepix)
#library(caret)


GTD_truePositives(Files$GTD, ttt)


# Site Configuration
setwd("/home/jeremy/Dokumente/1_University/Master/Masterarbeit/method/Hubland_Mo_EOI2/")
load("Results/GTD.RData")
Files <- Files %>%
  arrange(Timestamp) %>%
  select(-starts_with("Hum"))

# Test
ttt <- hog_dir(img.list, resize = 3, winStride = 2, padding = 32, Mscale = 1.01)


ttt  %>%
  mutate(FP = HOG - GTD,
         FP = ifelse(FP >=0, FP, 0),  # positive values only
         TP = HOG - FP,
         FN = GTD - HOG,
         FN = ifelse(FN >=0, FN, 0))  %>%
  summarise(FN = sum(FN),
            TP = sum(TP),
            FP = sum(FP),
            MR = FN/(TP + FN),
            FPPW = FP/n())

# Parameters
winStride <- c(2, 4, 8, 16)
padding <- c(8, 16, 24, 32)
Mscale <- c(1, 1.01, 1.02, 1.05, 1.1)
test_HOG <- expand.grid(par_winStride = winStride, par_padding = padding, par_Mscale = Mscale)


test_HOG_parameters <- function(Files2, winStride, padding, Mscale) {
  assign("Files2", Files)
  img.list <- Files2[,"Filename"]

  start <- Sys.time()
  Files2$HOG <- hog_dir(img.list, resize = 3, winStride, padding, Mscale)
  runtime <- Sys.time() - start

  Files2 <- Files2 %>%
    mutate(FP = HOG - GTD,
           FP = ifelse(FP >=0, FP, 0),  # positive values only
           TP = HOG - FP,
           FN = GTD - HOG,
           FN = ifelse(FN >=0, FN, 0))  %>%
    summarise(FN = sum(FN),
              TP = sum(TP),
              FP = sum(FP),
              MR = FN/(TP + FN),
              FPPW = FP/n())
  Files2$runtime <- runtime
  Files2
}
Files3 <- mapply(test_HOG_parameters, Files2=Files, test_HOG$par_winStride, test_HOG$par_padding, test_HOG$par_Mscale)

test_HOG$FN <- unlist(Files3[seq(1, length(Files3), by = 6)])
test_HOG$TP <- unlist(Files3[seq(2, length(Files3), by = 6)])
test_HOG$FP <- unlist(Files3[seq(3, length(Files3), by = 6)])
test_HOG$MR <- unlist(Files3[seq(4, length(Files3), by = 6)])
test_HOG$FPPW <- unlist(Files3[seq(5, length(Files3), by = 6)])
test_HOG$runtime <- unlist(Files3[seq(6, length(Files3), by = 6)])

#test_HOG2 <- test_HOG  # Scale 2
#save(test_HOG2, file = "test_HOG2.RData")


# Analyses
ggplot(test_HOG2, aes(FPPW, MR, size=as.factor(par_Mscale))) +
  geom_point() +
  facet_wrap(par_padding~par_winStride)

