library(tidyverse)

# Results
setwd("../method/Hubland_2/")

# Change Detection
load("Results/Enviroment.RData")

cor.test(Files_res$GTD, Files_res$CD)
summary(lm_cal)

ggplot(Files_res, aes(CD, GTD))+
  geom_abline(color="Red", slope = lm_cal$coefficients) +
  geom_point(alpha=0.7) +
  labs(title="Calibration Model",
       x = "Mean Number of Changed Pixels per Hour",
       y = "Summed GTD per Hour")
ggsave("FIG_CD_CalibrationModel.png", units = "cm", width = 15, height = 6)



# HOG
load("/Results/test_HOG_3.RData")
summary(test_HOG_3)


# Impact Model
lm(MR ~ par_winStride + par_padding + par_Mscale, data = test_HOG_3) %>%
  summary()
lm(FPPW ~ par_winStride + par_padding + par_Mscale, data = test_HOG_3) %>%
  summary()
lm(as.numeric(runtime) ~ par_winStride + par_padding + par_Mscale, data = test_HOG_3) %>%
  summary()

# "Best" Performer
test_HOG_3$Ratio <- test_HOG_3$MR / test_HOG_3$FPPW
test_HOG_3 %>%
  filter(cor == max(cor))
cor.test(Files_res$GTD, Files_res$HOG)

# Qualitative
# View predictions...
# Identify FP
View(filter(Files, HOG > GTD))




# YOLO
GTD_truePositives(Files$GTD, Files$YOLO)
View(filter(Files, YOLO > GTD))
