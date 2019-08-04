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

# Fixed parameters
AR_tolerance="10^-3"
canny_parameters="0x1+10%+30%"

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
bounding_rectangle=$(magick "$image" -canny "$canny_parameters" -blur "${u_pad}"x65000 -format "%@" info:)
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
if (( $(echo "$WB > $AR*$HB" | bc -l) )); then
    # Width is in excess => add padding vertically
    echo "  forcing aspect ratio to $AR"
    HT="$(echo "$WB/$AR" | bc -l)"
    D2="$(echo "($HT-$HB)/2" | bc -l)" # delta_half = pad needed in the up & down direction
    yT="$(echo "$yB-$D2" | bc -l)"
    # Adjust vertical position of crop box
    if (( $(echo "$SB < $D2" | bc -l) )); then
        echo "    notice: object close to bottom edge, will pad more from top"
        yT="$(echo "$H-$HT" | bc -l)"
    elif (( $(echo "$ST < $D2" | bc -l) )); then
        echo "    notice: object close to top edge, will pad more from bottom"
        yT="0"
    fi
    echo "    height changed from $HB to $HT"
    echo "    vertical position (y) changed from $yB to $yT"
else
    # Height is in excess => add padding horizontally
    echo "  forcing aspect ratio to $AR"
    WT="$(echo "$AR*$HT" | bc -l)"
    D2="$(echo "($WT-$WB)/2" | bc -l)"
    xT="$(echo "$xB-$D2" | bc -l)"
    # Adjust horizontal position of crop box
    if (( $(echo "$SL < $D2" | bc -l) )); then
        echo "    notice: object close to left edge, will pad more from right"
        xT="0"
    elif (( $(echo "$SR < $D2" | bc -l) )); then
        echo "    notice: object close to right edge, will pad more from left"
        xT="$(echo "$W-$WT" | bc -l)"
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
echo "  will now apply horizontal pad of $h_pad pixels"

# Space around the AR image
ST=$yT
SB=$(echo "$H-$HT-$ST" | bc -l)
SL=$xT
SR=$(echo "$W-$WT-$SL" | bc -l)
echo "    available space: top=${ST}, bottom=${SB}, left=${SL}, right=${SR}"

# Find maximum possibile horizontal padding
h_pad_max=$h_pad
if (( $(echo "$SL<$h_pad_max" | bc -l) )); then
    h_pad_max=$SL
    echo "    notice: will reduce h_pad from $h_pad to $h_pad_max to stay in image left boundary"
fi
if (( $(echo "$SR<$h_pad_max" | bc -l) )); then
    h_pad_max=$SR
    echo "    notice: will reduce h_pad from $h_pad to $h_pad_max to stay in image right boundary"
fi
if (( $(echo "$ST<$h_pad_max/$AR" | bc -l) )); then
    h_pad_max=$(echo "$ST*$AR" | bc -l)
    echo "    notice: will reduce h_pad from $h_pad to $h_pad_max to stay in image top boundary"
fi
if (( $(echo "$SB<$h_pad_max/$AR" | bc -l) )); then
    h_pad_max=$(echo "$SB*$AR" | bc -l)
    echo "    notice: will reduce h_pad from $h_pad to $h_pad_max to stay in image bottom boundary"
fi

# Pad the crop rectangle
v_pad_max=$(echo "$h_pad_max/$AR" | bc -l)
WT="$(echo "$WT+2*$h_pad_max" | bc -l)"
xT="$(echo "$xT-$h_pad_max" | bc -l)"
HT="$(echo "$HT+2*$v_pad_max" | bc -l)"
yT="$(echo "$yT-$v_pad_max" | bc -l)"

# Output final image
padded_rectangle="${WT}x${HT}+${xT}+${yT}"
echo "  rectangle with pad = $padded_rectangle"
echo "  writing to $padded_image"
magick "$image" -crop "$padded_rectangle" +repage "$padded_image"

# Checks
ART=$(magick "$padded_image" -format "%[fx:w/h]" info:)
AR_diff=$(echo "$ART/$AR-1" | bc -l)
AR_diff=$(echo "if ($AR_diff < 0) $AR_diff*-1 else $AR_diff" | bc -l)
(( $(echo "$AR_diff > $AR_tolerance" | bc -l) )) && echo "  WARNING: Found AR discrepance for $name => AR_in=$AR, AR_out=$ART"
