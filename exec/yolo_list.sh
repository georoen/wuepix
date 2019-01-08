# Classify list of images using YOLO darknet from bash
# https://pjreddie.com/darknet/install/

# Arguments
# 1 path to yolo.inst folder.
# 2 Absolute filepath to image list
# 3 Threshold value

# Get abolute path to img
imglist=$(readlink -f $2)

# cd to YOLO installation (mandatory)
cd $1

# execute
./darknet detect cfg/yolov3.cfg yolov3.weights -thresh $3 < "$imglist"
