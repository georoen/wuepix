# Large Parameter Optimization testing Thresholds and Arggregation Levels.

#source("~/Programmierung/Masterarbeit/wuepix/test_CD_threshold.r")
T_scales <- c("2M", "6M", "20M", "60M")

fun_Agg_Cal <- function(T_scale, test_threshold_min) {
  test_aggregation <- test_threshold_min %>%
    gather("Min", "Hum", 4:13) %>%
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
test_Agg_Cal$T_scale <- factor(test_Agg_Cal$T_scale, T_scales, ordered = TRUE)
ggplot(test_Agg_Cal, aes(T_scale, R2, group=Thr, color=Thr)) +
#ggplot(test_Agg_Cal, aes(Thr, R2, group=T_scale, color=T_scale)) +
  geom_line()
