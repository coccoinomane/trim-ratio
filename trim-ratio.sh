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
# UPDATED VERSION ON GITHUB:
#  https://github.com/coccoinomane/trim-ratio
#
# THANKS TO:
#  Fred (fmw42) and Snibgo from ImageMagick forums
#  (https://imagemagick.org/discourse-server/viewtopic.php?f=1&t=36443)

# Parse arguments
image="$1"
h_pad=${2-0} # horizontal pad
u_pad=${3-5}
out_folder=${4-.}

# Dependencies
source force-ar.sh

# Fixed parameters
canny_parameters="0x1+10%+30%"

# Get image info
name=$(magick "$image" -format "%t" info:)
W=$(magick "$image" -format "%[w]" info: )
H=$(magick "$image" -format "%[h]" info: )
AR=$(magick "$image" -format "%[fx:w/h]" info: )

# Output images
trimmed_image="$out_folder/${name}_upad${u_pad}_trim.jpg"
zeropad_image="$out_folder/${name}_upad${u_pad}_hpad0.jpg"
padded_image="$out_folder/${name}_upad${u_pad}_hpad${h_pad}.jpg"

echo "Processing image ${name} with size ${W}x${H} and AR=${AR}..."

# Get rectangle bounding highest definition region
bounding_rectangle=$(magick "$image" -canny "$canny_parameters" -blur "${u_pad}"x65000 -format "%@" info:)
echo "  bounding rectangle = $bounding_rectangle" 
magick "$image" -crop "$bounding_rectangle" +repage "$trimmed_image"

# Exand image to retain aspect ratio
forceAspectRatio "$W" "$H" "$bounding_rectangle"
zeropad_rectangle=$__output
echo "  writing to $zeropad_image"
[[ $zeropad_rectangle = "$bounding_rectangle" ]] && { echo "Nothing to trim, will exit"; exit; }
magick "$image" -crop "$zeropad_rectangle" +repage "$zeropad_image"

# If no padding was requested we are done 
(( h_pad <= 0 )) && { echo "  No padding requested, will exit"; exit; }
echo "  will now apply horizontal pad of $h_pad pixels"

# Get transformed rectangle properties
WT=$(getW "$zeropad_rectangle")
HT=$(getH "$zeropad_rectangle")
xT=$(getX "$zeropad_rectangle")
yT=$(getY "$zeropad_rectangle")

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
padded_rectangle=$(getRectangle "$WT" "$HT" "$xT" "$yT")
echo "  rectangle with pad = $padded_rectangle"
echo "  writing to $padded_image"
magick "$image" -crop "$padded_rectangle" +repage "$padded_image"

# Check aspect ratio is the same
ART=$(magick "$padded_image" -format "%[fx:w/h]" info:)
AR_tolerance=$(echo "1/$(min "$WT" "$HT")" | bc -l)
assertEqual "$AR" "$ART" "$AR_tolerance" || echo "  WARNING: Found AR discrepance for $name => AR_in=$AR, AR_out=$ART"
