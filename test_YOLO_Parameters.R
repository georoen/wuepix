library(tidyverse)
library(wuepix)



# Site Configuration
load("Results/GTD.RData")
Files <- Files %>%
  arrange(Timestamp) %>%
  select(-starts_with("Hum"))



# Test
img.list <- Files[,"Filename"]
start <- Sys.time()
YOLO <- yolo_list(img.list)
if(length(YOLO) < nrow(Files))
  Files$YOLO <- NA
Files$YOLO <- YOLO
(runtime <- Sys.time() - start)

# Benchmark
GTD_truePositives(Files$GTD, Files$YOLO)


# Save
test_YOLO <- Files
save(test_YOLO, runtime, file = "Results/test_YOLO.RData")

