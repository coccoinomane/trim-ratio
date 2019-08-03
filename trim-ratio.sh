#! /usr/bin/env bash

# Trim and center image around the highest detail region
# without changing its aspect ratio.
#
# Optionally specify how many pixels to pad around the
# highest detail region; the padded pixels will be taken
# from the actual image.
# The padding is done preserving the aspect ratio.
#
# Requires bash with the bc arithmetical library.
#
# THANKS TO:
# Fred (fmw42) and Snibgo from ImageMagick forums
# (https://imagemagick.org/discourse-server/viewtopic.php?f=1&t=36443)

# Parse arguments
image="$1"
h_pad=${2-0} # horizontal pad
u_pad=${3-5}
out_folder=${4-.}

# Get of image info
name=$(magick "$image" -format "%t" info:)
W=$(magick "$image" -format "%[w]" info: )
H=$(magick "$image" -format "%[h]" info: )
AR=$(magick "$image" -format "%[fx:w/h]" info: )

# Output images
trimmed_image="$out_folder/${name}_upad${u_pad}_trim.jpg"
zeropad_image="$out_folder/${name}_upad${u_pad}_hpad0.jpg"
padded_image="$out_folder/${name}_upad${u_pad}_hpad${h_pad}.jpg"

echo "Processing image ${name} with size ${W}x${H} and AR=${AR}..."

# Get rectangle bounding highest definition area, and store its parts
bounding_rectangle=$(magick "$image" -canny 0x1+10%+30% -blur "${u_pad}"x65000 -format "%@" info:)
# bounding_rectangle=$(magick "$image" -canny 0x1+2%+8% -blur "${u_pad}"x65000 -format "%@" info:)
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
# The letter 'T' stands for Transformed 
WT=$WB
HT=$HB
xT=$xB
yT=$yB

# Recover aspect ratio
if (( $(echo "$WB > $AR*$HB" | bc) )); then
    # Width is in excess => add padding vertically
    echo "  forcing aspect ratio to $AR"
    HT="$(echo "$WB/$AR" | bc)"
    D2="$(echo "($HT-$HB)/2" | bc)" # delta_half = pad needed in the up & down direction
    yT="$(echo "$yB-$D2" | bc)"
    # Adjust vertical position of crop box
    if (( $(echo "$SB < $D2" | bc) )); then
        yT="$(echo "$H-$HT" | bc)"
    elif (( $(echo "$ST < $D2" | bc) )); then
        yT="0"
    fi
    echo "    height changed from $HB to $HT"
    echo "    vertical position (y) changed from $yB to $yT"
else
    # Height is in excess => add padding horizontally
    echo "  forcing aspect ratio to $AR"
    WT="$(echo "$AR*$HT" | bc)"
    D2="$(echo "($WT-$WB)/2" | bc)"
    xT="$(echo "$xB-$D2" | bc)"
    # Adjust horizontal position of crop box
    if (( $(echo "$SL < $D2" | bc) )); then
        xT="0"
    elif (( $(echo "$SR < $D2" | bc) )); then
        xT="$(echo "$W-$WT" | bc)"
    fi
    echo "    width changed from $WB to $WT"
    echo "    horizontal position changed from $xB to $xT"
fi

# Write zero padding image
zeropad_rectangle="${WT}x${HT}+${xT}+${yT}"
echo "  zeropad rectangle = $zeropad_rectangle"
echo "  writing to $zeropad_image"
magick "$image" -crop "$zeropad_rectangle" +repage "$zeropad_image"

# If no padding was requested we are done 
(( h_pad <= 0 )) && { echo "  No padding requested, will exit"; exit; }
echo "  will now apply uniform pad of $h_pad pixels"

# Add padding
# TODO: skip out-of-bounds paddings
v_pad=$(echo "$h_pad / $AR" | bc)
WT="$(echo "$WT+2*$h_pad" | bc)"
xT="$(echo "$xT-$h_pad" | bc)"
HT="$(echo "$HT+2*$v_pad" | bc)"
yT="$(echo "$yT-$v_pad" | bc)"

# Output final image
padded_rectangle="${WT}x${HT}+${xT}+${yT}"
echo "  rectangle with pad = $padded_rectangle"
echo "  writing to $padded_image"
magick "$image" -crop "$padded_rectangle" +repage "$padded_image"
