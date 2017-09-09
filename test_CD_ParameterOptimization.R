library(tidyverse)
library(wuepix)
# Large Parameter Optimization testing Thresholds and Arggregation Levels.

load("Results/GTD.RData")
Files$Timestamp <- as.POSIXct(Files$Timestamp)

# Test Threshold
fun_Thr_Test <- function(Files, method) {
  test_threshold_min <- Files %>%
    arrange(Timestamp) %>%
    select(-starts_with("Hum"))
  # Process at different thresholds
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
  test_threshold_min
}

method <- "diff"  # "ratio"  # ChangeDetection Method ?wuepix::CD_list()
test_threshold_min <- fun_Thr_Test(Files, method)

# Test Scales
T_scales <- c("2M", "6M", "20M", "60M")  # Aggregation scale ?lubridate::round_date()
fun_Agg_Cal_df <- function(T_scales, test_threshold_min) {
  # Wrap fun_Agg_Cal and retrun DataFrame
  fun_Agg_Cal <- function(T_scale, test_threshold_min) {
    # Aggregat + Calibrate all results
    test_aggregation <- test_threshold_min %>%
      gather("Min", "Hum", 4:length(test_threshold_min)) %>%
      mutate(Min = gsub("Hum0", "0.", Min))  %>%
      mutate(Timestamp = lubridate::floor_date(Timestamp, T_scale)) %>%  # 15 Minutes
      group_by(Timestamp, Min) %>%
      summarise(GTD = sum(GTD), Hum = mean(Hum, na.rm=TRUE))
    test_calibration <- test_aggregation %>%
      split(.$Min) %>%
      map(~ lm(GTD ~ 0+Hum, data = .x)) %>%
      map(summary)
    r.squares <- map_dbl(test_calibration, "r.squared")

    data.frame(T_scale = T_scale, Thr = names(r.squares), R2 = r.squares,
               stringsAsFactors = FALSE)
  }

  test_Agg_Cal <- lapply(T_scales, fun_Agg_Cal, test_threshold_min)
  test_Agg_Cal <- do.call(rbind, test_Agg_Cal)
  test_Agg_Cal$Thr <- as.numeric(test_Agg_Cal$Thr)
  test_Agg_Cal$T_scale <- factor(test_Agg_Cal$T_scale, T_scales, ordered = TRUE)
  test_Agg_Cal
}
test_Agg_Cal <- fun_Agg_Cal_df(T_scales, test_threshold_min)

best <- test_Agg_Cal %>%
  group_by(T_scale) %>%
  filter(R2 == max(R2))
print(best)

ggplot(test_Agg_Cal, aes(Thr, R2, group=T_scale, color=T_scale)) +
  geom_line() +
  labs(title="Parameter Optimization",
       x = "Min Threshold", y = "Coefficient of Determination (R²)") +
  guides(color=guide_legend(title="T Scales")) +
  geom_point(data = best) +
  geom_text(data = best, aes(label=round(R2,3)),hjust=-0.2, vjust=-0.2,
            show.legend = FALSE, size = 3) +
  scale_x_continuous(breaks = round(seq(0, 1, by = 0.1),1)) +
  ylim(0,1)
ggsave("FIG_ParameterOptimization_1.png", units = "cm", width = 15, height = 8)


# N of tested Thresholds
length(unique(test_Agg_Cal$Thr))
# N of Models
nrow(test_Agg_Cal)

# Save
test_Agg_Cal_diff <- test_Agg_Cal
test_Agg_Cal_diff$Operator <- method
save(test_Agg_Cal_diff, file = "test_Agg_Cal_diff.RData")




# New Experiments
# Operator = Ratio
method <- "ratio"  # ChangeDetection Method ?wuepix::CD_list()
test_threshold_min <- fun_Thr_Test(Files, method)
test_Agg_Cal_ratio <- fun_Agg_Cal_df(T_scales, test_threshold_min)
test_Agg_Cal_ratio$Operator <- "ratio"




# Merge Diff & Ratio Experiments
test_Agg_Cal_full <- bind_rows(test_Agg_Cal_diff, test_Agg_Cal_ratio)
test_Agg_Cal_full$Operator <- factor(test_Agg_Cal_full$Operator, labels = c("Differencing" , "Rationing"))
save(test_Agg_Cal_full, file = "test_Agg_Cal_full.RData")

best <- test_Agg_Cal_full %>%
  group_by(T_scale, Operator) %>%
  filter(R2 == max(R2))
print(best)

ggplot(test_Agg_Cal_full, aes(Thr, R2, group=T_scale, color=T_scale)) +
  geom_line() +
  labs(title="Parameter Optimization",
       x = "Min Threshold", y = "Coefficient of Determination (R²)") +
  guides(color=guide_legend(title="T Scales")) +
  geom_point(data = best) +
  geom_text(data = best, aes(label=round(R2,3)),hjust=-0.2, vjust=-0.2,
            show.legend = FALSE, size = 3) +
  scale_x_continuous(breaks = round(seq(0, 1, by = 0.1),1)) +
  ylim(0,1) +
  facet_wrap(~ Operator) +
  theme(legend.title = element_text(size = rel(0.7)),  # theme_msc
        legend.text = element_text(size = rel(0.5)),
        legend.key.size = unit(1, units = "lines"))
ggsave("FIG_CD_ParameterOptimization.png", units = "cm", width = 15, height = 8)
