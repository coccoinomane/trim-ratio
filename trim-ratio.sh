#! /usr/bin/env bash

# Trim an image around the highest detail region without
# changing its aspect ratio.
#
# Optionally specify how many pixels to pad around the
# highest detail region; the padding will be taken
# from the actual image.
#
# Useful to trim background around the subject, while
# keeping the same AR and having control on how much
# is trimmed.
#
# Requires bash with the bc arithmetical library.
#
# TODO
# * Implement different padding strategy; at the moment
# the padding is uniform in the four dimensions no matter
# where the highest detail region is.
# * Test on AR different from a square
#
# THANKS TO:
# - Fred (fmw42) and Snibgo from ImageMagick forums
#   (https://imagemagick.org/discourse-server/viewtopic.php?f=1&t=36443)

# Parse arguments
image="$1"
pad=${2-0}
out_folder=${3-.}
blur=${4-5}

# Get of image info
name=$(magick "$image" -format "%t" info:)
W=$(magick "$image" -format "%[w]" info: )
H=$(magick "$image" -format "%[h]" info: )
AR=$(magick "$image" -format "%[fx:w/h]" info: )

# Output images
trimmed_image="${out_folder}/${name}_blur${blur}_trim.jpg"
padded_image="${out_folder}/${name}_blur${blur}_pad${pad}.jpg"

echo "Processing image ${name} with size ${W}x${H} and AR=${AR}..."

# Get rectangle bounding highest definition area, and store its parts
bounding_rectangle=$(magick "$image" -canny 0x1+10%+30% -blur "${blur}"x65000 -format "%@" info:)
echo "  bounding rectangle = $bounding_rectangle" 
WB=$(echo "$bounding_rectangle" | sed -E -e 's/^([[:digit:]]+).*/\1/')
HB=$(echo "$bounding_rectangle" | sed -E -e 's/^.*x([[:digit:]]+)\+.*/\1/')
xB=$(echo "$bounding_rectangle" | sed -E -e 's/^.*\+([[:digit:]]+)\+.*/\1/')
yB=$(echo "$bounding_rectangle" | sed -E -e 's/^.*\+([[:digit:]]+)$/\1/')
[[ $bounding_rectangle = ${WB}x${HB}+${xB}+${yB} ]] || { echo "Error extracting crop dimensions"; exit; }

# Exit if nothing can be trimmed
(( WB == W && HB == H )) && { echo "Nothing to trim, will exit"; exit; }

# Output image with bounding rectangle
magick "$image" -crop "$bounding_rectangle" +repage "$trimmed_image"

# Compute available space in the 4 directions
ST=$yB
SB=$((H-HB-ST))
SL=$xB
SR=$((W-WB-SL))
echo "  available space: top=${ST}, bottom=${SB}, left=${SL}, right=${SR}"

# Initialize parameters of new crop area
WT=$WB
HT=$HB
xT=$xB
yT=$yB

# Recover aspect ratio
if (( $(echo "$WB > $AR*$HB" | bc) )); then
    echo "  forcing aspect ratio to $AR"
    HT="$(echo "$WB/$AR" | bc)"
    yT="$(echo "$yB+($HB-$HT)/2" | bc)"
    echo "    height changed from $HB to $HT"
    echo "    vertical position (y) changed from $yB to $yT"
else
    echo "  forcing aspect ratio to $AR"
    WT="$(echo "$AR*$HT" | bc)"
    xT="$(echo "$xB+($WB-$WT)/2" | bc)"
    echo "    width changed from $WB to $WT"
    echo "    horizontal position changed from $xB to $xT"
fi

# Add padding
if (( pad > 0 )); then
    WT="$(echo "$WT+$pad" | bc)"
    xT="$(echo "$xT-($pad)/2" | bc)"
    HT="$(echo "$HT+$pad" | bc)"
    yT="$(echo "$yT-($pad)/2" | bc)"
fi

# Round to integer
WT="$(echo "($WT+0.5)/1" | bc)" # round to int
HT="$(echo "($HT+0.5)/1" | bc)" # round to int
xT="$(echo "($xT+0.5)/1" | bc)" # round to int
yT="$(echo "($yT+0.5)/1" | bc)" # round to int

# Output final image
padded_rectangle="${WT}x${HT}+${xT}+${yT}"
echo "  final rectangle = $padded_rectangle"
echo "  writing to $padded_image"
magick "$image" -crop "$padded_rectangle" +repage "$padded_image"