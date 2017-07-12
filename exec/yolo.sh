# Classify images using YOLO darknet from bash
# https://pjreddie.com/darknet/install/

# Arguments
# 1 path to yolo.inst folder.
# 2 Absolute filepath to image.
# 3 dirpath to where to store predictions.

# Get abolute path to img
file=$(readlink -f $2)
dir=$(readlink -f $3)

# cd to YOLO installation (mandatory)
cd $1

# execute
#./darknet detect cfg/yolo.cfg tiny.weights "$1"
./darknet detect cfg/yolo.cfg yolo.weights "$file"

# archive predictions
mv -fT predictions.png "$dir/$(basename -s .jpg $2).png"
