library(tidyverse)

# Load
load("Results/test_HOG.RData")
# load("Results/test_HOG_04.RData")
# load("Results/test_HOG_05.RData")
# load("hog_test64/test_HOG_2.RData")
# load("hog_test64/test_HOG_3.RData")
# load("hog_test64/test_HOG_4.RData")  # resize x4 same as x3. This means par_Mscale only dowscales images


# Analyses
# test_HOG_1$resize <- 1
# test_HOG_1$cor <- NA
# test_HOG_04$resize <- 0.25
# test_HOG_05$resize <- 0.16

# test_HOG <- test_HOG_1
# test_HOG_2$resize <- 2
# test_HOG_3$resize <- 3
# test_HOG_4$resize <- 4
# test_HOG <- rbind(test_HOG_1, test_HOG_04)
# test_HOG <- test_HOG %>%
#   filter(par_Mscale != 1.001, par_Mscale != 1.01) %>%
#   filter(par_padding != 64)


# test_HOG <- rbind(test_HOG_2, test_HOG_3)
# test_HOG <- rbind(test_HOG_2, test_HOG_3, test_HOG_4)
test_HOG$runtime <- as.numeric(test_HOG$runtime, units="mins")
summary(test_HOG)
ggplot(test_HOG, aes(FPPW, MR,
                     size=as.factor(par_Mscale),
                     color=runtime,
                     shape = paste("Resizing x",resize))) +
  geom_point() +
  facet_grid(paste("winStride =", par_winStride)
             ~ paste("padding =", par_padding)) +
  labs(title = "HOG Benchmarks",
       x = "FalsePositives / Frame (FPPW)",
       y = "Miss Rate (MR)") +
  ylim(0, 1) +
  scale_shape("Preprocessing") +
  scale_size_discrete("Scale Parameter", range = c(1,3)) +
  scale_color_gradient("Runtime (Mins)", low="green", high="red") +
  theme(legend.title = element_text(size = rel(0.7)),  # theme_msc
        legend.text = element_text(size = rel(0.5)),
        legend.key.size = unit(1, units = "lines")) +
  theme(panel.spacing = unit(15, units = "pt"))+
  theme(legend.position="bottom",
        legend.box="horizontal") +
  guides(colour = guide_colourbar(title.position="top", title.hjust = 0.5),
         size = guide_legend(title.position="top", title.hjust = 0.5),
         shape = guide_legend(title.position="top", title.hjust = 0.5))
ggsave("FIG_HOG_ParameterOptimization.png", units = "cm", width = 15, height = 12)

# Impact Model
lm(MR ~ resize + par_winStride + par_padding + par_Mscale, data = test_HOG) %>%
  summary()
lm(FPPW ~ resize + par_winStride + par_padding + par_Mscale, data = test_HOG) %>%
  summary()
lm(as.numeric(runtime) ~ resize + par_winStride + par_padding + par_Mscale, data = test_HOG) %>%
  summary()

# "Best" Performer
test_HOG$Ratio <- test_HOG$MR / test_HOG$FPPW
