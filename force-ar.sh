#! /usr/bin/env bash

# Given two numbers A and B, return success (0) if they are equal
# up to a given tolerance, return failure (1) otherwise.
# Arguments:
#  A: First number (float or int)
#  B: Second number (float or int)
#  tolerance: How much the numbers can differ, default is 0.001
# Returns:
#  Success (exit code 0) if the numbers are equal, failure (exit
#  code 1) otherwise.
# Example:
#  in> if assertEqual 1 1.1; then
#  in>  echo "Input numbers are equal"
#  in> else
#  in>  echo "Input numbers are different"
#  in> fi
#  out> "Input numbers are different"
function assertEqual {

    # Parse arguments
    local A=$1
    local B=$2
    local tolerance=${3-0.001}

    # Return |A/B-1| < tolerance
    local diff abs_diff
    diff=$(echo "$A/$B-1" | bc -l)
    abs_diff=$(abs "$diff")
    (( $(echo "$abs_diff < $tolerance" | bc -l) )) && return 0 || return 1
}

# Given a number, echo its absolute value
function abs {
    echo "if ($1 < 0) $1*-1 else $1" | bc -l
}

# Given two numbers, echo the smaller one
function min {
    echo "if ($1 < $2) $1 else $2" | bc -l
}

# Given two numbers, echo the bigger one
function max {
    echo "if ($1 < $2) $2 else $1" | bc -l
}

# Given a WxH+x+y rectangle, echo W
function getW {
    echo "$1" | sed -E -e 's/^([.0-9]+).*/\1/'
}

# Given a WxH+x+y rectangle, echo H
function getH {
    echo "$1" | sed -E -e 's/^.*x([.0-9]+)\+.*/\1/'
}

# Given a WxH+x+y rectangle, echo x
function getX {
    echo "$1" | sed -E -e 's/^.*\+([.0-9]+)\+.*/\1/'
}

# Given a WxH+x+y rectangle, echo y
function getY {
    echo "$1" | sed -E -e 's/^.*\+([.0-9]+)$/\1/'
}

# Given width (W), heigh (H), horizontal position (X) and 
# vertical position (Y), echo the WxH+x+y string representing
# a rectangle. 
function getRectangle {
    printf '%.0fx%.0f+%.0f+%.0f' "$1" "$2" "$3" "$4"
}

# Given a frame WxH and a rectangle B therein contained,
# extend B until it has the same aspect ratio of WxH.
# B will be kept as centered as possible.
# Arguments:
#  W: Width of the enclosing frame
#  H: Height of the enclosing frame
#  B: Rectangle B in the form WBxHB+xB+yB
# Returns:
#  The rectangle containing B expanded to have the same AR as the
#  frame, in the form WTxHT+xT+yT. The result is stored in the 
#  global variable __output
function forceAspectRatio {

    # Parse arguments
    local W=$1
    local H=$2
    local bRectangle=$3
    
    # Get bounding rectangle properties
    local WB HB xB yB
    WB=$(getW "$bRectangle")
    HB=$(getH "$bRectangle")
    xB=$(getX "$bRectangle")
    yB=$(getY "$bRectangle")
    [[ $bRectangle = ${WB}x${HB}+${xB}+${yB} ]] || { echo "Error extracting crop dimensions"; exit; }
    
    # Compute available space in the 4 directions
    local ST SB SL SR
    ST=$yB
    SB=$(echo "$H-$HB-$ST" | bc -l)
    SL=$xB
    SR=$(echo "$W-$WB-$SL" | bc -l)
    echo "  available space: top=${ST}, bottom=${SB}, left=${SL}, right=${SR}"
    
    # Initialize parameters of new crop area
    # The letter 'T' stands for Transformed
    local WT HT xT yT
    WT=$WB
    HT=$HB
    xT=$xB
    yT=$yB
    
    # Recover aspect ratio
    local AR D2
    AR=$(echo "$W/$H" | bc -l)
    printf '  forcing aspect ratio to %.0f\n' "$AR"
    if (( $(echo "$WB > $AR*$HB" | bc -l) )); then
        # Width is in excess => add padding vertically
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
        printf '    height changed from %.0f to %.0f\n' "$HB" "$HT"
        printf '    vertical position (y) changed from %.0f to %.0f\n' "$yB" "$yT"
    else
        # Height is in excess => add padding horizontally
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
        printf '    width changed from %.0f to %.0f\n' "$WB" "$WT"
        printf '    horizontal position changed from %.0f to %.0f\n' "$xB" "$xT"
    fi
    
    # Return transformed rectangle
    __output=$(getRectangle "$WT" "$HT" "$xT" "$yT")
    echo "    rectangle after forcing AR: $__output"

}

# If the file is invoked directly, execute the
# main function
[ "$0" = "${BASH_SOURCE[0]}" ] && { forceAspectRatio "$@"; }
