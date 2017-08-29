# Large Parameter Optimization testing Thresholds and Arggregation Levels.

#source("~/Programmierung/Masterarbeit/wuepix/test_CD_threshold.r")
T_scales <- c("2M", "6M", "20M", "60M")

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
ggsave("FIG_ParameterOptimization.png", units = "cm", width = 15, height = 8)


# N of tested Thresholds
length(unique(test_Agg_Cal$Thr))
# N of Models
nrow(test_Agg_Cal)

# Save
test_Agg_Cal_diff <- test_Agg_Cal
test_Agg_Cal_diff$Operator <- "diff"

# Operator = Ratio
#method <- "ratio"  # ChangeDetection Method ?wuepix::CD_list()
#source("~/Programmierung/Masterarbeit/wuepix/test_CD_threshold.r")
#source("~/Programmierung/Masterarbeit/wuepix/test_CD_ParameterOptimization.R")
test_Agg_Cal_ratio <- test_Agg_Cal
test_Agg_Cal_ratio$Operator <- "ratio"

# Merge
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
  facet_wrap(~ Operator)
ggsave("FIG_ParameterOptimization.png", units = "cm", width = 15, height = 8)
