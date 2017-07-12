# Classify list of images using YOLO darknet from bash
# https://pjreddie.com/darknet/install/

# Arguments
# 1 path to yolo.inst folder.
# 2 Absolute filepath to image list

# Get abolute path to img
imglist=$(readlink -f $2)

# cd to YOLO installation (mandatory)
cd $1

# execute
#./darknet detect cfg/yolo.cfg tiny.weights "$1"
./darknet detect cfg/yolo.cfg yolo.weights < "$imglist"
