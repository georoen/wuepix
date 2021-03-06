library(tidyverse)
library(wuepix)

# Site Configuration
setwd("~/Programmierung/Masterarbeit/method/Chorin")
#setwd("~/Dokumente/1_University/Master/Masterarbeit/method/Hubland_Mo_EOI2/")
load("Results/GTD.RData")
Files$Timestamp <- as.POSIXct(Files$Timestamp)

# Test Threshold
test_threshold_min <- Files %>%
  arrange(Timestamp) %>%
  select(-starts_with("Hum"))

method <- "diff"  # "ratio"  # ChangeDetection Method ?wuepix::CD_list()
T_scale <- "60M"  # "60M"  # Aggregation scale ?lubridate::round_date()
test_threshold_min$Hum005 <- CD_list(test_threshold_min$Filename, 0.05, method = method)
test_threshold_min$Hum01 <- CD_list(test_threshold_min$Filename, 0.1, method = method)
test_threshold_min$Hum015 <- CD_list(test_threshold_min$Filename, 0.15, method = method)
test_threshold_min$Hum02 <- CD_list(test_threshold_min$Filename, 0.2, method = method)
test_threshold_min$Hum025 <- CD_list(test_threshold_min$Filename, 0.25, method = method)
test_threshold_min$Hum03 <- CD_list(test_threshold_min$Filename, 0.3, method = method)
test_threshold_min$Hum035 <- CD_list(test_threshold_min$Filename, 0.35, method = method)
test_threshold_min$Hum04 <- CD_list(test_threshold_min$Filename, 0.4, method = method)
test_threshold_min$Hum045 <- CD_list(test_threshold_min$Filename, 0.45, method = method)
test_threshold_min$Hum05 <- CD_list(test_threshold_min$Filename, 0.5, method = method)
test_threshold_min$Hum055 <- CD_list(test_threshold_min$Filename, 0.55, method = method)
test_threshold_min$Hum06 <- CD_list(test_threshold_min$Filename, 0.6, method = method)
test_threshold_min$Hum065 <- CD_list(test_threshold_min$Filename, 0.65, method = method)
test_threshold_min$Hum07 <- CD_list(test_threshold_min$Filename, 0.7, method = method)
test_threshold_min$Hum075 <- CD_list(test_threshold_min$Filename, 0.75, method = method)
test_threshold_min$Hum08 <- CD_list(test_threshold_min$Filename, 0.8, method = method)
test_threshold_min$Hum085 <- CD_list(test_threshold_min$Filename, 0.85, method = method)
test_threshold_min$Hum09 <- CD_list(test_threshold_min$Filename, 0.9, method = method)
test_threshold_min$Hum095 <- CD_list(test_threshold_min$Filename, 0.95, method = method)

# Aggregation
test_aggregation <- test_threshold_min %>%
  gather("Min", "Hum", 4:length(test_threshold_min)) %>%
  mutate(Min = gsub("Hum0", "0.", Min))  %>%
  mutate(Timestamp = lubridate::floor_date(Timestamp, T_scale)) %>%  # 15 Minutes
  group_by(Timestamp, Min) %>%
  summarise(GTD = sum(GTD), Hum = mean(Hum, na.rm=TRUE))

ggplot(test_aggregation, aes(Timestamp, Hum, color=Min)) +
  geom_line() +
  scale_y_log10() +
  labs(title="Logarithmic Time-Series Testing Different Thresholdes")
ggplot(test_aggregation, aes(as.factor(GTD), Hum, color=Min)) +
  geom_boxplot()+
  #scale_y_log10() +
  facet_wrap(~Min, scales = "free") +
  geom_smooth() +
  labs(title="Aggregated Hum VS. GTD for Different Thresholdes")


# Calibration using purrr
test_calibration <- test_aggregation %>%
  split(.$Min) %>%
  map(~ lm(GTD ~ 0+Hum, data = .x)) %>%
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
#plot(best_aggregation$GTD, best_aggregation$Hum)
cor.test(best_aggregation$GTD, best_aggregation$Hum)
## Model
best_calibration <- lm(GTD ~ 0+Hum, data = best_aggregation)
summary(best_calibration)
best_aggregation$Prediction <- predict(best_calibration,
                                    select(best_aggregation, -GTD))
best_aggregation$Prediction <- round(best_aggregation$Prediction)

## Plot
best_aggregation %>%
  group_by(GTD, Prediction) %>%
  count() %>%
ggplot(aes(GTD, Prediction, size = n)) +
  geom_point() +
  geom_abline(slope = 1)
  #stat_smooth(method = "lm", col = "red") +
  #geom_abline(intercept = best_calibration$coefficients[1],
  #            slope = best_calibration$coefficients[2]) +
  #geom_smooth()

# FIG_Scatterplot+LinearModel
best_aggregation %>%
  ggplot(aes(Hum, GTD)) +
  geom_point() +
  geom_abline(slope = best_calibration$coefficients[1], color = "Red") +
  labs(title = "Scatterplot and Linear Model",
       x = expression(paste("Number of Changed Pixels (", H[T], ")")),
       y = "Visitor Number (GTD)")
ggsave("FIG_Scatterplot+LinearModel.png", units = "cm", width = 15, height = 8)


# FIG_V-Timeseries
best_aggregation %>%
  select(-Hum) %>%
  gather("Method", "Value", 2:3) %>%
  #mutate(Method = factor(Method, levels=c("Prediction", "GTD"), order = TRUE)) %>%
  ggplot(aes(Timestamp, Value, color=Method)) +
  geom_line(size = 1) +
  scale_color_manual("Legend", values = c("Gray", "#F8766D")) +
  #scale_size_manual(values =c(2,1))
  labs(title = "Visitor Numbers at Hubland",
       y = expression(paste("Number of Detected Visitors (", V[T], ")")))
ggsave("FIG_V-Timeseries.png", units = "cm", width = 15, height = 8)
