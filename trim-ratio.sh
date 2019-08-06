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
u_pad=${2-0}
h_pad=${3-0} # horizontal pad
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
image_upad="$out_folder/${name}_upad${u_pad}.jpg" # highest detail region + upad
image_upad_ar="$out_folder/${name}_upad${u_pad}_ar.jpg" # hdr + upad + forceAR
image_upad_hpad_ar="$out_folder/${name}_upad${u_pad}_hpad${h_pad}_ar.jpg" # hdr + upad + hpad + forceAR

echo "Processing image ${name} with size ${W}x${H} and AR=${AR}..."

# Get rectangle bounding highest definition region
# Optionally add $u_pad pixels of uniform padding
if (( u_pad > 0 )); then
    bounding_rectangle=$(magick "$image" -canny "$canny_parameters" -blur "${u_pad}"x65000 -format "%@" info:)
else
    bounding_rectangle=$(magick "$image" -canny "$canny_parameters" -format "%@" info:)
fi
echo "  bounding rectangle = $bounding_rectangle"
echo "  writing to $image_upad"
magick "$image" -crop "$bounding_rectangle" +repage "$image_upad"

# Exand image to retain aspect ratio
forceAspectRatio "$W" "$H" "$bounding_rectangle"
zeropad_rectangle=$__output
echo "  writing to $image_upad_ar"
[[ $zeropad_rectangle = "$bounding_rectangle" ]] && { echo "Nothing to trim, will exit"; exit; }
magick "$image" -crop "$zeropad_rectangle" +repage "$image_upad_ar"
assertAspectRatioEqual "$image" "$image_upad_ar"

# If no padding was requested we are done 
(( h_pad <= 0 )) && { echo "  No padding requested, will exit"; exit; }
echo "  will now apply horizontal pad of $h_pad pixels"

# Get transformed rectangle properties
WT=$(getW "$zeropad_rectangle")
HT=$(getH "$zeropad_rectangle")
xT=$(getX "$zeropad_rectangle")
yT=$(getY "$zeropad_rectangle")

# Pad the crop rectangle
WT=$(min "$W" "$(echo "$WT+2*$h_pad" | bc -l)")
xT=$(max 0 "$(echo "$xT-$h_pad" | bc -l)")
forceAspectRatio "$W" "$H" "$(getRectangle "$WT" "$HT" "$xT" "$yT")"
padded_rectangle=$__output
echo "  rectangle with pad = $padded_rectangle"
echo "  writing to $image_upad_hpad_ar"
magick "$image" -crop "$padded_rectangle" +repage "$image_upad_hpad_ar"
assertAspectRatioEqual "$image" "$image_upad_hpad_ar"
