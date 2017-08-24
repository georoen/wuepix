library(tidyverse)
library(wuepix)

# Site Configuration
setwd("/home/jeremy/Dokumente/1_University/Master/Masterarbeit/method/Hubland_Mo_EOI2/")
load("Results/GTD.RData")


# Test Threshold
test_threshold_min <- Files %>%
  arrange(Timestamp) %>%
  select(-starts_with("Hum"))

#test_threshold_min$Hum005 <- CD_list(Files$Filename, 0.05)
#test_threshold_min$Hum01 <- CD_list(Files$Filename, 0.1)
test_threshold_min$Hum015 <- CD_list(Files$Filename, 0.15)
test_threshold_min$Hum02 <- CD_list(Files$Filename, 0.2)
test_threshold_min$Hum025 <- CD_list(Files$Filename, 0.25)
test_threshold_min$Hum03 <- CD_list(Files$Filename, 0.3)
test_threshold_min$Hum035 <- CD_list(Files$Filename, 0.35)
test_threshold_min$Hum04 <- CD_list(Files$Filename, 0.4)
test_threshold_min$Hum045 <- CD_list(Files$Filename, 0.45)
test_threshold_min$Hum05 <- CD_list(Files$Filename, 0.5)
#test_threshold_min$Hum06 <- CD_list(Files$Filename, 0.6)
#test_threshold_min$Hum07 <- CD_list(Files$Filename, 0.7)

# Aggregation
test_aggregation <- test_threshold_min %>%
  gather("Min", "Hum", 4:11) %>%
  mutate(Min = gsub("Hum0", "0.", Min))  %>%
  mutate(Timestamp = lubridate::round_date(Timestamp, "5M")) %>%  # 15 Minutes
  group_by(Timestamp, Min) %>%
  summarise(GTD = sum(GTD), Hum = median(Hum, na.rm=TRUE))

ggplot(test_aggregation, aes(Timestamp, Hum, color=Min)) +
  geom_line() +
  scale_y_log10() +
  labs(title="Logarithmic Time-Series Testing Different Thresholdes")
ggplot(test_aggregation, aes(as.factor(GTD), Hum, color=Min)) +
  geom_boxplot()+
  scale_y_log10() +
  labs(title="Logarithmic Time-Series Testing Different Thresholdes")
ggplot(test_aggregation, aes(as.factor(GTD), Hum, color=Min)) +
  geom_boxplot()+
  #scale_y_log10() +
  facet_wrap(~Min, scales = "free") +
  geom_smooth() +
  labs(title="Logarithmic Time-Series Testing Different Thresholdes")


# Calibration using purrr
test_calibration <- test_aggregation %>%
  split(.$Min) %>%
  map(~ lm(GTD ~ Hum, data = .x)) %>%
  map(summary)
test_calibration

# Proceed with best fit
## Select best
r.squares <- map_dbl(test_calibration, "r.squared")
best <- which(r.squares == max(r.squares))
print(paste("Best fit for Min =", names(best),
            "where R-squared =", round(r.squares[best],3)))
best_aggregation <- test_aggregation %>%
  filter(Min == names(best)) %>%
  select(-Min)
plot(best_aggregation$GTD, best_aggregation$Hum)
cor.test(best_aggregation$GTD, best_aggregation$Hum)
## Model
best_calibration <- lm(GTD ~ Hum, data = best_aggregation)
summary(best_calibration)
best_aggregation$Results <- predict(best_calibration,
                                    select(best_aggregation, -GTD))
## Plot
best_aggregation %>%
  select(-Hum) %>%
  gather("Method", "Value", 2:3) %>%
  ggplot(aes(Timestamp, Value, color=Method)) +
  geom_point()
