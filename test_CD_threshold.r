# Test Threshold
test_threshold_min <- Files %>%
  select(-starts_with("Hum"))
CD_multi <- function(Files, min, max=1){
  cores <- detectCores()-1
  cl <- makeCluster(cores)
  registerDoParallel(cl)
  old.stop <- nrow(Files)
  new.stop <- old.stop-1

  act.Data <- foreach(now=Files$Filename[2:old.stop],
                      old=Files$Filename[1:new.stop],
                      .combine=c) %dopar%
    sum(wuepix::ChangeDetection(now, old, min, max))

  stopCluster(cl)

  act.Data <- c(NA,act.Data)
  act.Data
}
test_threshold_min$Hum0005 <- CD_multi(Files, 0.005)
test_threshold_min$Hum001 <- CD_multi(Files, 0.01)
test_threshold_min$Hum005 <- CD_multi(Files, 0.05)
test_threshold_min$Hum01 <- CD_multi(Files, 0.1)
test_threshold_min$Hum02 <- CD_multi(Files, 0.2)
test_threshold_min$Hum03 <- CD_multi(Files, 0.3)
test_threshold_min$Hum04 <- CD_multi(Files, 0.4)
test_threshold_min$Hum05 <- CD_multi(Files, 0.5)
test_threshold_min$Hum06 <- CD_multi(Files, 0.6)
test_threshold_min$Hum07 <- CD_multi(Files, 0.7)
test_threshold_min$Hum08 <- CD_multi(Files, 0.8)
test_threshold_min$Hum09 <- CD_multi(Files, 0.9)

test_threshold_min <- test_threshold_min %>%
  gather("Min", "Hum", 4:15) %>%
  mutate(Min = gsub("Hum0", "0.", Min))

# Acc Ass
ggplot(Files, aes(Timestamp, GTD)) +
  geom_jitter()
ggplot(test_threshold_min, aes(as.factor(GTD), Hum, color=Min)) +
  geom_boxplot()
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
  geom_point()
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

Files2 <- test_spread %>%
  mutate(hour = lubridate::hour(Timestamp)) %>%
  group_by(hour) %>%
  summarise(jo = sum(Hum02))
ggplot(Files2, aes(hour, jo)) +
  geom_point()

test_spread2 <- select(test_spread, -starts_with("Hum"))
test_spread2$GTD2 <- predict(test_md, select(test_spread, -GTD))
cor.test(test_spread2$GTD, test_spread2$GTD2)


ggplot(test_spread, aes(as.factor(GTD), Hum02)) +
  geom_boxplot()
