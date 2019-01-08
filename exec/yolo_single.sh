# Classify images using YOLO darknet from bash
# https://pjreddie.com/darknet/install/

# Arguments
# 1 path to yolo.inst folder.
# 2 filepath to image.
# 3 dirpath to where to store predictions.
# 4 Threshold value

# Get abolute path to img
file=$(readlink -f $2)
out="$(readlink -f $3)/$(basename -s .jpg $2)"

# cd to YOLO installation (mandatory)
cd $1

# execute
./darknet detect cfg/yolov3.cfg yolov3.weights -thresh $4 "$file" -out "$out"
