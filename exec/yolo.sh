# Classify images using YOLO darknet from bash
# https://pjreddie.com/darknet/install/

# Get abolute path to img
file=$(readlink -f $2)
# cd to YOLO installation
cd $1
# execute
#./darknet detect cfg/yolo.cfg tiny.weights "$1"
./darknet detect cfg/yolo.cfg yolo.weights "$file"
# archive predictions
#file=$(basename $1)
mv -f predictions.png ./predictions/$(basename $2).png
