library(tidyverse)
library(wuepix)

# Results
setwd("../Hubland_2/")
setwd("../Chorin/")
load("Results/Enviroment.RData")




# Intro
JPEG_plot(jpeg::readJPEG("extra/Ref.jpg"))




# Change Detection
## Parameters
load("Results/test_Agg_Cal_full.RData")
best <- test_Agg_Cal_full %>%
  group_by(T_scale, Operator) %>%
  filter(R2 == max(R2))
print(best)

cor.test(Files_res$GTD, Files_res$CD)
summary(lm_cal)

ggplot(Files_res, aes(CD, GTD))+
  geom_abline(color="Red", slope = lm_cal$coefficients) +
  geom_point(alpha=0.7) +
  labs(title="Calibration Model",
       # x = "Mean Number of Changed Pixels in 20 Minutes",
       # y = "Summed GTD over 20 Minutes")
       x = "Mean Number of Changed Pixels per Hour",
       y = "Summed GTD per Hour")
ggsave("FIG_CD_CalibrationModel.png", units = "cm", width = 9, height = 9)



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

yolo.results <- yolo_Read("yolo_detections.txt")
unique(yolo.results$Class)
View(yolo.results)

yolo.results <- yolo_Read() %>%
  group_by(Class) %>%
  count() %>%
  arrange(desc(n)) %>%
  ungroup() %>%
  # View() %>%
  # top_n(10) %>%
  mutate(Class = factor(Class, unique(Class)))
cat(paste0(yolo.results$n, "x & ", yolo.results$Class, " & "))  # yolo.table

ggplot(yolo.results, aes(Class, n)) +
  geom_col() +
  scale_x_discrete(limits = rev(levels(yolo.results$Class))) +
  labs(title = "Histogram of Detected Objects",
       y = "Frequency", x = "Object Class") +  # coords flipped!
  coord_flip() +
  geom_text(aes(label = n), hjust=-0.2, size = 2.5)
ggsave("FIG_YOLO_Histogram.png", units = "cm", width = 15, height = 6)


# Other Objects
yolo_View <- function(pattern, file = "yolo_detections.txt",
                      predicitions = "./YOLO_predicitions/", out.folder = "./View/") {
  dir.create(out.folder)
  yolo.results <- yolo_Read("yolo_detections.txt")
  yolo.hit <- yolo.results$Filename[grep(pattern, yolo.results$Class,
                                         ignore.case = TRUE)]
  yolo.hit <- gsub("jpg", "png", yolo.hit)
  yolo.from <- paste0(predicitions, yolo.hit)
  yolo.to <- paste0(out.folder, yolo.hit)
  file.copy(from = yolo.from, to = yolo.to)
}
yolo_View("backpack", predicitions = predicitions)
# yolo_View("backpack", predicitions = predicitions)
yolo_View("bicycle", predicitions = predicitions)
yolo_View("car", predicitions = predicitions)
yolo_View("dog", predicitions = predicitions)
yolo_View("truck", predicitions = predicitions)
yolo_View("motorbike", predicitions = predicitions)




# Results
## Cor.test
cor.test(Files_res$GTD, Files_res$CD_pred)
cor.test(Files_res$GTD, Files_res$HOG)
cor.test(Files_res$GTD, Files_res$YOLO)

## Plot TimeSeries
Files_res %>%
  select(-CD) %>%
  rename(CD = CD_pred) %>%
  gather("Method", "Value", 2:5) %>%
  mutate(Day = lubridate::wday(Timestamp, label = TRUE, abbr = FALSE),
         Method = factor(Method, unique(Method)),  # make msc order
         Method = factor(Method, levels = c("GTD", "CD", "HOG", "YOLO"))) %>%
  ggplot(aes(Timestamp, Value, color=Method)) +
  geom_line(size = 1) +
  facet_grid(. ~ Day, scales="free") +
  theme(legend.title = element_text(size = rel(0.7)),  # theme_msc
        legend.text = element_text(size = rel(0.5)),
        legend.key.size = unit(1, units = "lines")) +
  theme(panel.spacing = unit(15, units = "pt"))+
  # theme(legend.position="bottom",
  #       legend.box="horizontal") +
  # guides(color = guide_legend(title.position="top", title.hjust = 0.5)) +
  labs(title = "Visitor Numbers",
       y = expression(paste("Number of Detected Visitors (", V[T], ")"))) #+
  # theme(axis.text.x=element_text(angle = -90, hjust = 0))
ggsave("FIG_V-Timeseries.png", units = "cm", width = 15, height = 8)
ggsave("FIG_V-Timeseries.png", units = "cm", width = 15, height = 10)


# Derivation T scale
Files_res %>%
  select(-CD) %>%
  gather("Method", "Value", 2:5, -"GTD") %>%
  group_by(Method, Timestamp) %>%
  summarise(Value = sum(Value),
            GTD = sum(GTD)) %>%
  mutate(DER = Value /GTD) %>%
  filter(!is.infinite(DER)) %>%
  group_by(Method) %>%
  summarise(DER = round(mean(DER, na.rm = TRUE),3)-1)

# Derivation Day
Files_res %>%
  select(-CD) %>%
  gather("Method", "Value", 2:5, -"GTD") %>%
  group_by(Method, lubridate::wday(Timestamp)) %>%
  summarise(Value = sum(Value),
            GTD = sum(GTD)) %>%
  mutate(DER = Value /GTD) %>%
  filter(!is.infinite(DER)) %>%
  group_by(Method) %>%
  summarise(DER = round(mean(DER, na.rm = TRUE),3)-1)


# Insitu


# With in-Situ
df.in <- read.csv("extra/InSitu.csv", stringsAsFactors = FALSE) %>%
  tidyr::unite(Datum, Start, col = Timestamp, sep=" ") %>%
  mutate(Timestamp = lubridate::floor_date(anytime::anytime(Timestamp), "hour"),
         Day = lubridate::wday(Timestamp, label = TRUE, abbr = FALSE),
         InSu = Personen*2) %>%
  select(Timestamp, InSi)
df <- Files_res %>%
  select(-CD) %>%
  gather("Method", "Value", 2:5, -"GTD") %>%
  mutate(Timestamp = lubridate::floor_date(Timestamp, "hour")) %>%
  group_by(Method, Timestamp) %>%
  summarise(Value = sum(Value),
            GTD = sum(GTD)) %>%
  spread("Method", "Value") %>%
  right_join(df.in)


# Bind and plot
df <- rbind(df, df.in)
insitu <- read.csv("Results/InSitu.csv")
r <- 882/sum(Files_res$GTD)
(sum(Files_res$CD_pred)*r /882) -1
(sum(Files_res$HOG)*r /882) -1
(sum(Files_res$YOLO)*r /882) -1

