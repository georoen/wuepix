library(tidyverse)
library(doParallel)
library(foreach)
library(wuepix)

# Site Configuration
setwd("/home/jeremy/Dokumente/1_University/Master/Masterarbeit/method/Hubland_Mo_EOI2/")
load("Results/GTD.RData")


# Test Threshold
test_threshold_min <- Files %>%
  select(-starts_with("Hum"))

test_threshold_min$Hum005 <- CD_list(Files$Filename, 0.05)
test_threshold_min$Hum01 <- CD_list(Files$Filename, 0.1)
test_threshold_min$Hum015 <- CD_list(Files$Filename, 0.15)
test_threshold_min$Hum02 <- CD_list(Files$Filename, 0.2)
test_threshold_min$Hum025 <- CD_list(Files$Filename, 0.25)
test_threshold_min$Hum03 <- CD_list(Files$Filename, 0.3)
test_threshold_min$Hum035 <- CD_list(Files$Filename, 0.35)
test_threshold_min$Hum04 <- CD_list(Files$Filename, 0.4)
test_threshold_min$Hum045 <- CD_list(Files$Filename, 0.45)
test_threshold_min$Hum05 <- CD_list(Files$Filename, 0.5)
test_threshold_min$Hum06 <- CD_list(Files$Filename, 0.6)
test_threshold_min$Hum07 <- CD_list(Files$Filename, 0.7)

test_threshold_min <- test_threshold_min %>%
  gather("Min", "Hum", 4:15) %>%
  mutate(Min = gsub("Hum0", "0.", Min))

# Acc Ass
ggplot(Files, aes(Timestamp, GTD)) +
  geom_jitter()
ggplot(test_threshold_min, aes(as.factor(GTD), Hum, color=Min)) +
  geom_boxplot() +
  scale_y_log10()
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
  geom_smooth()
test_02 %>%
  ggplot(aes(as.factor(GTD), Hum)) +
  geom_boxplot()

test_spread <- test_threshold_min %>%
  spread(Min, Hum)
names(test_spread) <- sub("0.", "Hum0", names(test_spread))
test_md <- lm(GTD ~ Hum02, data = test_spread)
summary(test_md)
test_md <- lm(GTD ~ Hum08 + Hum02, data = test_spread)
summary(test_md)
test_md <- lm(GTD ~ Hum02 +Hum04 +Hum06 +Hum08, data = test_spread)
summary(test_md)

# Calibration Durchburch ?!
Files2 <- test_spread %>%
  mutate(Timestamp = lubridate::round_date(Timestamp, "30M")) %>%
  group_by(Timestamp) %>%
  summarise(GTD = sum(GTD), Hum = median(Hum02))
ggplot(Files2, aes(GTD, Hum)) +
  geom_point() +
  geom_smooth()
Files2 %>%
  gather("Method", "Value", 2:3) %>%
  ggplot(aes(Timestamp, Value, color=Method)) +
  geom_point()
cor.test(Files2$GTD, Files2$Hum)
test_md <- lm(GTD ~ Hum, data = Files2)
summary(test_md)

test_spread2 <- select(test_spread, -starts_with("Hum"))
test_spread2$GTD2 <- predict(test_md, select(test_spread, -GTD))
cor.test(test_spread2$GTD, test_spread2$GTD2)


ggplot(test_spread, aes(as.factor(GTD), Hum02)) +
  geom_boxplot()
